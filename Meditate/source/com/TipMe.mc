import Toybox.Communications;

class TipMe {
	static function openTipMe(minutes) {
		Communications.openWebPage("https://geigl.online/tipme/", { "meditate-minutes" => minutes.toString }, null);
	}
}
