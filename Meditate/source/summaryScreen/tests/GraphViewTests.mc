using Toybox.Test;
using Toybox.Graphics;

// the graph maths: grid, columns, time coverage, and a layout that survives running twice
(:test)
class GraphViewTests {
	private static function gridIs(logger, min, max, expected) {
		var grid = GraphView.gridRange(min, max);
		if (grid[0] != expected[0] || grid[1] != expected[1] || grid[2] != expected[2]) {
			logger.debug("grid " + min + ".." + max + " = " + grid + ", expected " + expected);
			return false;
		}
		return true;
	}

	private static function sameValues(actual, expected) {
		if (actual.size() != expected.size()) {
			return false;
		}
		for (var i = 0; i < actual.size(); i++) {
			var a = actual[i];
			var e = expected[i];
			if (a == null || e == null ? a != e : (a - e).abs() > 0.001) {
				return false;
			}
		}
		return true;
	}

	private static function dc() {
		var options = { :width => 218, :height => 218 };
		if (Graphics has :createBufferedBitmap) {
			return Graphics.createBufferedBitmap(options).get().getDc();
		}
		return new Graphics.BufferedBitmap(options).getDc();
	}

	private static function metric(values) {
		var m = new ScriptedMetric(values, 1);
		for (var i = 0; i < values.size(); i++) {
			m.sample(null);
		}
		return m.flush();
	}

	// [floor, step, steps]: round labels, tightest fit, floor below the data
	(:test)
	static function gridIsRoundAndHoldsTheData(logger) {
		return (
			gridIs(logger, 55, 75, [50, 10, 3]) &&
			gridIs(logger, 58, 66, [55, 5, 3]) &&
			gridIs(logger, 12.4, 13.1, [12, 1, 2]) &&
			gridIs(logger, 60, 60, [59, 1, 2]) &&
			gridIs(logger, 20, 40, [10, 10, 3])
		);
	}

	// data at a cap stays inside it; 0 is never undercut; no-data grids span the caps
	(:test)
	static function gridStaysWithinTheCaps(logger) {
		return (
			gridIs(logger, 11, 100, [0, 50, 2]) &&
			gridIs(logger, 149, 150, [148, 1, 2]) &&
			gridIs(logger, 0, 0, [0, 1, 2]) &&
			gridIs(logger, 20, 150, [0, 50, 3]) &&
			gridIs(logger, 1, 60, [0, 20, 3])
		);
	}

	// near-constant data gets the minimum span around its middle, inside the caps; wide data stays as is
	(:test)
	static function flatDataIsWidenedNotZoomed(logger) {
		return (
			sameValues(GraphView.widen(61, 63, 6, 20, 150), [59, 65]) &&
			sameValues(GraphView.widen(55, 75, 6, 20, 150), [55, 75]) &&
			sameValues(GraphView.widen(0, 3, 6, 0, 100), [0, 6]) &&
			sameValues(GraphView.widen(98, 100, 6, 0, 100), [94, 100]) &&
			// flat hr sits mid-grid, respiration 12.4-13.1 on 10-16 rather than a 12-14 zoom into noise
			gridIs(logger, 57, 63, [55, 5, 2]) &&
			gridIs(logger, 10.75, 14.75, [10, 2, 3])
		);
	}

	(:test)
	static function shortHistoryStretchesOverTheColumns(logger) {
		return sameValues(GraphView.columns([10, null, 30], 6), [10, 10, null, null, 30, 30]);
	}

	// every value lands in exactly one column, the first column included
	(:test)
	static function longHistoryAveragesPerColumn(logger) {
		return (
			sameValues(GraphView.columns([10, 20, 30, 40, 50, null], 3), [15, 35, 50]) &&
			GraphView.columns(new [721], 164).size() == 164
		);
	}

	(:test)
	static function barsCoverOnlyTheRecordedTime(logger) {
		return (
			GraphView.coveredColumns(164, 180, 10, 1800) == 164 &&
			// 10 min hrv window, 18 min session: the one window covers 10 of 18 min
			GraphView.coveredColumns(164, 1, 600, 1080) == 91 &&
			GraphView.coveredColumns(164, 181, 10, 1800) == 164 &&
			GraphView.coveredColumns(164, 1, 10, 100000) == 1 &&
			GraphView.coveredColumns(164, 2, 30, 0) == 164
		);
	}

	(:test)
	static function layoutCanRunTwice(logger) {
		var d = dc();
		var withData = new GraphView(metric([55, 65, 75]), 3, Rez.Strings.SummaryHR, 20, 150, 6);
		var flat = new GraphView(metric([60, 60]), 2, Rez.Strings.SummaryHR, 20, 150, 6);
		var noData = new GraphView(metric([null, null]), 2, Rez.Strings.SummaryHR, 20, 150, 6);
		var noMetric = new GraphView(null, 0, Rez.Strings.SummaryHR, 20, 150, 6);
		var views = [withData, flat, noData, noMetric];
		for (var i = 0; i < views.size(); i++) {
			views[i].onLayout(d);
			views[i].onLayout(d);
			views[i].onUpdate(d);
		}
		return true;
	}
}
