module HrvAlgorithms {
	class HrvRmssdRolling extends Rolling {
		private static const DataFieldId = 13;
		private var dataField;

		function initialize(activitySession, rollingIntervalSeconds) {
			Rolling.initialize(rollingIntervalSeconds);
			me.dataField = createDataField(activitySession);
		}

		private function createDataField(activitySession) {
			return activitySession.createField("hrv_rmssd_rolling", me.DataFieldId, FitContributor.DATA_TYPE_FLOAT, {
				:mesgType => FitContributor.MESG_TYPE_RECORD,
				:units => "ms",
			});
		}

		function aggregate(value) {
			if (value != null && me.previousValue != null) {
				me.count++;
				me.aggregatedValue += Math.pow(value - me.previousValue, 2);
			}
		}

		function calculate() {
			var result = null;
			if (
				me.secondsCount >= me.rollingIntervalSeconds ||
				(me.isFinalized && (me.secondsCount >= me.rollingIntervalSeconds * 0.9 || me.data.size() == 0))
			) {
				if (me.count > 0) {
					result = Math.sqrt(me.aggregatedValue / me.count.toFloat());
				}
				me.data.add(result);
				if (result != null) {
					me.dataField.setData(result);
				}

				me.reset();
			}
			return result;
		}
	}
}
