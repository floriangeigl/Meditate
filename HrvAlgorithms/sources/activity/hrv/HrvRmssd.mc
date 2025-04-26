using Toybox.FitContributor;

module HrvAlgorithms {
	class HrvRmssd {
		function initialize(activitySession) {
			me.mSquareDiffs = 0.0;
			me.mPreviousInterval = null;
			me.mIntervalsCount = 0;
			me.mHrvRmssdDataField = me.createDataField(activitySession);
		}

		private var mSquareDiffs;
		private var mPreviousInterval;
		private var mIntervalsCount;
		private static const DataFieldId = 7;
		private var mHrvRmssdDataField;

		private function createDataField(activitySession) {
			return activitySession.createField("hrv_rmssd", me.DataFieldId, FitContributor.DATA_TYPE_FLOAT, {
				:mesgType => FitContributor.MESG_TYPE_SESSION,
				:units => "ms",
			});
		}

		function addBeatToBeatInterval(beatToBeatInterval) {
			if (me.mPreviousInterval != null && beatToBeatInterval != null) {
				me.mIntervalsCount++;
				me.mSquareDiffs += Math.pow(beatToBeatInterval - me.mPreviousInterval, 2);
			}
			me.mPreviousInterval = beatToBeatInterval;
		}

		function calculate() {
			if (me.mIntervalsCount < 1) {
				return null;
			}
			var rmssd = Math.sqrt(me.mSquareDiffs / me.mIntervalsCount);
			if (rmssd != null) {
				me.mHrvRmssdDataField.setData(rmssd);
			}
			return rmssd;
		}
	}
}
