using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer;
using Toybox.Application as App;

class AddEditIntervalAlertMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnIntervalAlertChanged;
	private var mIntervalAlert;
	private var mIntervalAlertIndex;
	private var mOnIntervalAlertDeleted;
	private var notifyChangeTimer;

	private var mMenu;

	function initialize(intervalAlert, intervalAlertIndex, onIntervalAlertChanged, onIntervalAlertDeleted, menu) {
		Menu2InputDelegate.initialize();
		me.mOnIntervalAlertChanged = onIntervalAlertChanged;
		me.mIntervalAlert = intervalAlert;
		me.mIntervalAlertIndex = intervalAlertIndex;
		me.mOnIntervalAlertDeleted = onIntervalAlertDeleted;
		me.notifyChangeTimer = null;
		me.mMenu = menu;
	}

	// Update Menu2 subtexts to reflect current interval alert state
	function updateMenuItems() {
		if (me.mMenu == null || me.mIntervalAlert == null) {
			return;
		}

		// 0: vibePattern — map all known VibePattern values to readable labels.
		var vibeText = Utils.getVibePatternText(me.mIntervalAlert.vibePattern);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_vibeSound),
				vibeText,
				:vibePattern,
				{}
			),
			0
		);

		// 1: time (formatted)
		var timeText = TimeFormatter.format(me.mIntervalAlert.time);
		if (me.mIntervalAlert.type == IntervalAlertType.Repeat) {
			timeText = TimeFormatter.formatMinSec(me.mIntervalAlert.time);
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_time), timeText, :time, {}),
			1
		);

		// 2: offset
		var offsetText = TimeFormatter.formatMinSec(me.mIntervalAlert.offset);
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_offset), offsetText, :offset, {}),
			2
		);

		// 3: color (show transparent text if transparent)
		var colorText = "";
		if (me.mIntervalAlert.color == Gfx.COLOR_TRANSPARENT) {
			colorText = Ui.loadResource(Rez.Strings.intervalAlertTransparentColorText);
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_color), colorText, :color, {}),
			3
		);

		// 4: delete (no subtext)
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_delete), "", :delete, {}),
			4
		);
	}

	function onSelect(item) {
		var id = item.getId();
		if (id == :vibePattern) {
			var vibes = OptionMenu.intervalVibePatterns();
			OptionMenu.push(
				Rez.Strings.intervalVibePatternMenu_title,
				vibes[0],
				vibes[1],
				me.mIntervalAlert.vibePattern,
				vibes[2],
				method(:onVibePatternChanged),
				null
			);
		} else if (id == :time) {
			OptionMenu.push(
				Rez.Strings.intervalTypeMenu_title,
				[IntervalAlertType.OneOff, IntervalAlertType.Repeat],
				[Rez.Strings.intervalTypeMenu_oneOff, Rez.Strings.intervalTypeMenu_repeat],
				me.mIntervalAlert.type,
				null,
				method(:onTypeChanged),
				null
			);
		} else if (id == :offset) {
			me.notifyIntervalAlertChanged();
			DurationPicker.pushMinSec(me.mIntervalAlert.offset, method(:onOffsetPicked), Ui.SLIDE_IMMEDIATE);
		} else if (id == :color) {
			var colors = [
				Gfx.COLOR_RED,
				Gfx.COLOR_YELLOW,
				Gfx.COLOR_GREEN,
				Gfx.COLOR_ORANGE,
				Gfx.COLOR_BLUE,
				Gfx.COLOR_LT_GRAY,
				Gfx.COLOR_PINK,
				Gfx.COLOR_PURPLE,
				Gfx.COLOR_WHITE,
				Gfx.COLOR_DK_BLUE,
				Gfx.COLOR_DK_RED,
				Gfx.COLOR_DK_GREEN,
				Gfx.COLOR_DK_GRAY,
				Gfx.COLOR_TRANSPARENT,
			];
			Ui.pushView(
				new ColorPickerView(colors[0]),
				new ColorPickerDelegate(colors, method(:onColorPicked)),
				Ui.SLIDE_LEFT
			);
		} else if (id == :delete) {
			var confirmDeleteIntervalAlertHeader = Ui.loadResource(Rez.Strings.confirmDeleteIntervalAlertHeader);
			var confirmDeleteDialog = new Ui.Confirmation(confirmDeleteIntervalAlertHeader);
			Ui.pushView(confirmDeleteDialog, new YesDelegate(method(:onConfirmedDelete)), Ui.SLIDE_IMMEDIATE);
		}
	}

	function onConfirmedDelete() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mOnIntervalAlertDeleted.invoke(me.mIntervalAlertIndex);
	}

	private function notifyIntervalAlertChanged() {
		// stop any pending debounce first; rapid picks would otherwise stack timer slots
		if (me.notifyChangeTimer != null) {
			me.notifyChangeTimer.stop();
		}
		me.notifyChangeTimer = new Timer.Timer();
		me.notifyChangeTimer.start(method(:onNotifyIntervalAlertChanged), 500, false);
	}

	function onNotifyIntervalAlertChanged() {
		me.mOnIntervalAlertChanged.invoke(me.mIntervalAlertIndex, me.mIntervalAlert);
		me.notifyChangeTimer = null;
	}

	function onOneOffDurationPicked(value) {
		// value is total seconds from TwoColumnPicker
		me.mIntervalAlert.time = value;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	function onRepeatDurationPicked(value) {
		// value is total seconds from TwoColumnPicker
		me.mIntervalAlert.time = value;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	function onColorPicked(color) {
		me.mIntervalAlert.color = color;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	function onVibePatternChanged(tag, vibePattern) {
		me.mIntervalAlert.vibePattern = vibePattern;
		me.notifyIntervalAlertChanged();
		Vibe.vibrate(vibePattern);
		me.updateMenuItems();
	}

	function onOffsetPicked(value) {
		// value is total seconds from TwoColumnPicker
		me.mIntervalAlert.offset = value;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	// a one-off alert is picked as H:MM, a repeat interval as MM:SS; the picker stays on top of this menu
	function onTypeChanged(tag, type) {
		me.mIntervalAlert.type = type;
		me.notifyIntervalAlertChanged();
		if (type == IntervalAlertType.OneOff) {
			DurationPicker.pushHourMin(me.mIntervalAlert.time, method(:onOneOffDurationPicked), Ui.SLIDE_IMMEDIATE);
		} else {
			DurationPicker.pushMinSec(me.mIntervalAlert.time, method(:onRepeatDurationPicked), Ui.SLIDE_IMMEDIATE);
		}
		me.updateMenuItems();
	}
}
