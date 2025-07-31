using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Cryptography;
using Toybox.Communications;
using Toybox.StringUtil;

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
	private var sessionId;
	private var userProperties;
	private var location;

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
		me.sessionId = Cryptography.randomBytes(16);
		var options = {
			:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
			:toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
		};
		me.sessionId = StringUtil.convertEncodedString(me.sessionId, options);
		me.events = [
			{
				"name" => "finished_meditation",
				"params" => {
					"engagement_time_msec" => me.sessionTime * 1000,
					"app_version" => me.appVersion,
					"resolution" => me.resolution,
					"api_version" => me.apiVersion,
					"session_id" => me.sessionId,
				},
			},
		];
		me.device = {
			"operating_system" => "MonkeyC",
			"operating_system_version" => me.apiVersion,
			"screen_resolution" => me.resolution,
			"browser_version" => me.appVersion,
			"brand" => "Garmin",
			"category" => "watch",
		};
		me.userProperties = {
			// add any custom properties here
			"systemLanguage" => {
				"value" => me.systemLanguage,
			},
		};
	}

	function sendUsageStats() {
		me.getLocation();
	}

	function getLocation() {
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
		};
		var url = "https://api.ipify.org?format=json";
		Communications.makeWebRequest(url, null, options, method(:send));
	}

	function send(responseCode, data) {
		var params = {
			"client_id" => me.deviceId,
			"user_id" => me.deviceId,
			"events" => me.events,
			"device" => me.device,
			"user_properties" => me.userProperties,
		};

		if (responseCode == 200 && data != null) {
			//me.location = {
			//	"city" => data["city"],
			//	"country_id" => data["country_code"],
			//};
			//params["user_location"] = me.location;
			params["ip_override"] = data["ip"];
		}

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
