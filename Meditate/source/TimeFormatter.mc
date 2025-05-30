using Toybox.Lang;

class TimeFormatter {
	static function format(timeInSec) {
		var timeCalc = timeInSec;
		var seconds = timeCalc % 60;
		timeCalc /= 60;
		var minutes = timeCalc % 60;
		timeCalc /= 60;
		var hours = timeCalc % 24;

		if (minutes < 1) {
			return Lang.format("$1$:$2$:$3$", [hours.format("%02d"), minutes.format("%02d"), seconds.format("%02d")]);
		} else {
			return Lang.format("$1$:$2$", [hours.format("%02d"), minutes.format("%02d")]);
		}
	}
	static function formatMinSec(timeInSec) {
		var timeCalc = timeInSec;
		var seconds = timeCalc % 60;
		timeCalc /= 60;
		var minutes = timeCalc % 60;
		return Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);
	}
}
