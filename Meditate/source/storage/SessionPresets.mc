using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionPresets {
	// BreathTemplates owns the program data; this only wraps it in a session
	private static function createBreathworkPreset(name, templateId, sessionKey) {
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
		// The first three keep their original names so existing users still recognise them.
		var breathworkPresets = [
			["Box Breath", :box5],
			["B. Coherence", :coherence5],
			["B. 4-7-8", :b4785],
			["B. Energize", :energize],
			["B. Wind Down", :windDown],
			["B. Holds", :breathHolds],
		];
		for (var i = 0; i < breathworkPresets.size(); i++) {
			sessions.add(
				SessionPresets.createBreathworkPreset(breathworkPresets[i][0], breathworkPresets[i][1], sessionKey)
			);
			sessionKey++;
		}

		return sessions;
	}
}
