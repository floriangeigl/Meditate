// One-time upgrades, one step per version, each run once. Version 2 (guided breathwork): keys
// 7-9 shipped as alert-based breathwork sessions and are rewritten in place, 10-12 are added.
// Version 3 adds 13-14. A preset the user deleted stays deleted, and a renamed one is left alone.
class PresetMigration {
	private static const PresetsVersion = 3;
	private static const LegacyBreathPresetKeys = [7, 8, 9];
	private static const AddedInVersion2 = [10, 11, 12];
	private static const AddedInVersion3 = [13, 14];

	static function run(storage) {
		var version = GlobalSettings.load(GlobalSettings.PresetsVersionKey);
		if (version >= PresetMigration.PresetsVersion) {
			return;
		}
		if (version < 2) {
			for (var i = 0; i < PresetMigration.LegacyBreathPresetKeys.size(); i++) {
				PresetMigration.upgradeLegacyBreathPreset(storage, PresetMigration.LegacyBreathPresetKeys[i]);
			}
			PresetMigration.addMissing(storage, PresetMigration.AddedInVersion2);
		}
		if (version < 3) {
			PresetMigration.addMissing(storage, PresetMigration.AddedInVersion3);
		}
		GlobalSettings.save(GlobalSettings.PresetsVersionKey, PresetMigration.PresetsVersion);
	}

	// keeps the stored session and changes only what the program owns, so colour, vibration and
	// every other choice the user made survives
	private static function upgradeLegacyBreathPreset(storage, key) {
		if (storage.indexOfKey(key) == -1) {
			return;
		}
		var stored = storage.loadSessionByKey(key);
		if (stored == null || stored.hasBreathProgram()) {
			return;
		}
		var preset = SessionPresets.createBreathworkPreset(key);
		// equals() on the shipped name, so a null or non-string stored name just fails the match
		if (preset == null || !preset.name.equals(stored.name)) {
			return;
		}
		// the program now carries the rhythm the alerts used to; keeping both would double the cues
		stored.setBreathProgram(preset.getBreathProgram());
		stored.time = preset.time;
		stored.setIntervalAlerts(new IntervalAlerts());
		storage.saveSession(stored);
	}

	private static function addMissing(storage, keys) {
		for (var i = 0; i < keys.size(); i++) {
			if (storage.indexOfKey(keys[i]) == -1) {
				var preset = SessionPresets.createBreathworkPreset(keys[i]);
				if (preset != null) {
					storage.addSession(preset);
				}
			}
		}
	}
}
