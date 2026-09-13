using Toybox.Test;
using Toybox.Math;

// six intervals of a calm sensor and one outlier; expectations from HrvAlgorithmsSampleOutput.xlsx
(:test)
class HrvSdrrFixture {
	const Expected6NormalIntervals = 26.95;
	const Expected5MinNormalIntervals = 26.95;
	const Expected6NormalIntervals1Outlier = 129.07;
	const Expected5NormalIntervals1Outlier = 139.41;

	private var mSdrr;

	function initialize(sdrr) {
		me.mSdrr = sdrr;
	}

	function add1NormalInterval() {
		me.mSdrr.add(1090.9);
	}

	function add6NormalIntervals() {
		me.mSdrr.add(1090.9);
		me.mSdrr.add(1016.9);
		me.mSdrr.add(1016.9);
		me.mSdrr.add(1034.4);
		me.mSdrr.add(1016.9);
		me.mSdrr.add(1052.6);
	}

	function add5MinNormalIntervals() {
		for (var i = 1; i <= 5 * 10; i++) {
			me.add6NormalIntervals();
		}
	}

	function addOutlierInterval() {
		me.mSdrr.add(1400.0);
	}

	function calculate() {
		return me.mSdrr.calculate();
	}

	function isResultExpected(actual, expected) {
		if (actual == null) {
			return false;
		}
		return Math.floor(actual * 100.0) == Math.floor(expected * 100.0);
	}
}

(:test)
class HrvSdrrFirstTests {
	(:test)
	static function noIntervalIsNull(logger) {
		return new HrvSdrrFixture(new HrvSdrr(10, true)).calculate() == null;
	}

	(:test)
	static function oneIntervalIsNull(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(10, true));
		fixture.add1NormalInterval();
		return fixture.calculate() == null;
	}

	(:test)
	static function fiveMinNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60, true));
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function fiveMinNormalIntervalsInALargerWindow(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(3 * 5 * 60, true));
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function tenMinNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(10 * 5 * 60, true));
		fixture.add5MinNormalIntervals();
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function sixNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6, true));
		fixture.add6NormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function outlierAfterAFullWindowIsIgnored(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6, true));
		fixture.add6NormalIntervals();
		fixture.addOutlierInterval();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function outlierInsideTheWindowCounts(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(7, true));
		fixture.add6NormalIntervals();
		fixture.addOutlierInterval();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals1Outlier);
	}
}

(:test)
class HrvSdrrLastTests {
	(:test)
	static function noIntervalIsNull(logger) {
		return new HrvSdrrFixture(new HrvSdrr(10, false)).calculate() == null;
	}

	(:test)
	static function oneIntervalIsNull(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(10, false));
		fixture.add1NormalInterval();
		return fixture.calculate() == null;
	}

	(:test)
	static function fewerIntervalsThanTheWindowStillCount(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(7, false));
		fixture.add6NormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function fiveMinNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60, false));
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function outlierBeforeTheLastFiveMinIsForgotten(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60, false));
		fixture.addOutlierInterval();
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	// the ring keeps the last 300 beats of a longer session, not total mod 300
	(:test)
	static function tenMinNormalIntervalsKeepTheLastFive(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60, false));
		fixture.add5MinNormalIntervals();
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function sixNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6, false));
		fixture.add6NormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function outlierPushesTheFirstIntervalOut(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6, false));
		fixture.add6NormalIntervals();
		fixture.addOutlierInterval();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5NormalIntervals1Outlier);
	}
}
