using Toybox.Application as App;

// the FitSessionKind of the last saved or discarded session, so the next sensor wakeup session
// is created with the same sport; null until the first session
class WakeupSessionStorage {
	static const ActivityTypeKey = "wakeupSession_activityType";

	static function loadActivityType() {
		return App.Storage.getValue(ActivityTypeKey);
	}

	static function saveActivityType(fitSessionKind) {
		App.Storage.setValue(ActivityTypeKey, fitSessionKind);
	}
}
