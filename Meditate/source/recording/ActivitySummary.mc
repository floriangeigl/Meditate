// what a finished recording leaves behind; metrics maps id to its flushed Metric
class ActivitySummary {
	var elapsedTime;
	var sessionName;
	var metrics;

	function initialize(elapsedTime, sessionName) {
		me.elapsedTime = elapsedTime;
		me.sessionName = sessionName;
		me.metrics = {};
	}
}
