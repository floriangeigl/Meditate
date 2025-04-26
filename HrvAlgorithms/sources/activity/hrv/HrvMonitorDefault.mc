using Toybox.FitContributor;
using Toybox.Math;
using Toybox.Application as App;

module HrvAlgorithms {
	class HrvMonitorDefault {
		private var mHrvRmssd;
		private var mHrvSuccessive;

		function initialize(activitySession) {
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

		public function getHrv() {
			return me.mHrvSuccessive.calculate();
		}

		public function calculateHrvSummary() {
			var hrvSummary = new HrvSummary();
			hrvSummary.rmssd = me.mHrvRmssd.calculate();
			return hrvSummary;
		}

		static function getLoadTime() {
			return 1;
		}
	}
}
