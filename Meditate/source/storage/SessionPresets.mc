using Toybox.Graphics as Gfx;

class SessionPresets {
	// Session keys are persistent ids - a stored session is matched back to its preset by key,
	// so these must never be renumbered. A new preset takes the next free key at the end.
	static const FirstBreathworkKey = 7;

	// key = index, so the keys stop below FirstBreathworkKey; [minutes, color, alert minutes, alert vibe]
	private static function meditationPresetDefs() {
		return [
			[5, Gfx.COLOR_GREEN, 5, VibePattern.Blip],
			[10, Gfx.COLOR_YELLOW, 5, VibePattern.Blip],
			[15, Gfx.COLOR_BLUE, 5, VibePattern.Blip],
			[20, Gfx.COLOR_GREEN, 5, VibePattern.Blip],
			[30, Gfx.COLOR_GREEN, 15, VibePattern.Blip],
			[45, Gfx.COLOR_GREEN, 15, VibePattern.ShortAscending],
			[60, Gfx.COLOR_GREEN, 15, VibePattern.ShortAscending],
		];
	}

	// key = FirstBreathworkKey + index; the first three keep the names existing users know
	// [name, program, end vibe]; sleep ends with a blip so it doesn't wake anyone
	private static function breathworkPresetDefs() {
		var end = VibePattern.LongContinuous;
		return [
			["Box Breath", :box5, end],
			["B. Coherence", :coherence5, end],
			["B. 4-7-8", :b4785, end],
			["B. Energize", :energize, end],
			["B. Wind Down", :windDown, end],
			["B. Holds", :breathHolds, end],
			["B. Sleep", :sleep, VibePattern.Blip],
			["B. Calm", :calm, end],
		];
	}

	// the shipped breathwork session for one key, or null when the key is not one of them
	static function createBreathworkPreset(key) {
		var defs = SessionPresets.breathworkPresetDefs();
		var index = key - SessionPresets.FirstBreathworkKey;
		if (index < 0 || index >= defs.size()) {
			return null;
		}
		return SessionPresets.makeBreathworkSession(defs[index], key);
	}

	// one repeating alert, colour and type from the Alert defaults
	private static function makeMeditationSession(def, sessionKey) {
		var alerts = new IntervalAlerts();
		alerts.addNew();
		alerts.get(0).time = def[2] * 60;
		alerts.get(0).vibePattern = def[3];
		var session = new SessionModel();
		session.fromDictionary({
			"time" => def[0] * 60,
			"color" => def[1],
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => alerts.toArray(),
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		});
		return session;
	}

	// BreathTemplates owns the program data; this only wraps it in a session
	private static function makeBreathworkSession(def, sessionKey) {
		var program = BreathTemplates.createProgram(def[1]);
		var session = new SessionModel();
		session.fromDictionary({
			"time" => program.totalTime(),
			"color" => Gfx.COLOR_GREEN,
			"name" => def[0],
			"vibePattern" => def[2],
			"breathProgram" => program.toDictionary(),
			"activityType" => ActivityType.Breathing,
			"key" => sessionKey,
		});
		return session;
	}

	// every preset in list order, which is the order a fresh store shows them in
	static function getPresets() {
		var sessions = [];
		var meditationDefs = SessionPresets.meditationPresetDefs();
		for (var i = 0; i < meditationDefs.size(); i++) {
			sessions.add(SessionPresets.makeMeditationSession(meditationDefs[i], i));
		}
		var breathworkDefs = SessionPresets.breathworkPresetDefs();
		for (var i = 0; i < breathworkDefs.size(); i++) {
			sessions.add(
				SessionPresets.makeBreathworkSession(breathworkDefs[i], SessionPresets.FirstBreathworkKey + i)
			);
		}
		return sessions;
	}
}
