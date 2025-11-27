using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class MeditateApp extends App.AppBase {
	var heartbeatIntervalsSensor;

	function initialize() {
		AppBase.initialize();
		me.heartbeatIntervalsSensor = null;
	}

	// onStart() is called on application start up
	function onStart(state) {

	}
	// onStop() is called when your application is exiting
	function onStop(state) {
		// Disable and remove listeners for heatbeat sensor
		if (me.heartbeatIntervalsSensor != null) {
			me.heartbeatIntervalsSensor.shutdown();
		}
	}

	// Return the initial view of your application here
	function getInitialView() {
		if (me.heartbeatIntervalsSensor == null) {
			me.heartbeatIntervalsSensor = new HrvAlgorithms.HeartbeatIntervalsSensor(
				GlobalSettings.loadExternalSensor() == ExternalSensor.On
			);
			me.heartbeatIntervalsSensor.startup();
		}
		var sessionStorage = new SessionStorage();
		var sessionPickerDelegate = new SessionPickerDelegate(sessionStorage, heartbeatIntervalsSensor);
		return [sessionPickerDelegate.createScreenPickerView(), sessionPickerDelegate];
	}
}
