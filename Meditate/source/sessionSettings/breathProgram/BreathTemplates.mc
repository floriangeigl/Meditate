using Toybox.WatchUi as Ui;

// Ready-made steps and whole programs. Authoring a program from scratch on a
// 5-button watch is painful, so every entry point starts from one of these.
//
// Breathing routes follow the source techniques: 4-7-8 exhales through the mouth
// (Weil), coherent breathing is nasal throughout, box breathing is nasal in and
// tolerates either out, and power breathing is nose in / mouth out.
class BreathTemplates {
	// --- steps -------------------------------------------------------------

	static function stepIds() {
		return [:box, :b478, :coherence, :triangle, :extExhale, :fast, :hold, :custom];
	}

	static function createStep(id) {
		var nose = BreathRoute.Nose;
		var mouth = BreathRoute.Mouth;
		var unset = BreathRoute.Unset;
		if (id == :b478) {
			return BreathTemplates.makeStep([4, 7, 8, 0], BreathRepeat.Rounds, 4, nose, mouth);
		}
		if (id == :coherence) {
			return BreathTemplates.makeStep([6, 0, 6, 0], BreathRepeat.Rounds, 10, nose, nose);
		}
		if (id == :triangle) {
			return BreathTemplates.makeStep([4, 4, 4, 0], BreathRepeat.Rounds, 5, nose, nose);
		}
		if (id == :extExhale) {
			// pursed-lip exhale
			return BreathTemplates.makeStep([4, 0, 8, 0], BreathRepeat.Rounds, 5, nose, mouth);
		}
		if (id == :fast) {
			return BreathTemplates.makeStep([2, 0, 2, 0], BreathRepeat.Rounds, 15, nose, mouth);
		}
		if (id == :hold) {
			return BreathTemplates.makeStep([0, 60, 0, 0], BreathRepeat.Rounds, 1, unset, unset);
		}
		if (id == :custom) {
			return BreathTemplates.makeStep([4, 4, 4, 4], BreathRepeat.Rounds, 4, unset, unset);
		}
		return BreathTemplates.makeStep([4, 4, 4, 4], BreathRepeat.Rounds, 4, nose, nose);
	}

	// label shown in the "Add step" list; derived from the numbers except where a word reads better
	static function getStepLabel(id) {
		if (id == :custom) {
			return Ui.loadResource(Rez.Strings.breathTemplate_custom);
		}
		return Utils.getBreathStepName(BreathTemplates.createStep(id));
	}

	// --- programs ----------------------------------------------------------
	// These back the shipped breathwork sessions in SessionPresets; there is no
	// separate template picker, so this is the only definition of each program.

	static function createProgram(id) {
		var program = new BreathProgram();
		var nose = BreathRoute.Nose;
		var mouth = BreathRoute.Mouth;
		var unset = BreathRoute.Unset;
		var rounds = BreathRepeat.Rounds;
		var duration = BreathRepeat.Duration;

		if (id == :coherence5) {
			program.addNew(BreathTemplates.makeStep([6, 0, 6, 0], duration, 300, nose, nose));
		} else if (id == :b4785) {
			program.addNew(BreathTemplates.makeStep([4, 7, 8, 0], duration, 300, nose, mouth));
		} else if (id == :breathHolds) {
			// power breaths, then a retention on empty lungs, then a recovery breath held full
			for (var round = 0; round < 2; round++) {
				program.addNew(BreathTemplates.makeStep([2, 0, 2, 0], rounds, 30, nose, mouth));
				program.addNew(BreathTemplates.makeStep([0, 0, 0, round == 0 ? 60 : 90], rounds, 1, unset, unset));
				program.addNew(BreathTemplates.makeStep([4, 15, 4, 0], rounds, 1, nose, mouth));
			}
		} else if (id == :energize) {
			program.addNew(BreathTemplates.makeStep([2, 0, 2, 0], rounds, 40, nose, mouth));
			program.addNew(BreathTemplates.makeStep([4, 4, 4, 4], rounds, 10, nose, nose));
		} else if (id == :windDown) {
			program.addNew(BreathTemplates.makeStep([4, 0, 8, 0], duration, 180, nose, mouth));
			program.addNew(BreathTemplates.makeStep([4, 7, 8, 0], rounds, 6, nose, mouth));
		} else {
			// :box5
			program.addNew(BreathTemplates.makeStep([4, 4, 4, 4], duration, 300, nose, nose));
		}
		return program;
	}

	private static function makeStep(durations, repeatType, repeatValue, inRoute, outRoute) {
		var breathStep = new BreathStep();
		breathStep.durations = durations;
		breathStep.repeatType = repeatType;
		breathStep.repeatValue = repeatValue;
		breathStep.inRoute = inRoute;
		breathStep.outRoute = outRoute;
		return breathStep;
	}
}
