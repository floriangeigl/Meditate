using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Math;

class IntervalAlertsRenderer {
	function initialize(dc, sessionTime, intervalAlerts) {
		me.mSessionTime = sessionTime;
		me.mIntervalAlerts = intervalAlerts == null ? [] : intervalAlerts;
		var mDcWidth = dc.getWidth();
		var mDcHeight = dc.getHeight();
		me.xCenter = mDcWidth / 2;
		me.yCenter = mDcHeight / 2;
		var minDim = mDcWidth < mDcHeight ? mDcWidth : mDcHeight;
		me.mWidth = IntervalAlertsRenderer.penWidth(minDim);
		me.mRadius = (minDim / 2 - IntervalAlertsRenderer.inset(me.mWidth)).toNumber();
		me.mPercentageTimes = me.createPercentageTimes(mIntervalAlerts);
	}

	// one less than minDim/20 so the arc fits within the bounds
	private static function penWidth(minDim) {
		return Math.floor(minDim / 20.0).toNumber() - 1;
	}

	private static function inset(width) {
		return Math.ceil(width / 2) + 1;
	}

	// how far in from the ring's outer bound the ticks reach; the widest band of the session ring
	static function bandDepth(minDim) {
		var width = IntervalAlertsRenderer.penWidth(minDim);
		return (IntervalAlertsRenderer.inset(width) + Math.ceil(width / 2.0)).toNumber();
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

	// same ring, arbitrary tick positions; used for breath program step boundaries
	function drawTicksAt(dc, percentages, color) {
		if (percentages == null) {
			return;
		}
		dc.setPenWidth(me.mWidth);
		for (var i = 0; i < percentages.size(); i++) {
			me.drawIntervalAlert(dc, percentages[i], color);
		}
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
