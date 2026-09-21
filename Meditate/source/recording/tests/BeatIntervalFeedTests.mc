using Toybox.Test;
using Toybox.Application as App;

// shaped like Sensor.SensorData for BeatIntervalFeed.update
(:test)
class FakeHeartRateData {
	var heartBeatIntervals;

	function initialize(intervals) {
		me.heartBeatIntervals = intervals;
	}
}

(:test)
class FakeSensorData {
	var heartRateData;

	function initialize(intervals) {
		me.heartRateData = intervals == null ? null : new FakeHeartRateData(intervals);
	}
}

(:test)
class IntervalsCapture {
	var last = null;
	var calls = 0;

	function onIntervals(intervals) {
		me.last = intervals;
		me.calls++;
	}
}

// the feed is never started here, so no sensor listener is registered
(:test)
class BeatIntervalFeedTests {
	private static function feedWith(dataUpdates, emptyUpdates) {
		var feed = new BeatIntervalFeed();
		for (var i = 0; i < dataUpdates; i++) {
			feed.update(new FakeSensorData([1000]));
		}
		for (var i = 0; i < emptyUpdates; i++) {
			feed.update(new FakeSensorData([]));
		}
		return feed;
	}

	(:test)
	static function firstDataIsWeakThenGood(logger) {
		var feed = new BeatIntervalFeed();
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Error) {
			return false;
		}
		feed.update(new FakeSensorData([1000]));
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Weak) {
			return false;
		}
		feed.update(new FakeSensorData([1000]));
		return feed.pollStatus() == HeartbeatIntervalsSensorStatus.Good;
	}

	(:test)
	static function listenerGetsCleanedIntervalsEveryUpdate(logger) {
		var feed = new BeatIntervalFeed();
		var capture = new IntervalsCapture();
		feed.setListener(capture.method(:onIntervals));
		feed.update(new FakeSensorData([100, 1000, null, 2500, 250, 2000]));
		if (capture.calls != 1 || capture.last.size() != 3 || capture.last[0] != 1000 || capture.last[2] != 2000) {
			return false;
		}
		// no heart rate data at all still reaches the listener as an empty array
		feed.update(new FakeSensorData(null));
		if (capture.calls != 2 || capture.last.size() != 0) {
			return false;
		}
		feed.pause();
		feed.update(new FakeSensorData([1000]));
		return capture.calls == 2;
	}

	(:test)
	static function onlyDoubleFailsDegradeTheStatus(logger) {
		// good with the counter at zero
		var feed = feedWith(10, 0);
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Good) {
			return false;
		}
		feed = feedWith(10, 9);
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Good) {
			return false;
		}
		feed = feedWith(10, 10);
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Weak) {
			return false;
		}
		feed = feedWith(10, 17);
		if (feed.pollStatus() != HeartbeatIntervalsSensorStatus.Weak) {
			return false;
		}
		feed = feedWith(10, 18);
		return feed.pollStatus() == HeartbeatIntervalsSensorStatus.Error;
	}

	(:test)
	static function errorSecondsCountOnScreenAndNeverResetPastSixty(logger) {
		// at most one open session: past 60 error seconds the feed creates its wakeup session
		App.getApp().beatIntervalFeed.discardWakeupSession();
		var feed = new BeatIntervalFeed();
		for (var i = 0; i < 70; i++) {
			feed.pollStatus();
		}
		if (feed.errorSeconds() != 70 || feed.sensorWakeupSession == null) {
			return false;
		}
		// backgrounded polls neither count nor recover
		feed.setForeground(false);
		feed.pollStatus();
		if (feed.errorSeconds() != 70) {
			return false;
		}
		// back on screen the counters start over
		feed.setForeground(true);
		if (feed.errorSeconds() != 0 || feed.pollStatus() != HeartbeatIntervalsSensorStatus.Error) {
			return false;
		}
		feed.update(new FakeSensorData([1000]));
		feed.update(new FakeSensorData([1000]));
		var recovered = feed.pollStatus() == HeartbeatIntervalsSensorStatus.Good && feed.errorSeconds() == 0;
		feed.shutdown();
		return recovered && feed.sensorWakeupSession == null;
	}
}
