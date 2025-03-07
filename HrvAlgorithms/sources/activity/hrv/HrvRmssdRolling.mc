module HrvAlgorithms {
	class HrvRmssdRolling extends Rolling {
		function initialize(rollingIntervalSeconds) {
			Rolling.initialize(rollingIntervalSeconds);
		}
		function aggregate(value) {
			if (value != null && me.previousValue != null) {
				me.aggregatedValue += Math.pow(value - me.previousValue, 2);
			}
		}
		
		function calculate() {
			var result = null;
			if (me.secondsCount >= me.rollingIntervalSeconds && me.count > 0) {
				result = Math.sqrt(me.aggregatedValue / me.count.toFloat());
			}
			me.reset();
			me.data.add(result);
			return result;
		}
	}
}