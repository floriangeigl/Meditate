using Toybox.WatchUi as Ui;
using HrvAlgorithms.HrvTracking;

class GlobalSettingsMenuDelegate extends Ui.MenuInputDelegate {
	function initialize(onGlobalSettingsChanged) {
		MenuInputDelegate.initialize();
		mOnGlobalSettingsChanged = onGlobalSettingsChanged;
	}

	private var mOnGlobalSettingsChanged;

	function onMenuItem(item) {
		if (item == :hrvTracking) {
			var hrvTrackingDelegate = new MenuOptionsDelegate(method(:onHrvTrackingPicked));
			Ui.pushView(new Rez.Menus.newHrvTrackingOptionsMenu(), hrvTrackingDelegate, Ui.SLIDE_LEFT);
		} else if (item == :newActivityType) {
			var newActivityTypeDelegate = new MenuOptionsDelegate(method(:onNewActivityTypePicked));
			Ui.pushView(new Rez.Menus.newActivityTypeOptionsMenu(), newActivityTypeDelegate, Ui.SLIDE_LEFT);
		} else if (item == :confirmSaveActivity) {
			var confirmSaveActivityDelegate = new MenuOptionsDelegate(method(:onConfirmSaveActivityPicked));
			Ui.pushView(new Rez.Menus.confirmSaveActivityOptionsMenu(), confirmSaveActivityDelegate, Ui.SLIDE_LEFT);
		} else if (item == :multiSession) {
			var multiSessionDelegate = new MenuOptionsDelegate(method(:onMultiSessionPicked));
			Ui.pushView(new Rez.Menus.multiSessionOptionsMenu(), multiSessionDelegate, Ui.SLIDE_LEFT);
		} else if (item == :respirationRate) {
			// Respiration rate settings if supported
			if (HrvAlgorithms.RrActivity.isSensorSupported()) {
				var respirationRateDelegate = new MenuOptionsDelegate(method(:onRespirationRatePicked));
				Ui.pushView(new Rez.Menus.respirationRateOptionsMenu(), respirationRateDelegate, Ui.SLIDE_LEFT);
			} else {
				var respirationRateDelegate = new MenuOptionsDelegate(method(:onRespirationRateDisabledPicked));
				Ui.pushView(new Rez.Menus.respirationRateOptionsDisabledMenu(), respirationRateDelegate, Ui.SLIDE_LEFT);
			}
		} else if (item == :prepareTime) {
			var prepareTimeDelegate = new MenuOptionsDelegate(method(:onPrepareTimePicked));
			Ui.pushView(new Rez.Menus.prepareTimeOptionsMenu(), prepareTimeDelegate, Ui.SLIDE_LEFT);
		} else if (item == :finalizeTime) {
			var finalizeTimeDelegate = new MenuOptionsDelegate(method(:onFinalizeTimePicked));
			Ui.pushView(new Rez.Menus.finalizeTimeOptionsMenu(), finalizeTimeDelegate, Ui.SLIDE_LEFT);
		} else if (item == :autoStop) {
			var autoStopDelegate = new MenuOptionsDelegate(method(:onAutoStopPicked));
			Ui.pushView(new Rez.Menus.autoStopOptionMenu(), autoStopDelegate, Ui.SLIDE_LEFT);
		} else if (item == :notification) {
			var notificationDelegate = new MenuOptionsDelegate(method(:onNotificationPicked));
			Ui.pushView(new Rez.Menus.notificationOptionMenu(), notificationDelegate, Ui.SLIDE_LEFT);
		} else if (item == :colorTheme) {
			var colorThemeDelegate = new MenuOptionsDelegate(method(:onColorThemePicked));
			Ui.pushView(new Rez.Menus.colorThemeOptionsMenu(), colorThemeDelegate, Ui.SLIDE_LEFT);
		} else if (item == :hrvWindow) {
			var hrvWindowSizeDelegate = new MenuOptionsDelegate(method(:onHrvWindowSizePicked));
			Ui.pushView(new Rez.Menus.hrvWindowSizeOptionsMenu(), hrvWindowSizeDelegate, Ui.SLIDE_LEFT);
		}
	}

