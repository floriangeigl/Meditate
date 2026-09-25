using Toybox.WatchUi as Ui;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Application as App;

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
			var hrvVal = GlobalSettings.load(GlobalSettings.HrvTrackingKey);
			var focusIdx = 0;
			if (hrvVal == HrvTracking.OnDetailed) {
				focusIdx = 1;
			} else if (hrvVal == HrvTracking.Off) {
				focusIdx = 2;
			}
			var hrvMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_title),
				:focus => focusIdx,
			});
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on), "", :on, {}));
			hrvMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:onDetailed,
					{}
				)
			);
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off), "", :off, {}));
			var hrvTrackingDelegate = new MenuOptionsDelegate(method(:onHrvTrackingPicked));
			Ui.pushView(hrvMenu, hrvTrackingDelegate, Ui.SLIDE_LEFT);
		} else if (id == :newActivityType) {
			var actVal = GlobalSettings.load(GlobalSettings.ActivityTypeKey);
			var focusIdx = 0;
			if (actVal == ActivityType.Yoga) {
				focusIdx = 1;
			} else if (actVal == ActivityType.Generic) {
				focusIdx = 2;
			} else if (actVal == ActivityType.Breathing) {
				focusIdx = 3;
			}
			var actMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_newActivityType),
				:focus => focusIdx,
			});
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
			var csVal = GlobalSettings.load(GlobalSettings.ConfirmSaveActivityKey);
			var focusIdx = 0;
			if (csVal == ConfirmSaveActivity.AutoYes) {
				focusIdx = 1;
			} else if (csVal == ConfirmSaveActivity.AutoYesExit) {
				focusIdx = 2;
			} else if (csVal == ConfirmSaveActivity.AutoNo) {
				focusIdx = 3;
			}
			var confirmMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_confirmSaveActivity),
				:focus => focusIdx,
			});
			confirmMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuConfirmSaveActivityOptions_askSimple),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:ask,
					{}
				)
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
			var focusIdx = GlobalSettings.load(GlobalSettings.MultiSessionKey) == MultiSession.Yes ? 0 : 1;
			var multiMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuMultiSessionOptions_title),
				:focus => focusIdx,
			});
			multiMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuMultiSessionOptions_yes), "", :yes, {}));
			multiMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuMultiSessionOptions_no),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:no,
					{}
				)
			);
			var multiSessionDelegate = new MenuOptionsDelegate(method(:onMultiSessionPicked));
			Ui.pushView(multiMenu, multiSessionDelegate, Ui.SLIDE_LEFT);
		} else if (id == :respirationRate) {
			if (RrMetric.isSupported()) {
				var focusIdx = GlobalSettings.load(GlobalSettings.RespirationRateKey) == RespirationRate.On ? 0 : 1;
				var respirationMenu = new Ui.Menu2({
					:title => Ui.loadResource(Rez.Strings.menuRespirationRateOptions_title),
					:focus => focusIdx,
				});
				respirationMenu.addItem(
					new Ui.MenuItem(
						Ui.loadResource(Rez.Strings.menuRespirationRateOptions_on),
						Ui.loadResource(Rez.Strings.menuLabelDefault),
						:on,
						{}
					)
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
			var pt = GlobalSettings.load(GlobalSettings.PrepareTimeKey);
			var focusIdx = 0;
			if (pt == 15) {
				focusIdx = 1;
			} else if (pt == 30) {
				focusIdx = 2;
			} else if (pt == 45) {
				focusIdx = 3;
			} else if (pt == 60) {
				focusIdx = 4;
			} else if (pt == 120) {
				focusIdx = 5;
			} else if (pt == 180) {
				focusIdx = 6;
			} else if (pt == 240) {
				focusIdx = 7;
			} else if (pt == 300) {
				focusIdx = 8;
			}
			var prepareMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_prepareTime),
				:focus => focusIdx,
			});
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
			var ft = GlobalSettings.load(GlobalSettings.FinalizeTimeKey);
			var focusIdx = 0;
			if (ft == 15) {
				focusIdx = 1;
			} else if (ft == 30) {
				focusIdx = 2;
			} else if (ft == 45) {
				focusIdx = 3;
			} else if (ft == 60) {
				focusIdx = 4;
			} else if (ft == 120) {
				focusIdx = 5;
			} else if (ft == 180) {
				focusIdx = 6;
			}
			var finalizeMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_finalizeTime),
				:focus => focusIdx,
			});
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
			var focusIdx = GlobalSettings.load(GlobalSettings.AutoStopKey) == AutoStop.On ? 0 : 1;
			var autoStopMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_autoStop),
				:focus => focusIdx,
			});
			autoStopMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuAutoStopOptions_on),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:on,
					{}
				)
			);
			autoStopMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuAutoStopOptions_off), "", :off, {}));
			var autoStopDelegate = new MenuOptionsDelegate(method(:onAutoStopPicked));
			Ui.pushView(autoStopMenu, autoStopDelegate, Ui.SLIDE_LEFT);
		} else if (id == :notification) {
			var focusIdx = GlobalSettings.load(GlobalSettings.NotificationKey) == Notification.On ? 0 : 1;
			var notificationMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuNotificationOptions_title),
				:focus => focusIdx,
			});
			notificationMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuNotificationOptions_on),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:on,
					{}
				)
			);
			notificationMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNotificationOptions_off), "", :off, {})
			);
			var notificationDelegate = new MenuOptionsDelegate(method(:onNotificationPicked));
			Ui.pushView(notificationMenu, notificationDelegate, Ui.SLIDE_LEFT);
		} else if (id == :breathCues) {
			var cuesVal = GlobalSettings.load(GlobalSettings.BreathCuesKey);
			var focusIdx = 1;
			if (cuesVal == BreathCues.Off) {
				focusIdx = 0;
			} else if (cuesVal == BreathCues.VibrationTone) {
				focusIdx = 2;
			}
			var cuesMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_breathCues),
				:focus => focusIdx,
			});
			cuesMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNotificationOptions_off), "", :off, {}));
			cuesMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuBreathCuesOptions_vibration),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:vibration,
					{}
				)
			);
			cuesMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuBreathCuesOptions_vibrationTone), "", :vibrationTone, {})
			);
			Ui.pushView(cuesMenu, new MenuOptionsDelegate(method(:onBreathCuesPicked)), Ui.SLIDE_LEFT);
		} else if (id == :colorTheme) {
			var focusIdx = GlobalSettings.load(GlobalSettings.ColorThemeKey) == ColorTheme.Light ? 0 : 1;
			var themeMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_colorTheme),
				:focus => focusIdx,
			});
			themeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuColorThemeOptions_light), "", :Light, {})
			);
			themeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuColorThemeOptions_dark),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:Dark,
					{}
				)
			);
			var colorThemeDelegate = new MenuOptionsDelegate(method(:onColorThemePicked));
			Ui.pushView(themeMenu, colorThemeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :hrvWindow) {
			var w = GlobalSettings.load(GlobalSettings.HrvWindowTimeKey);
			var focusIdx = 0;
			if (w == 60) {
				focusIdx = 1;
			} else if (w == 120) {
				focusIdx = 2;
			} else if (w == 180) {
				focusIdx = 3;
			} else if (w == 300) {
				focusIdx = 4;
			} else if (w == 600) {
				focusIdx = 5;
			}
			var windowMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuHrvWindowSizeOptions_title),
				:focus => focusIdx,
			});
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_30s), "", :time_30s, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_1m),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:time_1m,
					{}
				)
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_2m), "", :time_2m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_3m), "", :time_3m, {})
			);
			windowMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_5m),
					Ui.loadResource(Rez.Strings.menuLabelRecommended),
					:time_5m,
					{}
				)
			);
			windowMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuPrepareTimeOptions_10m), "", :time_10m, {})
			);
			var hrvWindowSizeDelegate = new MenuOptionsDelegate(method(:onHrvWindowSizePicked));
			Ui.pushView(windowMenu, hrvWindowSizeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :useSessionName) {
			var focusIdx = GlobalSettings.load(GlobalSettings.UseSessionNameKey) ? 0 : 1;
			var useMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName),
				:focus => focusIdx,
			});
			useMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_on), "", :on, {})
			);
			useMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_off),
					Ui.loadResource(Rez.Strings.menuLabelDefault),
					:off,
					{}
				)
			);
			var useDelegate = new MenuOptionsDelegate(method(:onUseSessionNamePicked));
			Ui.pushView(useMenu, useDelegate, Ui.SLIDE_LEFT);
		} else if (id == :sensorRestart) {
			// Disable all HR sensors and exit the app cleanly
			App.getApp().beatIntervalFeed.shutdown();
			System.exit();
		}
	}

	// Helpers: update the Menu2 items' subtexts so they always show the current value
	function updateMenuItems() {
		if (mMenu == null) {
			return;
		}

		// 0: hrvTracking
		var hrvTracking = GlobalSettings.load(GlobalSettings.HrvTrackingKey);
		var hrvTrackingText = Utils.getHrvTrackingText(hrvTracking);
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_newHrvTracking),
				hrvTrackingText,
				:hrvTracking,
				{}
			),
			9
		);

		// 1: newActivityType
		var newActivityTypeText = "";
		var newActivityType = GlobalSettings.load(GlobalSettings.ActivityTypeKey);
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
			7
		);

		// 2: confirmSaveActivity
		var confirmSaveText = "";
		var saveActivityConfirmation = GlobalSettings.load(GlobalSettings.ConfirmSaveActivityKey);
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
		var multi = GlobalSettings.load(GlobalSettings.MultiSessionKey);
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
			12
		);

		// 4: respirationRate
		var respirationText = "";
		if (RrMetric.isSupported()) {
			var rr = GlobalSettings.load(GlobalSettings.RespirationRateKey);
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
			11
		);

		// 5: prepareTime
		var prepareTimeSeconds = GlobalSettings.load(GlobalSettings.PrepareTimeKey);
		var prepareText = TimeFormatter.formatMinSec(prepareTimeSeconds);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_prepareTime), prepareText, :prepareTime, {}),
			3
		);

		// 6: finalizeTime
		var finalizeTimeSeconds = GlobalSettings.load(GlobalSettings.FinalizeTimeKey);
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
		var autoStop = GlobalSettings.load(GlobalSettings.AutoStopKey);
		autoStopText =
			autoStop == AutoStop.On
				? Ui.loadResource(Rez.Strings.menuAutoStopOptions_on)
				: Ui.loadResource(Rez.Strings.menuAutoStopOptions_off);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_autoStop), autoStopText, :autoStop, {}),
			1
		);

		// 8: notification
		var notificationText =
			GlobalSettings.load(GlobalSettings.NotificationKey) == Notification.On
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

		// breathCues
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_breathCues),
				Utils.getBreathCuesText(GlobalSettings.load(GlobalSettings.BreathCuesKey)),
				:breathCues,
				{}
			),
			6
		);

		// 9: colorTheme
		var themeText =
			GlobalSettings.load(GlobalSettings.ColorThemeKey) == ColorTheme.Light
				? Ui.loadResource(Rez.Strings.menuColorThemeOptions_light)
				: Ui.loadResource(Rez.Strings.menuColorThemeOptions_dark);
		mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_colorTheme), themeText, :colorTheme, {}),
			0
		);

		// 10: hrvWindow
		var hrvWindowText = "";
		var w = GlobalSettings.load(GlobalSettings.HrvWindowTimeKey);
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
			10
		);

		// 11: useSessionName
		var useSessionNameText = GlobalSettings.load(GlobalSettings.UseSessionNameKey)
			? Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_on)
			: Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_off);
		mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName),
				useSessionNameText,
				:useSessionName,
				{}
			),
			8
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
			GlobalSettings.save(GlobalSettings.ConfirmSaveActivityKey, ConfirmSaveActivity.Ask);
		} else if (item == :autoYes) {
			GlobalSettings.save(GlobalSettings.ConfirmSaveActivityKey, ConfirmSaveActivity.AutoYes);
		} else if (item == :autoYesExit) {
			GlobalSettings.save(GlobalSettings.ConfirmSaveActivityKey, ConfirmSaveActivity.AutoYesExit);
		} else if (item == :autoNo) {
			GlobalSettings.save(GlobalSettings.ConfirmSaveActivityKey, ConfirmSaveActivity.AutoNo);
		}
		onChangedNotify();
	}

	function onMultiSessionPicked(item) {
		if (item == :yes) {
			GlobalSettings.save(GlobalSettings.MultiSessionKey, MultiSession.Yes);
		} else if (item == :no) {
			GlobalSettings.save(GlobalSettings.MultiSessionKey, MultiSession.No);
		}
		onChangedNotify();
	}

	function onRespirationRatePicked(item) {
		if (item == :on) {
			GlobalSettings.save(GlobalSettings.RespirationRateKey, RespirationRate.On);
		} else if (item == :off) {
			GlobalSettings.save(GlobalSettings.RespirationRateKey, RespirationRate.Off);
		}
		onChangedNotify();
	}

	function onAutoStopPicked(item) {
		if (item == :on) {
			GlobalSettings.save(GlobalSettings.AutoStopKey, AutoStop.On);
		} else if (item == :off) {
			GlobalSettings.save(GlobalSettings.AutoStopKey, AutoStop.Off);
		}
		onChangedNotify();
	}

	function onBreathCuesPicked(item) {
		if (item == :off) {
			GlobalSettings.save(GlobalSettings.BreathCuesKey, BreathCues.Off);
		} else if (item == :vibrationTone) {
			GlobalSettings.save(GlobalSettings.BreathCuesKey, BreathCues.VibrationTone);
		} else {
			GlobalSettings.save(GlobalSettings.BreathCuesKey, BreathCues.Vibration);
		}
		onChangedNotify();
	}

	function onNotificationPicked(item) {
		if (item == :on) {
			GlobalSettings.save(GlobalSettings.NotificationKey, Notification.On);
		} else if (item == :off) {
			GlobalSettings.save(GlobalSettings.NotificationKey, Notification.Off);
		}
		onChangedNotify();
	}

	function onColorThemePicked(item) {
		if (item == :Light) {
			GlobalSettings.save(GlobalSettings.ColorThemeKey, ColorTheme.Light);
		} else if (item == :Dark) {
			GlobalSettings.save(GlobalSettings.ColorThemeKey, ColorTheme.Dark);
		}
		onChangedNotify();
	}

	function onPrepareTimePicked(item) {
		if (item == :time_0s) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 0);
		} else if (item == :time_15s) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 15);
		} else if (item == :time_30s) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 30);
		} else if (item == :time_45s) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 45);
		} else if (item == :time_1m) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 60);
		} else if (item == :time_2m) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 120);
		} else if (item == :time_3m) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 180);
		} else if (item == :time_4m) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 240);
		} else if (item == :time_5m) {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 300);
		}
		onChangedNotify();
	}

	function onFinalizeTimePicked(item) {
		if (item == :time_0s) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 0);
		} else if (item == :time_15s) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 15);
		} else if (item == :time_30s) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 30);
		} else if (item == :time_45s) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 45);
		} else if (item == :time_1m) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 60);
		} else if (item == :time_2m) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 120);
		} else if (item == :time_3m) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 180);
		} else if (item == :time_4m) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 240);
		} else if (item == :time_5m) {
			GlobalSettings.save(GlobalSettings.FinalizeTimeKey, 300);
		}
		onChangedNotify();
	}

	function onRespirationRateDisabledPicked(item) {
		// nothing to save, but ensure labels refresh
		onChangedNotify();
	}

	function onNewActivityTypePicked(item) {
		if (item == :meditating) {
			GlobalSettings.save(GlobalSettings.ActivityTypeKey, ActivityType.Meditating);
		} else if (item == :yoga) {
			GlobalSettings.save(GlobalSettings.ActivityTypeKey, ActivityType.Yoga);
		} else if (item == :breathing) {
			GlobalSettings.save(GlobalSettings.ActivityTypeKey, ActivityType.Breathing);
		} else if (item == :generic) {
			GlobalSettings.save(GlobalSettings.ActivityTypeKey, ActivityType.Generic);
		}
		onChangedNotify();
	}

	function onHrvTrackingPicked(item) {
		if (item == :on) {
			GlobalSettings.save(GlobalSettings.HrvTrackingKey, HrvTracking.On);
		} else if (item == :onDetailed) {
			GlobalSettings.save(GlobalSettings.HrvTrackingKey, HrvTracking.OnDetailed);
		} else if (item == :off) {
			GlobalSettings.save(GlobalSettings.HrvTrackingKey, HrvTracking.Off);
		}
		onChangedNotify();
	}

	function onHrvWindowSizePicked(item) {
		if (item == :time_30s) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 30);
		} else if (item == :time_1m) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 60);
		} else if (item == :time_2m) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 60 * 2);
		} else if (item == :time_3m) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 60 * 3);
		} else if (item == :time_5m) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 60 * 5);
		} else if (item == :time_10m) {
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 60 * 10);
		}
		onChangedNotify();
	}

	function onUseSessionNamePicked(item) {
		if (item == :on) {
			GlobalSettings.save(GlobalSettings.UseSessionNameKey, true);
		} else if (item == :off) {
			GlobalSettings.save(GlobalSettings.UseSessionNameKey, false);
		}
		onChangedNotify();
	}
}
