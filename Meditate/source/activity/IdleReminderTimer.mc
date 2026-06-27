using Toybox.Timer;

class IdleReminderTimer {
	private static const IdleReminderIntervalMs = 600000; // 10 minutes
	private var mTimer;

	function initialize() {
		me.mTimer = null;
	}

	function start() {
		me.stop();
		me.mTimer = new Timer.Timer();
		me.mTimer.start(method(:onTimer), IdleReminderIntervalMs, true);
	}

	function stop() {
		if (me.mTimer != null) {
			me.mTimer.stop();
			me.mTimer = null;
		}
	}

	function onTimer() as Void {
		Vibe.vibrate(VibePattern.Blip);
	}
}
