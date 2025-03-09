module HrvAlgorithms {
	class HrvPnnx {
		function initialize(differenceThreshold) {		
			me.mPreviousBeatToBeatInterval = null;
			me.mTotalIntervalsCount = 0;
			me.mOverThresholdIntervalsCount = 0;
			me.mDifferenceThreshold = differenceThreshold;
		}
				
		private var mPreviousBeatToBeatInterval;
		private var mTotalIntervalsCount;
		private var mOverThresholdIntervalsCount;
		private var mDifferenceThreshold;
		
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
			if (me.mTotalIntervalsCount == 0) {
				return null;
			}
			return (me.mOverThresholdIntervalsCount.toFloat() / me.mTotalIntervalsCount.toFloat()) * 100.0;
		}
	}
}
