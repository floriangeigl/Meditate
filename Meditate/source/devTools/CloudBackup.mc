using Toybox.Application as App;
using Toybox.Communications;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

// Serializes all Application.Storage user data and PUTs it to Firebase RTDB.
// Called from DevToolsDelegate. Manages its own StatusView for progress display.
//
// When adding/removing Application.Storage keys in the app, update the
// GLOBAL_SETTINGS_KEYS array and restore logic in CloudRestore.mc accordingly.
class CloudBackup extends Ui.BehaviorDelegate {
	private var mStatusView;
	private var mActive;

	private static const GLOBAL_SETTINGS_KEYS = [
		"globalSettings_hrvTracking",
		"globalSettings_activityType",
		"globalSettings_confirmSaveActivity",
		"globalSettings_multiSession",
		"globalSettings_respirationRate",
		"globalSettings_autoStop",
		"globalSettings_notification",
		"globalSettings_colorTheme",
		"globalSettings_prapareTime",
		"globalSettings_finalizeTime",
		"globalSettings_hrvWindowTime",
		"globalSettings_useSessionName",
	];

	function initialize() {
		BehaviorDelegate.initialize();
		mActive = true;
	}

	// Called from DevToolsDelegate.onSelect — switches the DevTools menu to this view.
	static function run() {
		var backup = new CloudBackup();
		var view = new StatusView("Backing up...");
		backup.mStatusView = view;
		Ui.switchToView(view, backup, Ui.SLIDE_LEFT);
		backup.performBackup();
	}

	private function performBackup() {
		try {
			var firebaseUrl = App.Properties.getValue("firebaseUrl");
			var firebaseSecret = App.Properties.getValue("firebaseSecret");
			var deviceId = System.getDeviceSettings().uniqueIdentifier;
			var timestamp = Time.now().value();
			var appVersion = Ui.loadResource(Rez.Strings.about_AppVersion);

			// --- Global settings ---
			var globalSettings = {};
			for (var i = 0; i < GLOBAL_SETTINGS_KEYS.size(); i++) {
				var key = GLOBAL_SETTINGS_KEYS[i];
				var val = App.Storage.getValue(key);
				if (val != null) {
					globalSettings[key] = val;
				}
			}

			// --- Sessions ---
			var sessionKeys = App.Storage.getValue("sessionsKeys");
			var selectedIndex = App.Storage.getValue("selectedSessionIndex");
			var sessionItems = {};
			if (sessionKeys != null) {
				for (var i = 0; i < sessionKeys.size(); i++) {
					var k = sessionKeys[i];
					var sessionData = App.Storage.getValue("sesssion_" + k.toString());
					if (sessionData != null) {
						sessionItems[k.toString()] = sessionData;
					}
				}
			}
			var sessions = {
				"selectedIndex" => selectedIndex,
				"keys" => sessionKeys,
				"items" => sessionItems,
			};

			// --- Wakeup ---
			var wakeup = {
				"activityType" => App.Storage.getValue("wakeupSession_activityType"),
			};

			// --- Full payload ---
			var payload = {
				"appVersion" => appVersion,
				"timestamp" => timestamp,
				"globalSettings" => globalSettings,
				"sessions" => sessions,
				"wakeup" => wakeup,
			};

			var url =
				firebaseUrl + "/backups/" + deviceId + "/" + timestamp.toString() + ".json?auth=" + firebaseSecret;
			var options = {
				:method => Communications.HTTP_REQUEST_METHOD_PUT,
				:headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
				:maxLength => 32768,
			};
			Communications.makeWebRequest(url, payload, options, method(:onBackupResponse));
		} catch (ex) {
			mStatusView.setMessage("Error: " + ex.getErrorMessage());
		}
	}

	function onBackupResponse(responseCode, data) {
		if (!mActive) {
			return;
		} // user navigated away before response arrived
		if (responseCode >= 200 && responseCode < 300) {
			mStatusView.setMessage("Backup OK");
		} else {
			mStatusView.setMessage("Error: " + responseCode.toString());
		}
	}

	function onBack() {
		mActive = false;
		Ui.popView(Ui.SLIDE_RIGHT);
		return true;
	}
}
