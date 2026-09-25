using Toybox.Application as App;
using Toybox.Lang;

// saves and restores what the storage tests touch, so the simulator's own data survives a test run;
// key strings are literals on purpose: they are the stored format
(:test)
class StorageSnapshot {
	private var mKeys;
	private var mIndex;
	private var mPresetsVersion;
	private var mSessions;

	function initialize() {
		me.mKeys = App.Storage.getValue("sessionsKeys");
		me.mIndex = App.Storage.getValue("selectedSessionIndex");
		me.mPresetsVersion = App.Storage.getValue("globalSettings_presetsVersion");
		me.mSessions = {};
		if (me.mKeys != null) {
			for (var i = 0; i < me.mKeys.size(); i++) {
				me.mSessions[me.mKeys[i]] = App.Storage.getValue("sesssion_" + me.mKeys[i].toString());
			}
		}
	}

	function restore() {
		// presets use keys 0-12 and the tests keys from 100; drop whatever a test left behind
		var candidates = [];
		var current = App.Storage.getValue("sessionsKeys");
		if (current != null) {
			candidates.addAll(current);
		}
		for (var k = 0; k <= 12; k++) {
			candidates.add(k);
		}
		for (var k = 100; k < 120; k++) {
			candidates.add(k);
		}
		for (var i = 0; i < candidates.size(); i++) {
			if (!me.mSessions.hasKey(candidates[i])) {
				App.Storage.deleteValue("sesssion_" + candidates[i].toString());
			}
		}
		var keys = me.mSessions.keys();
		for (var i = 0; i < keys.size(); i++) {
			StorageSnapshot.put("sesssion_" + keys[i].toString(), me.mSessions[keys[i]]);
		}
		StorageSnapshot.put("sessionsKeys", me.mKeys);
		StorageSnapshot.put("selectedSessionIndex", me.mIndex);
		StorageSnapshot.put("globalSettings_presetsVersion", me.mPresetsVersion);
	}

	static function put(key, value) {
		if (value == null) {
			App.Storage.deleteValue(key);
		} else {
			App.Storage.setValue(key, value);
		}
	}

	// removes every session dict a test could meet: presets 0-12 and test keys from 100
	static function clearSessions() {
		for (var k = 0; k < 120; k++) {
			App.Storage.deleteValue("sesssion_" + k.toString());
		}
	}

	// structural equality; a missing dictionary key counts as a null value
	static function deepEquals(a, b) {
		if (a == null || b == null) {
			return a == null && b == null;
		}
		if (a instanceof Lang.Dictionary) {
			if (!(b instanceof Lang.Dictionary)) {
				return false;
			}
			var keys = a.keys();
			keys.addAll(b.keys());
			for (var i = 0; i < keys.size(); i++) {
				if (!StorageSnapshot.deepEquals(a[keys[i]], b[keys[i]])) {
					return false;
				}
			}
			return true;
		}
		if (a instanceof Lang.Array) {
			if (!(b instanceof Lang.Array) || a.size() != b.size()) {
				return false;
			}
			for (var i = 0; i < a.size(); i++) {
				if (!StorageSnapshot.deepEquals(a[i], b[i])) {
					return false;
				}
			}
			return true;
		}
		return a.equals(b);
	}
}
