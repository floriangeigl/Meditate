using Toybox.Math;

// hrv as a metric: the feed buffers this second's beats, the recording tick consumes them.
// On: window 1, live value is the last successive difference, session rmssd.
// Detailed: window = setting, live value and history are the rolling rmssd, plus pnn, sdrr over
// the first and last 5 min and the per beat fit records
class HrvMetric extends Metric {
	private var mFit;
	private var mBuffer;
	private var mPrev;
	private var mLastDiff;
	private var mSquareDiffs;
	private var mPairs;
	private var mBeats;
	private var mOver20;
	private var mOver50;
	private var mWinSquareDiffs;
	private var mWinPairs;
	private var mSdrr;
	private var mSeconds;
	private static const SdrrSeconds = 300;

	var detailed;
	var rmssd;
	var pnn20;
	var pnn50;
	var sdrrFirst;
	var sdrrLast;

	function initialize(fitFields, detailed, windowSize) {
		Metric.initialize(:hrv);
		me.detailed = detailed;
		me.mFit = fitFields;
		me.mBuffer = [];
		me.mPrev = null;
		me.mLastDiff = null;
		me.mSquareDiffs = 0.0;
		me.mPairs = 0;
		me.mBeats = 0;
		me.mOver20 = 0;
		me.mOver50 = 0;
		me.mWinSquareDiffs = 0.0;
		me.mWinPairs = 0;
		me.mSeconds = 0;
		if (detailed) {
			me.window = windowSize;
			me.mSdrr = new HrvSdrr(SdrrSeconds);
			fitFields.create([
				:hrvSuccessive,
				:rmssd,
				:beat2beat,
				:hrFromBeat,
				:sdrrFirst,
				:sdrrLast,
				:pnn50,
				:pnn20,
				:rmssdRolling,
			]);
		} else {
			me.window = 1;
			me.keepHistory = false;
			fitFields.create([:hrvSuccessive, :rmssd]);
		}
	}

	// feed listener; cleaned intervals of the last second
	function onIntervals(intervals) {
		if (me.mBuffer != null) {
			me.mBuffer.addAll(intervals);
		}
	}

	function read(info) {
		var beats = me.mBuffer;
		me.mBuffer = [];
		return beats;
	}

	// one ring slot per tick; sdrr first is the ring on the tick it first fills, last at flush
	function accept(beats) {
		if (beats == null) {
			return;
		}
		if (me.detailed) {
			me.mSeconds++;
			me.mSdrr.addSecond(beats);
			if (me.mSeconds == SdrrSeconds) {
				me.sdrrFirst = me.mSdrr.calculate();
			}
		}
		for (var i = 0; i < beats.size(); i++) {
			var v = beats[i];
			me.mBeats++;
			if (me.mPrev != null) {
				var d = v - me.mPrev;
				me.mLastDiff = d;
				me.mFit.set(:hrvSuccessive, d);
				var dd = d * d;
				me.mSquareDiffs += dd;
				me.mPairs++;
				me.mWinSquareDiffs += dd;
				me.mWinPairs++;
				var ad = d.abs();
				if (ad > 20) {
					me.mOver20++;
				}
				if (ad > 50) {
					me.mOver50++;
				}
			}
			me.mPrev = v;
			if (me.detailed) {
				me.mFit.set(:beat2beat, v);
				me.mFit.set(:hrFromBeat, 60000.0 / v);
			}
		}
	}

	function windowValue() {
		if (!me.detailed) {
			return me.mLastDiff;
		}
		var value = me.mWinPairs > 0 ? Math.sqrt(me.mWinSquareDiffs / me.mWinPairs) : null;
		me.mFit.set(:rmssdRolling, value);
		return value;
	}

	function flushWindow() {
		Metric.flushWindow();
		me.mWinSquareDiffs = 0.0;
		me.mWinPairs = 0;
	}

	// session numbers and fit session fields; then only the light object stays for the rollup
	function flush() {
		if (me.mFit == null) {
			return me;
		}
		Metric.flush();
		me.rmssd = me.mPairs > 0 ? Math.sqrt(me.mSquareDiffs / me.mPairs) : null;
		me.mFit.set(:rmssd, me.rmssd);
		if (me.detailed) {
			// task force 1996: nn50 / total nn intervals, not pairs
			me.pnn20 = me.mBeats > 0 ? (me.mOver20 * 100.0) / me.mBeats : null;
			me.pnn50 = me.mBeats > 0 ? (me.mOver50 * 100.0) / me.mBeats : null;
			me.sdrrLast = me.mSdrr.calculate();
			if (me.mSeconds < SdrrSeconds) {
				// shorter than the window; both are the whole session
				me.sdrrFirst = me.sdrrLast;
			}
			me.mFit.set(:pnn20, me.pnn20);
			me.mFit.set(:pnn50, me.pnn50);
			me.mFit.set(:sdrrFirst, me.sdrrFirst);
			me.mFit.set(:sdrrLast, me.sdrrLast);
		}
		me.mFit = null;
		me.mBuffer = null;
		me.mSdrr = null;
		return me;
	}
}
