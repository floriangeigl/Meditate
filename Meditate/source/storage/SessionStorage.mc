using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionStorage {
	private var mSelectedSessionIndex;
	private var mSessionKeys;
	private var mFreshInstall;
	static const SessionPrefixKey = "sesssion_"; // historical triple-s typo, do not fix
	static const SelectedIndexKey = "selectedSessionIndex";
	static const SessionKeysKey = "sessionsKeys";

	function initialize() {
		me.mSessionKeys = App.Storage.getValue(SessionKeysKey);
		// no key list at all means this launch is creating the store; deleting every session
		// does not count, updateSessionStats has written the list back by then
		me.mFreshInstall = me.mSessionKeys == null;
		if (me.mSessionKeys == null) {
			me.mSessionKeys = [];
		}
		// restore last selected session
		me.setSelectedSessionIndex(App.Storage.getValue(SelectedIndexKey));		

		if (me.mSessionKeys.size() == 0){
			me.restorePresets();
			me.updateSessionStats();
		}
		PresetMigration.run(me);
	}

	function isFreshInstall() {
		return me.mFreshInstall;
	}

	// the stored entry of one session; CloudBackup and CloudRestore use it too
	static function storageKeyFor(sessionKey) {
		return SessionPrefixKey + sessionKey.toString();
	}

	// null for anything unreadable: a corrupt entry must skip the migration, never fail startup
	function loadSessionByKey(key) {
		try {
			var loadedSessionDictionary = App.Storage.getValue(SessionStorage.storageKeyFor(key));
			if (loadedSessionDictionary == null) {
				return null;
			}
			var session = new SessionModel();
			session.fromDictionary(loadedSessionDictionary);
			return session;
		} catch (ex) {
			return null;
		}
	}

	function generateSessionKey() {
		var key = 100; // 100: offset for presets
		// smallest unused key; the list is in creation order, not sorted
		while (me.mSessionKeys.indexOf(key) != -1) {
			key++;
		}
		return key;
	}

	// the picker calls this on every rebuild; only a real change is written
	function selectSession(index) {
		var before = me.mSelectedSessionIndex;
		me.setSelectedSessionIndex(index);
		if (me.mSelectedSessionIndex != before) {
			App.Storage.setValue(SelectedIndexKey, me.mSelectedSessionIndex);
		}
	}

	function getSelectedSessionKey() {
		if (me.mSelectedSessionIndex < mSessionKeys.size()){
			return me.mSessionKeys[me.mSelectedSessionIndex];
		}
		else {
			return null;
		}
	}

	// -1 for a key that is null or gone
	function indexOfKey(key) {
		return key == null ? -1 : me.mSessionKeys.indexOf(key);
	}

	function loadSelectedSession() {
		try {
			var loadedSessionDictionary = App.Storage.getValue(SessionStorage.storageKeyFor(me.getSelectedSessionKey()));

			var session = new SessionModel();
			session.fromDictionary(loadedSessionDictionary);
			return session;
		} catch (ex) {
			me.setSelectedSessionIndex(0);
			me.mSessionKeys = [];
			// the keys are gone without a delete, so new sessions would inherit their routines
			SessionHistory.clear();
			me.restorePresets();

			throw ex;
		}
	}

	function saveSession(session) {
		App.Storage.setValue(SessionStorage.storageKeyFor(session.key), session.toDictionary());
		me.updateSessionStats();
	}

	function getSessionsCount() {
		return me.mSessionKeys.size();
	}

	function getSelectedSessionIndex() {
		return me.mSelectedSessionIndex;
	}

	private function updateSessionStats() {
		App.Storage.setValue(SelectedIndexKey, me.mSelectedSessionIndex);
		App.Storage.setValue(SessionKeysKey, me.mSessionKeys);
	}

	// adds the presets that are not stored, in preset order; a stored one is left as it is
	function restorePresets() {
		var presets = SessionPresets.getPresets();
		for (var i = 0; i < presets.size(); i++) {
			if (me.mSessionKeys.indexOf(presets[i].key) == -1) {
				me.addSession(presets[i]);
			}
		}
	}

	function newSession() {
		var session = new SessionModel();
		session.key = me.generateSessionKey();
		session.time = 5 * 60;
		session.color = Gfx.COLOR_BLUE;
		session.vibePattern = VibePattern.LongContinuous;
		me.addSession(session);
		return session;
	}

	function addSession(session) {
		if (session == null){
			session = me.newSession();
		}
		if (session.key == null){
			session.key = me.generateSessionKey();
		}
		if (me.mSessionKeys.indexOf(session.key) == -1 ) {
			me.mSessionKeys.add(session.key);
		}
		me.saveSession(session);
		return session;
	}

	function deleteSelectedSession() {
		var deletedKey = me.getSelectedSessionKey();
		App.Storage.deleteValue(SessionStorage.storageKeyFor(deletedKey));
		me.mSessionKeys.removeAll(deletedKey);
		SessionHistory.forget(deletedKey);
		if (me.mSessionKeys.size() == 0) {
			// if all deleted, automatically restore presets
			me.restorePresets();
		}
		// the next session moves into view; clamp, since the setter would wrap past the last to the first
		me.setSelectedSessionIndex(Utils.clampToRange(me.mSelectedSessionIndex, 0, me.mSessionKeys.size() - 1));
		me.updateSessionStats();
	}

	function setSelectedSessionIndex(index) {
		me.mSelectedSessionIndex = index == null ? 0 : index;
		var nKeys = me.mSessionKeys.size();
		if (me.mSelectedSessionIndex < 0 || nKeys == 0) {
			me.mSelectedSessionIndex = nKeys == 0 ? 0 : nKeys - 1;
		} else {
			me.mSelectedSessionIndex = me.mSelectedSessionIndex % nKeys;
		}
	}
}
