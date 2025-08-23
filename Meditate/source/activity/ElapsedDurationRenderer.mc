using Toybox.Graphics as Gfx;
using Toybox.Lang;

class ElapsedDurationRenderer {
	function initialize(color, radius, width) {
		me.mColor = color;
		me.mArcRadius = radius;
		me.mArcWidth = width;
		me.mX = null;
		me.mY = null;
		me.mDcWidth = null;
		me.mDcHeight = null;
	}

	private var mColor;
	private var mArcRadius;
	private var mArcWidth;
	private var mX, mY;
	private var mDcWidth, mDcHeight;
	private const StartDegree = 90;

	function drawOverallElapsedTime(dc, overallElapsedTime, alarmTime) {
		var progressPercentage;
		if (overallElapsedTime >= alarmTime) {
			progressPercentage = 100;
		} else {
			progressPercentage = 100 * (overallElapsedTime / alarmTime.toFloat());
			if (progressPercentage == 0) {
				progressPercentage = 0.05;
			}
		}
		me.drawDuration(dc, progressPercentage);
	}

	private function layoutDuration(dc) {
		var mDcWidth = dc.getWidth();
		var mDcHeight = dc.getHeight();
		me.mX = mDcWidth / 2;
		me.mY = mDcHeight / 2;
		var minDim = mDcWidth < mDcHeight ? mDcWidth : mDcHeight;
		if (me.mArcWidth == null) {
			me.mArcWidth = Math.floor(minDim / 32.0).toNumber();
		}
		if (me.mArcRadius == null) {
			me.mArcRadius = minDim / 2;
		}
		me.mArcRadius -= Math.ceil(me.mArcWidth / 2);
		me.mArcWidth -= 1; // Make sure the arc fits within the bounds
		me.mArcRadius = me.mArcRadius.toNumber();
	}

	private function drawDuration(dc, progressPercentage) {
		if (me.mX == null || me.mY == null || me.mArcWidth == null) {
			me.layoutDuration(dc);
		}
		dc.setColor(me.mColor, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(me.mArcWidth);
		var endDegree = me.StartDegree + percentageToArcDegree(progressPercentage);
		dc.drawArc(me.mX, me.mY, me.mArcRadius, Gfx.ARC_CLOCKWISE, me.StartDegree, endDegree);
	}

	private static function percentageToArcDegree(percentage) {
		return -percentage * 3.6;
	}
}
