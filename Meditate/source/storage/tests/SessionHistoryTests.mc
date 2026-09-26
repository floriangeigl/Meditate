using Toybox.Test;
using Toybox.Application as App;

// the lookup behind the picker's launch position and the multi-session next session
(:test)
class SessionHistoryTests {
	// [[key, hour, minute, prevKey], ...] oldest first, as the log stores them
	private static function history(starts) {
		var log = [];
		for (var i = 0; i < starts.size(); i++) {
			log.addAll([starts[i][0], starts[i][1] * 60 + starts[i][2], starts[i][3]]);
		}
		return log;
	}

	private static function at(hour, minute) {
		return hour * 60 + minute;
	}

	(:test)
	static function emptyLogSuggestsNothing(logger) {
		return SessionHistory.pick(null, null, 420) == null && SessionHistory.pick([], null, 420) == null;
	}

	// last used wins, whichever order
	(:test)
	static function newestStartWithinTheHourWins(logger) {
		var coherentLast = SessionHistoryTests.history([[1, 7, 0, null], [2, 7, 10, null]]);
		var boxLast = SessionHistoryTests.history([[2, 7, 10, null], [1, 7, 0, null]]);
		var now = SessionHistoryTests.at(7, 5);
		return SessionHistory.pick(coherentLast, null, now) == 2 && SessionHistory.pick(boxLast, null, now) == 1;
	}

	// 08:01 is 61 min away, so the older 07:00 start is the only one within the hour
	(:test)
	static function withinTheHourBeatsNewerFurtherAway(logger) {
		var log = SessionHistoryTests.history([[1, 7, 0, null], [2, 8, 1, null]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(7, 0)) == 1;
	}

	// sleeping in: 08:15 is 90 min after the morning routine, far from the evening one
	(:test)
	static function nearestRoutineWhenNothingIsWithinTheHour(logger) {
		var log = SessionHistoryTests.history([[1, 6, 45, null], [3, 21, 30, null]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(8, 15)) == 1;
	}

	// the old start is two minutes closer, the newer one of the same routine still wins
	(:test)
	static function nearestRoutineKeepsLastUsedWins(logger) {
		var log = SessionHistoryTests.history([[1, 7, 2, null], [2, 7, 0, null]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(9, 30)) == 2;
	}

	(:test)
	static function beyondReachStaysPut(logger) {
		var log = SessionHistoryTests.history([[1, 6, 45, null]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(12, 0)) == null;
	}

	(:test)
	static function matchesAcrossMidnight(logger) {
		var log = SessionHistoryTests.history([[1, 23, 50, null]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(0, 30)) == 1 && SessionHistory.distance(1430, 30) == 40;
	}

	// yesterday's second session of the run is newer, but not a first start
	(:test)
	static function launchSkipsSessionsThatFollowedAnother(logger) {
		var log = SessionHistoryTests.history([[1, 6, 30, null], [2, 6, 36, 1]]);
		return SessionHistory.pick(log, null, SessionHistoryTests.at(6, 30)) == 1;
	}

	// the same opener leads to silent in the morning and to sleep in the evening
	(:test)
	static function followersAreMatchedByTime(logger) {
		var log = SessionHistoryTests.history([[1, 6, 30, null], [2, 6, 36, 1], [1, 21, 30, null], [3, 21, 36, 1]]);
		return (
			SessionHistory.pick(log, 1, SessionHistoryTests.at(6, 40)) == 2 &&
			SessionHistory.pick(log, 1, SessionHistoryTests.at(21, 40)) == 3 &&
			SessionHistory.pick(log, 1, SessionHistoryTests.at(9, 0)) == 2 &&
			SessionHistory.pick(log, 5, SessionHistoryTests.at(6, 40)) == null
		);
	}

	(:test)
	static function dropRemovesTheKeyAndWhatFollowedIt(logger) {
		var log = SessionHistoryTests.history([[1, 6, 30, null], [2, 6, 36, 1], [3, 8, 20, null]]);
		return StorageSnapshot.deepEquals(SessionHistory.drop(log, 1), [3, 500, null]);
	}

	(:test)
	static function appendKeepsTheNewest(logger) {
		var log = null;
		for (var key = 0; key < SessionHistory.MaxEntries + 5; key++) {
			log = SessionHistory.append(log, key, 420, null);
		}
		var cap = SessionHistory.MaxEntries * SessionHistory.Stride;
		// a log stored longer than the cap, e.g. by a build with a larger one, shrinks in one go
		var longer = [];
		for (var k = 0; k < SessionHistory.MaxEntries + 10; k++) {
			longer.addAll([k, 420, null]);
		}
		longer = SessionHistory.append(longer, 99, 420, null);
		return (
			log.size() == cap &&
			log[0] == 5 &&
			log[log.size() - 3] == 54 &&
			longer.size() == cap &&
			longer[longer.size() - 3] == 99
		);
	}

	// sessions 100-103, a routine on 101 started just now, 101 selected
	private static function routineStore() {
		SessionStorageTests.writeStore(
			[
				SessionStorageTests.plainSession(100, "a"),
				SessionStorageTests.plainSession(101, "b"),
				SessionStorageTests.plainSession(102, "c"),
				SessionStorageTests.plainSession(103, "d"),
			],
			1
		);
		GlobalSettings.save(GlobalSettings.LearnRoutineKey, true);
		SessionHistory.clear();
		var storage = new SessionStorage();
		SessionHistory.record(101, null);
		return storage;
	}

	(:test)
	static function launchMovesOnlyWhatTheUserLeftAlone(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var storage = SessionHistoryTests.routineStore();
			var untouched = SessionHistory.pickAtLaunch(101) == 101;
			storage.selectSession(3);
			var moved = SessionHistory.pickAtLaunch(storage.getSelectedSessionKey()) == null;
			// deleting 103 brings 102 into view, which the user did not choose
			storage.deleteSelectedSession();
			var afterDelete = storage.getSelectedSessionKey() == 102 && SessionHistory.pickAtLaunch(102) == 101;
			if (!(untouched && moved && afterDelete)) {
				logger.debug("untouched " + untouched + ", moved " + moved + ", after delete " + afterDelete);
			}
			snapshot.restore();
			return untouched && moved && afterDelete;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	// the freed key goes to the next new session, which must not inherit the routine
	(:test)
	static function deletedSessionIsForgotten(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var storage = SessionHistoryTests.routineStore();
			SessionHistory.record(102, 101);
			storage.deleteSelectedSession();
			var reused = storage.newSession().key == 101;
			var ok = reused && StorageSnapshot.deepEquals(App.Storage.getValue(SessionHistory.StorageKey), []);
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function offForgetsAndRecordsNothing(logger) {
		var snapshot = new StorageSnapshot();
		try {
			SessionHistoryTests.routineStore();
			GlobalSettings.save(GlobalSettings.LearnRoutineKey, false);
			var none = SessionHistory.pickAtLaunch(101) == null;
			SessionHistory.record(102, null);
			var ok =
				none &&
				App.Storage.getValue(SessionHistory.StorageKey) == null &&
				App.Storage.getValue(SessionHistory.AutoKey) == null &&
				SessionHistory.suggest(101) == null;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}
}
