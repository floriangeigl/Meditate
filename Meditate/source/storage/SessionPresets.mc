using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionPresets {
	// Session keys are persistent ids - a stored session is matched back to its preset by key,
	// so these must never be renumbered. A new preset takes the next free key at the end.
	static const FirstBreathworkKey = 7;

	// key = FirstBreathworkKey + index; the first three keep the names existing users know
	private static function breathworkPresetDefs() {
		return [
			["Box Breath", :box5],
			["B. Coherence", :coherence5],
			["B. 4-7-8", :b4785],
			["B. Energize", :energize],
			["B. Wind Down", :windDown],
			["B. Holds", :breathHolds],
		];
	}

	// the shipped breathwork session for one key, or null when the key is not one of them
	static function createBreathworkPreset(key) {
		var defs = SessionPresets.breathworkPresetDefs();
		var index = key - SessionPresets.FirstBreathworkKey;
		if (index < 0 || index >= defs.size()) {
			return null;
		}
		return SessionPresets.makeBreathworkSession(defs[index][0], defs[index][1], key);
	}

	// BreathTemplates owns the program data; this only wraps it in a session
	private static function makeBreathworkSession(name, templateId, sessionKey) {
		var program = BreathTemplates.createProgram(templateId);
		var session = new SessionModel();
		session.fromDictionary({
			"time" => program.totalTime(),
			"color" => Gfx.COLOR_GREEN,
			"name" => name,
			"vibePattern" => VibePattern.LongContinuous,
			"breathProgram" => program.toDictionary(),
			"activityType" => ActivityType.Breathing,
			"key" => sessionKey,
		});
		return session;
	}

	static function getPresets() {
		var sessions = new SessionModel [0];
		var session = null;
		var iAlert = null;
		var settings = null;
		var sessionKey = 0;

		// 5min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew(); // default every 5min
		settings = {
			"time" => 5 * 60,
			"color" => Gfx.COLOR_GREEN,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(), // default every 5min
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 10min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew(); // default every 5min
		settings = {
			"time" => 10 * 60,
			"color" => Gfx.COLOR_YELLOW,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(), // default every 5min
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 15min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew(); // default every 5min
		settings = {
			"time" => 15 * 60,
			"color" => Gfx.COLOR_BLUE,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(), // default every 5min
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 20min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew(); // default every 5min
		settings = {
			"time" => 20 * 60,
			"color" => Gfx.COLOR_GREEN,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 30min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		// change interval alert to every 15min
		iAlert.addNew();
		iAlert.get(0).time = 15 * 60;
		settings = {
			"time" => 30 * 60,
			"color" => Gfx.COLOR_GREEN,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 45min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew();
		// change interval alert to every 15min
		iAlert.get(0).time = 15 * 60;
		iAlert.get(0).vibePattern = VibePattern.ShortAscending;
		settings = {
			"time" => 45 * 60,
			"color" => Gfx.COLOR_GREEN,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 60min Meditation
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew();
		// change interval alert to every 15min
		iAlert.get(0).time = 15 * 60;
		iAlert.get(0).vibePattern = VibePattern.ShortAscending;
		settings = {
			"time" => 60 * 60,
			"color" => Gfx.COLOR_GREEN,
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Meditating,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// Breathwork presets are guided breath programs; the program defines the length.
		// sessionKey is FirstBreathworkKey here - keys are addressed directly so the migration
		// in SessionStorage can rebuild any single preset from its key.
		var breathworkDefs = SessionPresets.breathworkPresetDefs();
		for (var i = 0; i < breathworkDefs.size(); i++) {
			sessions.add(
				SessionPresets.makeBreathworkSession(
					breathworkDefs[i][0],
					breathworkDefs[i][1],
					SessionPresets.FirstBreathworkKey + i
				)
			);
		}

		return sessions;
	}
}
