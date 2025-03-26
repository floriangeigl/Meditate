using Toybox.ActivityRecording;
using Toybox.Activity;

module HrvAlgorithms {
	class FitSessionSpec {		
		static function createYoga(sessionName) {
			if (Activity has :SUB_SPORT_YOGA) {
				return {
					:name => sessionName,
					:subSport => Activity.SUB_SPORT_YOGA
					};
			} else {
				return createGeneric(sessionName);
			}
		}
		
		static function createMeditation(sessionName) {
			if (Activity has :SPORT_MEDITATION) {
				return {
					:name => sessionName,
					:sport => Activity.SPORT_MEDITATION
					};
			} else {
				return createGeneric(sessionName);
			}
		}

		static function createBreathing(sessionName) {
			if (Activity has :SUB_SPORT_BREATHING) {
				return {
					:name => sessionName,
					:subSport => Activity.SUB_SPORT_BREATHING
					};
			} else {
				return createGeneric(sessionName);
			}
		}

		static function createGeneric(sessionName) {
			return {
                 :name => sessionName,
                 :Sport => Activity.SPORT_GENERIC
                };
		}
	}
}