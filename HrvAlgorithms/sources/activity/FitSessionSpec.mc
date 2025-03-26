using Toybox.ActivityRecording;
using Toybox.Activity;

module HrvAlgorithms {
	class FitSessionSpec {
		// https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html
		static const subSportYoga = 43;
		static const subSportBreathing = 62;
		static const sportMeditation = 67;
		static function createYoga(sessionName) {
			var subsport = null;
			if (Activity has :SUB_SPORT_YOGA) {
				subsport = Activity.SUB_SPORT_YOGA;
			} else {
				subsport = subSportYoga;
			}
			return {
				:name => sessionName,
				:subSport => subsport,
			};
		}

		static function createMeditation(sessionName) {
			var sport = null;
			if (Activity has :SPORT_MEDITATION) {
				sport = Activity.SPORT_MEDITATION;
			} else {
				sport = sportMeditation;
			}
			return {
				:name => sessionName,
				:sport => sport,
			};
		}

		static function createBreathing(sessionName) {
			var subsport = null;
			if (Activity has :SUB_SPORT_BREATHING) {
				subsport = Activity.SUB_SPORT_BREATHING;
			} else {
				subsport = subSportBreathing;
			}
			return {
				:name => sessionName,
				:subSport => subsport,
			};
		}

		static function createGeneric(sessionName) {
			return {
				:name => sessionName,
				:Sport => Activity.SPORT_GENERIC,
			};
		}
	}
}
