using Toybox.Application as App;
using Toybox.System;

// recent session starts: the picker opens on the session usually started at this time of day, a
// multi-session offers what usually follows. key strings are stored data, never change them
class SessionHistory {
	static const StorageKey = "sessionHistory";
	// the key the app itself last put the picker on; any other selection is the user's choice
	static const AutoKey = "sessionAutoKey";
	// one start: session key, minute of day, key started before it in the same launch or null
	static const Stride = 3;
	static const MaxEntries = 50;
	static const WindowMinutes = 60;
	static const ReachMinutes = 180;

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
		return SessionHistory.suggest(null);
	}

	// what is usually started after prevKey around now; null prevKey: first in a launch
	static function suggest(prevKey) {
		if (!SessionHistory.enabled()) {
			return null;
		}
		return SessionHistory.pick(App.Storage.getValue(StorageKey), prevKey, SessionHistory.minuteNow());
	}

	static function record(key, prevKey) {
		if (!SessionHistory.enabled()) {
			return;
		}
		var log = SessionHistory.append(App.Storage.getValue(StorageKey), key, SessionHistory.minuteNow(), prevKey);
		App.Storage.setValue(StorageKey, log);
		SessionHistory.markAuto(key);
	}

	// written only on a change; the picker marks on nearly every launch
	static function markAuto(key) {
		if (key != null && SessionHistory.enabled() && key != App.Storage.getValue(AutoKey)) {
			App.Storage.setValue(AutoKey, key);
		}
	}

	// a freed key is handed out again; the next session must not inherit its routine
	static function forget(key) {
		var log = App.Storage.getValue(StorageKey);
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

	static function minuteNow() {
		var clock = System.getClockTime();
		return clock.hour * 60 + clock.min;
	}

	// newest start within the hour, else the newest around the closest start within reach
	static function pick(log, prevKey, minute) {
		if (log == null) {
			return null;
		}
		var key = SessionHistory.newestNear(log, prevKey, minute);
		if (key == null) {
			var nearest = SessionHistory.nearestMinute(log, prevKey, minute);
			if (nearest != null) {
				// re-centred, so an abandoned session a minute closer cannot win
				key = SessionHistory.newestNear(log, prevKey, nearest);
			}
		}
		return key;
	}

	static function newestNear(log, prevKey, minute) {
		for (var i = log.size() - Stride; i >= 0; i -= Stride) {
			if (log[i + 2] == prevKey && SessionHistory.distance(log[i + 1], minute) <= WindowMinutes) {
				return log[i];
			}
		}
		return null;
	}

	static function nearestMinute(log, prevKey, minute) {
		var nearest = null;
		var nearestDistance = ReachMinutes + 1;
		for (var i = log.size() - Stride; i >= 0; i -= Stride) {
			if (log[i + 2] == prevKey) {
				var d = SessionHistory.distance(log[i + 1], minute);
				if (d < nearestDistance) {
					nearest = log[i + 1];
					nearestDistance = d;
				}
			}
		}
		return nearest;
	}

	// minutes between two times of day, across midnight
	static function distance(a, b) {
		var d = a - b;
		if (d < 0) {
			d = -d;
		}
		return d > 720 ? 1440 - d : d;
	}

	static function append(log, key, minute, prevKey) {
		if (log == null) {
			log = [];
		}
		log.addAll([key, minute, prevKey]);
		// to the cap, not by one, so a longer stored log shrinks too
		var max = MaxEntries * Stride;
		if (log.size() > max) {
			log = log.slice(log.size() - max, log.size());
		}
		return log;
	}

	// without the key's own starts and the starts that followed it
	static function drop(log, key) {
		var kept = [];
		for (var i = 0; i < log.size(); i += Stride) {
			if (log[i] != key && log[i + 2] != key) {
				kept.addAll([log[i], log[i + 1], log[i + 2]]);
			}
		}
		return kept;
	}
}
