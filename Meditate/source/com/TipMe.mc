import Toybox.Communications;

class TipMe {
	static function openTipMe(minutes) {
		Communications.openWebPage(
			"https://geigl.online/tipme/",
			{
				"meditate-minutes" => minutes.toString(),
				"utm_source" => "meditate_app",
				"utm_medium" => "garmin_watch",
				"utm_campaign" => "tip",
			},
			null
		);
	}
}
