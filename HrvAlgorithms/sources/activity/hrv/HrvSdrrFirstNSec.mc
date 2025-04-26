using Toybox.FitContributor;

module HrvAlgorithms {
	class HrvSdrrFirstNSec extends WindowAvg {
		protected var DataFieldId = 9;
		protected var dataField;

		function initialize(activitySession, maxIntervalsCount) {
			WindowAvg.initialize(maxIntervalsCount, true);
			me.dataField = me.createDataField(activitySession, "hrv_sdrr_first5min");
		}

		protected function createDataField(activitySession, name) {
			return activitySession.createField(name, me.DataFieldId, FitContributor.DATA_TYPE_FLOAT, {
				:mesgType => FitContributor.MESG_TYPE_SESSION,
				:units => "ms",
			});
		}

		function calculate() {
			var avg = WindowAvg.calculate();
			var sdrr = null;
			if (avg == null) {
				return null;
			}
			var sumSquaredDeviations = 0.0;
			for (var i = 0; i < me.count; i++) {
				sumSquaredDeviations += Math.pow(me.data[i] - avg, 2);
			}
			sdrr = Math.sqrt(sumSquaredDeviations / me.count.toFloat());
			if (sdrr != null) {
				me.dataField.setData(sdrr);
			}
			return sdrr;
		}
	}
}
