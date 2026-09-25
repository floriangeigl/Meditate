using Toybox.Test;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;

// the only code that can lose user data: stored format, presets, migration, keys and selection.
// every test writes its own store and restores the simulator's afterwards
(:test)
class SessionStorageTests {
	// a session as the released app stores it, every field set away from its default
	private static function storedSession(key, activityType, hrvTracking) {
		return {
			"time" => 754,
			"color" => Gfx.COLOR_PURPLE,
			"name" => "Evening",
			"key" => key,
			"vibePattern" => VibePattern.MediumPulsating,
			"intervalAlerts" => [
				{
					"type" => IntervalAlertType.OneOff,
					"time" => 120,
					"offset" => 0,
					"color" => Gfx.COLOR_YELLOW,
					"vibePattern" => VibePattern.ShortSound,
				},
				{
					"type" => IntervalAlertType.Repeat,
					"time" => 90,
					"offset" => 30,
					"color" => Gfx.COLOR_TRANSPARENT,
					"vibePattern" => VibePattern.Blip,
				},
			],
			"breathProgram" => {
				"steps" => [
					{
						"d" => [4, 7, 8, 0],
						"rt" => BreathRepeat.Rounds,
						"rv" => 4,
						"ir" => BreathRoute.Nose,
						"or" => BreathRoute.Mouth,
					},
					{
						"d" => [0, 0, 0, 0],
						"rt" => BreathRepeat.Duration,
						"rv" => 60,
						"ir" => BreathRoute.Unset,
						"or" => BreathRoute.Unset,
					},
				],
			},
			"activityType" => activityType,
			"hrvTracking" => hrvTracking,
		};
	}

	private static function plainSession(key, name) {
		return {
			"time" => 300,
			"color" => Gfx.COLOR_BLUE,
			"name" => name,
			"key" => key,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => null,
			"breathProgram" => null,
			"activityType" => null,
			"hrvTracking" => null,
		};
	}

	// a dict for every listed key; version 2 so the preset migration stays out of the way
	private static function writeStore(sessions, selectedIndex) {
		StorageSnapshot.clearSessions();
		var keys = [];
		for (var i = 0; i < sessions.size(); i++) {
			var key = sessions[i]["key"];
			App.Storage.setValue("sesssion_" + key.toString(), sessions[i]);
			keys.add(key);
		}
		App.Storage.setValue("sessionsKeys", keys);
		App.Storage.setValue("selectedSessionIndex", selectedIndex);
		App.Storage.setValue("globalSettings_presetsVersion", 2);
	}

	private static function stored(key) {
		return App.Storage.getValue("sesssion_" + key.toString());
	}

	private static function storedKeys() {
		return App.Storage.getValue("sessionsKeys");
	}

