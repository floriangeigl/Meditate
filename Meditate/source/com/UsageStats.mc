using Toybox.Application as App;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

// optional GA4 analytics: one event per saved session, queued on the watch and sent in one request.
// the monthly minutes and the tip prompt live in MonthlyStats
class UsageStats {
	// flat [endTime, seconds, endTime, seconds, ...], oldest first
	static const QueueKey = "usageStats_queue_v3";
	static const OldQueueKey = "usageStats_queue_v2";
	static const MaxQueued = 10;
	// 71 h: ga drops events backdated past 72 h
	static const MaxAgeSec = 255600;

	private static var sSending = false;

	private var mMeasurementId;
	private var mApiSecret;
	// the events in the request, put back if it fails
	private var mInFlight;

	// queued before any request, so an exit right after the save keeps the event
	static function record(sessionTime) {
		try {
			if (sessionTime == null) {
				return;
			}
			App.Storage.setValue(QueueKey, add(App.Storage.getValue(QueueKey), Time.now().value(), sessionTime));
			flush();
		} catch (ex) {}
	}

	static function flushOnStartup() {
		try {
			if (App.Storage.getValue(OldQueueKey) != null) {
				App.Storage.deleteValue(OldQueueKey);
			}
			flush();
		} catch (ex) {}
	}

	private static function flush() {
		var queue = App.Storage.getValue(QueueKey);
		if (sSending || queue == null || queue.size() == 0) {
			return;
		}
		// throws without secrets.xml, caught by the caller
		var stats = new UsageStats();
		sSending = true;
		stats.lookUpLocation();
	}

	// drops what is not a [Number, Number] pair or too old to be backdated; anything else starts over
	static function prune(queue, now) {
		var kept = [];
		if (queue instanceof Lang.Array) {
			for (var i = 0; i + 1 < queue.size(); i += 2) {
				var ts = queue[i];
				var seconds = queue[i + 1];
				if (ts instanceof Lang.Number && seconds instanceof Lang.Number && now - ts <= MaxAgeSec) {
					kept.add(ts);
					kept.add(seconds);
				}
			}
		}
		return kept;
	}

	static function add(queue, now, seconds) {
		queue = prune(queue, now);
		queue.add(now);
		queue.add(seconds);
		return cap(queue);
	}

	// failed events go back in front of those queued meanwhile
	static function requeue(sent, queue, now) {
		var merged = prune(sent, now);
		merged.addAll(prune(queue, now));
		return cap(merged);
	}

	// keeps the newest
	private static function cap(queue) {
		var excess = queue.size() - 2 * MaxQueued;
		return excess > 0 ? queue.slice(excess, null) : queue;
	}

	// ipapi.co answer -> ga user_location, null without a country
	static function locationFrom(data) {
		if (!(data instanceof Lang.Dictionary) || data["country_code"] == null) {
			return null;
		}
		var country = data["country_code"];
		var location = { "country_id" => country };
		if (data["region_code"] != null) {
			location["region_id"] = country + "-" + data["region_code"];
		}
		if (data["city"] != null) {
			location["city"] = data["city"];
		}
		return location;
	}

	static function payload(queue, location) {
		var settings = System.getDeviceSettings();
		var resolution = settings.screenWidth + "x" + settings.screenHeight;
		var apiVersion = Lang.format("$1$.$2$.$3$", settings.monkeyVersion);
		var firmware = Lang.format("$1$.$2$", settings.firmwareVersion);
		var language = settings has :systemLanguage ? settings.systemLanguage : "unknown";
		var appVersion = Ui.loadResource(Rez.Strings.about_AppVersion);
		var model = settings.partNumber;
		var events = [];
		for (var i = 0; i + 1 < queue.size(); i += 2) {
			events.add({
				"name" => "finished_meditation",
				// micros overflow a Number
				"timestamp_micros" => queue[i].toLong() * 1000000l,
				"params" => {
					"engagement_time_msec" => queue[i + 1] * 1000,
					"session_id" => queue[i],
					"app_version" => appVersion,
					"resolution" => resolution,
					"api_version" => apiVersion,
					"model" => model,
					"firmware_version" => firmware,
					"system_language" => language,
				},
			});
		}
		var payload = {
			"client_id" => settings.uniqueIdentifier,
			"user_id" => settings.uniqueIdentifier,
			"events" => events,
			"device" => {
				"operating_system" => "MonkeyC",
				"operating_system_version" => apiVersion,
				"screen_resolution" => resolution,
				"browser" => "Meditate",
				"browser_version" => appVersion,
				"brand" => "Garmin",
				"category" => "watch",
				"model" => model,
			},
			"user_properties" => {
				"systemLanguage" => { "value" => language },
				"firmwareVersion" => { "value" => firmware },
			},
		};
		if (location != null) {
			payload["user_location"] = location;
		}
		return payload;
	}

	function initialize() {
		me.mMeasurementId = App.Properties.getValue("gaMeasurementId");
		me.mApiSecret = App.Properties.getValue("gaApiSecret");
	}

	function lookUpLocation() {
		Communications.makeWebRequest(
			"https://ipapi.co/json/",
			null,
			{ :method => Communications.HTTP_REQUEST_METHOD_GET },
			method(:onLocation)
		);
	}

	// sends with or without a location; offline the send fails and the events go back
	function onLocation(responseCode, data) {
		try {
			me.send(responseCode == 200 ? locationFrom(data) : null);
		} catch (ex) {
			me.done(false);
		}
	}

	private function send(location) {
		var queue = prune(App.Storage.getValue(QueueKey), Time.now().value());
		if (queue.size() == 0) {
			me.done(true);
			return;
		}
		var body = payload(queue, location);
		// removed before sending, so an exit mid-request cannot send them twice
		me.mInFlight = queue;
		App.Storage.deleteValue(QueueKey);
		Communications.makeWebRequest(
			"https://www.google-analytics.com/mp/collect?api_secret=" + me.mApiSecret + "&measurement_id=" + me.mMeasurementId,
			body,
			{
				:method => Communications.HTTP_REQUEST_METHOD_POST,
				:headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
			},
			method(:onSent)
		);
	}

	function onSent(responseCode, data) {
		me.done(responseCode >= 200 && responseCode < 300);
	}

	private function done(sent) {
		try {
			if (!sent && me.mInFlight != null) {
				App.Storage.setValue(QueueKey, requeue(me.mInFlight, App.Storage.getValue(QueueKey), Time.now().value()));
			}
		} catch (ex) {}
		me.mInFlight = null;
		sSending = false;
	}
}
