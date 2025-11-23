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
	var shiftRight;
	var data;
	var min, max, avg;
	var elapsedTime;
	var title;
	var titleText;
	var minCut, maxCut;
	var minTextE, maxTextE, avgTextE, timeTextE;
	var minMaxDiff;
	var minCutSet, maxCutSet;
	var yMin, yMax;
	var lines;
	var chartLines;
	var chartLinesValues;

	function initialize(data, elapsedTime, title, minCut, maxCut) {
		me.minCut = minCut;
		me.maxCut = maxCut;
		me.data = data;
		me.avg = null;
		me.min = null;
		me.max = null;
		var val = null;
		me.titleText = null;
		me.minTextE = null;
		me.maxTextE = null;
		me.avgTextE = null;
		me.timeTextE = null;
		me.minMaxDiff = null;
		me.minCutSet = null;
		me.maxCutSet = null;
		me.yMin = null;
		me.yMax = null;
		me.lines = null;
		me.chartLines = null;
		me.chartLinesValues = null;

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
		me.yOffsetTitle = Math.ceil(me.height * 0.1);

		// Calculate position of the chart
		me.graphHeight = Math.round(dc.getHeight() * 0.33);
		me.graphWidth = Math.round(dc.getWidth() * 0.75);
		me.shiftRight = me.graphWidth * 0.05;
		me.positionX = me.centerXPos - me.graphWidth / 2 + me.shiftRight;
		me.positionY = me.centerYPos + me.graphHeight / 2;
		// calculate offset of y-ticks to chart
		me.chartToLabelOffset = Math.ceil(me.graphWidth * 0.01);

		// text elements
		me.titleText = Ui.loadResource(me.title);
		me.avgTextE = new TextElement(
			centerXPos,
			centerYPos - graphHeight / 2 - me.spaceYSmall * 5,

			Ui.loadResource(Rez.Strings.SummaryAvg) + me.formatNumber(me.avg),
			Gfx.FONT_SYSTEM_TINY,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
		me.minTextE = new TextElement(
			me.positionX + me.spaceXSmall,
			me.positionY + me.spaceYSmall * 5,
			Ui.loadResource(Rez.Strings.SummaryMin) + me.formatNumber(me.min),
			Gfx.FONT_SYSTEM_TINY,
			Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
		);
		me.maxTextE = new TextElement(
			me.positionX + graphWidth / 2 + me.spaceXSmall,
			me.positionY + me.spaceYSmall * 5,
			Ui.loadResource(Rez.Strings.SummaryMax) + me.formatNumber(me.max),
			Gfx.FONT_SYSTEM_TINY,
			Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
		);

		me.timeTextE = new TextElement(
			centerXPos,
			centerYPos + centerYPos / 1.5 + 13,
			TimeFormatter.format(me.elapsedTime),
			Gfx.FONT_SYSTEM_TINY,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);

		var heightFact = null;

		if (me.data != null && me.data.size() >= 1 && me.min != null && me.max != null) {
			// System.println("Chart " + me.data.size() + " datapoints");
			// Calculate different between min and max
			me.minMaxDiff = me.max - me.min;

			// allow for some space between data and chart min/max
			me.minCutSet = me.minCut != null;
			me.maxCutSet = me.maxCut != null;
			var yOffset = Math.ceil(me.minMaxDiff * 0.1);
			me.yMin = Math.floor(me.min - yOffset);
			me.yMax = Math.ceil(me.max + yOffset);

			// if y-cuts set, make sure graph stays within set range
			if (me.minCutSet && me.yMin < me.minCut) {
				me.yMin = me.minCut;
			}
			if (me.maxCutSet && me.yMin > me.maxCut) {
				me.yMin = me.maxCut;
			}

			if (me.maxCutSet && me.yMax > me.maxCut) {
				me.yMax = me.maxCut;
			}
			if (me.minCutSet && me.yMax < me.minCut) {
				me.yMax = me.minCut;
			}

			// update min max diff and make sure > 0
			me.minMaxDiff = me.yMax - me.yMin;
			if (me.minMaxDiff < 2) {
				var tmpOffset = Math.ceil(me.yMax * 0.1);
				tmpOffset = tmpOffset < 1 ? 1.0 : tmpOffset;
				if (me.maxCutSet && me.yMax + tmpOffset < me.maxCut) {
					me.yMax += tmpOffset;
				}
				if (me.minCutSet && me.yMin - tmpOffset > me.minCut) {
					me.yMin -= tmpOffset;
				}
				if (me.yMax - me.yMin < 1) {
					me.yMin -= tmpOffset;
					me.yMax += tmpOffset;
				}
				me.minMaxDiff = me.yMax - me.yMin;
			}

			// ensure lines spaced evenly
			while ((me.yMax - me.yMin).toNumber() % 3 != 0) {
				me.yMax += 1;
			}
			me.minMaxDiff = me.yMax - me.yMin;

			// Try adapting the data for the graph width
			var bucketSize = Math.ceil(me.data.size() / me.graphWidth.toFloat()).toNumber();
			var nBuckets = Math.ceil(me.data.size() / bucketSize.toFloat());
			var step = nBuckets / me.graphWidth.toFloat();
			me.lines = [];

			// Draw chart
			var line = null;
			var val = null;
			heightFact = me.graphHeight.toFloat() / me.minMaxDiff;
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
						if (me.minCutSet && me.minCut > val) {
							val = me.minCut;
						}
						if (me.maxCutSet && me.maxCut < val) {
							val = me.maxCut;
						}
						val = Math.round(val);
						line = me.positionY - Math.round((val - me.yMin) * heightFact).toNumber();
					} else {
						line = null;
					}
					while (currentStep < nextStep) {
						lines.add(line);
						currentStep += step;
					}
					nextStep++;
					// reset bucket
					bucketVal = 0;
					bucketCount = 0;
				}
			}
		}

		// if no data available, set default lines for the y-axis
		if (me.minMaxDiff == null) {
			me.yMin = 0;
			me.yMax = 100;
			me.minMaxDiff = 100;
			heightFact = me.graphHeight.toFloat() / me.minMaxDiff;
		}

		var numLines = 4;
		var yStep = me.minMaxDiff / (numLines - 1).toFloat();
		var line = null;
		var val = null;
		me.chartLines = [];
		me.chartLinesValues = [];
		var lastVal = null;
		for (var i = 0; i < numLines; i++) {
			val = Math.round(me.yMin + yStep * i).toNumber();
			if (lastVal != null && val == lastVal) {
				continue;
			}
			lastVal = val;
			line = me.positionY - Math.round((val - me.yMin) * heightFact).toNumber();
			me.chartLines.add(line);
			me.chartLinesValues.add(val);
		}
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

		me.drawTitle(dc, me.titleText, null);
		me.minTextE.draw(dc);
		me.avgTextE.draw(dc);
		me.maxTextE.draw(dc);
		me.timeTextE.draw(dc);

		// Draw data if available
		if (me.data != null && me.data.size() >= 1 && me.min != null && me.max != null) {
			// Chart as light blue
			dc.setPenWidth(1);
			dc.setColor(0x27a0c4, Graphics.COLOR_TRANSPARENT);

			var val = null;
			var xPos = me.positionX + 1 + chartToLabelOffset; // leave some space to labels
			for (var i = 0; i < me.lines.size(); i++) {
				val = me.lines[i];
				if (val != null) {
					dc.drawLine(xPos, val, xPos, me.positionY);
				}
				xPos++;
			}
		}
		// Draw lines and labels
		dc.setPenWidth(1);
		dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
		var val = null;
		var linePos = null;
		var startX = me.positionX + me.chartToLabelOffset;
		var endX = me.positionX + me.chartToLabelOffset + me.graphWidth + me.chartToLabelOffset;
		for (var i = 0; i < me.chartLines.size(); i++) {
			// Draw lines over chart
			linePos = me.chartLines[i];
			dc.drawLine(startX, linePos, endX, linePos);

			// Draw labels for the lines except last one
			val = me.chartLinesValues[i];
			dc.drawText(
				me.positionX,
				linePos,
				Gfx.FONT_SYSTEM_XTINY,
				val,
				Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
			);
		}
	}
}

class TextElement {
	var x = null;
	var y = null;
	var text = null;
	var font = null;
	var justify = null;
	function initialize(x, y, text, font, justify) {
		me.x = x;
		me.y = y;
		me.text = text;
		me.font = font;
		me.justify = justify;
	}
	function draw(dc) {
		dc.drawText(me.x, me.y, me.font, me.text, me.justify);
	}
}
