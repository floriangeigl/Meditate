using Toybox.ActivityRecording;
using Toybox.Activity;

// the kind of fit session; WakeupSessionStorage stores it, so the numbers never change
module FitSessionKind {
	enum {
		Training = 0,
		Meditation = 1,
		Yoga = 2,
		Breathing = 3,
	}
}

class FitSessionSpec {
	// https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html
	private static var subSportYoga = Activity has :SUB_SPORT_YOGA ? Activity.SUB_SPORT_YOGA : 43;
	private static var subSportBreathing = Activity has :SUB_SPORT_BREATHING ? Activity.SUB_SPORT_BREATHING : 62;
	private static var sportMeditation = Activity has :SPORT_MEDITATION ? Activity.SPORT_MEDITATION : 67;
	private static var sportTraining = Activity has :SPORT_TRAINING ? Activity.SPORT_TRAINING : 10;
	private static var subSportStrengthTraining =
		Activity has :SUB_SPORT_STRENGTH_TRAINING ? Activity.SUB_SPORT_STRENGTH_TRAINING : 20;

	// the createSession options for a kind; null or unknown (nothing stored yet) records as training.
	// an if chain on purpose: a switch on null throws
	static function create(kind, sessionName) {
		if (kind == FitSessionKind.Meditation) {
			return {
				:name => sessionName,
				:sport => sportMeditation,
			};
		}
		if (kind == FitSessionKind.Yoga) {
			return {
				:name => sessionName,
				:sport => sportTraining,
				:subSport => subSportYoga,
			};
		}
		if (kind == FitSessionKind.Breathing) {
			return {
				:name => sessionName,
				:sport => sportTraining,
				:subSport => subSportBreathing,
			};
		}
		return {
			:name => sessionName,
			:sport => sportTraining,
			:subSport => subSportStrengthTraining,
		};
	}
}
