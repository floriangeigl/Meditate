using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi as Ui;
using HrvAlgorithms.HrvTracking;

class Utils {
	static function MonkeyVersionAtLeast(version) {
		var device_version = System.getDeviceSettings().monkeyVersion;
		device_version = device_version[0] * 10000 + device_version[1] * 100 + device_version[2];
		var compare_version = version[0] * 10000 + version[1] * 100 + version[2];
		return device_version >= compare_version ? true : false;
	}

	static function getVibePatternText(vibePattern) {
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
			case VibePattern.ShorterAscending:
				return Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shorterAscending);
			case VibePattern.ShorterContinuous:
				return Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shorterContinuous);
			case VibePattern.Blip:
				return Ui.loadResource(Rez.Strings.intervalVibePatternMenu_blip);
			case VibePattern.ShortSound:
				return Ui.loadResource(Rez.Strings.intervalVibePatternMenu_shortSound);
			case VibePattern.NoNotification:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification);
			default:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification);
		}
	}

	static function getActivityTypeText(activityType) {
		switch (activityType) {
			case ActivityType.Meditating:
				return Ui.loadResource(Rez.Strings.activityNameMeditate);
			case ActivityType.Generic:
				return Ui.loadResource(Rez.Strings.activityNameGeneric);
			case ActivityType.Yoga:
				return Ui.loadResource(Rez.Strings.activityNameYoga);
			case ActivityType.Breathing:
				return Ui.loadResource(Rez.Strings.activityNameBreathing);
			default:
				// Fallback to meditating label if unknown
				return Ui.loadResource(Rez.Strings.activityNameMeditate);
		}
	}

	static function getHrvTrackingText(hrvTracking) {
		switch (hrvTracking) {
			case HrvTracking.On:
				return Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_on);
			case HrvTracking.OnDetailed:
				return Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_onDetailed);
			default:
				return Ui.loadResource(Rez.Strings.menuHrvTrackingOptions_off);
		}
	}
}
