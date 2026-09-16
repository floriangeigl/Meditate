using Toybox.ActivityMonitor;

class RrMetric extends Metric {
	function initialize() {
		Metric.initialize(:rr);
		me.window = 30;
		me.lo = 1;
		me.hi = 99;
		me.liveBeforeWindow = true;
	}

	static function isSupported() {
		return ActivityMonitor.getInfo() has :respirationRate;
	}

	function read(info) {
		return ActivityMonitor.getInfo().respirationRate;
	}
}
