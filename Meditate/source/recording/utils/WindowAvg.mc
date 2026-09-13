class WindowAvg {
	function initialize(windowSize, first) {
		me.windowSize = windowSize;
		me.count = 0;
		me.data = new [me.windowSize];
		me.first = first;
	}
	
	var windowSize;
	var count;
	var data;
	var first;
	
	function addData(data) {
		if (me.first && me.count >= me.windowSize) {
			return;
		}
		
		if (data != null) {
			me.count = me.count % me.windowSize;
			me.data[me.count] = data.toNumber();
			me.count++;
		}
	}
	
	function calculate() {
		if (me.count < 2) {
			return null;
		}			
		var sum = 0;
		var val = 0;
		for (var i = 0; i < me.count; i++) {
			val = me.data[i];
			if (val != null){
				sum += me.data[i];
			}
		}
		return sum / me.count.toFloat();
	}
}
