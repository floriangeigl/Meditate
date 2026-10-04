using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Sensor;
using Toybox.System;

class MeditateApp extends App.AppBase {
	var beatIntervalFeed;

	function initialize() {
		AppBase.initialize();
		me.beatIntervalFeed = null;
	}

	// onStart() is called on application start up
	function onStart(state) {}

	// multitasking devices only; app is back on screen and sensors are re-enabled
	function onActive(state) {
		if (me.beatIntervalFeed != null) {
			me.beatIntervalFeed.setForeground(true);
		}
		me.showSessionView(true);
	}

	// app keeps running off screen; sensor state must not be touched here
	function onInactive(state) {
		if (me.beatIntervalFeed != null) {
			me.beatIntervalFeed.setForeground(false);
		}
		me.showSessionView(false);
	}

	// going inactive is not one of the onHide triggers (push, pop, exit); the session view must
	// still stop its ball frames off screen. both calls are idempotent
	private function showSessionView(shown) {
		var view = Ui.getCurrentView()[0];
		if (view instanceof MeditateView) {
			if (shown) {
				view.onShow();
			} else {
				view.onHide();
			}
		}
	}

	// onStop() is called when your application is exiting
	function onStop(state) {
		// Disable and remove listeners for heatbeat sensor
		if (me.beatIntervalFeed != null) {
			me.beatIntervalFeed.shutdown();
		}
		// Defensive: work around firmware bug that can leave sensor callbacks
		// alive after app exit, causing battery drain (Venu 2, FR955, FR265, etc.)
		Sensor.setEnabledSensors([]);
		Sensor.enableSensorEvents(null);
	}

	// Return the initial view of your application here
	function getInitialView() {
		if (me.beatIntervalFeed == null) {
			me.beatIntervalFeed = new BeatIntervalFeed();
			me.beatIntervalFeed.startup();
		}
		// after the sensor startup, which must not be delayed
		UsageStats.flushOnStartup();
		// a tip postponed for lack of a phone connection
		MonthlyStats.tryOpenPendingTip();
		var sessionStorage = new SessionStorage();
		var sessionPickerDelegate = new SessionPickerDelegate(sessionStorage, me.beatIntervalFeed);

		// after the sensor startup above, which must not be delayed
		if (sessionStorage.isFreshInstall()) {
			// a first-time user has nothing to catch up on
			WhatsNewDelegate.markSeen();
		} else if (WhatsNewDelegate.hasUnseenNews()) {
			var whatsNewDelegate = new WhatsNewDelegate(sessionPickerDelegate);
			return [whatsNewDelegate.createView(), whatsNewDelegate];
		}
		return [sessionPickerDelegate.createScreenPickerView(), sessionPickerDelegate];
	}
}
