using Toybox.ActivityRecording;
using Toybox.Activity;

module HrvAlgorithms {
	class FitSessionSpec {
		// https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html
		private static var subSportYoga = Activity has :SUB_SPORT_YOGA ? Activity.SUB_SPORT_YOGA : 43;
		private static var subSportBreathing = Activity has :SUB_SPORT_BREATHING ? Activity.SUB_SPORT_BREATHING : 62;
		private static var sportMeditation = Activity has :SPORT_MEDITATION ? Activity.SPORT_MEDITATION : 67;
		private static var sportGeneric = Activity has :SPORT_GENERIC ? Activity.SPORT_GENERIC : 0;
		private static var sportTraining = Activity has :SPORT_TRAINING ? Activity.SPORT_TRAINING : 10;
		static function createYoga(sessionName) {
			return {
				:name => sessionName,
				:sport => sportTraining,
				:subSport => subSportYoga,
			};
		}

		static function createMeditation(sessionName) {
			return {
				:name => sessionName,
				:sport => sportMeditation,
			};
		}

		static function createBreathing(sessionName) {
			return {
				:name => sessionName,
				:sport => sportTraining,
				:subSport => subSportBreathing,
			};
		}

		static function createGeneric(sessionName) {
			return {
				:name => sessionName,
				:Sport => sportGeneric,
			};
		}
	}
}
