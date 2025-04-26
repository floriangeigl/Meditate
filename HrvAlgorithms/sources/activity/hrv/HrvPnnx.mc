using Toybox.FitContributor;

module HrvAlgorithms {
	class HrvPnnx {
		private var mPreviousBeatToBeatInterval;
		private var mTotalIntervalsCount;
		private var mOverThresholdIntervalsCount;
		private var mDifferenceThreshold;
		private var dataFieldId;
		private var dataField;

		function initialize(activitySession, differenceThreshold, dataFieldId) {
			me.mPreviousBeatToBeatInterval = null;
			me.mTotalIntervalsCount = 0;
			me.mOverThresholdIntervalsCount = 0;
			me.mDifferenceThreshold = differenceThreshold;
			me.dataFieldId = dataFieldId;
			me.dataField = createDataField(activitySession);
		}

		private function createDataField(activitySession) {
			return activitySession.createField(
				"hrv_pnn" + me.mDifferenceThreshold.toNumber().toString(),
				me.dataFieldId,
				FitContributor.DATA_TYPE_FLOAT,
				{ :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
			);
		}

		function addBeatToBeatInterval(beatToBeatInterval) {
			me.mTotalIntervalsCount++;
			if (me.mPreviousBeatToBeatInterval != null && beatToBeatInterval != null) {
				var intervalsDifference = (beatToBeatInterval - me.mPreviousBeatToBeatInterval).abs();
				if (intervalsDifference > me.mDifferenceThreshold) {
					me.mOverThresholdIntervalsCount++;
				}
			}
			me.mPreviousBeatToBeatInterval = beatToBeatInterval;
		}

		function calculate() {
			var result = null;
			if (me.mTotalIntervalsCount == 0) {
				return null;
			}
			result = (me.mOverThresholdIntervalsCount.toFloat() / me.mTotalIntervalsCount.toFloat()) * 100.0;
			if (result != null) {
				me.dataField.setData(result);
			}
			return result;
		}
	}
}
