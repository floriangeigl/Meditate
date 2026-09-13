using Toybox;
using Toybox.Time;
using Toybox.SensorHistory;
using Toybox.ActivityMonitor;

class StressActivity extends SensorActivityTumbling {
	static var apiV5Plus;
	private static const windowSize = 30;
	private var liveStressAvailable = false;

	function initialize() {
		SensorActivityTumbling.initialize(new SensorSummary(), false, StressActivity.windowSize);
	}

	static function isSensorSupported() {
		// live 30s score is an instance attribute of getInfo(), not of the Info class
		if (Toybox has :ActivityMonitor && ActivityMonitor.getInfo() has :stressScore) {
			me.apiV5Plus = true;
			return true;
		} else if (Toybox has :SensorHistory && Toybox.SensorHistory has :getStressHistory) {
			me.apiV5Plus = false;
			return true;
		} else {
			return false;
		}
	}

	function getCurrentValueRaw() {
		var val = null;
		if (me.sensorSupported) {
			if (me.apiV5Plus) {
				val = ActivityMonitor.getInfo().stressScore;
			}
			if (val == null && !me.liveStressAvailable) {
				var iter = Toybox.SensorHistory.getStressHistory({
					:period => null,
					:order => Toybox.SensorHistory.ORDER_NEWEST_FIRST,
				});
				var sample = iter.next();
				while (sample != null) {
					val = sample.data;
					if (val != null) {
						break;
					}
					sample = iter.next();
				}
			} else {
				// force to use live stress if it provides values once
				me.liveStressAvailable = true;
			}
		}
		return val;
	}

	function getCurrentValueClean() {
		var val = me.getCurrentValueRaw();
		if (val != null && val >= 0 && val <= 100) {
			return val;
		} else {
			return null;
		}
	}

	static function getLoadTime() {
		return StressActivity.windowSize;
	}
}
