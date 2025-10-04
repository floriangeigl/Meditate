using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class MeditateApp extends App.AppBase {
	var heartbeatIntervalsSensor;

	function initialize() {
		me.heartbeatIntervalsSensor = null;
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state) {
		if (me.heartbeatIntervalsSensor == null) {
			me.heartbeatIntervalsSensor = new HrvAlgorithms.HeartbeatIntervalsSensor(GlobalSettings.loadExternalSensor() == ExternalSensor.On);
		}
	}
	// onStop() is called when your application is exiting
	function onStop(state) {
		// Disable and remove listeners for heatbeat sensor
		if (me.heartbeatIntervalsSensor != null) {
			me.heartbeatIntervalsSensor.stop();
			me.heartbeatIntervalsSensor = null;
		}
	}

	// Return the initial view of your application here
	function getInitialView() {
		var sessionStorage = new SessionStorage();
		var sessionPickerDelegate = new SessionPickerDelegate(sessionStorage, heartbeatIntervalsSensor);
		return [sessionPickerDelegate.createScreenPickerView(), sessionPickerDelegate];
	}
}
