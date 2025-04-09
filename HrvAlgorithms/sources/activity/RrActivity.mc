using Toybox.ActivityMonitor;

module HrvAlgorithms {
	class RrActivity extends SensorActivityTumbling {
		private static const windowSize = 30;
		function initialize() {
			SensorActivityTumbling.initialize(new SensorSummary(), true, RrActivity.windowSize);
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

		static function getLoadTime() {
			return RrActivity.windowSize;
		}
	}
}
