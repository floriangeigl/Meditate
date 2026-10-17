using Toybox.WatchUi as Ui;

// the two duration pickers, both drawn 00:00 style; the title already names the columns.
// same ranges, starting-value clamping and returned seconds as the hand-built pickers had
class DurationPicker {
	// hours 0-9 and minutes; onAccept gets the total in seconds
	static function pushHourMin(seconds, onAccept, transition) {
		var minutes = (seconds == null ? 0 : seconds) / 60;
		var view = new TwoColumnPickerView({
			:title => Ui.loadResource(Rez.Strings.pickHMM),
			:isHourMinute => true,
			:leftMin => 0,
			:leftMax => 9,
			:leftPad => 1,
			:rightMin => 0,
			:rightMax => 59,
			:rightPad => 2,
			:leftValue => Utils.clampToRange(minutes / 60, 0, 9),
			:rightValue => Utils.clampToRange(minutes % 60, 0, 59),
		});
		Ui.pushView(view, new TwoColumnPickerDelegate(view, onAccept, true), transition);
	}

	// minutes 0-59 and seconds; onAccept gets the total in seconds
	static function pushMinSec(seconds, onAccept, transition) {
		var total = seconds == null ? 0 : seconds;
		var view = new TwoColumnPickerView({
			:title => Ui.loadResource(Rez.Strings.pickMMSS),
			:isHourMinute => false,
			:leftMin => 0,
			:leftMax => 59,
			:leftPad => 2,
			:rightMin => 0,
			:rightMax => 59,
			:rightPad => 2,
			:leftValue => Utils.clampToRange(total / 60, 0, 59),
			:rightValue => Utils.clampToRange(total % 60, 0, 59),
		});
		Ui.pushView(view, new TwoColumnPickerDelegate(view, onAccept, false), transition);
	}
}
