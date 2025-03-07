using Toybox.Application as App;
using HrvAlgorithms.HrvTracking;

class GlobalSettings {
	private static const HrvTrackingKey = "globalSettings_hrvTracking";

	static function loadHrvTracking() {
		var hrvTracking = App.Storage.getValue(HrvTrackingKey);
		if (hrvTracking == null) {
			hrvTracking = HrvTracking.OnDetailed;
		}
		return hrvTracking;
	}

	static function saveHrvTracking(hrvTracking) {
		App.Storage.setValue(HrvTrackingKey, hrvTracking);
	}

	private static const ActivityTypeKey = "globalSettings_activityType";

	static function loadActivityType() {
		var activityType = App.Storage.getValue(ActivityTypeKey);
		if (activityType == null) {
			return ActivityType.Meditating;
		} else {
			return activityType;
		}
	}

	static function saveActivityType(activityType) {
		App.Storage.setValue(ActivityTypeKey, activityType);
	}

	private static const ConfirmSaveActivityKey = "globalSettings_confirmSaveActivity";

	static function loadConfirmSaveActivity() {
		var confirmSaveActivity = App.Storage.getValue(ConfirmSaveActivityKey);
		if (confirmSaveActivity == null) {
			return ConfirmSaveActivity.Ask;
		} else {
			return confirmSaveActivity;
		}
	}

	static function saveConfirmSaveActivity(confirmSaveActivity) {
		App.Storage.setValue(ConfirmSaveActivityKey, confirmSaveActivity);
	}

	private static const MultiSessionKey = "globalSettings_multiSession";

	static function loadMultiSession() {
		var multiSession = App.Storage.getValue(MultiSessionKey);
		if (multiSession == null) {
			return MultiSession.No;
		} else {
			return multiSession;
		}
	}

	static function saveMultiSession(multiSession) {
		App.Storage.setValue(MultiSessionKey, multiSession);
	}

	private static const RespirationRateKey = "globalSettings_respirationRate";

	static function loadRespirationRate() {
		var respirationRate = App.Storage.getValue(RespirationRateKey);
		if (respirationRate == null) {
			return RespirationRate.On;
		} else {
			return respirationRate;
		}
	}

	static function saveRespirationRate(respirationRate) {
		App.Storage.setValue(RespirationRateKey, respirationRate);
	}

	private static const AutoStopKey = "globalSettings_autoStop";

	static function loadAutoStop() {
		var autoStop = App.Storage.getValue(AutoStopKey);
		if (autoStop == null) {
			return AutoStop.On; // 'On' the default value for AutoStop
		} else {
			return autoStop;
		}
	}

	static function saveAutoStop(autoStop) {
		App.Storage.setValue(AutoStopKey, autoStop);
	}

	private static const NotificationKey = "globalSettings_notification";

	static function loadNotification() {
		var notification = App.Storage.getValue(NotificationKey);
		if (notification == null) {
			return Notification.On; // 'On' is the default value for Notification
		} else {
			return notification;
		}
	}

	static function saveNotification(notification) {
		App.Storage.setValue(NotificationKey, notification);
	}

	private static const ColorThemeKey = "globalSettings_colorTheme";

	static function loadColorTheme() {
		var colorTheme = App.Storage.getValue(ColorThemeKey);
		if (colorTheme == null) {
			return ColorTheme.Dark; // 'Dark' is the default color theme
		} else {
			return colorTheme;
		}
	}

	static function saveColorTheme(colorTheme) {
		App.Storage.setValue(ColorThemeKey, colorTheme);
	}

	private static const PrepareTimeKey = "globalSettings_prapareTime";

	static function loadPrepareTime() {
		var prepareTime = App.Storage.getValue(PrepareTimeKey);
		if (prepareTime == null) {
			//DEBUG - no prepare time for debugging faster
			//return 0;
			return 15;
		} else {
			return prepareTime;
		}
	}

	static function savePrepareTime(prepareTime) {
		App.Storage.setValue(PrepareTimeKey, prepareTime);
	}

	private static const FinalizeTimeKey = "globalSettings_finalizeTime";

	static function loadFinalizeTime() {
		var finalizeTime = App.Storage.getValue(FinalizeTimeKey);
		if (finalizeTime == null) {
			return 0;
		} else {
			return finalizeTime;
		}
	}

	static function saveFinalizeTime(finalizeTime) {
		App.Storage.setValue(FinalizeTimeKey, finalizeTime);
	}
}

module ConfirmSaveActivity {
	enum {
		Ask = 0,
		AutoNo = 1,
		AutoYes = 2,
		AutoYesExit = 3,
	}
}

module MultiSession {
	enum {
		No = 0,
		Yes = 1,
	}
}

module RespirationRate {
	enum {
		Off = 0,
		On = 1,
	}
}

module AutoStop {
	enum {
		Off = 0,
		On = 1,
	}
}

module Notification {
	enum {
		Off = 0,
		On = 1,
	}
}

module ColorTheme {
	enum {
		Dark = 0,
		Light = 1,
	}
}
