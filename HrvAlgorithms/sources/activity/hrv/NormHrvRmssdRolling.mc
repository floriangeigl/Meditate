module HrvAlgorithms {
	class NormHrvRmssdRolling extends Rolling {
		private var avgAggValue;
		function initialize(rollingIntervalSeconds) {
			Rolling.initialize(rollingIntervalSeconds);
		}
		function aggregate(value) {
			if (value != null && me.previousValue != null) {
				me.aggregatedValue += Math.pow(value - me.previousValue, 2);
				me.avgAggValue += value;
			}
		}

		function calculate() {
			var result = null;
			if (me.secondsCount >= me.rollingIntervalSeconds) {
				if (me.count > 0 && me.avgAggValue > 0) {
					result = Math.sqrt(me.aggregatedValue / me.count.toFloat());
					result /= me.avgAggValue.toFloat() * 100.0;
				}
				me.data.add(result);
				me.reset();
			}
			return result;
		}

		function reset() {
			me.avgAggValue = 0;
			Rolling.reset();
		}
	}
}
