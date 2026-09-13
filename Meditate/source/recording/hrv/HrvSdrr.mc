using Toybox.Math;

// population standard deviation of the first or the last N beat intervals
class HrvSdrr {
	private var mData;
	private var mSize;
	private var mCount;
	private var mNext;
	private var mKeepFirst;

	function initialize(size, keepFirst) {
		me.mSize = size;
		me.mData = new [size];
		me.mCount = 0;
		me.mNext = 0;
		me.mKeepFirst = keepFirst;
	}

	function add(interval) {
		if (me.mKeepFirst && me.mCount >= me.mSize) {
			return;
		}
		me.mData[me.mNext] = interval;
		me.mNext = (me.mNext + 1) % me.mSize;
		if (me.mCount < me.mSize) {
			me.mCount++;
		}
	}

	// null below two intervals
	function calculate() {
		if (me.mCount < 2) {
			return null;
		}
		var sum = 0.0;
		for (var i = 0; i < me.mCount; i++) {
			sum += me.mData[i];
		}
		var mean = sum / me.mCount;
		var squares = 0.0;
		for (var i = 0; i < me.mCount; i++) {
			var d = me.mData[i] - mean;
			squares += d * d;
		}
		return Math.sqrt(squares / me.mCount);
	}
}
