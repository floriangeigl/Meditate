using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionStorage {
	private var mSelectedSessionIndex;
	private var mSessionKeys;
	private static var mStorageKeySessionPrefix = "sesssion_";
	private static var mStorageKeySelectedSessionIndex = "selectedSessionIndex";
	private static var mStorageKeySessionsKeys = "sessionsKeys";

	function initialize() {
		// restore last selected session
		me.mSelectedSessionIndex = App.Storage.getValue(me.mStorageKeySelectedSessionIndex);
		if (me.mSelectedSessionIndex == null) {
			me.mSelectedSessionIndex = 0;
		}
		
		me.mSessionKeys = App.Storage.getValue(me.mStorageKeySessionsKeys);
		if (me.mSessionKeys == null) {
			me.mSessionKeys = [];
		}

		if (me.mSessionKeys.size() == 0){
			me.restorePresets();
		}
	}

	function generateSessionKey() {
		var key = 100; // 100: offset for presets
		// find smallest not used session key
		for (var i = 0; i < mSessionKeys.size(); i++){
			if (key == mSessionKeys[i]){
				key++;
			}
		}
		return key;
	}

	function selectSession(index) {
		me.mSelectedSessionIndex = index;
		App.Storage.setValue(mStorageKeySelectedSessionIndex, me.mSelectedSessionIndex);
	}

	private function getSelectedSessionKey() {
		if (me.mSelectedSessionIndex < mSessionKeys.size()){
			return me.mSessionKeys[me.mSelectedSessionIndex];
		}
		else {
			return null;
		}
	}

	function getSessionStorageKey(session) {
		return me.mStorageKeySessionPrefix + session.key.toString();
	}

	function getSelectedSessionStorageKey(){
		return me.mStorageKeySessionPrefix + me.getSelectedSessionKey().toString();
	}

	function loadSelectedSession() {
		try {
			var loadedSessionDictionary = App.Storage.getValue(me.getSelectedSessionStorageKey());

			var session = new SessionModel();
			session.fromDictionary(loadedSessionDictionary);
			return session;
		} catch (ex) {
			me.mSelectedSessionIndex = 0;
			me.mSessionKeys = [];
			me.restorePresets();
			
			throw ex;
		}
	}

	function saveSession(session) {
		App.Storage.setValue(me.getSessionStorageKey(session), session.toDictionary());
	}

	function getSessionsCount() {
		return me.mSessionKeys.size();
	}

	function getSelectedSessionIndex() {
		return me.mSelectedSessionIndex;
	}

	private function updateSessionStats() {
		App.Storage.setValue(me.mStorageKeySelectedSessionIndex, me.mSelectedSessionIndex);
		App.Storage.setValue(me.mStorageKeySessionsKeys, me.mSessionKeys);
	}

	function restorePresets() {
		var sessions = SessionPresets.getPresets();
		var presetDict = {};
		var session = null;
		for (var i=0; i < sessions.size(); i++){
			session = sessions[i];
			presetDict[session.key] = session;
		}
		var key = null;
		for (var i = 0; i < me.mSessionKeys.size(); i++) {
			key = me.mSessionKeys[i];
			if (presetDict.hasKey(key)) {
				// preset exists in storage - consider not touching or reseting
				presetDict.remove(key);
			}
		}
		for (var i = 0; i < presetDict.keys().size(); i++) {
			session = presetDict[presetDict.keys()[i]];
			me.addSession(session);
		}
	}

	function newSession() {
		var session = new SessionModel();
		session.key = me.generateSessionKey();
		return session;
	}

	function addSession(session) {
		if (session == null){
			session = me.newSession();
		}
		if (session.key == null){
			session.key = me.generateSessionKey();
		}
		me.mSessionKeys.add(session.key);
		me.saveSession(session);
		return session;
	}

	function deleteSelectedSession() {
		App.Storage.deleteValue(me.getSelectedSessionStorageKey());
		me.mSessionKeys.removeAll(me.getSelectedSessionKey());
		if (me.mSelectedSessionIndex > 0) {
			me.mSelectedSessionIndex--;
		} else if (me.mSessionKeys.size() == 0) {
			// if all deleted, automatically restore presets
			me.restorePresets();
		}
		me.updateSessionStats();
	}
}
