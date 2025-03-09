module HrvAlgorithms {
	class Rolling {
		function initialize(rollingIntervalSeconds) {	
			me.rollingIntervalSeconds = rollingIntervalSeconds;		
			me.reset();
			me.data = [];
			me.previousValue = null;
		}
			
		var rollingIntervalSeconds;
		var secondsCount;	
		var previousValue;
		var count;
		var aggregatedValue;
		var data;
		
		function reset() {
			me.secondsCount = 0;	
			me.count = 0;
			me.aggregatedValue = 0.0;
		}
		
		function addOneSec(data) {
			for (var i = 0; i < data.size(); i++) {
				me.addValue(data[i]);
			}
			me.secondsCount++;
			return me.calculate();
		}
		
		function addValue(value) {
			if (value != null) {
				me.count++;
				me.aggregate(value);
			}
			me.previousValue = value;
		}

		function aggregate(value) {
			me.aggregatedValue += value;
		}

		function getLastCalcValue() {
			if (me.data.size() > 0)
			{
				return me.data[me.data.size()-1];
			} else {
				return null;
			}
		}
	
		function calculate() {
			var result = null;
			if (me.secondsCount >= me.rollingIntervalSeconds) {
				if (me.count > 0) {
					result = me.aggregatedValue / me.count.toFloat();
				}
				me.reset();
				me.data.add(result);
			}			
			return result;
		}

		function getHistory() {
			return me.data;
		}
	}
}