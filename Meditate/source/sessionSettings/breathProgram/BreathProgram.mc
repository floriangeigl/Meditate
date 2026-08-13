using Toybox.Lang;
using Toybox.Math;

module BreathPhase {
	enum {
		Inhale = 0,
		HoldFull = 1,
		Exhale = 2,
		HoldEmpty = 3,
	}
}

module BreathRepeat {
	enum {
		Rounds = 1,
		Duration = 2,
	}
}

module BreathRoute {
	enum {
		Unset = 0,
		Nose = 1,
		Mouth = 2,
	}
}

class BreathStep {
	var durations; // [inhale, holdFull, exhale, holdEmpty] in seconds
	var repeatType;
	var repeatValue; // rounds count, or seconds when repeatType is Duration
	var inRoute; // nose / mouth / unset, per step
	var outRoute;

	static const PhaseCount = 4;
	static const MaxPhaseTime = 599; // 9:59, the MM:SS picker ceiling
	static const MaxRounds = 99;
	static const MaxDuration = 3599; // 59:59

	function initialize() {
		me.reset();
	}

	function reset() {
		me.durations = [4, 4, 4, 4];
		me.repeatType = BreathRepeat.Rounds;
		me.repeatValue = 4;
		me.inRoute = BreathRoute.Unset;
		me.outRoute = BreathRoute.Unset;
	}

	function cycleTime() {
		var total = 0;
		for (var i = 0; i < BreathStep.PhaseCount; i++) {
			total += me.durations[i];
		}
		return total;
	}

	function totalTime() {
		if (me.repeatType == BreathRepeat.Duration) {
			return me.repeatValue;
		}
		return me.cycleTime() * me.repeatValue;
	}

	function roundsCount() {
		var cycle = me.cycleTime();
		if (cycle < 1) {
			return 0;
		}
		if (me.repeatType == BreathRepeat.Duration) {
			return Math.ceil(me.repeatValue.toFloat() / cycle).toNumber();
		}
		return me.repeatValue;
	}

	function isValid() {
		return me.cycleTime() > 0 && me.totalTime() > 0;
	}

	// true when only a hold slot is set; rendered as "Hold M:SS" instead of "a-b-c"
	function isHoldOnly() {
		return me.durations[BreathPhase.Inhale] == 0 && me.durations[BreathPhase.Exhale] == 0;
	}

	// nose/mouth for a breathing phase; holds have no route
	function getRoute(phase) {
		if (phase == BreathPhase.Inhale) {
			return me.inRoute;
		}
		if (phase == BreathPhase.Exhale) {
			return me.outRoute;
		}
		return BreathRoute.Unset;
	}

	function setRoute(phase, route) {
		if (phase == BreathPhase.Inhale) {
			me.inRoute = route;
		} else if (phase == BreathPhase.Exhale) {
			me.outRoute = route;
		}
	}

	static function fromDictionary(loadedStep) {
		if (!(loadedStep instanceof Lang.Dictionary)) {
			return null;
		}
		var loadedDurations = loadedStep["d"];
		if (!(loadedDurations instanceof Lang.Array) || loadedDurations.size() != BreathStep.PhaseCount) {
			return null;
		}
		var durations = new [BreathStep.PhaseCount];
		for (var i = 0; i < BreathStep.PhaseCount; i++) {
			var duration = BreathStep.readInt(loadedDurations[i], 0, BreathStep.MaxPhaseTime);
			if (duration == null) {
				return null;
			}
			durations[i] = duration;
		}

		var step = new BreathStep();
		step.durations = durations;
		step.repeatType = loadedStep["rt"] == BreathRepeat.Duration ? BreathRepeat.Duration : BreathRepeat.Rounds;
		var maxRepeat = step.repeatType == BreathRepeat.Duration ? BreathStep.MaxDuration : BreathStep.MaxRounds;
		var repeatValue = BreathStep.readInt(loadedStep["rv"], 1, maxRepeat);
		if (repeatValue == null) {
			return null;
		}
		step.repeatValue = repeatValue;
		step.inRoute = BreathStep.readRoute(loadedStep["ir"]);
		step.outRoute = BreathStep.readRoute(loadedStep["or"]);

		if (!step.isValid()) {
			return null;
		}
		return step;
	}

