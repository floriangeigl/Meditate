using Toybox.Test;
using Toybox.Application as App;

// the settings are stored data: every key and default is typed out here as the released app stores
// it, so a renamed key or a changed default fails instead of silently changing users' apps
(:test)
class GlobalSettingsTests {
	// [constant, stored key, default, a value away from the default]
	private static function table() {
		return [
			[GlobalSettings.HrvTrackingKey, "globalSettings_hrvTracking", 2, 0],
			[GlobalSettings.ActivityTypeKey, "globalSettings_activityType", 0, 1],
			[GlobalSettings.ConfirmSaveActivityKey, "globalSettings_confirmSaveActivity", 0, 3],
			[GlobalSettings.MultiSessionKey, "globalSettings_multiSession", 0, 1],
			[GlobalSettings.RespirationRateKey, "globalSettings_respirationRate", 1, 0],
			[GlobalSettings.AutoStopKey, "globalSettings_autoStop", 1, 0],
			[GlobalSettings.NotificationKey, "globalSettings_notification", 1, 0],
			[GlobalSettings.ColorThemeKey, "globalSettings_colorTheme", 0, 1],
			[GlobalSettings.PrepareTimeKey, "globalSettings_prapareTime", 15, 45],
			[GlobalSettings.FinalizeTimeKey, "globalSettings_finalizeTime", 0, 30],
			[GlobalSettings.HrvWindowTimeKey, "globalSettings_hrvWindowTime", 60, 300],
			[GlobalSettings.BreathCuesKey, "globalSettings_breathCues", 1, 2],
			[GlobalSettings.UseSessionNameKey, "globalSettings_useSessionName", false, true],
			[GlobalSettings.LastSeenNewsIdKey, "globalSettings_lastSeenNewsId", 0, 7],
			[GlobalSettings.PresetsVersionKey, "globalSettings_presetsVersion", 0, 2],
		];
	}

	// the simulator's own settings survive the tests
	private static function snapshot() {
		var saved = {};
		var rows = GlobalSettingsTests.table();
		for (var i = 0; i < rows.size(); i++) {
			saved[rows[i][1]] = App.Storage.getValue(rows[i][1]);
		}
		return saved;
	}

	private static function restore(saved) {
		var keys = saved.keys();
		for (var i = 0; i < keys.size(); i++) {
			StorageSnapshot.put(keys[i], saved[keys[i]]);
		}
	}

	private static function contains(strings, value) {
		for (var i = 0; i < strings.size(); i++) {
			if (strings[i].equals(value)) {
				return true;
			}
		}
		return false;
	}

	(:test)
	static function keysAndDefaultsNeverChange(logger) {
		var saved = GlobalSettingsTests.snapshot();
		try {
			var rows = GlobalSettingsTests.table();
			var keys = GlobalSettings.keys();
			var ok = keys.size() == rows.size();
			for (var i = 0; i < rows.size(); i++) {
				var row = rows[i];
				App.Storage.deleteValue(row[1]);
				var value = GlobalSettings.load(row[1]);
				if (
					!row[0].equals(row[1]) ||
					!GlobalSettingsTests.contains(keys, row[1]) ||
					!StorageSnapshot.deepEquals(value, row[2])
				) {
					logger.debug("row " + i + " " + row[1] + " defaults to " + value);
					ok = false;
				}
			}
			GlobalSettingsTests.restore(saved);
			return ok;
		} catch (ex) {
			GlobalSettingsTests.restore(saved);
			throw ex;
		}
	}

	(:test)
	static function storedValuesComeBackUnchanged(logger) {
		var saved = GlobalSettingsTests.snapshot();
		try {
			var rows = GlobalSettingsTests.table();
			var ok = true;
			for (var i = 0; i < rows.size(); i++) {
				var row = rows[i];
				GlobalSettings.save(row[0], row[3]);
				if (
					!StorageSnapshot.deepEquals(App.Storage.getValue(row[1]), row[3]) ||
					!StorageSnapshot.deepEquals(GlobalSettings.load(row[0]), row[3])
				) {
					logger.debug("row " + i + " " + row[1] + " came back as " + GlobalSettings.load(row[0]));
					ok = false;
				}
			}
			GlobalSettingsTests.restore(saved);
			return ok;
		} catch (ex) {
			GlobalSettingsTests.restore(saved);
			throw ex;
		}
	}

	// the numbers stored for each setting; renumbering one changes what every user has chosen
	(:test)
	static function settingEnumNumbersNeverChange(logger) {
		var pins = [
			[ConfirmSaveActivity.Ask, 0],
			[ConfirmSaveActivity.AutoNo, 1],
			[ConfirmSaveActivity.AutoYes, 2],
			[ConfirmSaveActivity.AutoYesExit, 3],
			[MultiSession.No, 0],
			[MultiSession.Yes, 1],
			[RespirationRate.Off, 0],
			[RespirationRate.On, 1],
			[AutoStop.Off, 0],
			[AutoStop.On, 1],
			[Notification.Off, 0],
			[Notification.On, 1],
			[ColorTheme.Dark, 0],
			[ColorTheme.Light, 1],
			[BreathCues.Off, 0],
			[BreathCues.Vibration, 1],
			[BreathCues.VibrationTone, 2],
		];
		for (var i = 0; i < pins.size(); i++) {
			if (pins[i][0] != pins[i][1]) {
				logger.debug("pin " + i + " is " + pins[i][0]);
				return false;
			}
		}
		return true;
	}

	(:test)
	static function otherStorageKeysNeverChange(logger) {
		return (
			SessionStorage.SessionPrefixKey.equals("sesssion_") &&
			SessionStorage.SessionKeysKey.equals("sessionsKeys") &&
			SessionStorage.SelectedIndexKey.equals("selectedSessionIndex") &&
			WakeupSessionStorage.ActivityTypeKey.equals("wakeupSession_activityType") &&
			UsageStats.MonthlyKey.equals("usageStats_monthly") &&
			UsageStats.TipPendingKey.equals("usageStats_tipPending")
		);
	}
}
