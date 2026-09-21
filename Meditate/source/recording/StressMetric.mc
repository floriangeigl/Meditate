using Toybox;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;

class StressMetric extends Metric {
	private var mLive;
	private var mHistory;
	private var mLiveSeen;

	function initialize() {
		Metric.initialize(:stress);
		me.window = 30;
		me.lo = 0;
		me.hi = 100;
		me.liveBeforeWindow = true;
		me.mLive = StressMetric.hasLiveScore();
		me.mHistory = StressMetric.hasStressHistory();
		me.mLiveSeen = false;
	}

	// live 30s score is an instance attribute of getInfo(), not of the Info class
	private static function hasLiveScore() {
		return ActivityMonitor.getInfo() has :stressScore;
	}

	private static function hasStressHistory() {
		return Toybox has :SensorHistory && Toybox.SensorHistory has :getStressHistory;
	}

	static function isSupported() {
		return StressMetric.hasLiveScore() || StressMetric.hasStressHistory();
	}

	function read(info) {
		if (me.mLive) {
			var val = ActivityMonitor.getInfo().stressScore;
			if (val != null) {
				// force to use live stress once it provided a value
				me.mLiveSeen = true;
				return val;
			}
		}
		if (me.mLiveSeen || !me.mHistory) {
			return null;
		}
		// newest logged snapshot; updates every few minutes
		var iter = Toybox.SensorHistory.getStressHistory({
			:period => null,
			:order => Toybox.SensorHistory.ORDER_NEWEST_FIRST,
		});
		var sample = iter.next();
		while (sample != null) {
			if (sample.data != null) {
				return sample.data;
			}
			sample = iter.next();
		}
		return null;
	}
}
