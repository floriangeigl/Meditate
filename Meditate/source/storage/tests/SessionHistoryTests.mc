using Toybox.Test;
using Toybox.Application as App;

// the lookup behind the picker's launch position and the multi-session next session
(:test)
class SessionHistoryTests {
	// Monday 5 January 2026, in days since 1970
	private static const Monday = 20458;
	private static const N = SessionHistory.None;

	// minutes since 1970 on day (0 = that Monday) at hour:minute
	private static function at(day, hour, minute) {
		return (Monday + day) * 1440 + hour * 60 + minute;
	}

	// [[key, day, hour, minute, prevKey, minutes], ...] in any order; logged oldest first, as finished
	private static function history(sessions) {
		var entries = [];
		for (var i = 0; i < sessions.size(); i++) {
			var s = sessions[i];
			var entry = [s[0], SessionHistoryTests.at(s[1], s[2], s[3]), s[4], s[5]];
			var j = entries.size();
			while (j > 0 && entries[j - 1][1] > entry[1]) {
				j--;
			}
			entries = entries.slice(0, j).add(entry).addAll(entries.slice(j, null));
		}
		var log = [];
		for (var i = 0; i < entries.size(); i++) {
			log.addAll(entries[i]);
		}
		return log;
	}

	// key at hour:minute on each of days
	private static function daily(key, days, hour, minute) {
		var sessions = [];
		for (var i = 0; i < days.size(); i++) {
			sessions.add([key, days[i], hour, minute, N, 10]);
		}
		return sessions;
	}

	private static function weekdays(fromDay, weeks) {
		var days = [];
		for (var w = 0; w < weeks; w++) {
			for (var d = 0; d < 5; d++) {
				days.add(fromDay + w * 7 + d);
			}
		}
		return days;
	}

	(:test)
	static function emptyLogSuggestsNothing(logger) {
		var now = SessionHistoryTests.at(0, 7, 0);
		return SessionHistory.pick(null, N, now) == null && SessionHistory.pick([], N, now) == null;
	}

	(:test)
	static function weekdayCountsFromMonday(logger) {
		return (
			SessionHistory.weekday(SessionHistoryTests.at(0, 0, 0)) == 0 &&
			SessionHistory.weekday(SessionHistoryTests.at(5, 23, 59)) == 5 &&
			SessionHistory.weekday(SessionHistoryTests.at(6, 12, 0)) == 6
		);
	}

	// two weeks of A, then B once: A stays; B twice in a row: B wins
	(:test)
	static function oneOffLosesTwoInARowWin(logger) {
		var sessions = SessionHistoryTests.daily(1, SessionHistoryTests.weekdays(0, 2), 7, 0);
		sessions.add([2, 14, 7, 0, N, 10]);
		var once = SessionHistory.pick(SessionHistoryTests.history(sessions), N, SessionHistoryTests.at(15, 7, 5));
		sessions.add([2, 15, 7, 0, N, 10]);
		var twice = SessionHistory.pick(SessionHistoryTests.history(sessions), N, SessionHistoryTests.at(16, 7, 5));
		if (once != 1 || twice != 2) {
			logger.debug("once " + once + ", twice " + twice);
		}
		return once == 1 && twice == 2;
	}

	// 08:01 is 61 min away, so the older 07:00 session is the only one within the hour
	(:test)
	static function withinTheHourBeatsNewerFurtherAway(logger) {
		var log = SessionHistoryTests.history([[1, 0, 7, 0, N, 10], [2, 1, 8, 1, N, 10]]);
		return SessionHistory.pick(log, N, SessionHistoryTests.at(2, 7, 0)) == 1;
	}

