using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using HrvAlgorithms.HrvTracking;
using Toybox.Application as App;

class AddEditSessionMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnChangeSession;
	private var mIntervalAlerts;
	private var mMenu;
	private var mSessionModel;

	function initialize(sessionModel, intervalAlerts, onChangeSession, menu) {
		Menu2InputDelegate.initialize();
		me.mSessionModel = sessionModel;
		me.mIntervalAlerts = intervalAlerts;
		me.mOnChangeSession = onChangeSession;
		me.mMenu = menu;
	}

	private static function getVibePatternText(vibePattern) {
		if (vibePattern == null) {
			vibePattern = VibePattern.NoNotification;
		}
		switch (vibePattern) {
			case VibePattern.LongPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longPulsating);
			case VibePattern.LongSound:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longSound);
			case VibePattern.LongAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longAscending);
			case VibePattern.LongContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longContinuous);
			case VibePattern.LongDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longDescending);
			case VibePattern.MediumAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumAscending);
			case VibePattern.MediumContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumContinuous);
			case VibePattern.MediumPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumPulsating);
			case VibePattern.MediumDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumDescending);
			case VibePattern.ShortAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortAscending);
			case VibePattern.ShortContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortContinuous);
			case VibePattern.ShortPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortPulsating);
			case VibePattern.ShortDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortDescending);
			default:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification);
		}
	}

	private function createHmmTimeLayoutBuilder() {
		var digitsLayout = new DigitsLayoutBuilder(Gfx.FONT_TINY);
		var outputXOffset = App.getApp().getProperty("hmmTimePickerOutputXOffset");
		digitsLayout.setOutputXOffset(outputXOffset);
		digitsLayout.addInitialHint(Ui.loadResource(Rez.Strings.pickHMM));
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 9 });
		digitsLayout.addSeparator("h");
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 5 });
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 9 });
		digitsLayout.addSeparator("m");
		return digitsLayout;
	}

	// Menu2 selection handler
	function onSelect(item) {
		var id = item.getId();
		if (id == :name) {
			var initial = "";
			if (me.mSessionModel.name != null) {
				initial = me.mSessionModel.name;
			}
			Ui.pushView(new Ui.TextPicker(initial), new SessionNamePickerDelegate(method(:onNamePicked)), Ui.SLIDE_LEFT);
			return;
		}
		if (id == :time) {
			var durationPickerModel = new DurationPickerModel(3);
			var hMmTimeLayoutBuilder = createHmmTimeLayoutBuilder();
			Ui.pushView(
				new DurationPickerView(durationPickerModel, hMmTimeLayoutBuilder),
				new DurationPickerDelegate(durationPickerModel, method(:onHmmDigitsPicked)),
				Ui.SLIDE_LEFT
			);
		} else if (id == :color) {
			var colors = [
				Gfx.COLOR_BLUE,
				Gfx.COLOR_DK_BLUE,
				Gfx.COLOR_DK_RED,
				Gfx.COLOR_DK_GREEN,
				Gfx.COLOR_DK_GRAY,
				Gfx.COLOR_RED,
				Gfx.COLOR_YELLOW,
				Gfx.COLOR_ORANGE,
				Gfx.COLOR_GREEN,
				Gfx.COLOR_LT_GRAY,
				Gfx.COLOR_PINK,
				Gfx.COLOR_PURPLE,
				Gfx.COLOR_WHITE,
			];
			Ui.pushView(
				new ColorPickerView(colors[0]),
				new ColorPickerDelegate(colors, method(:onColorSelected)),
				Ui.SLIDE_LEFT
			);
		} else if (id == :vibePattern) {
			// Programmatic Menu2 for vibe patterns so the delegate gets Menu2.MenuItems
			var vibeMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.vibePatternMenu_title) });
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification), "", :noNotification, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longContinuous), "", :longContinuous, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longSound), "", :longSound, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longPulsating), "", :longPulsating, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longAscending), "", :longAscending, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longDescending), "", :longDescending, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.vibePatternMenu_mediumContinuous),
					"",
					:mediumContinuous,
					{}
				)
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_mediumPulsating), "", :mediumPulsating, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_mediumAscending), "", :mediumAscending, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.vibePatternMenu_mediumDescending),
					"",
					:mediumDescending,
					{}
				)
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortContinuous), "", :shortContinuous, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortPulsating), "", :shortPulsating, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortAscending), "", :shortAscending, {})
			);
			vibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortDescending), "", :shortDescending, {})
			);
			// Interval-only patterns (blip/shortSound/shorter*) are not part of the general session vibe menu

			var vibePatternMenuDelegate = new VibePatternMenuDelegate(method(:onVibePatternPicked));
			Ui.pushView(vibeMenu, vibePatternMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :intervalAlerts) {
			// Build Menu2 root for interval alert settings so delegate can update subtexts
			var intervalAlertSettingsMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuIntervalAlertSettings_Title),
			});
			intervalAlertSettingsMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuIntervalAlertSettings_addNew), "", :addNew, {})
			);
			intervalAlertSettingsMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuIntervalAlertSettings_edit), "", :edit, {})
			);
			intervalAlertSettingsMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuIntervalAlertSettings_deleteAll), "", :deleteAll, {})
			);

			var intervalAlertsMenuDelegate = new IntervalAlertsMenuDelegate(
				me.mIntervalAlerts,
				method(:onIntervalAlertsChanged),
				intervalAlertSettingsMenu
			);
			if (intervalAlertsMenuDelegate.updateMenuItems != null) {
				intervalAlertsMenuDelegate.updateMenuItems();
			}
			Ui.pushView(intervalAlertSettingsMenu, intervalAlertsMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :activityType) {
			// Programmatic Menu2 for activity type
			var activityMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_title),
			});
			activityMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_meditating), "", :meditating, {})
			);
			activityMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_yoga), "", :yoga, {})
			);
			activityMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_breathing), "", :breathing, {})
			);
			activityMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNewActivityTypeOptions_generic), "", :generic, {})
			);
			var activityTypeDelegate = new MenuOptionsDelegate(method(:onActivityTypePicked));
			Ui.pushView(activityMenu, activityTypeDelegate, Ui.SLIDE_LEFT);
		} else if (id == :hrvTracking) {
			var hrvMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_title) });
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on), "", :on, {}));
			hrvMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed), "", :onDetailed, {})
			);
			hrvMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off), "", :off, {}));
			var hrvTrackingDelegate = new MenuOptionsDelegate(method(:onHrvTrackingPicked));
			Ui.pushView(hrvMenu, hrvTrackingDelegate, Ui.SLIDE_LEFT);
		}
	}

	// Public: refresh Menu2 subtexts to show current session values
	function updateMenuItems() {
		if (me.mMenu == null || me.mSessionModel == null) {
			return;
		}

		// 0: name
		var nameText = "";
		if (me.mSessionModel.name != null && me.mSessionModel.name != "") {
			nameText = me.mSessionModel.name;
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_name), nameText, :name, {}),
			0
		);

		// time
		var timeText = TimeFormatter.format(me.mSessionModel.time);
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), timeText, :time, {}),
			1
		);

		// color: show a textual placeholder; per-item text color isn't widely supported
		var colorText = "";
		if (me.mSessionModel.color == null) {
			colorText = "";
		} else if (me.mSessionModel.color == Gfx.COLOR_TRANSPARENT) {
			colorText = Ui.loadResource(Rez.Strings.intervalAlertTransparentColorText);
		} else {
			// no localized name for colors; show empty so the color is implied in other UI
			colorText = "";
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_color), colorText, :color, {}),
			2
		);

		// vibePattern
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.addEditSessionMenu_vibeSound),
				getVibePatternText(me.mSessionModel.vibePattern),
				:vibePattern,
				{}
			),
			3
		);

		// interval alerts - show count
		var alertsCount = me.mSessionModel.getIntervalAlerts().size();
		var alertsText = alertsCount == 0 ? "0" : alertsCount + "";
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.addEditSessionMenu_intervalAlerts),
				alertsText,
				:intervalAlerts,
				{}
			),
			4
		);

		// activity type
		var activityText = "";
		switch (me.mSessionModel.getActivityType()) {
			case ActivityType.Yoga:
				activityText = Ui.loadResource(Rez.Strings.activityNameYoga);
				break;
			case ActivityType.Breathing:
				activityText = Ui.loadResource(Rez.Strings.activityNameBreathing);
				break;
			default:
				activityText = Ui.loadResource(Rez.Strings.activityNameMeditate);
				break;
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.addEditSessionMenu_activityType),
				activityText,
				:activityType,
				{}
			),
			5
		);

		// hrv tracking
		var hrvText = "";
		switch (me.mSessionModel.getHrvTracking()) {
			case HrvTracking.On:
				hrvText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on);
				break;
			case HrvTracking.OnDetailed:
				hrvText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed);
				break;
			default:
				hrvText = Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off);
				break;
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_hrvTracking), hrvText, :hrvTracking, {}),
			6
		);
	}

	// Text picker callback for the session name
	function onNamePicked(text) {
		var sessionModel = new SessionModel();
		sessionModel.name = text;
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	// Small TextPickerDelegate that forwards the entered text to a callback
	class SessionNamePickerDelegate extends Ui.TextPickerDelegate {
		private var mOnTextEntered;

		function initialize(onTextEntered) {
			TextPickerDelegate.initialize();
			me.mOnTextEntered = onTextEntered;
		}

		function onTextEntered(text, changed) {
			if (me.mOnTextEntered != null) {
				me.mOnTextEntered.invoke(text);
			}
		}

		function onCancel() {
			// No-op
		}
	}

	function onHrvTrackingPicked(item) {
		var sessionModel = new SessionModel();
		if (item == :on) {
			sessionModel.setHrvTracking(HrvTracking.On);
		} else if (item == :onDetailed) {
			sessionModel.setHrvTracking(HrvTracking.OnDetailed);
		} else if (item == :off) {
			sessionModel.setHrvTracking(HrvTracking.Off);
		}
		// Update local model so the menu subtext can be refreshed immediately
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	function onActivityTypePicked(item) {
		var sessionModel = new SessionModel();
		if (item == :meditating) {
			sessionModel.setActivityType(ActivityType.Meditating);
		} else if (item == :yoga) {
			sessionModel.setActivityType(ActivityType.Yoga);
		} else if (item == :breathing) {
			sessionModel.setActivityType(ActivityType.Breathing);
		} else if (item == :generic) {
			sessionModel.setActivityType(ActivityType.Generic);
		}
		// Update local model so the menu subtext can be refreshed immediately
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	function onIntervalAlertsChanged(intervalAlerts) {
		var sessionModel = new SessionModel();
		sessionModel.setIntervalAlerts(intervalAlerts);
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	function onVibePatternPicked(vibePattern) {
		var sessionModel = new SessionModel();
		sessionModel.vibePattern = vibePattern;
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
		Vibe.vibrate(vibePattern);
	}

	function onHmmDigitsPicked(digits) {
		var sessionModel = new SessionModel();
		var durationMins = digits[0] * 60 + digits[1] * 10 + digits[2];
		sessionModel.time = durationMins * 60;
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	function onColorSelected(color) {
		var sessionModel = new SessionModel();
		sessionModel.color = color;
		me.mSessionModel.copyNonNullFieldsFromSession(sessionModel);
		me.mOnChangeSession.invoke(sessionModel);
		me.updateMenuItems();
	}

	// Ensure any pending changes are applied when the user presses Back to leave
	// this Add/Edit menu. We invoke the change callback with the current local
	// session model so the session picker can immediately refresh.
	function onBack() {
		me.mOnChangeSession.invoke(me.mSessionModel);
		Menu2InputDelegate.onBack();
		// Return false to let the default back pop behavior proceed.
		return false;
	}
}
