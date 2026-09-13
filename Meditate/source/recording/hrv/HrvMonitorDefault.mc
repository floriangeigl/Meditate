using Toybox.FitContributor;
using Toybox.Math;
using Toybox.Application as App;

class HrvMonitorDefault {
	var id;
	private var mHrvRmssd;
	private var mHrvSuccessive;

	function initialize(activitySession) {
		me.id = :hrv;
		me.mHrvRmssd = new HrvRmssd(activitySession);
		me.mHrvSuccessive = new HrvSuccessive(activitySession);
	}

	function addOneSecBeatToBeatIntervals(beatToBeatIntervals) {
		for (var i = 0; i < beatToBeatIntervals.size(); i++) {
			me.addBeatToBeatInterval(beatToBeatIntervals[i]);
		}
	}

	protected function addBeatToBeatInterval(beatToBeatInterval) {
		me.mHrvSuccessive.addBeatToBeatInterval(beatToBeatInterval);
		me.mHrvRmssd.addBeatToBeatInterval(beatToBeatInterval);
	}

	public function getValue() {
		return me.mHrvSuccessive.calculate();
	}

	public function calculateHrvSummary() {
		var hrvSummary = new HrvSummary();
		hrvSummary.rmssd = me.mHrvRmssd.calculate();
		hrvSummary.detailed = false;
		return hrvSummary;
	}

	function getLoadTime() {
		return 1;
	}
}