	// sleeping in: 08:15 is 90 min after the morning routine, far from the evening one
	(:test)
	static function nearestRoutineWhenNothingIsWithinTheHour(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 45, N, 10], [3, 0, 21, 30, N, 10]]);
		return SessionHistory.pick(log, N, SessionHistoryTests.at(1, 8, 15)) == 1;
	}

	// the old session is two minutes closer, the newer one of the same routine still wins
	(:test)
	static function reCentredRoutineStillVotes(logger) {
		var log = SessionHistoryTests.history([[1, 0, 7, 2, N, 10], [2, 1, 7, 0, N, 10]]);
		return SessionHistory.pick(log, N, SessionHistoryTests.at(2, 9, 30)) == 2;
	}

	(:test)
	static function beyondReachStaysPut(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 45, N, 10]]);
		return SessionHistory.pick(log, N, SessionHistoryTests.at(1, 12, 0)) == null;
	}

	(:test)
	static function matchesAcrossMidnight(logger) {
		var log = SessionHistoryTests.history([[1, 0, 23, 50, N, 10]]);
		return (
			SessionHistory.pick(log, N, SessionHistoryTests.at(1, 0, 30)) == 1 && SessionHistory.distance(1430, 30) == 40
		);
	}

	// short on weekdays, long at the weekend: each on its own kind of day
	(:test)
	static function weekendHasItsOwnSession(logger) {
		var sessions = SessionHistoryTests.daily(1, SessionHistoryTests.weekdays(0, 2), 7, 0);
		sessions.addAll(SessionHistoryTests.daily(2, [5, 6, 12], 7, 0));
		var log = SessionHistoryTests.history(sessions);
		var sunday = SessionHistory.pick(log, N, SessionHistoryTests.at(13, 7, 0));
		var monday = SessionHistory.pick(log, N, SessionHistoryTests.at(14, 7, 0));
		return sunday == 2 && monday == 1;
	}

	// no weekend yet: the weekday session is still the best guess
	(:test)
	static function firstWeekendUsesTheWeekdaySession(logger) {
		var log = SessionHistoryTests.history(SessionHistoryTests.daily(1, SessionHistoryTests.weekdays(0, 1), 7, 0));
		return SessionHistory.pick(log, N, SessionHistoryTests.at(5, 7, 0)) == 1;
	}

	(:test)
	static function sessionsPastTheAgeLimitAreIgnored(logger) {
		var log = SessionHistoryTests.history([[1, 0, 7, 0, N, 10]]);
		return (
			SessionHistory.pick(log, N, SessionHistoryTests.at(89, 7, 0)) == 1 &&
			SessionHistory.pick(log, N, SessionHistoryTests.at(91, 7, 0)) == null
		);
	}

	// yesterday's second session of the sitting is newer, but not a first one
	(:test)
	static function launchSkipsSessionsThatFollowedAnother(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 30, N, 5], [2, 0, 6, 36, 1, 10]]);
		return SessionHistory.pick(log, N, SessionHistoryTests.at(1, 6, 30)) == 1;
	}

	// the same opener leads to silent in the morning and to sleep in the evening
	(:test)
	static function followersAreMatchedByTime(logger) {
		var log = SessionHistoryTests.history([
			[1, 0, 6, 30, N, 5],
			[2, 0, 6, 36, 1, 10],
			[1, 0, 21, 30, N, 5],
			[3, 0, 21, 36, 1, 10],
		]);
		return (
			SessionHistory.pick(log, 1, SessionHistoryTests.at(1, 6, 40)) == 2 &&
			SessionHistory.pick(log, 1, SessionHistoryTests.at(1, 21, 40)) == 3 &&
			SessionHistory.pick(log, 1, SessionHistoryTests.at(1, 9, 0)) == 2 &&
			SessionHistory.pick(log, 5, SessionHistoryTests.at(1, 6, 40)) == null
		);
	}

	// reopening the app after a session offers its follower, an hour after its end the usual opener
	(:test)
	static function reopeningOffersTheFollower(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 30, N, 10], [2, 0, 6, 50, 1, 20], [1, 1, 6, 30, N, 10]]);
		return (
			SessionHistory.pickAt(log, SessionHistoryTests.at(1, 6, 45)) == 2 &&
			SessionHistory.pickAt(log, SessionHistoryTests.at(1, 7, 40)) == 2 &&
			SessionHistory.pickAt(log, SessionHistoryTests.at(1, 7, 41)) == 1
		);
	}

	// nothing learned after this session yet: the usual session for now
	(:test)
	static function reopeningWithoutAFollowerFallsBack(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 30, N, 10], [3, 1, 6, 30, N, 10]]);
		return SessionHistory.pickAt(log, SessionHistoryTests.at(1, 6, 45)) == 3;
	}

	// a 45 minute sitting, then up to an hour's break: the gap counts from its end
	(:test)
	static function previousCountsFromTheEnd(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 0, N, 45]]);
		return (
			SessionHistory.previousFor(null, SessionHistoryTests.at(0, 7, 0)) == N &&
			SessionHistory.previousFor(log, SessionHistoryTests.at(0, 6, 44)) == 1 &&
			SessionHistory.previousFor(log, SessionHistoryTests.at(0, 7, 45)) == 1 &&
			SessionHistory.previousFor(log, SessionHistoryTests.at(0, 7, 46)) == N
		);
	}

	(:test)
	static function dropRemovesTheKeyAndWhatFollowedIt(logger) {
		var log = SessionHistoryTests.history([[1, 0, 6, 30, N, 5], [2, 0, 6, 36, 1, 10], [3, 0, 8, 20, N, 10]]);
		return StorageSnapshot.deepEquals(
			SessionHistory.drop(log, 1),
			[3, SessionHistoryTests.at(0, 8, 20), N, 10]
		);
	}

	(:test)
	static function appendKeepsTheNewestAndTheRecent(logger) {
		var now = SessionHistoryTests.at(100, 7, 0);
		var log = null;
		for (var key = 0; key < SessionHistory.MaxEntries + 5; key++) {
			log = SessionHistory.append(log, [key, now, N, 10], now);
		}
		var stride = SessionHistory.Stride;
		var capped = log.size() == SessionHistory.MaxEntries * stride && log[0] == 5 && log[log.size() - stride] == 104;
		var aged = SessionHistory.append(
			SessionHistoryTests.history([[1, 9, 7, 0, N, 10], [2, 11, 7, 0, N, 10]]),
			[3, now, N, 10],
			now
		);
		return capped && aged.size() == 2 * stride && aged[0] == 2 && aged[stride] == 3;
	}

	// sessions 100-103, 101 finished just now, 101 selected
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
		SessionHistory.markAuto(101);
		SessionHistory.record(101, SessionHistory.minuteNow() - 10, 300);
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
			new SessionSettingsMenuDelegate(storage, new PickerSpy()).onConfirmedDeleteSession();
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
			SessionHistory.record(102, SessionHistory.minuteNow() - 3, 60);
			var followed = App.Storage.getValue(SessionHistory.StorageKey)[SessionHistory.Stride + 2] == 101;
			storage.deleteSelectedSession();
			var reused = storage.newSession().key == 101;
			var ok = followed && reused && StorageSnapshot.deepEquals(App.Storage.getValue(SessionHistory.StorageKey), []);
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	// a log of another shape, e.g. from a development build, is ignored instead of misread
	(:test)
	static function wrongShapedLogReadsAsEmpty(logger) {
		var snapshot = new StorageSnapshot();
		try {
			SessionHistoryTests.routineStore();
			App.Storage.setValue(SessionHistory.StorageKey, [101, 420, null]);
			var ok = SessionHistory.load() == null && SessionHistory.pickAtLaunch(101) == null;
			SessionHistory.record(102, SessionHistory.minuteNow(), 60);
			ok = ok && App.Storage.getValue(SessionHistory.StorageKey).size() == SessionHistory.Stride;
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
			SessionHistory.record(102, SessionHistory.minuteNow(), 60);
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
