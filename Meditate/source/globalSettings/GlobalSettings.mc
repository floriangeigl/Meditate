using Toybox.Application as App;

// every globalSettings_* value: one table of key and default, read with load and written with save.
// CloudBackup backs up exactly keys(). key strings and defaults are stored data, never change them
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

	private static var sDefaults = null;

	// built on first use instead of in a static initialiser
	private static function defaults() {
		if (sDefaults == null) {
			sDefaults = {
				HrvTrackingKey => HrvTracking.OnDetailed,
				ActivityTypeKey => ActivityType.Meditating,
				ConfirmSaveActivityKey => ConfirmSaveActivity.Ask,
				MultiSessionKey => MultiSession.No,
				RespirationRateKey => RespirationRate.On,
				AutoStopKey => AutoStop.On,
				NotificationKey => Notification.On,
				ColorThemeKey => ColorTheme.Dark,
				PrepareTimeKey => 15,
				FinalizeTimeKey => 0,
				HrvWindowTimeKey => 60,
				BreathCuesKey => BreathCues.Vibration,
				UseSessionNameKey => false,
				LastSeenNewsIdKey => 0,
				PresetsVersionKey => 0,
			};
		}
		return sDefaults;
	}

	static function load(key) {
		var value = App.Storage.getValue(key);
		return value == null ? GlobalSettings.defaults()[key] : value;
	}

	static function save(key, value) {
		App.Storage.setValue(key, value);
	}

	static function keys() {
		return GlobalSettings.defaults().keys();
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
