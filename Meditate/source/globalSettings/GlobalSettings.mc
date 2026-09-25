using Toybox.Application as App;

// every globalSettings_* value, read with load and written with save; CloudBackup backs up exactly
// keys(). key strings and defaults are stored data, never change them
class GlobalSettings {
	static const HrvTrackingKey = "globalSettings_hrvTracking";
	static const ActivityTypeKey = "globalSettings_activityType";
	static const ConfirmSaveActivityKey = "globalSettings_confirmSaveActivity";
	static const MultiSessionKey = "globalSettings_multiSession";
	static const RespirationRateKey = "globalSettings_respirationRate";
	static const AutoStopKey = "globalSettings_autoStop";
	static const NotificationKey = "globalSettings_notification";
	static const ColorThemeKey = "globalSettings_colorTheme";
	static const PrepareTimeKey = "globalSettings_prapareTime"; // historical typo, do not fix
	static const FinalizeTimeKey = "globalSettings_finalizeTime";
	static const HrvWindowTimeKey = "globalSettings_hrvWindowTime";
	static const BreathCuesKey = "globalSettings_breathCues";
	static const UseSessionNameKey = "globalSettings_useSessionName";
	// markers, not user settings: the newest WhatsNewDelegate.NewsId dismissed, the preset migrations run
	static const LastSeenNewsIdKey = "globalSettings_lastSeenNewsId";
	static const PresetsVersionKey = "globalSettings_presetsVersion";

	static function load(key) {
		var value = App.Storage.getValue(key);
		return value == null ? GlobalSettings.defaultFor(key) : value;
	}

	static function save(key, value) {
		App.Storage.setValue(key, value);
	}

	// keep in step with defaultFor and the table in GlobalSettingsTests
	static function keys() {
		return [
			HrvTrackingKey,
			ActivityTypeKey,
			ConfirmSaveActivityKey,
			MultiSessionKey,
			RespirationRateKey,
			AutoStopKey,
			NotificationKey,
			ColorThemeKey,
			PrepareTimeKey,
			FinalizeTimeKey,
			HrvWindowTimeKey,
			BreathCuesKey,
			UseSessionNameKey,
			LastSeenNewsIdKey,
			PresetsVersionKey,
		];
	}

	// an if chain, not a cached table: nothing stays in memory (see CLAUDE.md runtime memory)
	private static function defaultFor(key) {
		if (key.equals(HrvTrackingKey)) {
			return HrvTracking.OnDetailed;
		}
		if (key.equals(ActivityTypeKey)) {
			return ActivityType.Meditating;
		}
		if (key.equals(ConfirmSaveActivityKey)) {
			return ConfirmSaveActivity.Ask;
		}
		if (key.equals(MultiSessionKey)) {
			return MultiSession.No;
		}
		if (key.equals(RespirationRateKey)) {
			return RespirationRate.On;
		}
		if (key.equals(AutoStopKey)) {
			return AutoStop.On;
		}
		if (key.equals(NotificationKey)) {
			return Notification.On;
		}
		if (key.equals(ColorThemeKey)) {
			return ColorTheme.Dark;
		}
		if (key.equals(PrepareTimeKey)) {
			return 15;
		}
		if (key.equals(FinalizeTimeKey)) {
			return 0;
		}
		if (key.equals(HrvWindowTimeKey)) {
			return 60;
		}
		if (key.equals(BreathCuesKey)) {
			return BreathCues.Vibration;
		}
		if (key.equals(UseSessionNameKey)) {
			return false;
		}
		if (key.equals(LastSeenNewsIdKey)) {
			return 0;
		}
		if (key.equals(PresetsVersionKey)) {
			return 0;
		}
		return null;
	}
}

module ConfirmSaveActivity {
	enum {
		Ask = 0,
		AutoNo = 1,
		AutoYes = 2,
		AutoYesExit = 3,
	}
}

module MultiSession {
	enum {
		No = 0,
		Yes = 1,
	}
}

module RespirationRate {
	enum {
		Off = 0,
		On = 1,
	}
}

module AutoStop {
	enum {
		Off = 0,
		On = 1,
	}
}

module Notification {
	enum {
		Off = 0,
		On = 1,
	}
}

module ColorTheme {
	enum {
		Dark = 0,
		Light = 1,
	}
}

module BreathCues {
	enum {
		Off = 0,
		Vibration = 1,
		VibrationTone = 2,
	}
}
