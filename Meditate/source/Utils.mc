using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi as Ui;
using HrvAlgorithms.HrvTracking;

class Utils {
	// Clamp a numeric value to the inclusive [min, max] range
	static function clampToRange(value, min, max) {
		if (value < min) { return min; }
		if (value > max) { return max; }
		return value;
	}

	static function MonkeyVersionAtLeast(version) {
		var device_version = System.getDeviceSettings().monkeyVersion;
		device_version = device_version[0] * 10000 + device_version[1] * 100 + device_version[2];
		var compare_version = version[0] * 10000 + version[1] * 100 + version[2];
		return device_version >= compare_version ? true : false;
	}

	// per-device sport override; keyed by partNumber. add new devices here, not one-off checks
	private static var activityTypeOverridesByPartNumber = {
		"006-B3225-00" => { ActivityType.Meditating => ActivityType.Breathing }, // vivoactive4
		"006-B3388-00" => { ActivityType.Meditating => ActivityType.Breathing }, // vivoactive4
		"006-B3224-00" => { ActivityType.Meditating => ActivityType.Breathing }, // vivoactive4s
		"006-B3387-00" => { ActivityType.Meditating => ActivityType.Breathing }, // vivoactive4s
		"006-B3226-00" => { ActivityType.Meditating => ActivityType.Breathing }, // venu
		"006-B3389-00" => { ActivityType.Meditating => ActivityType.Breathing }, // venu
		"006-B3740-00" => { ActivityType.Meditating => ActivityType.Breathing }, // venud (Mercedes-Benz Collection)
		"006-B3737-00" => { ActivityType.Meditating => ActivityType.Breathing }, // venud (Mercedes-Benz Collection)
	};

	static function getEffectiveActivityType(selectedActivityType) {
		var overrides = Utils.activityTypeOverridesByPartNumber[System.getDeviceSettings().partNumber];
		if (overrides != null && overrides[selectedActivityType] != null) {
			return overrides[selectedActivityType];
		}
		return selectedActivityType;
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
	static function getHrvStatusText(status) {
		switch (status) {
			case HeartbeatIntervalsSensorStatus.Good:
				return Ui.loadResource(Rez.Strings.HRVready);
			case HeartbeatIntervalsSensorStatus.Weak:
				return Ui.loadResource(Rez.Strings.HRVweak);
			case HeartbeatIntervalsSensorStatus.Error:
				return Ui.loadResource(Rez.Strings.HRVwaiting);
			default:
				return Ui.loadResource(Rez.Strings.HRVwaiting);
		}
	}

	// step names are derived from the numbers, never typed by the user
	static function getBreathStepName(step) {
		if (step == null) {
			return "";
		}
		if (step.isHoldOnly()) {
			return (
				Ui.loadResource(Rez.Strings.breathPhase_hold) + " " + TimeFormatter.formatMinSec(step.cycleTime())
			);
		}
		var d = step.durations;
		// no holds at all reads as "6-6" rather than "6-0-6"
		if (d[BreathPhase.HoldFull] == 0 && d[BreathPhase.HoldEmpty] == 0) {
			return d[BreathPhase.Inhale].toString() + "-" + d[BreathPhase.Exhale].toString();
		}
		var last = BreathStep.PhaseCount - 1;
		while (last > 0 && d[last] == 0) {
			last--;
		}
		var name = d[0].toString();
		for (var i = 1; i <= last; i++) {
			name += "-" + d[i].toString();
		}
		return name;
	}

	static function getBreathStepDetail(step) {
		if (step == null) {
			return "";
		}
		var total = TimeFormatter.formatMinSec(step.totalTime());
		if (step.repeatType == BreathRepeat.Rounds && step.repeatValue > 1) {
			return "x" + step.repeatValue.toString() + " " + total;
		}
		return total;
	}

	static function getBreathRouteText(route) {
		switch (route) {
			case BreathRoute.Nose:
				return Ui.loadResource(Rez.Strings.breathRouteMenu_nose);
			case BreathRoute.Mouth:
				return Ui.loadResource(Rez.Strings.breathRouteMenu_mouth);
			default:
				return Ui.loadResource(Rez.Strings.breathRouteMenu_unset);
		}
	}

	// subtitle for the session menu row: "3 steps 6:00", or "Off"
	static function getBreathProgramText(breathProgram) {
		if (breathProgram == null || breathProgram.isEmpty()) {
			return Ui.loadResource(Rez.Strings.menuNotificationOptions_off);
		}
		return (
			breathProgram.size().toString() +
			" " +
			Ui.loadResource(Rez.Strings.breathProgramMenu_steps) +
			" " +
			TimeFormatter.formatMinSec(breathProgram.totalTime())
		);
	}

	static function getBreathCuesText(breathCues) {
		switch (breathCues) {
			case BreathCues.Off:
				return Ui.loadResource(Rez.Strings.menuNotificationOptions_off);
			case BreathCues.VibrationTone:
				return Ui.loadResource(Rez.Strings.menuBreathCuesOptions_vibrationTone);
			default:
				return Ui.loadResource(Rez.Strings.menuBreathCuesOptions_vibration);
		}
	}

	static function getSessionDisplayName(sessionModel, ordinalIndex) {
		if (sessionModel == null) { return ""; }
		if (sessionModel.name != null && sessionModel.name.length() > 0) {
			return sessionModel.name.toString();
		}
		var activityTypeText = Utils.getActivityTypeText(sessionModel.getActivityType());
		return activityTypeText + " " + (ordinalIndex + 1);
	}
}
