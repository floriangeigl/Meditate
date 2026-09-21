using Toybox.Test;
using Toybox.Math;

// six intervals of a calm sensor and one outlier, one beat per second unless stated;
// expectations from HrvAlgorithmsSampleOutput.xlsx
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
		me.mSdrr.addSecond([1090.9]);
	}

	function add6NormalIntervals() {
		me.mSdrr.addSecond([1090.9]);
		me.mSdrr.addSecond([1016.9]);
		me.mSdrr.addSecond([1016.9]);
		me.mSdrr.addSecond([1034.4]);
		me.mSdrr.addSecond([1016.9]);
		me.mSdrr.addSecond([1052.6]);
	}

	// the same six beats in two seconds
	function add6NormalIntervalsIn2Seconds() {
		me.mSdrr.addSecond([1090.9, 1016.9, 1016.9]);
		me.mSdrr.addSecond([1034.4, 1016.9, 1052.6]);
	}

	function add5MinNormalIntervals() {
		for (var i = 1; i <= 5 * 10; i++) {
			me.add6NormalIntervals();
		}
	}

	function addEmptySeconds(count) {
		for (var i = 0; i < count; i++) {
			me.mSdrr.addSecond([]);
		}
	}

	function addOutlierInterval() {
		me.mSdrr.addSecond([1400.0]);
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
class HrvSdrrTests {
	(:test)
	static function noIntervalIsNull(logger) {
		return new HrvSdrrFixture(new HrvSdrr(10)).calculate() == null;
	}

	(:test)
	static function oneIntervalIsNull(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(10));
		fixture.add1NormalInterval();
		return fixture.calculate() == null;
	}

	(:test)
	static function fewerSecondsThanTheWindowStillCount(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(7));
		fixture.add6NormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function severalBeatsInOneSecondAllCount(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(7));
		fixture.add6NormalIntervalsIn2Seconds();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function fiveMinNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60));
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function outlierBeforeTheLastFiveMinIsForgotten(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60));
		fixture.addOutlierInterval();
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	// the ring keeps the last 300 seconds of a longer session, not total mod 300
	(:test)
	static function tenMinNormalIntervalsKeepTheLastFive(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60));
		fixture.add5MinNormalIntervals();
		fixture.add5MinNormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5MinNormalIntervals);
	}

	(:test)
	static function sixNormalIntervals(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6));
		fixture.add6NormalIntervals();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals);
	}

	(:test)
	static function outlierPushesTheFirstSecondOut(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(6));
		fixture.add6NormalIntervals();
		fixture.addOutlierInterval();
		return fixture.isResultExpected(fixture.calculate(), fixture.Expected5NormalIntervals1Outlier);
	}

	// time moves without beats; a sensor gap as long as the window empties it
	(:test)
	static function emptySecondsPushBeatsOut(logger) {
		var fixture = new HrvSdrrFixture(new HrvSdrr(5 * 60));
		fixture.add6NormalIntervals();
		fixture.addEmptySeconds(5 * 60 - 6);
		if (!fixture.isResultExpected(fixture.calculate(), fixture.Expected6NormalIntervals)) {
			return false;
		}
		// two beats left in the window, then one
		fixture.addEmptySeconds(4);
		if (fixture.calculate() == null) {
			return false;
		}
		fixture.addEmptySeconds(1);
		return fixture.calculate() == null;
	}
}