	(:test)
	static function storedSessionLoadsAndSavesBackUnchanged(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var ok = true;
			var cases = [
				SessionStorageTests.storedSession(101, null, null),
				SessionStorageTests.storedSession(101, ActivityType.Yoga, HrvTracking.Off),
			];
			for (var i = 0; i < cases.size(); i++) {
				SessionStorageTests.writeStore([cases[i]], 0);
				var storage = new SessionStorage();
				storage.saveSession(storage.loadSelectedSession());
				if (!StorageSnapshot.deepEquals(SessionStorageTests.stored(101), cases[i])) {
					logger.debug("case " + i + " came back as " + SessionStorageTests.stored(101));
					ok = false;
				}
			}
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function emptyProgramIsStoredAsNull(logger) {
		var session = new SessionModel();
		session.setBreathProgram(new BreathProgram());
		var stored = session.toDictionary();
		return stored.hasKey("breathProgram") && stored["breathProgram"] == null;
	}

	// the numbers inside stored sessions; renumbering one changes what every user has saved
	(:test)
	static function storedEnumNumbersNeverChange(logger) {
		var pins = [
			[VibePattern.NoNotification, 0],
			[VibePattern.Blip, 1],
			[VibePattern.ShorterAscending, 2],
			[VibePattern.ShorterContinuous, 3],
			[VibePattern.ShortAscending, 4],
			[VibePattern.ShortDescending, 5],
			[VibePattern.ShortContinuous, 6],
			[VibePattern.ShortPulsating, 7],
			[VibePattern.ShortSound, 8],
			[VibePattern.MediumAscending, 9],
			[VibePattern.MediumDescending, 10],
			[VibePattern.MediumContinuous, 11],
			[VibePattern.MediumPulsating, 12],
			[VibePattern.LongAscending, 13],
			[VibePattern.LongDescending, 14],
			[VibePattern.LongContinuous, 15],
			[VibePattern.LongPulsating, 16],
			[VibePattern.LongSound, 17],
			[ActivityType.Meditating, 0],
			[ActivityType.Yoga, 1],
			[ActivityType.Breathing, 2],
			[ActivityType.Generic, 3],
			[HrvTracking.Off, 0],
			[HrvTracking.On, 1],
			[HrvTracking.OnDetailed, 2],
			[IntervalAlertType.OneOff, 1],
			[IntervalAlertType.Repeat, 2],
			[BreathRepeat.Rounds, 1],
			[BreathRepeat.Duration, 2],
			[BreathRoute.Unset, 0],
			[BreathRoute.Nose, 1],
			[BreathRoute.Mouth, 2],
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
	static function freshStoreRestoresPresets(logger) {
		var snapshot = new StorageSnapshot();
		try {
			StorageSnapshot.clearSessions();
			App.Storage.deleteValue("sessionsKeys");
			App.Storage.deleteValue("selectedSessionIndex");
			App.Storage.deleteValue("globalSettings_presetsVersion");
			var storage = new SessionStorage();
			var ok =
				storage.isFreshInstall() &&
				storage.getSessionsCount() == SessionPresets.getPresets().size() &&
				App.Storage.getValue("globalSettings_presetsVersion") == 2;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	// an install from before guided breathwork: key 7 kept its shipped name, 8 was renamed, 9 deleted
	(:test)
	static function migrationUpgradesLegacyBreathPresetsOnce(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var preset7 = SessionPresets.createBreathworkPreset(7);
			var legacy7 = SessionStorageTests.plainSession(7, preset7.name);
			legacy7["intervalAlerts"] = SessionStorageTests.storedSession(7, null, null)["intervalAlerts"];
			var renamed8 = SessionStorageTests.plainSession(8, "My box");
			var own0 = SessionStorageTests.plainSession(0, "Quiet");
			SessionStorageTests.writeStore([own0, legacy7, renamed8], 0);
			App.Storage.deleteValue("globalSettings_presetsVersion");
			new SessionStorage();

			var keys = SessionStorageTests.storedKeys();
			var upgraded = SessionStorageTests.stored(7);
			var ok =
				upgraded["breathProgram"] != null &&
				upgraded["time"] == preset7.time &&
				upgraded["intervalAlerts"].size() == 0 &&
				upgraded["name"].equals(preset7.name) &&
				StorageSnapshot.deepEquals(SessionStorageTests.stored(8), renamed8) &&
				StorageSnapshot.deepEquals(SessionStorageTests.stored(0), own0) &&
				keys.indexOf(9) == -1 &&
				SessionStorageTests.stored(9) == null &&
				keys.indexOf(10) != -1 &&
				keys.indexOf(11) != -1 &&
				keys.indexOf(12) != -1 &&
				App.Storage.getValue("globalSettings_presetsVersion") == 2;

			// the next start changes nothing
			var added10 = SessionStorageTests.stored(10);
			new SessionStorage();
			ok =
				ok &&
				StorageSnapshot.deepEquals(SessionStorageTests.storedKeys(), keys) &&
				StorageSnapshot.deepEquals(SessionStorageTests.stored(7), upgraded) &&
				StorageSnapshot.deepEquals(SessionStorageTests.stored(10), added10);
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function selectedIndexWraps(logger) {
		var snapshot = new StorageSnapshot();
		try {
			SessionStorageTests.writeStore(
				[
					SessionStorageTests.plainSession(100, "a"),
					SessionStorageTests.plainSession(101, "b"),
					SessionStorageTests.plainSession(102, "c"),
				],
				0
			);
			var storage = new SessionStorage();
			storage.setSelectedSessionIndex(-1);
			var negative = storage.getSelectedSessionIndex();
			storage.setSelectedSessionIndex(5);
			var overflow = storage.getSelectedSessionIndex();
			storage.setSelectedSessionIndex(null);
			var missing = storage.getSelectedSessionIndex();
			snapshot.restore();
			return negative == 2 && overflow == 2 && missing == 0;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function deletingEverySessionRestoresPresets(logger) {
		var snapshot = new StorageSnapshot();
		try {
			SessionStorageTests.writeStore([SessionStorageTests.plainSession(100, "only")], 0);
			var storage = new SessionStorage();
			storage.deleteSelectedSession();
			var ok =
				storage.getSessionsCount() == SessionPresets.getPresets().size() &&
				SessionStorageTests.storedKeys().indexOf(100) == -1 &&
				SessionStorageTests.stored(100) == null;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	// delete 100 then add a session: the list reads [.., 101, 100]; the next key must not be 101
	(:test)
	static function newSessionNeverReusesAKey(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var keep = SessionStorageTests.plainSession(101, "keep me");
			SessionStorageTests.writeStore(
				[SessionStorageTests.plainSession(0, "preset"), keep, SessionStorageTests.plainSession(100, "newer")],
				0
			);
			var storage = new SessionStorage();
			var first = storage.newSession();
			var second = storage.newSession();
			var keys = SessionStorageTests.storedKeys();
			var ok =
				first.key == 102 &&
				second.key == 103 &&
				keys.size() == 5 &&
				StorageSnapshot.deepEquals(SessionStorageTests.stored(101), keep);
			if (!ok) {
				logger.debug("keys " + keys + ", new " + first.key + " and " + second.key);
			}
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}
}
