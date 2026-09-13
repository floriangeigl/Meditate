using Toybox.Timer;
using Toybox.ActivityRecording;
using Toybox.Activity;

// fit session, the 1s tick and the metric list; the listener gets onTick after the metrics sampled
class ActivityRecorder {
	private const TickInterval = 1000;
	private var mFitSession;
	private var mTimer;
	private var mListener;
	private var mMetrics;
	var fit;
	var elapsedTime;

	function initialize(fitSessionSpec, listener) {
		me.mListener = listener;
		me.mFitSession = ActivityRecording.createSession(fitSessionSpec);
		me.fit = new FitFields(me.mFitSession);
		me.fit.create([:minHr]);
		me.mTimer = new Timer.Timer();
		me.mMetrics = [];
		me.elapsedTime = 0;
	}

	function setMetrics(metrics) {
		me.mMetrics = metrics;
	}

	function start() {
		me.mFitSession.start();
		me.mTimer.start(method(:onTick), TickInterval, true);
	}

	function stop() {
		me.mTimer.stop();
		if (me.isRecording()) {
			me.mFitSession.stop();
		}
	}

	// returns true if the session is now running
	function pauseResume() {
		if (me.mFitSession.isRecording()) {
			me.mFitSession.stop();
			me.mTimer.stop();
			return false;
		} else {
			me.mFitSession.start();
			me.mTimer.start(method(:onTick), TickInterval, true);
			return true;
		}
	}

	function isRecording() {
		return me.mFitSession != null && me.mFitSession.isRecording();
	}

	function onTick() {
		if (me.isRecording()) {
			var info = Activity.getActivityInfo();
			if (info.timerTime != null) {
				me.elapsedTime = info.timerTime / 1000;
			}
			for (var i = 0; i < me.mMetrics.size(); i++) {
				me.mMetrics[i].sample(info);
			}
		}
		me.mListener.onTick();
	}

	// call before stop so session fields still land in the fit file
	function summary(sessionName) {
		var info = Activity.getActivityInfo();
		if (info.timerTime != null) {
			me.elapsedTime = info.timerTime / 1000;
		}
		var summary = new ActivitySummary(me.elapsedTime, sessionName);
		for (var i = 0; i < me.mMetrics.size(); i++) {
			var metric = me.mMetrics[i].flush();
			summary.metrics[metric.id] = metric;
		}
		var hr = summary.metrics[:hr];
		if (hr != null) {
			me.fit.set(:minHr, hr.min);
		}
		return summary;
	}

	function finish() {
		if (me.mFitSession != null) {
			me.mFitSession.save();
		}
		me.mFitSession = null;
	}

	function discard() {
		if (me.mFitSession != null) {
			me.mFitSession.discard();
		}
		me.mFitSession = null;
	}

	// transitional: the old hrv monitors create their own fields
	function getFitSession() {
		return me.mFitSession;
	}
}
