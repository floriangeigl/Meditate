using Toybox.ActivityMonitor;

module HrvAlgorithms {
	class RrActivity extends SensorActivityTumbling {
		function initialize() {
			SensorActivityTumbling.initialize(new SensorSummary(), true, 30);
		}

		// Method to be used without class instance
		static function isSensorSupported() {
			return ActivityMonitor.getInfo() has :respirationRate ? true : false;
		}

		function getCurrentValueRaw() {
			return ActivityMonitor.getInfo().respirationRate;
		}

		function getCurrentValueClean() {
			var val = me.getCurrentValueRaw();
			if (val != null && val > 0 && val < 100) {
				return val;
			} else {
				return null;
			}
		}
	}
}
