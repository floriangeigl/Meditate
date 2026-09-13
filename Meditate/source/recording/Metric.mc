using Toybox.Math;

// one sampling engine for every live metric: fixed tick window, range check, window mean,
// history and summary stats over the window values. subclasses set the config fields after
// Metric.initialize and override read(info); the flushed object itself is the summary entry
class Metric {
	var id;
	var history;
	var min;
	var max;
	var first;
	var last;

	// config, set by subclasses
	protected var window = 1;
	protected var lo = null;
	protected var hi = null;
	protected var skipFirst = false;
	protected var liveBeforeWindow = false;
	protected var keepHistory = true;

	private var mValue;
	private var mRaw;
	private var mWinTicks;
	private var mWinSum;
	private var mWinCount;
	private var mSum;
	private var mCount;

	function initialize(id) {
		me.id = id;
		me.history = [];
		me.min = null;
		me.max = null;
		me.first = null;
		me.last = null;
		me.mValue = null;
		me.mRaw = null;
		me.mWinTicks = 0;
		me.mWinSum = 0.0;
		me.mWinCount = 0;
		me.mSum = 0.0;
		me.mCount = 0;
	}

	// hook: this tick's raw sample
	protected function read(info) {
		return null;
	}

	// hook: range check, window sum and count, remembers the raw
	protected function accept(raw) {
		if (raw != null && ((me.lo != null && raw < me.lo) || (me.hi != null && raw > me.hi))) {
			raw = null;
		}
		me.mRaw = raw;
		if (raw != null) {
			me.mWinSum += raw;
			me.mWinCount++;
		}
	}

	// hook: window mean, null without a valid sample
	protected function windowValue() {
		return me.mWinCount > 0 ? me.mWinSum / me.mWinCount.toFloat() : null;
	}

	// recording tick; null samples count towards the window
	function sample(info) {
		if (me.skipFirst) {
			me.skipFirst = false;
			return;
		}
		me.accept(me.read(info));
		me.mWinTicks++;
		if (me.mWinTicks >= me.window) {
			me.flushWindow();
		}
	}

	protected function flushWindow() {
		var v = me.windowValue();
		if (me.keepHistory) {
			me.history.add(v);
		}
		if (v != null) {
			if (me.first == null) {
				me.first = v;
			}
			me.last = v;
			me.mSum += v;
			me.mCount++;
			if (me.min == null || v < me.min) {
				me.min = v;
			}
			if (me.max == null || v > me.max) {
				me.max = v;
			}
		}
		me.mValue = v;
		me.mWinTicks = 0;
		me.mWinSum = 0.0;
		me.mWinCount = 0;
	}

	// end of recording; a partial window counts only if nearly complete or it is all there is
	function flush() {
		if (me.mWinTicks > 0 && (me.mWinTicks >= me.window * 0.9 || me.history.size() == 0)) {
			me.flushWindow();
		}
		return me;
	}

	function getValue() {
		if (me.mValue == null && me.liveBeforeWindow) {
			return me.mRaw;
		}
		return me.mValue;
	}

	function getAvg() {
		return me.mCount > 0 ? me.mSum / me.mCount : null;
	}

	// true once a window produced a value
	function hasData() {
		return me.mCount > 0;
	}

	function getLoadTime() {
		return me.liveBeforeWindow ? 0 : me.window;
	}
}
