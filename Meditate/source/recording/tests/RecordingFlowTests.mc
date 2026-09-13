using Toybox.Test;
using Toybox.Application as App;

// stands in for MeditateActivity as the recorder listener and for MeditateDelegate as the auto-stop target
(:test)
class FlowListener {
	var ticks = 0;

	function onTick() {
		me.ticks++;
	}

	function onSessionAutoComplete() {}
}

// runs the recording core against a real simulator fit session, no timer and no ui
(:test)
class RecordingFlowTests {
	private static function near(actual, expected) {
		return actual != null && (actual - expected).abs() < 0.001;
	}

	// at most one open session: the app booted by the test runner holds the wakeup session
	private static function closeAppWakeupSession() {
		App.getApp().beatIntervalFeed.discardWakeupSession();
	}

	(:test)
	static function recorderSamplesOnTheTickAndSummarises(logger) {
		closeAppWakeupSession();
		var listener = new FlowListener();
		var recorder = new ActivityRecorder(FitSessionSpec.createTraining("test"), listener);
		var hr = new ScriptedMetric([60, 70, 80, 90], 2).configure(null, null, false, true, true);
		hr.id = :hr;
		var metrics = [hr];
		if (StressMetric.isSupported()) {
			metrics.add(new StressMetric());
		}
		if (RrMetric.isSupported()) {
			metrics.add(new RrMetric());
		}
		recorder.setMetrics(metrics);
		// a repeated or unknown id creates nothing and does not throw
		recorder.fit.create([:minHr, :noSuchField]);
		recorder.start();
		if (!recorder.isRecording()) {
			return false;
		}
		for (var i = 0; i < 4; i++) {
			recorder.onTick();
		}
		var summary = recorder.summary("flow");
		recorder.stop();
		recorder.discard();
		return (
			listener.ticks == 4 &&
			recorder.isRecording() == false &&
			summary.elapsedTime != null &&
			summary.sessionName.equals("flow") &&
			summary.metrics[:hr] == hr &&
			summary.metrics.size() == metrics.size() &&
			hr.history.size() == 2 &&
			near(hr.min, 65) &&
			near(hr.max, 85)
		);
	}

	(:test)
	static function activityRecordsPausesAndSummarises(logger) {
		closeAppWakeupSession();
		var session = new SessionModel();
		session.time = 60;
		session.color = 0xff0000;
		session.name = "flow";
		session.vibePattern = VibePattern.NoNotification;
		session.setHrvTracking(HrvTracking.OnDetailed);
		var model = new MeditateModel(session);
		var feed = new BeatIntervalFeed();
		var activity = new MeditateActivity(model, feed, new FlowListener());
		// hr leads the metrics page, hrv follows, the rest depends on the device
		if (model.liveMetrics[0].id != :hr || model.liveMetrics[1].id != :hrv) {
			return false;
		}
		if (model.getMetric(:hrv).getLoadTime() != GlobalSettings.loadHrvWindowTime()) {
			return false;
		}
		activity.start();
		if (!model.isTimerRunning) {
			return false;
		}
		model.getMetric(:hrv).onIntervals([1000, 1020, 990]);
		model.getMetric(:hrv).sample(null);
		activity.onTick();
		if (activity.pauseResume() != false || activity.pauseResume() != true) {
			return false;
		}
		activity.stop();
		var summary = activity.getSummary();
		activity.discard();
		var hrv = summary.metrics[:hrv];
		// diffs 20 and -30: rmssd sqrt of 650
		if (hrv == null || !hrv.detailed || !near(hrv.rmssd, 25.4951)) {
			return false;
		}
		// every summary page builds a view
		var delegate = new SummaryViewDelegate(summary, null);
		for (var i = 0; i < 8; i++) {
			delegate.setPageIndex(i);
			if (delegate.createScreenPickerView() == null) {
				return false;
			}
		}
		return summary.metrics[:hr] != null && summary.sessionName.equals("flow");
	}

	// hrv off: no hrv metric, no feed wiring, summary without an hrv entry
	(:test)
	static function activityWithHrvOffLeavesTheFeedAlone(logger) {
		closeAppWakeupSession();
		var session = new SessionModel();
		session.time = 60;
		session.setHrvTracking(HrvTracking.Off);
		var model = new MeditateModel(session);
		var feed = new BeatIntervalFeed();
		var capture = new IntervalsCapture();
		feed.setListener(capture.method(:onIntervals));
		var activity = new MeditateActivity(model, feed, new FlowListener());
		if (model.getMetric(:hrv) != null || model.liveMetrics[0].id != :hr) {
			return false;
		}
		activity.start();
		activity.stop();
		var summary = activity.getSummary();
		activity.discard();
		// the picker listener is still in place
		feed.update(new FakeSensorData([1000]));
		return summary.metrics[:hrv] == null && summary.metrics[:hr] != null && capture.calls == 1;
	}
}
