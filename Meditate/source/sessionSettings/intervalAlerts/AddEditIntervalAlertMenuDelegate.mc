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

			var durationPickerModel = new DurationPickerModel(4);
			var timeLayoutBuilder = me.createTimeLayoutMmSsBuilder();
			var durationPickerDelgate = new DurationPickerDelegate(durationPickerModel, method(:onOffsetPicked));
			var view = new DurationPickerView(durationPickerModel, timeLayoutBuilder);
			// Push the duration picker on top of this menu so that when the picker
			// pops itself the user returns to this Add/Edit Interval Alert menu.
			Ui.pushView(view, durationPickerDelgate, Ui.SLIDE_IMMEDIATE);
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

	function onOneOffDurationPicked(digits) {
		var durationInMins = digits[0] * 60 + digits[1] * 10 + digits[2];
		var durationInSeconds = durationInMins * 60;
		me.mIntervalAlert.time = durationInSeconds;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	function onRepeatDurationPicked(digits) {
		var durationInSeconds = digits[0] * 600 + digits[1] * 60 + digits[2] * 10 + digits[3];
		me.mIntervalAlert.time = durationInSeconds;
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

	function onOffsetPicked(digits) {
		var offsetInSeconds = digits[0] * 600 + digits[1] * 60 + digits[2] * 10 + digits[3];
		me.mIntervalAlert.offset = offsetInSeconds;
		me.notifyIntervalAlertChanged();
		me.updateMenuItems();
	}

	function onTypeChanged(type) {
		me.mIntervalAlert.type = type;
		me.notifyIntervalAlertChanged();

		var durationPickerModel;
		var durationPickerDelgate;
		var timeLayoutBuilder;
		if (type == IntervalAlertType.OneOff) {
			durationPickerModel = new DurationPickerModel(3);
			timeLayoutBuilder = me.createTimeLayoutHmmBuilder();
			durationPickerDelgate = new DurationPickerDelegate(durationPickerModel, method(:onOneOffDurationPicked));
		} else {
			durationPickerModel = new DurationPickerModel(4);
			timeLayoutBuilder = me.createTimeLayoutMmSsBuilder();
			durationPickerDelgate = new DurationPickerDelegate(durationPickerModel, method(:onRepeatDurationPicked));
		}
		var view = new DurationPickerView(durationPickerModel, timeLayoutBuilder);
		// Push the duration picker on top of this menu so the user remains in
		// the Add/Edit Interval Alert menu after finishing the picker.
		Ui.pushView(view, durationPickerDelgate, Ui.SLIDE_IMMEDIATE);
		me.updateMenuItems();
	}

	private function createTimeLayoutMmSsBuilder() {
		var digitsLayout = new DigitsLayoutBuilder(Gfx.FONT_SYSTEM_TINY);
		var outputXOffset = App.getApp().getProperty("mmssTimePickerOutputXOffset");
		digitsLayout.setOutputXOffset(outputXOffset);
		digitsLayout.addInitialHint(Ui.loadResource(Rez.Strings.pickMMSS));
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 5 });
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 9 });
		digitsLayout.addSeparator("m");
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 5 });
		digitsLayout.addDigit({ :minValue => 0, :maxValue => 9 });
		digitsLayout.addSeparator("s");
		return digitsLayout;
	}

	private function createTimeLayoutHmmBuilder() {
		var digitsLayout = new DigitsLayoutBuilder(Gfx.FONT_SYSTEM_TINY);
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
}
