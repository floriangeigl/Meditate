using Toybox.Application as App;

module HrvAlgorithms {
	module WakeupSessionType {
		enum {
			Training = 0,
			Meditation = 1,
			Yoga = 2,
			Breathing = 3,
		}
	}

	class WakeupSessionStorage {
		private static const WakeupActivityTypeKey = "wakeupSession_activityType";

		static function loadActivityType() {
			return App.Storage.getValue(WakeupActivityTypeKey);
		}

		static function saveActivityType(activityType) {
			App.Storage.setValue(WakeupActivityTypeKey, activityType);
		}
	}
}
