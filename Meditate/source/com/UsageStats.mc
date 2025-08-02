using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Cryptography;
using Toybox.Communications;
using Toybox.StringUtil;

class UsageStats {
	private var gMeasurmentID;
	private var gApiSecret;
	private static const usageStatsCacheKey = "usageStats_cache";
	private var lastParams;

	function initialize() {
		me.gMeasurmentID = App.getApp().getProperty("gMeasurmentID");
		me.gApiSecret = App.getApp().getProperty("gApiSecret");
		me.lastParams = [];
	}

	function sendCurrent(sessionTime) {
		var params = me.createParams(sessionTime);
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
					"timestamp_micros" => Time.now().value() * 1000
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
			"user_properties" => userProperties
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
			if (responseCode >= 400 ) {
				//response didn' go thru; store and try next time.
				App.Storage.setValue(usageStatsCacheKey, params);
			}
		}
	}
}
