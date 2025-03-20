using Toybox.ActivityRecording;
using Toybox.Activity;

module HrvAlgorithms {
	class FitSessionSpec {
		private static const SUB_SPORT_YOGA = 43;
		private static const SUB_SPORT_BREATHWORKS = 62;
		private static const SPORT_MEDITATION = 67;
		
		static function createYoga(sessionName) {
			return {
                 :name => sessionName,
                 :subSport => SUB_SPORT_YOGA
                };
		}
		
		static function createMeditation(sessionName) {
			return {
                 :name => sessionName,
                 :sport => SPORT_MEDITATION
                };
		}

		static function createBreathing(sessionName) {
			return {
                 :name => sessionName,
                 :subSport => SUB_SPORT_BREATHWORKS
                };
		}
	}
}