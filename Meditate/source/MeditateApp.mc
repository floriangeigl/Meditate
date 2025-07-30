using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class MeditateApp extends App.AppBase {
	var heartbeatIntervalsSensor;

	function initialize() {
		heartbeatIntervalsSensor = null;
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state) {
		if (heartbeatIntervalsSensor == null) {
			heartbeatIntervalsSensor = new HrvAlgorithms.HeartbeatIntervalsSensor();
			// Ensure the heartbeat sensor is enabled and listening when app starts
			heartbeatIntervalsSensor.enableHrSensor();
			heartbeatIntervalsSensor.start();
		}
	}
	// onStop() is called when your application is exiting
	function onStop(state) {
		// Disable and remove listeners for heatbeat sensor
		if (heartbeatIntervalsSensor != null) {
			heartbeatIntervalsSensor.stop();
			heartbeatIntervalsSensor.disableHrSensor();
		}
		// TipMe.openTipMe(60);
	}

	// Return the initial view of your application here
	function getInitialView() {
		var mySettings = System.getDeviceSettings();
		var version = mySettings.monkeyVersion;
		var versionString = Lang.format("API version: $1$.$2$.$3$", version);
		System.println(versionString);
		var sessionStorage = new SessionStorage();
		var sessionPickerDelegate = new SessionPickerDelegate(sessionStorage, heartbeatIntervalsSensor);
		return [sessionPickerDelegate.createScreenPickerView(), sessionPickerDelegate];
	}
}
