using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
import Toybox.Communications;

class UsageStats {
	private var deviceId;
	private var appVersion;
	private var resolution;
	private var sessionTime;
	private var apiVersion;
	private var systemLanguage;
	private var gMeasurmentID;
	private var gApiSecret;
	private var events;
	private var device;

	function initialize(sessionTime) {
        var devSettings = System.getDeviceSettings();
		me.resolution = devSettings.screenWidth + "x" + devSettings.screenHeight;
        me.apiVersion = Lang.format("$1$.$2$.$3$", devSettings.monkeyVersion);
		me.systemLanguage = devSettings.systemLanguage;
		me.deviceId = devSettings.uniqueIdentifier;
		me.appVersion = Ui.loadResource(Rez.Strings.about_AppVersion);
		me.sessionTime = sessionTime;
		me.gMeasurmentID = App.getApp().getProperty("gMeasurmentID");
		me.gApiSecret = App.getApp().getProperty("gApiSecret");
		me.events = [
			{
				"name" => "finished_meditation",
				"params" => {
					"engagement_time_msec" => me.sessionTime * 1000,
					"app_version" => me.appVersion,
					"resolution" => me.resolution,
					"api_version" => me.apiVersion,
					"system_language" => me.systemLanguage,
				},
			},
		];
		me.device = {
			"language" => me.systemLanguage,
			"operating_system" => "MonkeyC",
			"operating_system_version" => me.apiVersion,
			"screen_resolution" => me.resolution,
			"app_version" => me.appVersion,
			"brand" => "Garmin",
            "category" => "watch"
		};
	}

	function sendUsageStats() {
		var params = {
			"client_id" => me.deviceId,
			"events" => me.events,
			"device" => me.device,
		};
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

    function requestCallback(responseCode, data) {
        System.println("UsageStats request completed with response code: " + responseCode);
    }
}
