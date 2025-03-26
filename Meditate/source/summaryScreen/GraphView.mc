using Toybox.Math;
using Toybox.System;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity as Activity;
using Toybox.SensorHistory as SensorHistory;
using Toybox.ActivityMonitor as ActivityMonitor;

class GraphView extends ScreenPicker.ScreenPickerBaseView {
	var positionX, positionY;
	var chartToLabelOffset;
	var graphWidth, graphHeight;
	var centerX, centerY;
	var shiftRight, smallXSpace, smallYSpace;
	var data;
	var min, max, avg;
	var elapsedTime;
	var title;
	var minCut, maxCut;

	function initialize(data, elapsedTime, title, minCut, maxCut) {
		me.minCut = minCut;
		me.maxCut = maxCut;
		me.data = data;
		me.avg = null;
		me.min = null;
		me.max = null;
		var val = null;
		var total = 0;
		var count = 0;

		if (me.data != null) {
			for (var i = 0; i < me.data.size(); i++) {
				val = me.data[i];
				if (val != null) {
					if (me.min == null || val < me.min) {
						me.min = val;
					}
					if (me.max == null || val > me.max) {
						me.max = val;
					}
					total += val;
					count++;
				}
			}
		}
		if (count > 0) {
			me.avg = total / count;
		}

		me.elapsedTime = elapsedTime;
		me.title = title;
		ScreenPickerBaseView.initialize(true);
	}

	static function formatNumber(number) {
		if (number == null) {
			return " --";
		} else {
			return Math.round(number).format("%3.0f");
		}
	}

	function onLayout(dc) {
		ScreenPickerBaseView.onLayout(dc);

		// Calculate center of the screen
		me.centerX = dc.getWidth() / 2;
		me.centerY = dc.getHeight() / 2;
		me.smallXSpace = dc.getWidth() * 0.05;
		me.smallYSpace = dc.getWidth() * 0.05;

		// Calculate position of the chart
		me.graphHeight = Math.round(dc.getHeight() * 0.33);
		me.graphWidth = Math.round(dc.getWidth() * 0.75);
		me.shiftRight = me.graphWidth * 0.05;
		me.positionX = me.centerX - me.graphWidth / 2 + me.shiftRight;
		me.positionY = me.centerY + me.graphHeight / 2;
		// calculate offset of y-ticks to chart
		me.chartToLabelOffset = Math.ceil(me.graphWidth * 0.01);
	}