	function onConfirmSaveActivityPicked(item) {
		if (item == :ask) {
			GlobalSettings.saveConfirmSaveActivity(ConfirmSaveActivity.Ask);
		} else if (item == :autoYes) {
			GlobalSettings.saveConfirmSaveActivity(ConfirmSaveActivity.AutoYes);
		} else if (item == :autoYesExit) {
			GlobalSettings.saveConfirmSaveActivity(ConfirmSaveActivity.AutoYesExit);
		} else if (item == :autoNo) {
			GlobalSettings.saveConfirmSaveActivity(ConfirmSaveActivity.AutoNo);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onMultiSessionPicked(item) {
		if (item == :yes) {
			GlobalSettings.saveMultiSession(MultiSession.Yes);
		} else if (item == :no) {
			GlobalSettings.saveMultiSession(MultiSession.No);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onRespirationRatePicked(item) {
		if (item == :on) {
			GlobalSettings.saveRespirationRate(RespirationRate.On);
		} else if (item == :off) {
			GlobalSettings.saveRespirationRate(RespirationRate.Off);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onAutoStopPicked(item) {
		if (item == :on) {
			GlobalSettings.saveAutoStop(AutoStop.On);
		} else if (item == :off) {
			GlobalSettings.saveAutoStop(AutoStop.Off);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onNotificationPicked(item) {
		if (item == :on) {
			GlobalSettings.saveNotification(Notification.On);
		} else if (item == :off) {
			GlobalSettings.saveNotification(Notification.Off);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onColorThemePicked(item) {
		if (item == :Light) {
			GlobalSettings.saveColorTheme(ColorTheme.Light);
		} else if (item == :Dark) {
			GlobalSettings.saveColorTheme(ColorTheme.Dark);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onPrepareTimePicked(item) {
		if (item == :time_0s) {
			GlobalSettings.savePrepareTime(0);
		} else if (item == :time_15s) {
			GlobalSettings.savePrepareTime(15);
		} else if (item == :time_30s) {
			GlobalSettings.savePrepareTime(30);
		} else if (item == :time_45s) {
			GlobalSettings.savePrepareTime(45);
		} else if (item == :time_1m) {
			GlobalSettings.savePrepareTime(60);
		} else if (item == :time_2m) {
			GlobalSettings.savePrepareTime(120);
		} else if (item == :time_3m) {
			GlobalSettings.savePrepareTime(180);
		} else if (item == :time_4m) {
			GlobalSettings.savePrepareTime(240);
		} else if (item == :time_5m) {
			GlobalSettings.savePrepareTime(300);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onFinalizeTimePicked(item) {
		if (item == :time_0s) {
			GlobalSettings.saveFinalizeTime(0);
		} else if (item == :time_15s) {
			GlobalSettings.saveFinalizeTime(15);
		} else if (item == :time_30s) {
			GlobalSettings.saveFinalizeTime(30);
		} else if (item == :time_45s) {
			GlobalSettings.saveFinalizeTime(45);
		} else if (item == :time_1m) {
			GlobalSettings.saveFinalizeTime(60);
		} else if (item == :time_2m) {
			GlobalSettings.saveFinalizeTime(120);
		} else if (item == :time_3m) {
			GlobalSettings.saveFinalizeTime(180);
		} else if (item == :time_4m) {
			GlobalSettings.saveFinalizeTime(240);
		} else if (item == :time_5m) {
			GlobalSettings.saveFinalizeTime(300);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onRespirationRateDisabledPicked(item) {
		mOnGlobalSettingsChanged.invoke();
	}

	function onNewActivityTypePicked(item) {
		if (item == :meditating) {
			GlobalSettings.saveActivityType(ActivityType.Meditating);
		} else if (item == :yoga) {
			GlobalSettings.saveActivityType(ActivityType.Yoga);
		} else if (item == :breathing) {
			GlobalSettings.saveActivityType(ActivityType.Breathing);
		} else if (item == :generic) {
			GlobalSettings.saveActivityType(ActivityType.Generic);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onHrvTrackingPicked(item) {
		if (item == :on) {
			GlobalSettings.saveHrvTracking(HrvTracking.On);
		} else if (item == :onDetailed) {
			GlobalSettings.saveHrvTracking(HrvTracking.OnDetailed);
		} else if (item == :off) {
			GlobalSettings.saveHrvTracking(HrvTracking.Off);
		}
		mOnGlobalSettingsChanged.invoke();
	}

	function onHrvWindowSizePicked(item) {
		if (item == :time_30s) {
			GlobalSettings.saveHrvWindowTime(30);
		} else if (item == :time_1m) {
			GlobalSettings.saveHrvWindowTime(60);
		} else if (item == :time_2m) {
			GlobalSettings.saveHrvWindowTime(60*2);
		} else if (item == :time_3m) {
			GlobalSettings.saveHrvWindowTime(60*3);
		} else if (item == :time_5m) {
			GlobalSettings.saveHrvWindowTime(60*5);
		} else if (item == :time_10m) {
			GlobalSettings.saveHrvWindowTime(60*10);
		}
		mOnGlobalSettingsChanged.invoke();
	}
}
