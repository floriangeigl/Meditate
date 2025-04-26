using Toybox.FitContributor;

module HrvAlgorithms {
	class HrvSuccessive {
		function initialize(activitySession) {
			me.mPreviousBeatToBeatInterval = null;
			me.mLastSuccessive = null;
			me.mHrvSuccessiveDataField = me.createDataField(activitySession);
		}

		private var mPreviousBeatToBeatInterval;
		private var mHrvSuccessiveDataField;
		private static const DataFieldId = 6;
		private var mLastSuccessive;

		private function createDataField(activitySession) {
			return activitySession.createField("hrv_successive", me.DataFieldId, FitContributor.DATA_TYPE_FLOAT, {
				:mesgType => FitContributor.MESG_TYPE_RECORD,
				:units => "ms",
			});
		}

		function addBeatToBeatInterval(beatToBeatInterval) {
			if (me.mPreviousBeatToBeatInterval != null && beatToBeatInterval != null) {
				me.mLastSuccessive = beatToBeatInterval - me.mPreviousBeatToBeatInterval;
				if (mLastSuccessive != null) {
					me.mHrvSuccessiveDataField.setData(mLastSuccessive);
				}
			}
			if (beatToBeatInterval != null) {
				me.mPreviousBeatToBeatInterval = beatToBeatInterval;
			}
		}

		function calculate() {
			return mLastSuccessive;
		}
	}
}
