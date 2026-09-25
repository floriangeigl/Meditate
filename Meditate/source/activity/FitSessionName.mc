using Toybox.Application as App;
using Toybox.Lang;
using Toybox.Math;
using Toybox.WatchUi as Ui;

// the activity name Garmin Connect shows: the session name when that setting is on, else the
// phone's activity name setting, else the title of the activity type
class FitSessionName {
	static function resolve(sessionName, effectiveActivityType) {
		if (
			GlobalSettings.load(GlobalSettings.UseSessionNameKey) &&
			sessionName != null &&
			sessionName.length() > 0
		) {
			return sessionName.toString();
		}
		var property = App.Properties.getValue("activityName");
		if (property != null && property.length() > 0) {
			return property.toString();
		}
		return Ui.loadResource(FitSessionName.defaultTitle(effectiveActivityType));
	}

	// follows the chosen type even when the sport falls back to training
	static function defaultTitle(effectiveActivityType) {
		if (effectiveActivityType == ActivityType.Yoga) {
			return Rez.Strings.sessionTitleYoga;
		}
		if (effectiveActivityType == ActivityType.Breathing) {
			return Rez.Strings.sessionTitleBreathing;
		}
		return Rez.Strings.sessionTitleMeditate;
	}

	// [time] becomes the planned length (5min, 1h, 1h 30min); the result is cut to 21 characters
	static function format(name, sessionSeconds) {
		var minutes = Math.round(sessionSeconds / 60.0).toNumber();
		var hours = minutes / 60;
		var time;
		if (hours < 1) {
			time = Lang.format("$1$min", [minutes]);
		} else {
			minutes = minutes % 60;
			time = minutes == 0 ? Lang.format("$1$h", [hours]) : Lang.format("$1$h $2$min", [hours, minutes]);
		}
		var result = name;
		var index = result.find("[time]");
		while (index != null) {
			result = result.substring(0, index) + time + result.substring(index + 6, result.length());
			index = result.find("[time]");
		}
		return result.length() > 21 ? result.substring(0, 21) : result;
	}
}
