using Toybox.Graphics as Gfx;
using Toybox.Lang;

class IntervalAlertsRenderer {
	function initialize(sessionTime, intervalAlerts, radius, width) {
		me.mSessionTime = sessionTime;
		me.mIntervalAlerts = intervalAlerts;
		me.mRadius = radius;
		me.mWidth = width;
		me.mPercentageTimes = me.createPercentageTimes(mIntervalAlerts);
	}

	private var mSessionTime;
	private var mIntervalAlerts;
	private var mRadius;
	private var mWidth;
	private var mPercentageTimes;
	private var width, height, xCenter, yCenter;

	function drawAllIntervalAlerts(dc) {
		dc.setPenWidth(me.mWidth);
		me.drawIntervalAlerts(dc, me.mIntervalAlerts, me.mPercentageTimes);
	}

	private function createPercentageTimes(intervalAlerts) {
		if (intervalAlerts.size() == 0) {
			return [];
		}
		var resultPercentageTimes = new [intervalAlerts.size()];
		for (var i = 0; i < intervalAlerts.size(); i++) {
			var intervalAlert = intervalAlerts.get(i);
			resultPercentageTimes[i] = intervalAlert.getAlertArcPercentageTimes(me.mSessionTime);
		}
		return resultPercentageTimes;
	}

	function layoutIntervalAlerts(dc) {
		me.height = dc.getHeight();
		me.width = dc.getWidth();
		me.xCenter = me.width / 2;
		me.yCenter = me.height / 2;
	}

	private function drawIntervalAlerts(dc, intervalAlerts, percentageTimes) {
		for (var i = 0; i < intervalAlerts.size(); i++) {
			for (var pIndex = 0; pIndex < percentageTimes[i].size(); pIndex++) {
				me.drawIntervalAlert(dc, percentageTimes[i][pIndex], intervalAlerts.get(i).color);
			}
		}
	}

	private function getAlertProgressPercentage(percentageTime) {
		var progressPercentage = percentageTime * 100;
		if (progressPercentage > 100) {
			progressPercentage = 100;
		} else {
			if (progressPercentage == 0) {
				progressPercentage = 0.05;
			}
		}
		return progressPercentage;
	}

	private function drawIntervalAlert(dc, intervalAlertTime, color) {
		var progressPercentage = me.getAlertProgressPercentage(intervalAlertTime);
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
		var startDegree = percentageToArcDegree(progressPercentage);
		dc.drawArc(me.xCenter, me.yCenter, me.mRadius, Gfx.ARC_CLOCKWISE, startDegree, startDegree - 1.2);
	}

	private static function percentageToArcDegree(percentage) {
		return 90 - percentage * 3.6;
	}
}
