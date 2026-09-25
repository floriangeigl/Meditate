using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// the session editor. createMenu() and updateMenuItems() both walk rows(), so a row's menu index
// is its position there. every edit changes the session in place and hands the whole session on
class AddEditSessionMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnChangeSession;
	private var mIntervalAlerts;
	private var mMenu;
	private var mSessionModel;

	// [id, title] in menu order
	private static function rows() {
		return [
			[:name, Rez.Strings.addEditSessionMenu_name],
			[:time, Rez.Strings.addEditSessionMenu_time],
			[:breathProgram, Rez.Strings.addEditSessionMenu_breathProgram],
			[:color, Rez.Strings.addEditSessionMenu_color],
			[:vibePattern, Rez.Strings.addEditSessionMenu_vibeSound],
			[:intervalAlerts, Rez.Strings.addEditSessionMenu_intervalAlerts],
			[:activityType, Rez.Strings.addEditSessionMenu_activityType],
			[:hrvTracking, Rez.Strings.addEditSessionMenu_hrvTracking],
		];
	}

	static function createMenu(sessionNumber) {
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) + " " + sessionNumber,
		});
		var rows = AddEditSessionMenuDelegate.rows();
		for (var i = 0; i < rows.size(); i++) {
			menu.addItem(new Ui.MenuItem(Ui.loadResource(rows[i][1]), "", rows[i][0], {}));
		}
		return menu;
	}

	function initialize(sessionModel, intervalAlerts, onChangeSession, menu) {
		Menu2InputDelegate.initialize();
		me.mSessionModel = sessionModel;
		me.mIntervalAlerts = intervalAlerts;
		me.mOnChangeSession = onChangeSession;
		me.mMenu = menu;
	}

	function onSelect(item) {
		var id = item.getId();
		if (id == :name) {
			var initial = me.mSessionModel.name != null ? me.mSessionModel.name : "";
			Ui.pushView(
				new Ui.TextPicker(initial),
				new SessionNamePickerDelegate(method(:onNamePicked)),
				Ui.SLIDE_LEFT
			);
		} else if (id == :breathProgram) {
			me.pushBreathProgramMenu();
		} else if (id == :time) {
			// with a breath program the steps define the length, so Time leads there instead
			if (me.mSessionModel.hasBreathProgram()) {
				me.pushBreathProgramMenu();
				return;
			}
			DurationPicker.pushHourMin(me.mSessionModel.time, method(:onTimePicked), Ui.SLIDE_LEFT);
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
			var vibes = OptionMenu.sessionVibePatterns();
			OptionMenu.push(
				Rez.Strings.vibePatternMenu_title,
				vibes[0],
				vibes[1],
				me.mSessionModel.vibePattern,
				vibes[2],
				method(:onVibePatternPicked),
				null
			);
		} else if (id == :intervalAlerts) {
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
			intervalAlertsMenuDelegate.updateMenuItems();
			Ui.pushView(intervalAlertSettingsMenu, intervalAlertsMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :activityType) {
			var activity = OptionMenu.activityTypes();
			OptionMenu.push(
				Rez.Strings.menuNewActivityTypeOptions_title,
				activity[0],
				activity[1],
				me.mSessionModel.getActivityType(),
				activity[2],
				method(:onActivityTypePicked),
				null
			);
		} else if (id == :hrvTracking) {
			var hrv = OptionMenu.hrvTracking();
			OptionMenu.push(
				Rez.Strings.menuHrvTrackingOptions_title,
				hrv[0],
				hrv[1],
				me.mSessionModel.getHrvTracking(),
				hrv[2],
				method(:onHrvTrackingPicked),
				null
			);
		}
	}

	private function pushBreathProgramMenu() {
		var menu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.addEditSessionMenu_breathProgram) });
		var breathProgramDelegate = new BreathProgramMenuDelegate(
			me.mSessionModel.getBreathProgram(),
			method(:onBreathProgramChanged),
			menu
		);
		breathProgramDelegate.rebuildMenuItems();
		Ui.pushView(menu, breathProgramDelegate, Ui.SLIDE_LEFT);
	}

	// refresh every row's subtitle to the current session values
	function updateMenuItems() {
		if (me.mMenu == null || me.mSessionModel == null) {
			return;
		}
		var rows = AddEditSessionMenuDelegate.rows();
		for (var i = 0; i < rows.size(); i++) {
			me.mMenu.updateItem(
				new Ui.MenuItem(Ui.loadResource(rows[i][1]), me.subtitleFor(rows[i][0]), rows[i][0], {}),
				i
			);
		}
	}

	// activity type and hrv read the effective value (the global default when unset) but never store it
	private function subtitleFor(id) {
		var session = me.mSessionModel;
		if (id == :name) {
			return session.name != null ? session.name : "";
		}
		if (id == :time) {
			return TimeFormatter.format(session.time);
		}
		if (id == :breathProgram) {
			return Utils.getBreathProgramText(session.getActiveBreathProgram());
		}
		if (id == :color) {
			// no localized colour names; only transparent gets a word
			return session.color == Gfx.COLOR_TRANSPARENT
				? Ui.loadResource(Rez.Strings.intervalAlertTransparentColorText)
				: "";
		}
		if (id == :vibePattern) {
			return Utils.getVibePatternText(session.vibePattern);
		}
		if (id == :intervalAlerts) {
			return session.getIntervalAlerts().size().toString();
		}
		if (id == :activityType) {
			return AddEditSessionMenuDelegate.labelOf(OptionMenu.activityTypes(), session.getActivityType());
		}
		return AddEditSessionMenuDelegate.labelOf(OptionMenu.hrvTracking(), session.getHrvTracking());
	}

	private static function labelOf(options, value) {
		var index = OptionMenu.indexOf(options[0], value);
		return index < 0 ? "" : OptionMenu.text(options[1][index]);
	}

	// the one write path: the whole session goes to storage, then the subtitles refresh
	private function publish() {
		me.mOnChangeSession.invoke(me.mSessionModel);
		me.updateMenuItems();
	}

	function onNamePicked(text) {
		me.mSessionModel.name = text;
		me.publish();
	}

	function onTimePicked(value) {
		me.mSessionModel.time = value;
		me.publish();
	}

	function onBreathProgramChanged(breathProgram) {
		me.mSessionModel.setBreathProgram(breathProgram);
		// the program owns the session length once it has any steps
		if (!breathProgram.isEmpty()) {
			me.mSessionModel.time = breathProgram.totalTime();
		}
		me.publish();
	}

	function onColorSelected(color) {
		me.mSessionModel.color = color;
		me.publish();
	}

	function onVibePatternPicked(tag, vibePattern) {
		me.mSessionModel.vibePattern = vibePattern;
		me.publish();
		Vibe.vibrate(vibePattern);
	}

	function onIntervalAlertsChanged(intervalAlerts) {
		me.mSessionModel.setIntervalAlerts(intervalAlerts);
		me.publish();
	}

	function onActivityTypePicked(tag, activityType) {
		me.mSessionModel.setActivityType(activityType);
		me.publish();
	}

	function onHrvTrackingPicked(tag, hrvTracking) {
		me.mSessionModel.setHrvTracking(hrvTracking);
		me.publish();
	}

	// back sends the session once more so the picker shows the final state, then pops as usual
	function onBack() {
		me.mOnChangeSession.invoke(me.mSessionModel);
		Menu2InputDelegate.onBack();
		return false;
	}

	// forwards the entered text; cancel changes nothing
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

		function onCancel() {}
	}
}
