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
			if (me.secondsCount >= me.rollingIntervalSeconds) {
				if (me.count > 0) {
					result = Math.sqrt(me.aggregatedValue / me.count.toFloat());
				}
				me.data.add(result);
				me.reset();				
			}
			return result;
		}
	}
}