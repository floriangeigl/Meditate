using Toybox.WatchUi as Ui;
using HrvAlgorithms.HrvTracking;

class GlobalSettingsMenuDelegate extends Ui.Menu2InputDelegate {
	function initialize(onGlobalSettingsChanged, menu) {
		Menu2InputDelegate.initialize();
		mOnGlobalSettingsChanged = onGlobalSettingsChanged;
		mMenu = menu;
	}

	private var mOnGlobalSettingsChanged;
	private var mMenu;

	// Menu2: handle selection via the MenuItem passed
	function onSelect(item) {
		var id = item.getId();
		if (id == :hrvTracking) {
			var hrvMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_title) });
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on), "", :on, {}));
			hrvMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed), "", :onDetailed, {})
			);
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off), "", :off, {}));
			var hrvTrackingDelegate = new MenuOptionsDelegate(method(:onHrvTrackingPicked));
			Ui.pushView(hrvMenu, hrvTrackingDelegate, Ui.SLIDE_LEFT);
		} else if (id == :newActivityType) {
			var actMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_newActivityType) });
			actMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_meditating), "", :meditating, {})
			);
			actMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_yoga), "", :yoga, {})
			);
			actMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_generic), "", :generic, {})
			);
			actMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_breathing), "", :breathing, {})
			);
			var newActivityTypeDelegate = new MenuOptionsDelegate(method(:onNewActivityTypePicked));
			Ui.pushView(actMenu, newActivityTypeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :confirmSaveActivity) {
			var confirmMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_confirmSaveActivity),
			});
			confirmMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_askSimple), "", :ask, {})
			);
			confirmMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoYes), "", :autoYes, {})
			);
			confirmMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoYesExit),
					"",
					:autoYesExit,
					{}
				)
			);
			confirmMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoNo), "", :autoNo, {})
			);
			var confirmSaveActivityDelegate = new MenuOptionsDelegate(method(:onConfirmSaveActivityPicked));
			Ui.pushView(confirmMenu, confirmSaveActivityDelegate, Ui.SLIDE_LEFT);
		} else if (id == :multiSession) {
			var multiMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuMultiSessionOptions_title) });
			multiMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuMultiSessionOptions_yes), "", :yes, {}));
			multiMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuMultiSessionOptions_no), "", :no, {}));
			var multiSessionDelegate = new MenuOptionsDelegate(method(:onMultiSessionPicked));
			Ui.pushView(multiMenu, multiSessionDelegate, Ui.SLIDE_LEFT);
		} else if (id == :respirationRate) {
			if (HrvAlgorithms.RrActivity.isSensorSupported()) {
				var respirationMenu = new Ui.Menu2({
					:title => Ui.loadResource(Rez.Strings.menuRespirationRateOptions_title),
				});
				respirationMenu.addItem(
					new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuRespirationRateOptions_on), "", :on, {})
				);
				respirationMenu.addItem(
					new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuRespirationRateOptions_off), "", :off, {})
				);
				var respirationRateDelegate = new MenuOptionsDelegate(method(:onRespirationRatePicked));
				Ui.pushView(respirationMenu, respirationRateDelegate, Ui.SLIDE_LEFT);
			} else {
				var respirationMenu = new Ui.Menu2({
					:title => Ui.loadResource(Rez.Strings.menuRespirationRateOptions_title),
				});
				respirationMenu.addItem(
					new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuRespirationRateOptions_off), "", :off, {})
				);
				var respirationRateDelegate = new MenuOptionsDelegate(method(:onRespirationRateDisabledPicked));
				Ui.pushView(respirationMenu, respirationRateDelegate, Ui.SLIDE_LEFT);
			}
		} else if (id == :prepareTime) {
			var prepareMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_prepareTime) });
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_0s), "", :time_0s, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_15s), "", :time_15s, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_30s), "", :time_30s, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_45s), "", :time_45s, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_1m), "", :time_1m, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_2m), "", :time_2m, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_3m), "", :time_3m, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_4m), "", :time_4m, {})
			);
			prepareMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_5m), "", :time_5m, {})
			);
			var prepareTimeDelegate = new MenuOptionsDelegate(method(:onPrepareTimePicked));
			Ui.pushView(prepareMenu, prepareTimeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :finalizeTime) {
			var finalizeMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_finalizeTime) });
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_0s), "", :time_0s, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_15s), "", :time_15s, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_30s), "", :time_30s, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_45s), "", :time_45s, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_1m), "", :time_1m, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_2m), "", :time_2m, {})
			);
			finalizeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_3m), "", :time_3m, {})
			);
			var finalizeTimeDelegate = new MenuOptionsDelegate(method(:onFinalizeTimePicked));
			Ui.pushView(finalizeMenu, finalizeTimeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :autoStop) {
			var autoStopMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_autoStop) });
			autoStopMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuAutoStopOptions_on), "", :on, {}));
			autoStopMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuAutoStopOptions_off), "", :off, {}));
			var autoStopDelegate = new MenuOptionsDelegate(method(:onAutoStopPicked));
			Ui.pushView(autoStopMenu, autoStopDelegate, Ui.SLIDE_LEFT);
		} else if (id == :notification) {
			var notificationMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuNotificationOptions_title),
			});
			notificationMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNotificationOptions_on), "", :on, {})
			);
			notificationMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNotificationOptions_off), "", :off, {})
			);
			var notificationDelegate = new MenuOptionsDelegate(method(:onNotificationPicked));
			Ui.pushView(notificationMenu, notificationDelegate, Ui.SLIDE_LEFT);
		} else if (id == :colorTheme) {
			var themeMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_colorTheme) });
			themeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuColorThemeOptions_light), "", :Light, {})
			);
			themeMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuColorThemeOptions_dark), "", :Dark, {}));
			var colorThemeDelegate = new MenuOptionsDelegate(method(:onColorThemePicked));
			Ui.pushView(themeMenu, colorThemeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :externalSensor) {
			var extMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_externalSensor) });
			extMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuExternalSensorOptions_on), "", :on, {}));
			extMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuExternalSensorOptions_off), "", :off, {}));
			var externalSensorDelegate = new MenuOptionsDelegate(method(:onExternalSensorPicked));
			Ui.pushView(extMenu, externalSensorDelegate, Ui.SLIDE_LEFT);
		} else if (id == :hrvWindow) {
			var windowMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuHrvWindowSizeOptions_title) });
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_30s), "", :time_30s, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_1m), "", :time_1m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_2m), "", :time_2m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_3m), "", :time_3m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_5m), "", :time_5m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_10m), "", :time_10m, {})
			);
			var hrvWindowSizeDelegate = new MenuOptionsDelegate(method(:onHrvWindowSizePicked));
			Ui.pushView(windowMenu, hrvWindowSizeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :useSessionName) {
			var useMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName) });
			useMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_on), "", :on, {}));
			useMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_off), "", :off, {}));
			var useDelegate = new MenuOptionsDelegate(method(:onUseSessionNamePicked));
			Ui.pushView(useMenu, useDelegate, Ui.SLIDE_LEFT);
		}
	}

	// Helpers: update the Menu2 items' subtexts so they always show the current value
	function updateMenuItems() {
		if (mMenu == null) {
			return;
		}

		// 0: hrvTracking
		var hrvTrackingText = "";
		var hrvTracking = GlobalSettings.loadHrvTracking();
		if (hrvTracking == HrvTracking.On) {
			hrvTrackingText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on);
		} else if (hrvTracking == HrvTracking.OnDetailed) {
			hrvTrackingText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed);
		} else {
			hrvTrackingText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off);
		}
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_newHrvTracking),
				hrvTrackingText,
				:hrvTracking,
				{}
			),
			7
		);

		// 1: newActivityType
		var newActivityTypeText = "";
		var newActivityType = GlobalSettings.loadActivityType();
		if (newActivityType == ActivityType.Meditating) {
			newActivityTypeText = Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_meditating);
		} else if (newActivityType == ActivityType.Yoga) {
			newActivityTypeText = Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_yoga);
		} else if (newActivityType == ActivityType.Generic) {
			newActivityTypeText = Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_generic);
		} else {
			newActivityTypeText = Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_breathing);
		}
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_newActivityType),
				newActivityTypeText,
				:newActivityType,
				{}
			),
			6
		);

		// 2: confirmSaveActivity
		var confirmSaveText = "";
		var saveActivityConfirmation = GlobalSettings.loadConfirmSaveActivity();
		if (saveActivityConfirmation == ConfirmSaveActivity.AutoYes) {
			confirmSaveText = Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoYes);
		} else if (saveActivityConfirmation == ConfirmSaveActivity.AutoYesExit) {
			confirmSaveText = Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoYesExit);
		} else if (saveActivityConfirmation == ConfirmSaveActivity.AutoNo) {
			confirmSaveText = Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_autoNo);
		} else {
			confirmSaveText = Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_askSimple);
		}
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_confirmSaveActivity),
				confirmSaveText,
				:confirmSaveActivity,
				{}
			),
			2
		);

		// 3: multiSession
		var multiSessionText = "";
		var multi = GlobalSettings.loadMultiSession();
		if (multi == MultiSession.Yes) {
			multiSessionText = Ui.loadResource(Rez.Strings.menuMultiSessionOptions_yes);
		} else {
			multiSessionText = Ui.loadResource(Rez.Strings.menuMultiSessionOptions_no);
		}
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_multiSession),
				multiSessionText,
				:multiSession,
				{}
			),
			10
		);

		// 4: respirationRate
		var respirationText = "";
		if (HrvAlgorithms.RrActivity.isSensorSupported()) {
			var rr = GlobalSettings.loadRespirationRate();
			respirationText =
				rr == RespirationRate.On
					? Ui.loadResource(Rez.Strings.menuRespirationRateOptions_on)
					: Ui.loadResource(Rez.Strings.menuRespirationRateOptions_off);
		} else {
			respirationText = Ui.loadResource(Rez.Strings.menuRespirationRateOptions_off);
		}
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_respirationRate),
				respirationText,
				:respirationRate,
				{}
			),
			9
		);

		// 5: prepareTime
		var prepareTimeSeconds = GlobalSettings.loadPrepareTime();
		var prepareText = TimeFormatter.formatMinSec(prepareTimeSeconds);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_prepareTime), prepareText, :prepareTime, {}),
			3
		);

		// 6: finalizeTime
		var finalizeTimeSeconds = GlobalSettings.loadFinalizeTime();
		var finalizeText = TimeFormatter.formatMinSec(finalizeTimeSeconds);
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_finalizeTime),
				finalizeText,
				:finalizeTime,
				{}
			),
			4
		);

		// 7: autoStop
		var autoStopText = "";
		var autoStop = GlobalSettings.loadAutoStop();
		autoStopText =
			autoStop == AutoStop.On
				? Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on)
				: Ui.loadResource(Rez.Strings.menuAutoStopOptions_off);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_autoStop), autoStopText, :autoStop, {}),
			1
		);

		// 8: notification
		var notificationText =
			GlobalSettings.loadNotification() == Notification.On
				? Ui.loadResource(Rez.Strings.menuNotificationOptions_on)
				: Ui.loadResource(Rez.Strings.menuNotificationOptions_off);
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuNotificationOptions_title),
				notificationText,
				:notification,
				{}
			),
			5
		);

		// 9: colorTheme
		var themeText =
			GlobalSettings.loadColorTheme() == ColorTheme.Light
				? Ui.loadResource(Rez.Strings.menuColorThemeOptions_light)
				: Ui.loadResource(Rez.Strings.menuColorThemeOptions_dark);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_colorTheme), themeText, :colorTheme, {}),
			0
		);

		// 10: externalSensor
		var extText =
			GlobalSettings.loadExternalSensor() == ExternalSensor.On
				? Ui.loadResource(Rez.Strings.menuExternalSensorOptions_on)
				: Ui.loadResource(Rez.Strings.menuExternalSensorOptions_off);
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_externalSensor),
				extText,
				:externalSensor,
				{}
			),
			11
		);

		// 11: hrvWindow
		var hrvWindowText = "";
		var w = GlobalSettings.loadHrvWindowTime();
		if (w == 30) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_30s);
		} else if (w == 60) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_1m);
		} else if (w == 120) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_2m);
		} else if (w == 180) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_3m);
		} else if (w == 300) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_5m);
		} else if (w == 600) {
			hrvWindowText = Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_10m);
		}
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvWindowSizeOptions_title), hrvWindowText, :hrvWindow, {}),
			8
		);

		// 12: useSessionName
		var useSessionNameText = GlobalSettings.loadUseSessionName() ? Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_on) : Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_off);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName), useSessionNameText, :useSessionName, {}),
			12
		);
	}

	// When option menus save changes they call back here. Update Menu2 subtexts and notify parent.
	private function onChangedNotify() {
		updateMenuItems();
		if (mOnGlobalSettingsChanged != null) {
			mOnGlobalSettingsChanged.invoke();
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
		onChangedNotify();
	}

	function onMultiSessionPicked(item) {
		if (item == :yes) {
			GlobalSettings.saveMultiSession(MultiSession.Yes);
		} else if (item == :no) {
			GlobalSettings.saveMultiSession(MultiSession.No);
		}
		onChangedNotify();
	}

	function onRespirationRatePicked(item) {
		if (item == :on) {
			GlobalSettings.saveRespirationRate(RespirationRate.On);
		} else if (item == :off) {
			GlobalSettings.saveRespirationRate(RespirationRate.Off);
		}
		onChangedNotify();
	}

	function onAutoStopPicked(item) {
		if (item == :on) {
			GlobalSettings.saveAutoStop(AutoStop.On);
		} else if (item == :off) {
			GlobalSettings.saveAutoStop(AutoStop.Off);
		}
		onChangedNotify();
	}

	function onNotificationPicked(item) {
		if (item == :on) {
			GlobalSettings.saveNotification(Notification.On);
		} else if (item == :off) {
			GlobalSettings.saveNotification(Notification.Off);
		}
		onChangedNotify();
	}

	function onColorThemePicked(item) {
		if (item == :Light) {
			GlobalSettings.saveColorTheme(ColorTheme.Light);
		} else if (item == :Dark) {
			GlobalSettings.saveColorTheme(ColorTheme.Dark);
		}
		onChangedNotify();
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
		onChangedNotify();
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
		onChangedNotify();
	}

	function onRespirationRateDisabledPicked(item) {
		// nothing to save, but ensure labels refresh
		onChangedNotify();
	}

	function onExternalSensorPicked(item) {
		if (item == :on) {
			GlobalSettings.saveExternalSensor(ExternalSensor.On);
		} else if (item == :off) {
			GlobalSettings.saveExternalSensor(ExternalSensor.Off);
		}
		onChangedNotify();
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
		onChangedNotify();
	}

	function onHrvTrackingPicked(item) {
		if (item == :on) {
			GlobalSettings.saveHrvTracking(HrvTracking.On);
		} else if (item == :onDetailed) {
			GlobalSettings.saveHrvTracking(HrvTracking.OnDetailed);
		} else if (item == :off) {
			GlobalSettings.saveHrvTracking(HrvTracking.Off);
		}
		onChangedNotify();
	}

	function onHrvWindowSizePicked(item) {
		if (item == :time_30s) {
			GlobalSettings.saveHrvWindowTime(30);
		} else if (item == :time_1m) {
			GlobalSettings.saveHrvWindowTime(60);
		} else if (item == :time_2m) {
			GlobalSettings.saveHrvWindowTime(60 * 2);
		} else if (item == :time_3m) {
			GlobalSettings.saveHrvWindowTime(60 * 3);
		} else if (item == :time_5m) {
			GlobalSettings.saveHrvWindowTime(60 * 5);
		} else if (item == :time_10m) {
			GlobalSettings.saveHrvWindowTime(60 * 10);
		}
		onChangedNotify();
	}

	function onUseSessionNamePicked(item) {
		if (item == :on) {
			GlobalSettings.saveUseSessionName(true);
		} else if (item == :off) {
			GlobalSettings.saveUseSessionName(false);
		}
		onChangedNotify();
	}
}
