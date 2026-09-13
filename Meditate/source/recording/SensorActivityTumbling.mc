using Toybox.ActivityMonitor;

class SensorActivityTumbling extends SensorActivity {
	// Tumbling window: https://stackoverflow.com/a/40599361
	private var windowSize;
	private var windowCounter;
	private var windowSum;
	private var totalCounter;
	function initialize(summary, skipeFirstMeasure, windowSize) {
		SensorActivity.initialize(summary, skipeFirstMeasure);
		if (windowSize == null) {
			windowSize = 10;
		}
		me.windowSize = windowSize;
		me.windowCounter = 0;
		me.windowSum = 0;
		me.totalCounter = 0;
	}

	function addData(val) {
		if (totalCounter % me.windowSize == 0 && totalCounter > 0) {
			flushWindow();
		}
		if (val != null) {
			me.windowCounter++;
			me.windowSum += val;
		}
		totalCounter++;
	}

	function flushWindow() {
		var avg = null;
		if (me.windowCounter > 0) {
			avg = me.windowSum / me.windowCounter.toFloat();
		}
		me.data.add(avg);
		me.windowCounter = 0;
		me.windowSum = 0;
	}

	function getSummary() {
		me.flushWindow();
		me.summary = SensorActivity.getSummary();
		return me.summary;
	}
}
