using Toybox.Math;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// one metric's window history as bars on a round-numbered grid; onLayout rebuilds everything
class GraphView extends ScreenPicker.ScreenPickerBaseView {
	private static const GridSteps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];
	private static const BarColor = 0x27a0c4;

	var title;
	private var mMetric;
	private var mElapsedTime;
	private var mLo;
	private var mHi;
	private var mMinSpan;

	private var mTitleText;
	private var mTexts;
	private var mBars;
	private var mBarX;
	private var mBottom;
	private var mGridY;
	private var mGridLabels;
	private var mGridX;
	private var mGridEnd;
	private var mLabelX;

	// lo and hi cap the plotted values only, the avg, min and max texts show the metric as it is;
	// minSpan is the flattest scale, so near-constant data isn't zoomed into noise
	function initialize(metric, elapsedTime, title, lo, hi, minSpan) {
		ScreenPickerBaseView.initialize(true);
		me.mMetric = metric;
		me.mElapsedTime = elapsedTime;
		me.title = title;
		me.mLo = lo;
		me.mHi = hi;
		me.mMinSpan = minSpan;
	}

	// [min, max] grown around its middle to at least minSpan, kept inside [lo, hi]
	static function widen(min, max, minSpan, lo, hi) {
		var pad = (minSpan - (max - min)) / 2.0;
		if (pad <= 0) {
			return [min, max];
		}
		min -= pad;
		max += pad;
		if (min < lo) {
			max += lo - min;
			min = lo;
		}
		if (max > hi) {
			min -= max - hi;
			max = hi;
		}
		return [min < lo ? lo : min, max];
	}

	// tightest round grid of 2 or 3 steps holding [min, max]; the floor stays below min unless that goes under 0
	static function gridRange(min, max) {
		var best = null;
		for (var i = 0; i < GridSteps.size(); i++) {
			var step = GridSteps[i];
			var floor = Math.floor(min / step.toFloat()).toNumber() * step;
			if (floor >= min && floor >= step) {
				floor -= step;
			}
			for (var steps = 2; steps <= 3; steps++) {
				if (floor + steps * step >= max && (best == null || steps * step < best[1] * best[2])) {
					best = [floor, step, steps];
				}
			}
		}
		return best;
	}

	// one value per column: the mean of the column's share of the history, null for a gap
	static function columns(history, width) {
		var n = history.size();
		var out = new [width];
		for (var x = 0; x < width; x++) {
			var from = (x * n) / width;
			var to = ((x + 1) * n) / width;
			if (to <= from) {
				to = from + 1;
			}
			var sum = 0.0;
			var count = 0;
			for (var i = from; i < to; i++) {
				if (history[i] != null) {
					sum += history[i];
					count++;
				}
			}
			out[x] = count > 0 ? sum / count : null;
		}
		return out;
	}

	// columns the history covers; a trailing partial window dropped at flush leaves the right edge empty
	static function coveredColumns(width, windows, window, elapsedTime) {
		if (elapsedTime == null || elapsedTime <= 0) {
			return width;
		}
		var cols = Math.round((width * windows * window) / elapsedTime.toFloat()).toNumber();
		return Utils.clampToRange(cols, 1, width);
	}

	private static function valueText(label, value) {
		return Ui.loadResource(label) + ScreenPicker.ScreenPickerBaseView.formatValue(value);
	}

	function onLayout(dc) {
		ScreenPickerBaseView.onLayout(dc);
		me.yOffsetTitle = Math.ceil(me.height * 0.1);
		var graphHeight = Math.round(me.height * 0.33);
		var graphWidth = Math.round(me.width * 0.75);
		var labelGap = Math.ceil(graphWidth * 0.01);
		var left = me.centerXPos - graphWidth / 2 + graphWidth * 0.05;
		me.mBottom = me.centerYPos + graphHeight / 2;
		me.mBarX = left + 1 + labelGap;
		me.mGridX = left + labelGap;
		me.mGridEnd = left + labelGap + graphWidth + labelGap;
		me.mLabelX = left;

		var metric = me.mMetric;
		var history = metric != null ? metric.history : null;
		var min = metric != null ? metric.min : null;
		var max = metric != null ? metric.max : null;
		var avg = metric != null ? metric.getAvg() : null;

		var center = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
		var leftAligned = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
		var aboveGraph = me.centerYPos - graphHeight / 2 - me.spaceYSmall * 5;
		var belowGraph = me.mBottom + me.spaceYSmall * 5;
		me.mTitleText = Ui.loadResource(me.title);
		me.mTexts = [
			[me.centerXPos, aboveGraph, valueText(Rez.Strings.SummaryAvg, avg), center],
			[left + me.spaceXSmall, belowGraph, valueText(Rez.Strings.SummaryMin, min), leftAligned],
			[left + graphWidth / 2 + me.spaceXSmall, belowGraph, valueText(Rez.Strings.SummaryMax, max), leftAligned],
			[me.centerXPos, me.centerYPos + me.centerYPos / 1.5 + 13, TimeFormatter.format(me.mElapsedTime), center],
		];

		var hasData = min != null && history.size() > 0;
		var range = [me.mLo, me.mHi];
		if (hasData) {
			var low = Utils.clampToRange(min, me.mLo, me.mHi);
			var high = Utils.clampToRange(max, me.mLo, me.mHi);
			range = widen(low, high, me.mMinSpan, me.mLo, me.mHi);
		}
		var grid = gridRange(range[0], range[1]);
		var floor = grid[0];
		var step = grid[1];
		var scale = graphHeight / (step * grid[2]).toFloat();
		me.mGridY = new [grid[2] + 1];
		me.mGridLabels = new [grid[2] + 1];
		for (var k = 0; k <= grid[2]; k++) {
			me.mGridY[k] = me.mBottom - Math.round(k * step * scale);
			me.mGridLabels[k] = (floor + k * step).toString();
		}

		me.mBars = [];
		if (hasData) {
			var cols = coveredColumns(graphWidth.toNumber(), history.size(), metric.getWindow(), me.mElapsedTime);
			me.mBars = columns(history, cols);
			for (var x = 0; x < cols; x++) {
				var v = me.mBars[x];
				if (v != null) {
					var top = me.mBottom - Math.round((Utils.clampToRange(v, me.mLo, me.mHi) - floor) * scale);
					// a value on the floor still gets a pixel, so it doesn't read as a gap
					me.mBars[x] = top < me.mBottom - 1 ? top : me.mBottom - 1;
				}
			}
		}
	}

	// runs several times per show on some devices; skipping a call leaves the screen black
	function onUpdate(dc) {
		ScreenPickerBaseView.onUpdate(dc);
		me.drawTitle(dc, me.mTitleText, null);
		for (var i = 0; i < me.mTexts.size(); i++) {
			var text = me.mTexts[i];
			dc.drawText(text[0], text[1], Gfx.FONT_SYSTEM_TINY, text[2], text[3]);
		}

		dc.setPenWidth(1);
		dc.setColor(BarColor, Gfx.COLOR_TRANSPARENT);
		for (var x = 0; x < me.mBars.size(); x++) {
			if (me.mBars[x] != null) {
				dc.drawLine(me.mBarX + x, me.mBars[x], me.mBarX + x, me.mBottom);
			}
		}

		dc.setColor(me.foregroundColor, Gfx.COLOR_TRANSPARENT);
		for (var k = 0; k < me.mGridY.size(); k++) {
			dc.drawLine(me.mGridX, me.mGridY[k], me.mGridEnd, me.mGridY[k]);
			dc.drawText(
				me.mLabelX,
				me.mGridY[k],
				Gfx.FONT_SYSTEM_XTINY,
				me.mGridLabels[k],
				Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
			);
		}
	}
}
