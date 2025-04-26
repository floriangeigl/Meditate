module HrvAlgorithms {
	class HrvSdrrLastNSec extends HrvSdrrFirstNSec {
		protected var DataFieldId = 10;

		function initialize(activitySession, maxIntervalsCount) {
			WindowAvg.initialize(maxIntervalsCount, false);
			me.dataField = me.createDataField(activitySession, "hrv_sdrr_last5min");
		}
	}
}
