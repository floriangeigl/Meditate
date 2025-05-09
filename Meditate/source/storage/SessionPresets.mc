using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class SessionPresets {
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

		// 5min Breathwork Box-Breathing
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew();
		iAlert.get(0).time = 4;
		settings = {
			"time" => 5 * 60,
			"color" => Gfx.COLOR_GREEN,
			"name" => "Box Breath",
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Breathing,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 5min Breathwork Coherence
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew();
		iAlert.get(0).time = 6;
		settings = {
			"time" => 5 * 60,
			"color" => Gfx.COLOR_GREEN,
			"name" => "B. Coherence",
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Breathing,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		// 5min 4-7-8 breathing
		session = new SessionModel();
		iAlert = new IntervalAlerts();
		iAlert.addNew();
		iAlert.get(0).time = 19;
		iAlert.get(0).offset = 4;
		iAlert.get(0).color = Gfx.COLOR_BLUE;
		iAlert.get(0).vibePattern = VibePattern.ShortContinuous;

		iAlert.addNew();
		iAlert.get(1).time = 19;
		iAlert.get(1).offset = 4 + 7;
		iAlert.get(1).color = Gfx.COLOR_RED;
		iAlert.get(1).vibePattern = VibePattern.MediumDescending;

		iAlert.addNew();
		iAlert.get(2).time = 19;
		iAlert.get(2).offset = 4 + 7 + 8;
		iAlert.get(2).color = Gfx.COLOR_WHITE;
		iAlert.get(2).vibePattern = VibePattern.ShortAscending;
		settings = {
			"time" => 5 * 60,
			"color" => Gfx.COLOR_GREEN,
			"name" => "B. 4-7-8",
			"vibePattern" => VibePattern.LongContinuous,
			"intervalAlerts" => iAlert.toArray(),
			"activityType" => ActivityType.Breathing,
			"key" => sessionKey,
		};
		session.fromDictionary(settings);
		sessions.add(session);
		sessionKey++;

		return sessions;
	}
}