	function toDictionary() {
		return {
			"d" => me.durations,
			"rt" => me.repeatType,
			"rv" => me.repeatValue,
			"ir" => me.inRoute,
			"or" => me.outRoute,
		};
	}

	static function readRoute(value) {
		if (value == BreathRoute.Nose || value == BreathRoute.Mouth) {
			return value;
		}
		return BreathRoute.Unset;
	}

	// returns null for anything non-numeric; never throws
	private static function readInt(value, min, max) {
		if (
			value instanceof Lang.Number ||
			value instanceof Lang.Float ||
			value instanceof Lang.Long ||
			value instanceof Lang.Double
		) {
			return Utils.clampToRange(value.toNumber(), min, max);
		}
		return null;
	}
}

class BreathProgram {
	private var mSteps;

	static const MaxSteps = 10;

	function initialize() {
		me.reset();
	}

	function reset() {
		me.mSteps = [];
	}

	function size() {
		return me.mSteps.size();
	}

	function get(index) {
		if (index < 0 || index >= me.mSteps.size()) {
			return null;
		}
		return me.mSteps[index];
	}

	// returns the new index, or -1 when the program is full
	function addNew(step) {
		if (me.mSteps.size() >= BreathProgram.MaxSteps) {
			return -1;
		}
		me.mSteps.add(step == null ? new BreathStep() : step);
		return me.mSteps.size() - 1;
	}

	function delete(index) {
		if (index < 0 || index >= me.mSteps.size()) {
			return;
		}
		me.mSteps.remove(me.mSteps[index]);
	}

	// delta is -1 (up) or +1 (down); out-of-range moves are ignored
	function move(index, delta) {
		var target = index + delta;
		if (index < 0 || index >= me.mSteps.size() || target < 0 || target >= me.mSteps.size()) {
			return;
		}
		var moved = me.mSteps[index];
		me.mSteps[index] = me.mSteps[target];
		me.mSteps[target] = moved;
	}

	function totalTime() {
		var total = 0;
		for (var i = 0; i < me.mSteps.size(); i++) {
			total += me.mSteps[i].totalTime();
		}
		return total;
	}

	// size()+1 entries; last one equals totalTime()
	function stepStartOffsets() {
		var offsets = new [me.mSteps.size() + 1];
		var running = 0;
		for (var i = 0; i < me.mSteps.size(); i++) {
			offsets[i] = running;
			running += me.mSteps[i].totalTime();
		}
		offsets[me.mSteps.size()] = running;
		return offsets;
	}

	function isEmpty() {
		return me.mSteps.size() == 0 || me.totalTime() < 1;
	}

	static function fromDictionary(loadedProgram) {
		if (!(loadedProgram instanceof Lang.Dictionary)) {
			return null;
		}
		var loadedSteps = loadedProgram["steps"];
		if (!(loadedSteps instanceof Lang.Array)) {
			return null;
		}
		var program = new BreathProgram();
		for (var i = 0; i < loadedSteps.size() && program.size() < BreathProgram.MaxSteps; i++) {
			var step = BreathStep.fromDictionary(loadedSteps[i]);
			if (step != null) {
				program.addNew(step);
			}
		}
		return program;
	}

	function toDictionary() {
		var serializedSteps = new [me.mSteps.size()];
		for (var i = 0; i < me.mSteps.size(); i++) {
			serializedSteps[i] = me.mSteps[i].toDictionary();
		}
		return {
			"steps" => serializedSteps,
		};
	}

	// the single route used by every step for this phase, or Unset when the steps disagree
	function getCommonRoute(phase) {
		var common = BreathRoute.Unset;
		for (var i = 0; i < me.mSteps.size(); i++) {
			var route = me.mSteps[i].getRoute(phase);
			if (route == BreathRoute.Unset) {
				continue;
			}
			if (common == BreathRoute.Unset) {
				common = route;
			} else if (common != route) {
				return BreathRoute.Unset;
			}
		}
		return common;
	}
}
