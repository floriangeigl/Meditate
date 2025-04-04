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
		private var mHrvSdrrFirst5MinDataField;
		private var mHrvSdrrLast5MinDataField;
		private var mHrvRmssdRollingDataField;
		private var mHrvPnn50DataField;
		private var mHrvPnn20DataField;
		private var mHrFromHeartbeatDataField;

		private var mHrvRmssdRollingDataFieldLastVal;

		private static const HrvBeatToBeatIntervalsFieldId = 8;
		private static const HrvSdrrFieldId = 1;
		private static const HrvSdrrFirst5MinFieldId = 9;
		private static const HrvSdrrLast5MinFieldId = 10;
		private static const HrvPnn50FieldId = 11;
		private static const HrvPnn20FieldId = 12;
		private static const HrvRmssdRollingFieldId = 13;
		private static const HrFromHeartbeatField = 16;

		function initialize(activitySession, isSessionTimeLongerThan5min) {
			HrvMonitorDefault.initialize(activitySession);

			me.mHrvBeatToBeatIntervalsDataField =
				HrvMonitorDetailed.createHrvBeatToBeatIntervalsDataField(activitySession);
			me.mHrvSdrrFirst5MinDataField = HrvMonitorDetailed.createHrvSdrrFirst5MinDataField(
				activitySession,
				isSessionTimeLongerThan5min
			);
			me.mHrvSdrrLast5MinDataField = HrvMonitorDetailed.createHrvSdrrLast5MinDataField(activitySession);
			me.mHrFromHeartbeatDataField = HrvMonitorDetailed.createHrFromHeartbeatDataField(activitySession);
			me.mHrvRmssdRollingDataField = HrvMonitorDetailed.createHrvRmssdRollingDataField(activitySession);
			me.mHrvPnn50DataField = HrvMonitorDetailed.createHrvPnn50DataField(activitySession);
			me.mHrvPnn20DataField = HrvMonitorDetailed.createHrvPnn20DataField(activitySession);
			me.mHrvSdrrFirst5Min = new HrvSdrrFirstNSec(Buffer5MinLength);
			me.mHrvSdrrLast5Min = new HrvSdrrLastNSec(Buffer5MinLength);

			me.mHrvPnn50 = new HrvPnnx(50);
			me.mHrvPnn20 = new HrvPnnx(20);
			me.mHrvRmssdRolling = new HrvRmssdRolling(HrvRmssdWindowSize);
			me.mHrvRmssdRollingDataFieldLastVal = null;
		}

		private static function createHrvSdrrFirst5MinDataField(activitySession, isSessionTimeLongerThan5min) {
			var fieldId;
			if (isSessionTimeLongerThan5min) {
				fieldId = HrvMonitorDetailed.HrvSdrrFirst5MinFieldId;
			} else {
				fieldId = HrvMonitorDetailed.HrvSdrrFieldId;
			}
			return activitySession.createField("hrv_sdrr_first5min", fieldId, FitContributor.DATA_TYPE_FLOAT, {
				:mesgType => FitContributor.MESG_TYPE_SESSION,
				:units => "ms",
			});
		}

		private static function createHrvSdrrLast5MinDataField(activitySession) {
			return activitySession.createField(
				"hrv_sdrr_last5min",
				HrvMonitorDetailed.HrvSdrrLast5MinFieldId,
				FitContributor.DATA_TYPE_FLOAT,
				{ :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "ms" }
			);
		}

		private static function createHrvBeatToBeatIntervalsDataField(activitySession) {
			return activitySession.createField(
				"hrv_beat2beat_int",
				HrvMonitorDetailed.HrvBeatToBeatIntervalsFieldId,
				FitContributor.DATA_TYPE_UINT16,
				{ :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "ms" }
			);
		}

		private static function createHrvRmssdRollingDataField(activitySession) {
			return activitySession.createField(
				"hrv_rmssd_rolling",
				HrvMonitorDetailed.HrvRmssdRollingFieldId,
				FitContributor.DATA_TYPE_FLOAT,
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

		private static function createHrvPnn50DataField(activitySession) {
			return activitySession.createField(
				"hrv_pnn50",
				HrvMonitorDetailed.HrvPnn50FieldId,
				FitContributor.DATA_TYPE_FLOAT,
				{ :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
			);
		}

		private static function createHrvPnn20DataField(activitySession) {
			return activitySession.createField(
				"hrv_pnn20",
				HrvMonitorDetailed.HrvPnn20FieldId,
				FitContributor.DATA_TYPE_FLOAT,
				{ :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
			);
		}

		function addOneSecBeatToBeatIntervals(beatToBeatIntervals) {
			HrvMonitorDefault.addOneSecBeatToBeatIntervals(beatToBeatIntervals);
			var rmssdRolling = me.mHrvRmssdRolling.addOneSec(beatToBeatIntervals);
			if (rmssdRolling != null && mHrvRmssdRollingDataFieldLastVal != rmssdRolling) {
				me.mHrvRmssdRollingDataField.setData(rmssdRolling);
			}
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
			return mHrvRmssdRolling.getLastCalcValue();
		}

		public function calculateHrvSummary() {
			var hrvSummary = HrvMonitorDefault.calculateHrvSummary();

			hrvSummary.pnn50 = me.mHrvPnn50.calculate();
			if (hrvSummary.pnn50 != null) {
				me.mHrvPnn50DataField.setData(hrvSummary.pnn50);
			}
			hrvSummary.pnn20 = me.mHrvPnn20.calculate();
			if (hrvSummary.pnn20 != null) {
				me.mHrvPnn20DataField.setData(hrvSummary.pnn20);
			}
			hrvSummary.first5MinSdrr = me.mHrvSdrrFirst5Min.calculate();
			if (hrvSummary.first5MinSdrr != null) {
				me.mHrvSdrrFirst5MinDataField.setData(hrvSummary.first5MinSdrr);
			}
			hrvSummary.last5MinSdrr = me.mHrvSdrrLast5Min.calculate();
			if (hrvSummary.last5MinSdrr != null) {
				me.mHrvSdrrLast5MinDataField.setData(hrvSummary.last5MinSdrr);
			}
			hrvSummary.rmssdHistory = me.mHrvRmssdRolling.getHistory();
			return hrvSummary;
		}

		static function getLoadTime() {
			return HrvMonitorDetailed.HrvRmssdWindowSize;
		}
	}
}
