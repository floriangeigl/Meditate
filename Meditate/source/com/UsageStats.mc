using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Cryptography;
using Toybox.Communications;
using Toybox.StringUtil;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;

class UsageStats {
	private var gMeasurmentID;
	private var gApiSecret;
	// Queue of pending GA4 payloads: [{"id"=>Number, "ts"=>Number, "params"=>Dictionary}, ...]
	private static const usageStatsQueueKey = "usageStats_queue_v2";
	private static const usageStatsQueueMaxAgeSec = 3 * 24 * 60 * 60;
	private static const usageStatsQueueMaxItems = 50;
	private static var sFlushInProgress = false;
	private static const usageStatsMonthlyKey = "usageStats_monthly";
	private static const usageStatsTipPendingKey = "usageStats_tipPending";
	private var currentParams;
	private var lastMonthStats;
	private var mInFlightId;
	private var mLastLocation;

	static function flushQueuedOnStartup() {
		try {
			var stats = new UsageStats(null);
			// Attempt to get location first; if successful we'll enrich and flush.
			stats.flushQueueWithLocationLookup();
		} catch (ex) {
			// Never break the app due to optional usage stats.
		}
	}

	function flushQueueWithLocationLookup() {
		// Trigger the same location lookup; callback decides whether to flush.
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
		};
		var url = "https://ipapi.co/json/";
		Communications.makeWebRequest(url, null, options, method(:sendCurrentWithLocation));
	}

	static function tryOpenPendingTip() {
		try {
			var pending = App.Storage.getValue(usageStatsTipPendingKey);
			if (pending == null) {
				return;
			}
			// pending: [month_when_should_show, lastMonthStatsSeconds]
			if (pending.size() < 2 || pending[0] == null || pending[1] == null) {
				App.Storage.setValue(usageStatsTipPendingKey, null);
				return;
			}
			var month_today = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
			var pendingMonth = pending[0];
			if (month_today != pendingMonth) {
				// Next month started; drop the request so we don't show stale stats.
				App.Storage.setValue(usageStatsTipPendingKey, null);
				return;
			}
			var devSettings = System.getDeviceSettings();
			if (devSettings != null && (devSettings has :phoneConnected) && !devSettings.phoneConnected) {
				// Phone not connected; keep pending and retry later.
				return;
			}
			var mins = Math.ceil(pending[1] / 60.0);
			TipMe.openTipMe(mins);
			App.Storage.setValue(usageStatsTipPendingKey, null);
		} catch (ex) {
			// Never break the app due to optional tip prompt logic.
		}
	}

	function initialize(sessionTime) {
		me.gMeasurmentID = App.Properties.getValue("gMeasurmentID");
		me.gApiSecret = App.Properties.getValue("gApiSecret");
		me.lastMonthStats = 0;
		me.mInFlightId = null;
		me.mLastLocation = null;
		me.currentParams = null;
		if (sessionTime != null) {
			me.currentParams = me.createParams(sessionTime);
			me.addToMonthly(sessionTime);
		}
	}

	function sendCurrentWithLocation(responseCode, data) {
		var hadLocation = false;
		if (responseCode == 200 && data != null) {
			var ip = data["ip"];
			if (ip != null) {
				me.mLastLocation = {
					"user_location" => {
						"city" => data["city"],
						"country_id" => data["country_code"],
						"region_id" => data["country_code"] + "-" + data["region_code"],
					},
					"ip_override" => truncateIP(ip),
				};
				hadLocation = true;
			}
		}

		// Always enqueue the just-finished session.
		if (me.currentParams != null && hadLocation) {
			me.applyLocationToParams(me.currentParams, me.mLastLocation);
		}
		me.enqueue(me.currentParams);

		// Flush queued GA payloads when we have fresh location (preferred),
		// or when lookup failed but we're likely online (non-0 response).
		if (hadLocation) {
			me.applyLocationToQueued(me.mLastLocation);
			me.flushQueue();
		} else if (responseCode != null && responseCode != 0) {
			me.flushQueue();
		}
	}

	function truncateIP(ip) {
		ip = ip.toCharArray();
		var truncatedIP = "";
		var numSep = 0;
		for (var i = 0; i < ip.size(); i++) {
			if (ip[i] == '.') {
				numSep++;
				truncatedIP += ".";
			} else {
				if (numSep >= 3) {
					truncatedIP += "0";
					break;
				} else {
					truncatedIP += ip[i];
				}
			}
		}
		return truncatedIP;
	}

	function sendCurrent() {
		if (me.currentParams == null) {
			return;
		}
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
		};
		var url = "https://ipapi.co/json/";
		Communications.makeWebRequest(url, null, options, method(:sendCurrentWithLocation));
	}

	function createParams(sessionTime) {
		var devSettings = System.getDeviceSettings();
		var resolution = devSettings.screenWidth + "x" + devSettings.screenHeight;
		var apiVersion = Lang.format("$1$.$2$.$3$", devSettings.monkeyVersion);
		var systemLanguage = devSettings has :systemLanguage ? devSettings.systemLanguage : "unknown";
		var deviceId = devSettings.uniqueIdentifier;
		var firmwareVersion = Lang.format("$1$.$2$", devSettings.firmwareVersion);
		var appVersion = Ui.loadResource(Rez.Strings.about_AppVersion);
		var model = devSettings.partNumber;
		var sessionId = System.getTimer(); // returns ms since boot; overflows every 50d
		var events = [
			{
				"name" => "finished_meditation",
				"params" => {
					"engagement_time_msec" => sessionTime * 1000,
					"app_version" => appVersion,
					"resolution" => resolution,
					"api_version" => apiVersion,
					"session_id" => sessionId,
					"timestamp_micros" => Time.now().value() * 1000000,
					"model" => model,
					"firmware_version" => firmwareVersion,
					"system_language" => systemLanguage,
				},
			},
		];
		var device = {
			"operating_system" => "MonkeyC",
			"operating_system_version" => apiVersion,
			"screen_resolution" => resolution,
			"browser" => "Meditate",
			"browser_version" => appVersion,
			"brand" => "Garmin",
			"category" => "watch",
			"model" => model,
		};
		var userProperties = {
			// add any custom properties here
			"systemLanguage" => {
				"value" => systemLanguage,
			},
			"firmwareVersion" => {
				"value" => firmwareVersion,
			},
		};
		var statsParams = {
			"client_id" => deviceId,
			"user_id" => deviceId,
			"events" => events,
			"device" => device,
			"user_properties" => userProperties,
		};
		return statsParams;
	}

	private function send(params) {
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_POST,
			:headers => {
				"Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
			},
		};
		var url = "https://www.google-analytics.com/mp/collect";
		url += "?api_secret=" + me.gApiSecret;
		url += "&measurement_id=" + me.gMeasurmentID;
		Communications.makeWebRequest(url, params, options, method(:requestCallback));
	}

	function flushQueue() {
		// Only one flusher at a time; callbacks will continue the drain.
		if (sFlushInProgress) {
			return;
		}
		sFlushInProgress = true;
		me.flushNext();
	}

	private function enqueue(params) {
		if (params == null) {
			return;
		}
		var queue = me.loadQueue();
		var now = Time.now().value();
		queue = me.pruneQueue(queue, now);
		queue.add({
			"id" => me.newQueueId(now),
			"ts" => now,
			"params" => params,
		});
		queue = me.capQueue(queue);
		me.saveQueue(queue);
	}

	private function flushNext() {
		var queue = me.loadQueue();
		var now = Time.now().value();
		queue = me.pruneQueue(queue, now);
		me.saveQueue(queue);
		if (queue == null || queue.size() == 0) {
			sFlushInProgress = false;
			me.mInFlightId = null;
			return;
		}
		var entry = queue[0];
		if (entry == null || entry["id"] == null || entry["params"] == null) {
			// Drop corrupt entry and keep going.
			queue.remove(queue[0]);
			me.saveQueue(queue);
			me.flushNext();
			return;
		}
		me.mInFlightId = entry["id"];
		var params = entry["params"];
		if (me.mLastLocation != null) {
			me.applyLocationToParams(params, me.mLastLocation);
		}
		me.send(params);
	}

	private function loadQueue() {
		var queue = App.Storage.getValue(usageStatsQueueKey);
		if (queue == null) {
			queue = [];
		}
		return queue;
	}

	private function saveQueue(queue) {
		App.Storage.setValue(usageStatsQueueKey, queue);
	}

	private function pruneQueue(queue, now) {
		if (queue == null) {
			return [];
		}
		var keep = [];
		for (var i = 0; i < queue.size(); i++) {
			var entry = queue[i];
			if (entry == null || entry["ts"] == null || entry["params"] == null) {
				// Skip corrupt entries.
				continue;
			}
			// Ensure an id exists (older/corrupt stored queues might lack it).
			if (entry["id"] == null) {
				entry["id"] = me.newQueueId(now);
			}
			var ts = entry["ts"];
			if (ts != null && (now - ts) <= usageStatsQueueMaxAgeSec) {
				keep.add(entry);
			}
		}
		return keep;
	}

	private function applyLocationToQueued(location) {
		if (location == null) {
			return;
		}
		var queue = me.loadQueue();
		for (var i = 0; i < queue.size(); i++) {
			var entry = queue[i];
			if (entry == null) {
				continue;
			}
			var params = entry["params"];
			if (params != null) {
				me.applyLocationToParams(params, location);
				entry["params"] = params;
			}
		}
		me.saveQueue(queue);
	}

	private function applyLocationToParams(params, location) {
		if (params == null || location == null) {
			return;
		}
		// If we have fresh location, overwrite (queued items likely had none).
		if (location["user_location"] != null) {
			params["user_location"] = location["user_location"];
		}
		if (location["ip_override"] != null) {
			params["ip_override"] = location["ip_override"];
		}
	}

	private function capQueue(queue) {
		if (queue == null) {
			return [];
		}
		// Keep newest entries (drop oldest) if we exceed max.
		while (queue.size() > usageStatsQueueMaxItems) {
			queue.remove(queue[0]);
		}
		return queue;
	}

	private function newQueueId(nowSec) {
		// Unique-ish id: epoch seconds + ms-since-boot component.
		var jitter = System.getTimer() % 1000;
		return (nowSec * 1000) + jitter;
	}

	function requestCallback(responseCode, data) {
		// System.println("UsageStats request completed with response code: " + responseCode);
		var success = (responseCode != null && responseCode >= 200 && responseCode < 300);
		if (success) {
			// Remove the in-flight entry from the queue.
			var queue = me.loadQueue();
			var keep = [];
			for (var i = 0; i < queue.size(); i++) {
				var entry = queue[i];
				if (entry != null && entry["id"] != null && entry["id"] == me.mInFlightId) {
					// drop
				} else {
					keep.add(entry);
				}
			}
			me.saveQueue(keep);
			me.mInFlightId = null;
			// Continue flushing the remaining queue.
			me.flushNext();
		} else {
			// Network/offline/any non-2xx: keep queue as-is and stop flushing for now.
			sFlushInProgress = false;
			me.mInFlightId = null;
		}
	}

	function addToMonthly(sessionTime) {
		var monthlyStats = App.Storage.getValue(usageStatsMonthlyKey);
		var current = 0;
		var month_today = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
		if (monthlyStats == null) {
			monthlyStats = [];
		} else {
			var month_last_entry = monthlyStats[0];
			if (month_today != month_last_entry) {
				// reset monthly stats if the month has changed
				me.lastMonthStats = monthlyStats[1];
				if (me.lastMonthStats / 60 >= 30) {
					var existingPending = App.Storage.getValue(usageStatsTipPendingKey);
					if (existingPending == null || existingPending.size() < 1 || existingPending[0] != month_today) {
						App.Storage.setValue(usageStatsTipPendingKey, [month_today, me.lastMonthStats]);
					}
				}
				monthlyStats = [];
			} else {
				current = monthlyStats[1];
			}
		}
		current += sessionTime;
		monthlyStats = [month_today, current];
		App.Storage.setValue(usageStatsMonthlyKey, monthlyStats);
		// System.println("Set monthly stats: " + monthlyStats);
	}
}
