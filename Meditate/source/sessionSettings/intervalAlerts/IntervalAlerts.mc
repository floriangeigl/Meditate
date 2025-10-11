using Toybox.Graphics as Gfx;

module IntervalAlertType {
	enum {
		OneOff = 1,
		Repeat = 2
	}
}

class IntervalAlerts {
	private var mAlerts;

	function initialize() {
		me.reset();
	}

	function addNew() {
		me.mAlerts.add(new Alert());
		var newAlertIndex = me.mAlerts.size() - 1;
		return newAlertIndex;
	}

	function delete(index) {
		var alert = me.mAlerts[index];
		me.mAlerts.remove(alert);
	}

	function reset() {
		me.mAlerts = [];
	}

	function fromArray(serializedAlerts) {
		if (serializedAlerts != null) {
			me.mAlerts = new [serializedAlerts.size()];
			for (var i = 0; i < serializedAlerts.size(); i++) {
				me.mAlerts[i] = Alert.fromDictionary(serializedAlerts[i]);
			}
		}
	}

	function toArray() {
		var serializedAlerts = new [me.mAlerts.size()];
		for (var i = 0; i < me.mAlerts.size(); i++) {
			serializedAlerts[i] = me.mAlerts[i].toDictionary();
		}
		return serializedAlerts;
	}

	function get(index) {
		return me.mAlerts[index];
	}

	function set(index, alert) {
		me.mAlerts[index] = alert;
	}

	function size() {
		return me.mAlerts.size();
	}
}

class Alert {
	function initialize() {
		me.reset();
	}
	static function fromDictionary(loadedSessionDictionary) {
		var alert = new Alert();
		alert.type = loadedSessionDictionary["type"];
		alert.time = loadedSessionDictionary["time"];
		alert.offset = loadedSessionDictionary["offset"];
		alert.color = loadedSessionDictionary["color"];
		alert.vibePattern = loadedSessionDictionary["vibePattern"];
		return alert;
	}

	function toDictionary() {
		return {
			"type" => me.type,
			"time" => me.time,
			"offset" => me.offset,
			"color" => me.color,
			"vibePattern" => me.vibePattern
		};
	}

	function reset() {
		me.type = IntervalAlertType.Repeat;
		me.time = 60 * 5;
		me.offset = 0;
		me.color = Gfx.COLOR_RED;
		me.vibePattern = VibePattern.Blip;
	}

	function getAlertArcPercentageTimes(sessionTime) {
		return me.getAlertPercentageTimes(sessionTime, ArcMaxRepeatExecutionsCount, ArcMinRepeatPercentageTime);
	}
	private function getAlertPercentageTimes(sessionTime, maxRepeatExecutionsCount, minRepeatPercentageTime) {
		if (sessionTime == null || me.time == null || sessionTime < 1 || me.time < 1) {
			return [];
		}
		var percentageTime = me.time.toDouble() / sessionTime.toDouble();
		var offsetVal = me.offset == null ? 0 : me.offset;
		var percentageOffset = offsetVal.toDouble() / sessionTime.toDouble();
		if (me.type == IntervalAlertType.OneOff) {
			return [percentageOffset + percentageTime];
		} else {
			var executionsCount = (sessionTime - offsetVal) / me.time + 1;
			if (executionsCount > maxRepeatExecutionsCount) {
				executionsCount = maxRepeatExecutionsCount;
			}
			if (percentageTime < minRepeatPercentageTime) {
				percentageTime = minRepeatPercentageTime;
			}
			var result = new [executionsCount];
			for (var i = 0; i < executionsCount; i++) {
				if (offsetVal > 0) {
					result[i] = percentageOffset + percentageTime * i;
				} else {
					result[i] = percentageOffset + percentageTime * (i + 1);
				}
				if (result[i] > 1.0) {
					result[i] = 1.0;
				}
			}
			return result;
		}
	}

	function getAlertProgressBarPercentageTimes(sessionTime) {
		return me.getAlertPercentageTimes(
			sessionTime,
			ProgressBarRepeatExecutionsCount,
			ProgressBarRepeatPercentageTime
		);
	}

	private const ProgressBarRepeatExecutionsCount = 20;
	private const ProgressBarRepeatPercentageTime = 0.05;

	private const ArcMaxRepeatExecutionsCount = 139;
	private const ArcMinRepeatPercentageTime = 0.0072;

	var type;
	var time; // in seconds
	var offset; // in seconds
	var color;
	var vibePattern;
}
