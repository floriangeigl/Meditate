using Toybox.Test;

// the six fixture intervals split over two ticks; numbers as in HrvAlgorithmsSampleOutput.xlsx
(:test)
class HrvMetricTests {
	private static function near(actual, expected) {
		return actual != null && (actual - expected).abs() < 0.01;
	}

	private static function detailedAfterTwoTicks(window) {
		var hrv = new HrvMetric(new FitFields(null), true, window);
		hrv.onIntervals([1090.9, 1016.9, 1016.9]);
		hrv.sample(null);
		hrv.onIntervals([1034.4, 1016.9, 1052.6]);
		hrv.sample(null);
		return hrv;
	}

	(:test)
	static function detailedRollingValuePerWindowAndDifferencesAcrossWindows(logger) {
		var hrv = new HrvMetric(new FitFields(null), true, 1);
		if (hrv.getLoadTime() != 1 || hrv.getValue() != null) {
			return false;
		}
		hrv.onIntervals([1090.9, 1016.9, 1016.9]);
		hrv.sample(null);
		// pairs -74 and 0
		if (!near(hrv.getValue(), 52.33)) {
			return false;
		}
		hrv.onIntervals([1034.4, 1016.9, 1052.6]);
		hrv.sample(null);
		// the first pair of this window uses the last beat of the previous one
		if (!near(hrv.getValue(), 25.08) || hrv.history.size() != 2) {
			return false;
		}
		// a tick without beats has no value and does not stick
		hrv.sample(null);
		return hrv.getValue() == null && hrv.history.size() == 3 && hrv.history[2] == null;
	}

	(:test)
	static function detailedSessionNumbersOnFlush(logger) {
		var hrv = detailedAfterTwoTicks(60);
		if (hrv.getLoadTime() != 60 || hrv.hasData()) {
			return false;
		}
		hrv.flush();
		return (
			hrv.detailed &&
			near(hrv.rmssd, 38.37) &&
			near(hrv.pnn20, 33.33) &&
			near(hrv.pnn50, 16.67) &&
			near(hrv.sdrrFirst, 26.95) &&
			near(hrv.sdrrLast, 26.95) &&
			// the partial window is all there is, so it counts
			hrv.history.size() == 1 &&
			near(hrv.history[0], 38.37) &&
			hrv.hasData()
		);
	}

	(:test)
	static function onModeIsTheStickyLastDifference(logger) {
		var hrv = new HrvMetric(new FitFields(null), false, 60);
		if (hrv.getLoadTime() != 1) {
			return false;
		}
		hrv.onIntervals([1000, 1020]);
		hrv.sample(null);
		if (!near(hrv.getValue(), 20)) {
			return false;
		}
		// a beat-less tick keeps the last difference
		hrv.sample(null);
		if (!near(hrv.getValue(), 20) || hrv.history.size() != 0) {
			return false;
		}
		hrv.onIntervals([990]);
		hrv.sample(null);
		if (!near(hrv.getValue(), -30)) {
			return false;
		}
		hrv.flush();
		// pairs 20 and -30
		return !hrv.detailed && near(hrv.rmssd, 25.495) && hrv.pnn20 == null && hrv.sdrrFirst == null;
	}

	// fixture beats on tick 1, an outlier pair on the last tick, empty ticks between
	private static function detailedOverTicks(ticks) {
		var hrv = new HrvMetric(new FitFields(null), true, 60);
		hrv.onIntervals([1090.9, 1016.9, 1016.9, 1034.4, 1016.9, 1052.6]);
		hrv.sample(null);
		for (var i = 2; i < ticks; i++) {
			hrv.sample(null);
		}
		hrv.onIntervals([1000.0, 1400.0]);
		hrv.sample(null);
		hrv.flush();
		return hrv;
	}

	// sdrr first is the first 300 seconds, sdrr last the last 300; both when the session is shorter
	(:test)
	static function sdrrWindowsAreFiveMinutes(logger) {
		var hrv = detailedOverTicks(301);
		if (!near(hrv.sdrrFirst, 26.95) || !near(hrv.sdrrLast, 200.0)) {
			return false;
		}
		// exactly the window, and shorter: snapshot and flush see the same eight beats
		hrv = detailedOverTicks(300);
		if (!sameAndNotTheLastPair(hrv)) {
			return false;
		}
		hrv = detailedOverTicks(299);
		return sameAndNotTheLastPair(hrv);
	}

	private static function sameAndNotTheLastPair(hrv) {
		return hrv.sdrrLast != null && near(hrv.sdrrFirst, hrv.sdrrLast) && !near(hrv.sdrrFirst, 200.0);
	}

	(:test)
	static function flushedHrvMetricIsInert(logger) {
		var hrv = detailedAfterTwoTicks(1);
		hrv.flush();
		var entries = hrv.history.size();
		// beats and ticks after the summary, including a window close, change nothing and touch no fit field
		hrv.onIntervals([1000, 1100]);
		hrv.sample(null);
		hrv.sample(null);
		hrv.flush();
		return hrv.history.size() == entries && near(hrv.rmssd, 38.37) && near(hrv.pnn20, 33.33);
	}

	(:test)
	static function noBeatsAtAllLeavesNulls(logger) {
		var hrv = new HrvMetric(new FitFields(null), true, 2);
		hrv.sample(null);
		hrv.flush();
		return hrv.rmssd == null && hrv.pnn20 == null && hrv.sdrrLast == null && !hrv.hasData();
	}
}
