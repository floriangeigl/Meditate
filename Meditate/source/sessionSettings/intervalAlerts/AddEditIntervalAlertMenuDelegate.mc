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
			var intervalVibeMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.intervalVibePatternMenu_title),
			});
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification), "", :noNotification, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longContinuous), "", :longContinuous, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longSound), "", :longSound, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longPulsating), "", :longPulsating, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longAscending), "", :longAscending, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_longDescending), "", :longDescending, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.vibePatternMenu_mediumContinuous),
					"",
					:mediumContinuous,
					{}
				)
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_mediumPulsating), "", :mediumPulsating, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_mediumAscending), "", :mediumAscending, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.vibePatternMenu_mediumDescending),
					"",
					:mediumDescending,
					{}
				)
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortContinuous), "", :shortContinuous, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortPulsating), "", :shortPulsating, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortAscending), "", :shortAscending, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.vibePatternMenu_shortDescending), "", :shortDescending, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.intervalVibePatternMenu_blip), "", :blip, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shortSound), "", :shortSound, {})
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shorterAscending),
					"",
					:shorterAscending,
					{}
				)
			);
			intervalVibeMenu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shorterContinuous),
					"",
					:shorterContinuous,
					{}
				)
			);

			var intervalVibePatternMenuDelegate = new IntervalVibePatternMenuDelegate(method(:onVibePatternChanged));
			Ui.pushView(intervalVibeMenu, intervalVibePatternMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :time) {
			var intervalTypeMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.intervalTypeMenu_title) });
			intervalTypeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.intervalTypeMenu_oneOff), "", :oneOff, {})
			);
			intervalTypeMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.intervalTypeMenu_repeat), "", :repeat, {})
			);
			var intervalTypeMenuDelegate = new IntervalTypeMenuDelegate(method(:onTypeChanged));
			Ui.pushView(intervalTypeMenu, intervalTypeMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :offset) {
			me.notifyIntervalAlertChanged();

			// Use custom two-column picker for MM:SS format
			var initialValue = me.mIntervalAlert.offset != null ? me.mIntervalAlert.offset : 0;
			var minutes = initialValue / 60;
			var seconds = initialValue % 60;
			// Clamp to picker ranges
			if (minutes < 0) { minutes = 0; }
			if (minutes > 59) { minutes = 59; }
			if (seconds < 0) { seconds = 0; }
			if (seconds > 59) { seconds = 59; }
			
			var titleString = Ui.loadResource(Rez.Strings.pickMMSS);
			if (titleString == null) { titleString = "Offset"; }
			var view = new TwoColumnPickerView({
				:title => titleString, :isHourMinute => false,
				:leftMin => 0, :leftMax => 59, :leftPad => 2, :leftSuffix => "m",
				:rightMin => 0, :rightMax => 59, :rightPad => 2, :rightSuffix => "s",
				:leftValue => minutes, :rightValue => seconds,
			});
			var delegate = new TwoColumnPickerDelegate(view, method(:onOffsetPicked), false);
			Ui.pushView(view, delegate, Ui.SLIDE_IMMEDIATE);
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

	function onVibePatternChanged(vibePattern) {
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

	function onTypeChanged(type) {
		me.mIntervalAlert.type = type;
		me.notifyIntervalAlertChanged();

		var initialValue = me.mIntervalAlert.time != null ? me.mIntervalAlert.time : 0;
		
		// Determine text color based on color theme (default to white if theme not set)
		var picker;
		var pickerDelegate;
		
		if (type == IntervalAlertType.OneOff) {
			// For one-off: H:MM format
			var totalMinutes = initialValue / 60;
			var hours = totalMinutes / 60;
			var minutes = totalMinutes % 60;
			// Clamp to picker ranges
			if (hours < 0) { hours = 0; }
			if (hours > 9) { hours = 9; }
			if (minutes < 0) { minutes = 0; }
			if (minutes > 59) { minutes = 59; }
			
			var titleString = Ui.loadResource(Rez.Strings.pickHMM);
			if (titleString == null) { titleString = "Duration"; }
			picker = new TwoColumnPickerView({
				:title => titleString, :isHourMinute => true,
				:leftMin => 0, :leftMax => 9, :leftPad => 1, :leftSuffix => "h",
				:rightMin => 0, :rightMax => 59, :rightPad => 2, :rightSuffix => "m",
				:leftValue => hours, :rightValue => minutes,
			});
			pickerDelegate = new TwoColumnPickerDelegate(picker, method(:onOneOffDurationPicked), true);
		} else {
			// For repeat: MM:SS format
			var minutes = initialValue / 60;
			var seconds = initialValue % 60;
			// Clamp to picker ranges
			if (minutes < 0) { minutes = 0; }
			if (minutes > 59) { minutes = 59; }
			if (seconds < 0) { seconds = 0; }
			if (seconds > 59) { seconds = 59; }
			
			var titleString = Ui.loadResource(Rez.Strings.pickMMSS);
			if (titleString == null) { titleString = "Duration"; }
			picker = new TwoColumnPickerView({
				:title => titleString, :isHourMinute => false,
				:leftMin => 0, :leftMax => 59, :leftPad => 2, :leftSuffix => "m",
				:rightMin => 0, :rightMax => 59, :rightPad => 2, :rightSuffix => "s",
				:leftValue => minutes, :rightValue => seconds,
			});
			pickerDelegate = new TwoColumnPickerDelegate(picker, method(:onRepeatDurationPicked), false);
		}
		
		// Push the duration picker on top of this menu so the user remains in
		// the Add/Edit Interval Alert menu after finishing the picker.
		Ui.pushView(picker, pickerDelegate, Ui.SLIDE_IMMEDIATE);
		me.updateMenuItems();
	}
}

// (Removed) IntervalOffsetPickerDelegate and IntervalDurationPickerDelegate: superseded by TwoColumnPickerDelegate
