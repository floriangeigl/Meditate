using Toybox.Application as App;
using Toybox.System;
using Toybox.Time;

// finished sessions: the picker opens on the session usually done at this time and kind of day, and
// after a session on what usually follows it. key strings are stored data, never change them
class SessionHistory {
	static const StorageKey = "sessionHistory";
	// the key the app itself last put the picker on; any other selection is the user's choice
	static const AutoKey = "sessionAutoKey";
	// one finished session: key, local start in minutes since 1970, key finished up to GapMinutes
	// before it or None, length in minutes. None, not null: firebase drops nulls from arrays
	static const Stride = 4;
	static const None = -1;
	static const MaxEntries = 100;
	static const MaxAgeMinutes = 129600;
	static const WindowMinutes = 60;
	static const ReachMinutes = 180;
	static const GapMinutes = 60;
	// per newer vote of the same kind of day: one-off loses, two in a row win
	static const Decay = 0.6;
	static const OtherKindWeight = 0.25;

	// null when off (which forgets), when the user left the picker elsewhere, or when nothing is close
	static function pickAtLaunch(selectedKey) {
		if (!SessionHistory.enabled()) {
			SessionHistory.clear();
			return null;
		}
		var auto = App.Storage.getValue(AutoKey);
		if (auto != null && auto != selectedKey) {
			return null;
		}
		return SessionHistory.pickAt(SessionHistory.load(), SessionHistory.minuteNow());
	}

	// the follower of a session finished within the gap, else what is usually started now
	static function pickAt(log, now) {
		if (log != null && log.size() > 0) {
			var i = log.size() - Stride;
			var gap = now - log[i + 1] - log[i + 3];
			if (gap >= -GapMinutes && gap <= GapMinutes) {
				var key = SessionHistory.pick(log, log[i], now);
				if (key != null) {
					return key;
				}
			}
		}
		return SessionHistory.pick(log, None, now);
	}

	// what usually follows the session key around now
	static function suggest(key) {
		if (!SessionHistory.enabled()) {
			return null;
		}
		return SessionHistory.pick(SessionHistory.load(), key, SessionHistory.minuteNow());
	}

	// a saved session; start from minuteNow() when it started
	static function record(key, start, seconds) {
		if (start == null || !SessionHistory.enabled()) {
			return;
		}
		var log = SessionHistory.load();
		var entry = [key, start, SessionHistory.previousFor(log, start), (seconds + 30) / 60];
		App.Storage.setValue(StorageKey, SessionHistory.append(log, entry, start));
	}

	// written only on a change; the picker marks on nearly every launch
	static function markAuto(key) {
		if (key != null && SessionHistory.enabled() && key != App.Storage.getValue(AutoKey)) {
			App.Storage.setValue(AutoKey, key);
		}
	}

	// a freed key is handed out again; the next session must not inherit its routine
	static function forget(key) {
		var log = SessionHistory.load();
		if (log != null) {
			App.Storage.setValue(StorageKey, SessionHistory.drop(log, key));
		}
	}

	static function clear() {
		App.Storage.deleteValue(StorageKey);
		App.Storage.deleteValue(AutoKey);
	}

	static function enabled() {
		return GlobalSettings.load(GlobalSettings.LearnRoutineKey);
	}

	// local wall-clock minutes since 1970, so travel and daylight saving keep 07:00 at 07:00
	static function minuteNow() {
		return (Time.now().value() + System.getClockTime().timeZoneOffset) / 60;
	}

	// a log of another shape, e.g. from a development build, reads as empty
	static function load() {
		var log = App.Storage.getValue(StorageKey);
		return log == null || log.size() % Stride != 0 ? null : log;
	}

	// the newest session, when it finished within the gap before start
	static function previousFor(log, start) {
		if (log == null || log.size() == 0) {
			return None;
		}
		var i = log.size() - Stride;
		var gap = start - log[i + 1] - log[i + 3];
		return gap >= -1 && gap <= GapMinutes ? log[i] : None;
	}

	// votes within the hour, else around the closest start within reach
	static function pick(log, prevKey, now) {
		if (log == null) {
			return null;
		}
		var nearest = null;
		var nearestDistance = ReachMinutes + 1;
		for (var i = 0; i < log.size(); i += Stride) {
			if (SessionHistory.usable(log, i, prevKey, now)) {
				var minute = log[i + 1] % 1440;
				var d = SessionHistory.distance(minute, now % 1440);
				if (d < nearestDistance) {
					nearest = minute;
					nearestDistance = d;
				}
			}
		}
		if (nearest == null) {
			return null;
		}
		// re-centred, so an abandoned routine a minute closer cannot outvote the one around it
		return SessionHistory.vote(log, prevKey, now, nearestDistance <= WindowMinutes ? now % 1440 : nearest);
	}

	// each session votes for its key, the same kind of day louder, newer louder
	static function vote(log, prevKey, now, center) {
		var weekend = SessionHistory.weekday(now) >= 5;
		var scores = {};
		var order = [];
		var sameWeight = 1.0;
		var otherWeight = OtherKindWeight;
		for (var i = log.size() - Stride; i >= 0; i -= Stride) {
			if (
				!SessionHistory.usable(log, i, prevKey, now) ||
				SessionHistory.distance(log[i + 1] % 1440, center) > WindowMinutes
			) {
				continue;
			}
			var key = log[i];
			var weight;
			if ((SessionHistory.weekday(log[i + 1]) >= 5) == weekend) {
				weight = sameWeight;
				sameWeight *= Decay;
			} else {
				weight = otherWeight;
				otherWeight *= Decay;
			}
			if (scores.hasKey(key)) {
				scores[key] += weight;
			} else {
				scores[key] = weight;
				order.add(key);
			}
		}
		// newest first, so a tie goes to the newest
		var best = null;
		for (var j = 0; j < order.size(); j++) {
			if (best == null || scores[order[j]] > scores[best]) {
				best = order[j];
			}
		}
		return best;
	}

	static function usable(log, i, prevKey, now) {
		return log[i + 2] == prevKey && now - log[i + 1] <= MaxAgeMinutes;
	}

	// 0 Monday to 6 Sunday; 1 January 1970 was a Thursday
	static function weekday(minute) {
		return (minute / 1440 + 3) % 7;
	}

	// minutes between two times of day, across midnight
	static function distance(a, b) {
		var d = a - b;
		if (d < 0) {
			d = -d;
		}
		return d > 720 ? 1440 - d : d;
	}

	// without sessions older than the age limit, to the cap
	static function append(log, entry, now) {
		var kept = [];
		if (log != null) {
			var from = log.size() - (MaxEntries - 1) * Stride;
			for (var i = from > 0 ? from : 0; i < log.size(); i += Stride) {
				if (now - log[i + 1] <= MaxAgeMinutes) {
					kept.addAll(log.slice(i, i + Stride));
				}
			}
		}
		kept.addAll(entry);
		return kept;
	}

	// without the key's own sessions and the sessions that followed it
	static function drop(log, key) {
		var kept = [];
		for (var i = 0; i < log.size(); i += Stride) {
			if (log[i] != key && log[i + 2] != key) {
				kept.addAll(log.slice(i, i + Stride));
			}
		}
		return kept;
	}
}
