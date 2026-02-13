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
		// Try to send any queued usage stats early (e.g. after reconnect).
		UsageStats.flushQueuedOnStartup();

		// Retry monthly tip prompt if it was postponed due to missing phone connection.
		UsageStats.tryOpenPendingTip();

		if (me.heartbeatIntervalsSensor == null) {
			me.heartbeatIntervalsSensor = new HrvAlgorithms.HeartbeatIntervalsSensor();
			me.heartbeatIntervalsSensor.startup();
		}
		var sessionStorage = new SessionStorage();
		var sessionPickerDelegate = new SessionPickerDelegate(sessionStorage, heartbeatIntervalsSensor);
		return [sessionPickerDelegate.createScreenPickerView(), sessionPickerDelegate];
	}
}
