using Toybox.ActivityMonitor;

module HrvAlgorithms {
	class RrActivity extends SensorActivityTumbling {
		function initialize() {
			SensorActivityTumbling.initialize(new SensorSummary(), true, null);
		}

		// Method to be used without class instance
		static function isSensorSupported() {
			if (ActivityMonitor.getInfo() has :respirationRate) {
				return true;
			} else {
				return false;
			}
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
