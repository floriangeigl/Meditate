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
	private var lastParams;
	private var askTip;
	private var lastMonthStats;

	function initialize() {
		me.gMeasurmentID = App.getApp().getProperty("gMeasurmentID");
		me.gApiSecret = App.getApp().getProperty("gApiSecret");
		me.lastParams = [];
		me.askTip = false;
		me.lastMonthStats = 0;
	}

	function sendCurrent(sessionTime) {
		var params = me.createParams(sessionTime);
		me.addToMonthly(sessionTime);
		me.send(params);
	}

	function createParams(sessionTime) {
		var devSettings = System.getDeviceSettings();
		var resolution = devSettings.screenWidth + "x" + devSettings.screenHeight;
		var apiVersion = Lang.format("$1$.$2$.$3$", devSettings.monkeyVersion);
		var systemLanguage = devSettings.systemLanguage;
		var deviceId = devSettings.uniqueIdentifier;
		var appVersion = Ui.loadResource(Rez.Strings.about_AppVersion);
		var sessionId = Cryptography.randomBytes(16);
		var options = {
			:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
			:toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
		};
		sessionId = StringUtil.convertEncodedString(sessionId, options);
		var events = [
			{
				"name" => "finished_meditation",
				"params" => {
					"engagement_time_msec" => sessionTime * 1000,
					"app_version" => appVersion,
					"resolution" => resolution,
					"api_version" => apiVersion,
					"session_id" => sessionId,
					"timestamp_micros" => Time.now().value() * 1000,
				},
			},
		];
		var device = {
			"operating_system" => "MonkeyC",
			"operating_system_version" => apiVersion,
			"screen_resolution" => resolution,
			"browser_version" => appVersion,
			"brand" => "Garmin",
			"category" => "watch",
		};
		var userProperties = {
			// add any custom properties here
			"systemLanguage" => {
				"value" => systemLanguage,
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
			System.println("Send cached stats");
			App.Storage.setValue(usageStatsCacheKey, null);
		}
	}

	function requestCallback(responseCode, data) {
		System.println("UsageStats request completed with response code: " + responseCode);
		if (me.lastParams.size() > 0) {
			var params = me.lastParams[0];
			me.lastParams.remove(params);
			if (responseCode >= 400) {
				//response didn' go thru; store and try next time.
				App.Storage.setValue(usageStatsCacheKey, params);
			}
		}
		if (me.askTip) {
			me.askTip = false;
			var mins = Math.round(me.lastMonthStats / 60);
			TipMe.openTipMe(mins);
			System.println("Asked for tip. (" + mins + "min)");
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
				if (me.lastMonthStats / 60 >= 120) {
					me.askTip = true;
				}
				monthlyStats = [];
			} else {
				current = monthlyStats[1];
			}
		}
		current += sessionTime;
		monthlyStats = [month_today, current];
		App.Storage.setValue(usageStatsMonthlyKey, monthlyStats);
		System.println("Set monthly stats: " + monthlyStats);
	}
}
