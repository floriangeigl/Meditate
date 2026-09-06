using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionStorage {
	private var mSelectedSessionIndex;
	private var mSessionKeys;
	private var mFreshInstall;
	private static var mStorageKeySessionPrefix = "sesssion_";
	private static var mStorageKeySelectedSessionIndex = "selectedSessionIndex";
	private static var mStorageKeySessionsKeys = "sessionsKeys";

	function initialize() {
		me.mSessionKeys = App.Storage.getValue(me.mStorageKeySessionsKeys);
		// no key list at all means this launch is creating the store; deleting every session
		// does not count, updateSessionStats has written the list back by then
		me.mFreshInstall = me.mSessionKeys == null;
		if (me.mSessionKeys == null) {
			me.mSessionKeys = [];
		}
		// restore last selected session
		me.setSelectedSessionIndex(App.Storage.getValue(me.mStorageKeySelectedSessionIndex));		

		if (me.mSessionKeys.size() == 0){
			me.restorePresets();
			me.updateSessionStats();
		}
		me.migratePresets();
	}

	function isFreshInstall() {
		return me.mFreshInstall;
	}

	// One-time upgrade for anyone coming from a version without guided breathwork. Keys 7-9
	// shipped as alert-based breathwork sessions and are rewritten in place; 10-12 are new and
	// simply added. A preset the user deleted stays deleted, and a renamed one is left alone.
	private static const PresetsVersion = 2;
	private static const LegacyBreathPresetKeys = [7, 8, 9];
	private static const AddedBreathPresetKeys = [10, 11, 12];

	private function migratePresets() {
		if (GlobalSettings.loadPresetsVersion() >= SessionStorage.PresetsVersion) {
			return;
		}
		for (var i = 0; i < SessionStorage.LegacyBreathPresetKeys.size(); i++) {
			me.upgradeLegacyBreathPreset(SessionStorage.LegacyBreathPresetKeys[i]);
		}
		for (var i = 0; i < SessionStorage.AddedBreathPresetKeys.size(); i++) {
			me.addMissingBreathPreset(SessionStorage.AddedBreathPresetKeys[i]);
		}
		GlobalSettings.savePresetsVersion(SessionStorage.PresetsVersion);
	}

	// keeps the stored session and changes only what the program owns, so colour, vibration and
	// every other choice the user made survives
	private function upgradeLegacyBreathPreset(key) {
		if (me.mSessionKeys.indexOf(key) == -1) {
			return;
		}
		var stored = me.loadSessionByKey(key);
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
		me.saveSession(stored);
	}

	private function addMissingBreathPreset(key) {
		if (me.mSessionKeys.indexOf(key) != -1) {
			return;
		}
		var preset = SessionPresets.createBreathworkPreset(key);
		if (preset != null) {
			me.addSession(preset);
		}
	}

	// null for anything unreadable: a corrupt entry must skip the migration, never fail startup
	private function loadSessionByKey(key) {
		try {
			var loadedSessionDictionary = App.Storage.getValue(me.mStorageKeySessionPrefix + key.toString());
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
		// find smallest not used session key
		for (var i = 0; i < mSessionKeys.size(); i++){
			if (key == mSessionKeys[i]){
				key++;
			}
		}
		return key;
	}

	function selectSession(index) {
		me.setSelectedSessionIndex(index);
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
			me.setSelectedSessionIndex(0);
			me.mSessionKeys = [];
			me.restorePresets();
			
			throw ex;
		}
	}

	function saveSession(session) {
		App.Storage.setValue(me.getSessionStorageKey(session), session.toDictionary());
		me.updateSessionStats();
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
		App.Storage.deleteValue(me.getSelectedSessionStorageKey());
		me.mSessionKeys.removeAll(me.getSelectedSessionKey());
		if (me.mSessionKeys.size() == 0) {
			// if all deleted, automatically restore presets
			me.restorePresets();
		}
		me.setSelectedSessionIndex(me.mSelectedSessionIndex - 1);
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