	// Update the view
	function onUpdate(dc) {
		// onUpdate is called multiple times - see garmin forums
		// https://forums.garmin.com/developer/connect-iq/f/discussion/298992/onupdate-is-called-twice
		// https://forums.garmin.com/developer/connect-iq/f/discussion/8025/oddities-observed-in-log-on-device-regarding-calls-to-onupdate-and-draw
		// https://forums.garmin.com/developer/connect-iq/f/discussion/258945/watchui-requestupdate-twice
		// on some devices, the screen stays black, if we don't let that happen.
		// performance improved solution would be to do all the calc in onLayout.
		// maybe fix this at some point

		ScreenPickerBaseView.onUpdate(dc);

		// Draw title text
		me.drawTitle(dc, Ui.loadResource(me.title), null);

		// Draw MIN text
		dc.drawText(
			me.positionX + me.smallXSpace,
			centerY - graphHeight / 2 - me.smallYSpace,
			Gfx.FONT_SYSTEM_TINY,
			Ui.loadResource(Rez.Strings.SummaryMin) + me.formatNumber(me.min),
			Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
		);

		// Draw AVG text
		dc.drawText(
			centerX,
			me.positionY + me.smallYSpace,
			Gfx.FONT_SYSTEM_TINY,
			Ui.loadResource(Rez.Strings.SummaryAvg) + me.formatNumber(me.avg),
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);

		// Draw MAX text
		dc.drawText(
			me.positionX + graphWidth / 2 + me.smallXSpace,
			centerY - graphHeight / 2 - me.smallYSpace,
			Gfx.FONT_SYSTEM_TINY,
			Ui.loadResource(Rez.Strings.SummaryMax) + me.formatNumber(me.max),
			Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
		);

		// Draw Time text
		dc.drawText(
			centerX,
			centerY + centerY / 1.5 + 13,
			Gfx.FONT_SYSTEM_TINY,
			TimeFormatter.format(me.elapsedTime),
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);

		// Draw data if available
		var minMaxDiff = null;
		var yMin = null;
		var yMax = null;
		if (me.data != null && me.data.size() > 1 && me.min != null && me.max != null) {
			// Calculate different between min and max
			minMaxDiff = me.max - me.min;

			// allow for some space between data and chart min/max
			var minCutSet = me.minCut != null;
			var maxCutSet = me.maxCut != null;
			var yOffset = Math.ceil(minMaxDiff * 0.1);
			yMin = Math.floor(me.min - yOffset);
			yMax = Math.ceil(me.max + yOffset);

			// if y-cuts set, make sure graph stays within set range
			if (minCutSet && yMin < me.minCut) {
				yMin = me.minCut;
			}
			if (maxCutSet && yMin > me.maxCut) {
				yMin = me.maxCut;
			}

			if (maxCutSet && yMax > me.maxCut) {
				yMax = me.maxCut;
			}
			if (minCutSet && yMax < me.minCut) {
				yMax = me.minCut;
			}

			// update min max diff and make sure > 0
			minMaxDiff = yMax - yMin;
			if (minMaxDiff < 1) {
				var tmpOffset = Math.ceil(yMax * 0.1);
				if (maxCutSet && yMax + tmpOffset < me.maxCut) {
					yMax += tmpOffset;
				}
				if (minCutSet && yMin - tmpOffset > me.minCut) {
					yMin -= tmpOffset;
				}
				if (yMax - yMin < 1) {
					yMin -= tmpOffset;
					yMax += tmpOffset;
				}
				minMaxDiff = yMax - yMin;
			}

			// Chart as light blue
			dc.setPenWidth(1);
			dc.setColor(0x27a0c4, Graphics.COLOR_TRANSPARENT);

			// Try adapting the data for the graph width
			var bucketSize = Math.ceil(me.data.size() / me.graphWidth.toFloat()).toNumber();
			var nBuckets = Math.ceil(me.data.size() / bucketSize.toFloat());
			var step = nBuckets / me.graphWidth.toFloat();

			// Draw chart
			var lineHeight = null;
			var val = null;
			var heightFact = me.graphHeight.toFloat() / minMaxDiff;
			var xPos = me.positionX + 1 + chartToLabelOffset; // leave some space to labels
			var bucketVal = 0;
			var bucketCount = 0;
			var nextStep = 1;
			var currentStep = 0.0;
			for (var i = 0; i < me.data.size(); i++) {
				val = me.data[i];
				if (val != null) {
					bucketVal += val;
					bucketCount++;
				}
				// draw buckets: skip first, draw last, else every full bucket
				if ((i > 0 || bucketSize == 1) && (i + 1 == me.data.size() || i % bucketSize == 0)) {
					// draw bucket,
					if (bucketCount > 0) {
						// calc average of bucket
						val = bucketVal / bucketCount;

						// cut data if exceeds limits
						if (minCutSet && me.minCut > val) {
							val = me.minCut;
						}
						if (maxCutSet && me.maxCut < val) {
							val = me.maxCut;
						}
						lineHeight = Math.round((val - yMin) * heightFact).toNumber();
					} else {
						val = null;
					}
					while (currentStep < nextStep) {
						if (val != null) {
							dc.drawLine(xPos, me.positionY - lineHeight, xPos, me.positionY);
						}
						xPos++;
						currentStep += step;
					}
					nextStep++;
					// reset bucket
					bucketVal = 0;
					bucketCount = 0;
				}
			}
		}
		// Draw lines and labels
		dc.setPenWidth(1);
		dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
		if (minMaxDiff == null) {
			minMaxDiff = 100;
			yMin = 0;
		}
		var numLines = minMaxDiff;
		// max 4 lines
		if (numLines > 4) {
			numLines = 4;
		}
		var lineSpacing = Math.floor(me.graphHeight / numLines.toFloat());

		for (var i = 0; i <= numLines; i++) {
			// Draw lines over chart
			dc.drawLine(
				me.positionX + me.chartToLabelOffset,
				me.positionY - lineSpacing * i,
				me.positionX + me.chartToLabelOffset + me.graphWidth,
				me.positionY - lineSpacing * i
			);

			// Draw labels for the lines except last one
			dc.drawText(
				me.positionX,
				me.positionY - lineSpacing * i,
				Gfx.FONT_SYSTEM_XTINY,
				Math.round(yMin + (minMaxDiff / numLines) * i)
					.toNumber()
					.toString(),
				Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
			);
		}
	}
}
