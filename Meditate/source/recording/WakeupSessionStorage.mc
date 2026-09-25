using Toybox.Application as App;

module WakeupSessionType {
	enum {
		Training = 0,
		Meditation = 1,
		Yoga = 2,
		Breathing = 3,
	}
}

class WakeupSessionStorage {
	static const ActivityTypeKey = "wakeupSession_activityType";

	static function loadActivityType() {
		return App.Storage.getValue(ActivityTypeKey);
	}

	static function saveActivityType(activityType) {
		App.Storage.setValue(ActivityTypeKey, activityType);
	}
}
