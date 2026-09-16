using Toybox.Math;

// population standard deviation of the beat intervals of the last N recording seconds;
// one slot per second, the slot is that second's interval array
class HrvSdrr {
	private var mData;
	private var mSize;
	private var mCount;
	private var mNext;

	function initialize(seconds) {
		me.mSize = seconds;
		me.mData = new [seconds];
		me.mCount = 0;
		me.mNext = 0;
	}

	// once per tick; an empty second takes a slot too
	function addSecond(beats) {
		me.mData[me.mNext] = beats;
		me.mNext = (me.mNext + 1) % me.mSize;
		if (me.mCount < me.mSize) {
			me.mCount++;
		}
	}

	// null below two intervals
	function calculate() {
		var n = 0;
		var sum = 0.0;
		for (var i = 0; i < me.mCount; i++) {
			var beats = me.mData[i];
			for (var j = 0; j < beats.size(); j++) {
				sum += beats[j];
				n++;
			}
		}
		if (n < 2) {
			return null;
		}
		var mean = sum / n;
		var squares = 0.0;
		for (var i = 0; i < me.mCount; i++) {
			var beats = me.mData[i];
			for (var j = 0; j < beats.size(); j++) {
				var d = beats[j] - mean;
				squares += d * d;
			}
		}
		return Math.sqrt(squares / n);
	}
}
