using Toybox.Test;

// samples come from a script instead of a sensor
(:test)
class ScriptedMetric extends Metric {
	private var mScript;
	private var mIndex;

	function initialize(script, window) {
		Metric.initialize(:scripted);
		me.mScript = script;
		me.mIndex = 0;
		me.window = window;
	}

	function configure(lo, hi, skipFirst, liveBeforeWindow, keepHistory) {
		me.lo = lo;
		me.hi = hi;
		me.skipFirst = skipFirst;
		me.liveBeforeWindow = liveBeforeWindow;
		me.keepHistory = keepHistory;
		return me;
	}

	function read(info) {
		var v = me.mScript[me.mIndex];
		me.mIndex++;
		return v;
	}
}

(:test)
class MetricTests {
	private static function near(actual, expected) {
		return actual != null && (actual - expected).abs() < 0.001;
	}

	private static function tick(metric, times) {
		for (var i = 0; i < times; i++) {
			metric.sample(null);
		}
	}

	(:test)
	static function windowFlushesOnTheCompletingTick(logger) {
		var m = new ScriptedMetric([60, 62, 70, 80], 2);
		m.sample(null);
		if (m.getValue() != null || m.history.size() != 0 || m.hasData()) {
			return false;
		}
		m.sample(null);
		if (!near(m.getValue(), 61) || m.history.size() != 1 || !near(m.history[0], 61)) {
			return false;
		}
		tick(m, 2);
		return near(m.getValue(), 75) && m.history.size() == 2 && m.getLoadTime() == 2;
	}

	(:test)
	static function statsAreOverWindowValuesNotSamples(logger) {
		var m = new ScriptedMetric([10, 30, 50, 90, 20, 40], 2);
		tick(m, 6);
		// windows: 20, 70, 30
		return (
			near(m.first, 20) && near(m.last, 30) && near(m.min, 20) && near(m.max, 70) && near(m.getAvg(), 40) && m.hasData()
		);
	}

	(:test)
	static function skipFirstDropsTheFirstSampleEntirely(logger) {
		// the skipped tick reads nothing, so 10 is the second tick's sample
		var m = new ScriptedMetric([10, 20], 2).configure(null, null, true, false, true);
		tick(m, 2);
		if (m.getValue() != null || m.history.size() != 0) {
			return false;
		}
		m.sample(null);
		return near(m.getValue(), 15) && m.history.size() == 1;
	}

	(:test)
	static function outOfRangeSamplesCountAsMissing(logger) {
		var m = new ScriptedMetric([0, 100, 5, null, 50, 60], 2).configure(1, 99, false, false, true);
		tick(m, 2);
		// window of only invalid samples: null entry, no stats
		if (m.getValue() != null || m.history.size() != 1 || m.history[0] != null || m.hasData()) {
			return false;
		}
		tick(m, 2);
		if (!near(m.getValue(), 5) || !near(m.min, 5)) {
			return false;
		}
		tick(m, 2);
		return near(m.getValue(), 55) && near(m.max, 55) && m.history.size() == 3;
	}

	(:test)
	static function partialWindowKeptOnlyWhenNearlyComplete(logger) {
		var script = new [40];
		for (var i = 0; i < script.size(); i++) {
			script[i] = 50;
		}
		// 3 of 10 ticks with nothing else: kept
		var m = new ScriptedMetric(script, 10);
		tick(m, 3);
		m.flush();
		if (m.history.size() != 1 || !near(m.history[0], 50)) {
			return false;
		}
		// 8 of 10 after a full window: dropped
		m = new ScriptedMetric(script, 10);
		tick(m, 18);
		m.flush();
		if (m.history.size() != 1) {
			return false;
		}
		// 9 of 10 after a full window: kept
		m = new ScriptedMetric(script, 10);
		tick(m, 19);
		m.flush();
		if (m.history.size() != 2) {
			return false;
		}
		// nothing pending: nothing added, flush returns the metric
		m = new ScriptedMetric(script, 10);
		tick(m, 10);
		return m.flush() == m && m.history.size() == 1;
	}

	(:test)
	static function keepHistoryOffStillTracksValueAndStats(logger) {
		var m = new ScriptedMetric([10, 20, 30], 1).configure(null, null, false, false, false);
		tick(m, 3);
		return m.history.size() == 0 && near(m.getValue(), 30) && near(m.min, 10) && near(m.max, 30) && near(m.getAvg(), 20);
	}

	(:test)
	static function liveBeforeWindowShowsTheRawSample(logger) {
		var m = new ScriptedMetric([70, 72, 74, null, null, null, 80], 3).configure(null, null, false, true, true);
		if (m.getLoadTime() != 0) {
			return false;
		}
		m.sample(null);
		if (!near(m.getValue(), 70)) {
			return false;
		}
		tick(m, 2);
		if (!near(m.getValue(), 72)) {
			return false;
		}
		// after a window without samples the live value is back
		tick(m, 3);
		if (m.getValue() != null || m.history.size() != 2 || m.history[1] != null) {
			return false;
		}
		m.sample(null);
		return near(m.getValue(), 80) && m.history.size() == 2;
	}
}
