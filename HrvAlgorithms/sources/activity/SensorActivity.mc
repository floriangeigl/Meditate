using Toybox.ActivityMonitor;

module HrvAlgorithms {
	class SensorActivity {
		function initialize(summary, skipeFirstMeasure) {
			// Check if device supports the sensor
			if (isSensorSupported()) {
				me.sensorSupported = true;
			} else {
				me.sensorSupported = false;
			}
			if (summary == null) {
				summary = new SensorSummary();
			}
			me.summary = summary;
			me.count = 0;
			me.sum = 0;
			me.min = null;
			me.max = null;
			me.first = null;
			me.last = null;
			me.skipeFirstMeasure = skipeFirstMeasure;
			me.skipeFirstMeasure = me.skipeFirstMeasure == null ? false : me.skipeFirstMeasure;
		}

		var sensorSupported;
		var count;
		var sum;
		var summary;
		var min, max;
		var first, last;
		var data = [];
		var skipeFirstMeasure;

		// Method to be used without class instance
		static function isSensorSupported() {
			return false;
		}

		function isSupported() {
			return me.sensorSupported;
		}

		protected function getCurrentValueRaw() {
			// return ActivityMonitor.getInfo().respirationRate;
			return null;
		}

		protected function getCurrentValueClean() {
			var val = me.getCurrentValueRaw();
			if (val > 0) {
				return val;
			} else {
				return null;
			}
		}

		function getCurrentValue() {
			// If device supports the sensor
			if (me.sensorSupported) {
				var val = me.getCurrentValueClean();
				if (me.skipeFirstMeasure) {
					me.skipeFirstMeasure = false;
					return null;
				}

				// Update summary metrics
				updateData(val);
				return me.getLastValue();
			} else {
				return null;
			}
		}

		function addData(val) {
			me.data.add(val);
		}

		function updateData(val) {
			me.addData(val);
			// update min, max, count, sum
			if (val != null) {
				if (me.first == null) {
					me.first = val;
				}
				me.last = val;
				me.count++;
				me.sum += val;
				if (me.min == null || val < me.min) {
					me.min = val;
				}
				if (me.max == null || val > me.max) {
					me.max = val;
				}
			}
		}

		function getAvg() {
			if (me.count > 0) {
				return me.sum / me.count.toFloat();
			} else {
				return null;
			}
		}

		function getLastValue() {
			if (me.data != null and me.data.size() > 0) {
				return me.data[me.data.size() - 1];
			} else {
				return null;
			}
		}

		function getSummary() {
			me.summary.avg = getAvg();
			me.summary.min = me.min;
			me.summary.max = me.max;
			me.summary.first = me.first;
			me.summary.last = me.last;
			me.summary.data = me.data;
			return me.summary;
		}
	}
}
