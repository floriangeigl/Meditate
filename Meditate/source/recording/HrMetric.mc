class HrMetric extends Metric {
	function initialize() {
		Metric.initialize(:hr);
		me.window = 10;
		me.liveBeforeWindow = true;
	}

	static function isSupported() {
		return true;
	}

	function read(info) {
		return info.currentHeartRate;
	}
}
