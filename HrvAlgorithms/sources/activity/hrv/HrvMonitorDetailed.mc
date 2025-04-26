using Toybox.FitContributor;
using Toybox.Math;
using Toybox.Application as App;

module HrvAlgorithms {
	class HrvMonitorDetailed extends HrvMonitorDefault {
		private static const HrvRmssdWindowSize = 60;
		private static const Buffer5MinLength = 300;

		private var mHrvSdrrFirst5Min;
		private var mHrvSdrrLast5Min;
		private var mHrvRmssdRolling;
		private var mHrvPnn50;
		private var mHrvPnn20;

		private var mHrvBeatToBeatIntervalsDataField;
		private var mHrFromHeartbeatDataField;

		private static const HrvBeatToBeatIntervalsFieldId = 8;
		private static const HrFromHeartbeatField = 16;

		function initialize(activitySession) {
			HrvMonitorDefault.initialize(activitySession);

			me.mHrvBeatToBeatIntervalsDataField =
				HrvMonitorDetailed.createHrvBeatToBeatIntervalsDataField(activitySession);

			me.mHrFromHeartbeatDataField = HrvMonitorDetailed.createHrFromHeartbeatDataField(activitySession);
			me.mHrvSdrrFirst5Min = new HrvSdrrFirstNSec(activitySession, Buffer5MinLength);
			me.mHrvSdrrLast5Min = new HrvSdrrLastNSec(activitySession, Buffer5MinLength);

			me.mHrvPnn50 = new HrvPnnx(activitySession, 50, 11);
			me.mHrvPnn20 = new HrvPnnx(activitySession, 20, 12);
			me.mHrvRmssdRolling = new HrvRmssdRolling(activitySession, HrvRmssdWindowSize);
		}

		private static function createHrvBeatToBeatIntervalsDataField(activitySession) {
			return activitySession.createField(
				"hrv_beat2beat_int",
				HrvMonitorDetailed.HrvBeatToBeatIntervalsFieldId,
				FitContributor.DATA_TYPE_UINT16,
				{ :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "ms" }
			);
		}

		private static function createHrFromHeartbeatDataField(activitySession) {
			return activitySession.createField(
				"hrv_hr",
				HrvMonitorDetailed.HrFromHeartbeatField,
				FitContributor.DATA_TYPE_UINT16,
				{ :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "bpm" }
			);
		}

		function addOneSecBeatToBeatIntervals(beatToBeatIntervals) {
			HrvMonitorDefault.addOneSecBeatToBeatIntervals(beatToBeatIntervals);
			me.mHrvRmssdRolling.addOneSec(beatToBeatIntervals);
		}

		protected function addBeatToBeatInterval(beatToBeatInterval) {
			HrvMonitorDefault.addBeatToBeatInterval(beatToBeatInterval);
			if (beatToBeatInterval != null && beatToBeatInterval > 0) {
				me.mHrvBeatToBeatIntervalsDataField.setData(beatToBeatInterval.toNumber());
				var hrFromHeartbeat = Math.round(60000 / beatToBeatInterval.toFloat()).toNumber();
				me.mHrFromHeartbeatDataField.setData(hrFromHeartbeat);
			}

			me.mHrvSdrrFirst5Min.addData(beatToBeatInterval);
			me.mHrvSdrrLast5Min.addData(beatToBeatInterval);

			me.mHrvPnn50.addBeatToBeatInterval(beatToBeatInterval);
			me.mHrvPnn20.addBeatToBeatInterval(beatToBeatInterval);
		}

		public function getHrv() {
			HrvMonitorDefault.getHrv();
			return mHrvRmssdRolling.getLastCalcValue();
		}

		public function calculateHrvSummary() {
			var hrvSummary = HrvMonitorDefault.calculateHrvSummary();
			hrvSummary.pnn50 = me.mHrvPnn50.calculate();
			hrvSummary.pnn20 = me.mHrvPnn20.calculate();
			hrvSummary.first5MinSdrr = me.mHrvSdrrFirst5Min.calculate();
			hrvSummary.last5MinSdrr = me.mHrvSdrrLast5Min.calculate();
			hrvSummary.rmssdHistory = me.mHrvRmssdRolling.getHistory();
			return hrvSummary;
		}

		static function getLoadTime() {
			return HrvMonitorDetailed.HrvRmssdWindowSize;
		}
	}
}
