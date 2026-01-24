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
	private static const usageStatsCacheKey = "usageStats_cache";
	private static const usageStatsMonthlyKey = "usageStats_monthly";
	private static const usageStatsTipPendingKey = "usageStats_tipPending";
	private var lastParams;
	private var currentParams;
	private var lastMonthStats;

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
			var mins = Math.ceil(pending[1] / 60);
			TipMe.openTipMe(mins);
			App.Storage.setValue(usageStatsTipPendingKey, null);
		} catch (ex) {
			// Never break the app due to optional tip prompt logic.
		}
	}

	function initialize(sessionTime) {
		me.gMeasurmentID = App.Properties.getValue("gMeasurmentID");
		me.gApiSecret = App.Properties.getValue("gApiSecret");
		me.lastParams = [];
		me.lastMonthStats = 0;
		me.currentParams = me.createParams(sessionTime);
		me.addToMonthly(sessionTime);
	}

	function sendCurrentWithLocation(responseCode, data) {
		if (responseCode == 200 && data != null) {
			me.currentParams["user_location"] = {
				"city" => data["city"],
				"country_id" => data["country_code"],
				"region_id" => data["country_code"] + "-" + data["region_code"],
			};
			me.currentParams["ip_override"] = truncateIP(data["ip"]);
		}
		me.send(me.currentParams);
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

	function send(params) {
		me.lastParams.add(params);
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

	function sendCached() {
		var params = App.Storage.getValue(usageStatsCacheKey);
		if (params != null) {
			me.send(params);
			// System.println("Send cached stats");
			App.Storage.setValue(usageStatsCacheKey, null);
		}
	}

	function requestCallback(responseCode, data) {
		// System.println("UsageStats request completed with response code: " + responseCode);
		if (me.lastParams.size() > 0) {
			var params = me.lastParams[0];
			me.lastParams.remove(params);
			if (responseCode >= 400) {
				//response didn' go thru; store and try next time.
				App.Storage.setValue(usageStatsCacheKey, params);
			}
		}
		UsageStats.tryOpenPendingTip();
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
