using Toybox.Application as App;
using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Fetches the list of available backups from Firebase, lets the user pick one,
// then downloads it and writes all keys back to Application.Storage.
//
// When adding/removing Application.Storage keys in the app, update the restore
// logic in onRestoreResponse() and GLOBAL_SETTINGS_KEYS in CloudBackup.mc.
class CloudRestore extends Ui.BehaviorDelegate {
	private var mStatusView;
	private var mActive;
	private var mTimestamps; // Array of timestamp strings, sorted descending
	private var mFirebaseUrl;
	private var mFirebaseSecret;
	private var mDeviceId;

	function initialize() {
		BehaviorDelegate.initialize();
		mActive = true;
		mFirebaseUrl = App.Properties.getValue("firebaseUrl");
		mFirebaseSecret = App.Properties.getValue("firebaseSecret");
		// Use restoreDeviceId phone-setting override if set — allows restoring another device's backup.
		// Leave the setting empty to restore from this device's own backups.
		var overrideId = App.Properties.getValue("restoreDeviceId");
		mDeviceId =
			overrideId != null && overrideId.length() > 0 ? overrideId : System.getDeviceSettings().uniqueIdentifier;
		mStatusView = new StatusView("Loading backups...");
		Ui.switchToView(mStatusView, me, Ui.SLIDE_LEFT);
		fetchBackupList();
	}

	// Called from DevToolsDelegate.onSelect — switches the DevTools menu to this view.
	static function run() {
		new CloudRestore();
	}

	private function fetchBackupList() {
		var url = mFirebaseUrl + "/backups/" + mDeviceId + ".json?shallow=true&auth=" + mFirebaseSecret;
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
			:maxLength => 4096,
		};
		Communications.makeWebRequest(url, null, options, method(:onListResponse));
	}

	function onListResponse(responseCode, data) {
		if (!mActive) {
			return;
		} // user navigated away before response arrived
		if (responseCode < 200 || responseCode >= 300) {
			mStatusView.setMessage("Error: " + responseCode.toString());
			return;
		}
		if (data == null) {
			mStatusView.setMessage("No backups found");
			return;
		}

		// data is a Dictionary of { "timestamp_string" => true }
		// Sort keys descending (most recent first)
		var keys = data.keys();
		if (keys == null || keys.size() == 0) {
			mStatusView.setMessage("No backups found");
			return;
		}

		// Simple insertion sort descending (timestamp strings sort lexicographically
		// correctly for epoch seconds of the same digit count)
		for (var i = 1; i < keys.size(); i++) {
			var cur = keys[i];
			var j = i - 1;
			while (j >= 0 && keys[j].compareTo(cur) < 0) {
				keys[j + 1] = keys[j];
				j--;
			}
			keys[j + 1] = cur;
		}
		// Keep only the 10 most recent entries
		mTimestamps = keys.size() > 10 ? keys.slice(0, 10) : keys;

		// Replace the status view with the backup picker menu
		showBackupMenu();
	}

	private function showBackupMenu() {
		var menu = new Ui.Menu2({ :title => "Restore Backup" });
		for (var i = 0; i < mTimestamps.size(); i++) {
			var ts = mTimestamps[i].toNumber();
			var label = formatTimestamp(ts);
			menu.addItem(new Ui.MenuItem(label, "", mTimestamps[i], {}));
		}
		// Replace the loading status view with the picker menu
		Ui.switchToView(menu, new RestorePickerDelegate(self), Ui.SLIDE_LEFT);
	}

	// Called by RestorePickerDelegate when user selects a backup
	function onBackupSelected(timestampStr) {
		var view = new StatusView("Restoring...");
		mStatusView = view;
		// Replace the picker menu with the restore status view
		Ui.switchToView(view, self, Ui.SLIDE_LEFT);
		fetchBackup(timestampStr);
	}

	private function fetchBackup(timestampStr) {
		var url = mFirebaseUrl + "/backups/" + mDeviceId + "/" + timestampStr + ".json?auth=" + mFirebaseSecret;
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
			:maxLength => 32768,
		};
		Communications.makeWebRequest(url, null, options, method(:onRestoreResponse));
	}

	function onRestoreResponse(responseCode, data) {
		if (!mActive) {
			return;
		} // user navigated away before response arrived
		if (responseCode < 200 || responseCode >= 300) {
			mStatusView.setMessage("Error: " + responseCode.toString());
			return;
		}
		if (data == null) {
			mStatusView.setMessage("Backup not found");
			return;
		}
		try {
			// --- Global settings ---
			var gs = data["globalSettings"];
			if (gs != null) {
				var gsKeys = gs.keys();
				for (var i = 0; i < gsKeys.size(); i++) {
					App.Storage.setValue(gsKeys[i], gs[gsKeys[i]]);
				}
			}

			// --- Sessions ---
			var sessions = data["sessions"];
			if (sessions != null) {
				var sessionKeys = sessions["keys"];
				var selectedIndex = sessions["selectedIndex"];
				var items = sessions["items"];

				if (sessionKeys != null) {
					App.Storage.setValue("sessionsKeys", sessionKeys);
				}
				if (selectedIndex != null) {
					App.Storage.setValue("selectedSessionIndex", selectedIndex);
				}
				if (items != null && sessionKeys != null) {
					// Firebase coerces {"0":…,"1":…} with integer-like keys into a JSON
					// array on read-back, so items may arrive as an Array instead of a
					// Dictionary.  Use sessionKeys (which we already restored) as the
					// source of truth for the key names; index into items accordingly.
					for (var i = 0; i < sessionKeys.size(); i++) {
						var k = sessionKeys[i];
						var sessionData;
						if (items instanceof Toybox.Lang.Dictionary) {
							sessionData = items[k.toString()];
						} else {
							// Array — Firebase preserved insertion order which matches sessionKeys order
							sessionData = i < items.size() ? items[i] : null;
						}
						if (sessionData != null) {
							App.Storage.setValue("sesssion_" + k.toString(), sessionData);
						}
					}
				}
			}

			// --- Wakeup ---
			var wakeup = data["wakeup"];
			if (wakeup != null && wakeup["activityType"] != null) {
				App.Storage.setValue("wakeupSession_activityType", wakeup["activityType"]);
			}

			// --- Monthly meditation stats ---
			var monthlyStats = data["monthlyStats"];
			if (monthlyStats != null) {
				if (monthlyStats["monthly"] != null) {
					App.Storage.setValue("usageStats_monthly", monthlyStats["monthly"]);
				}
				if (monthlyStats["tipPending"] != null) {
					App.Storage.setValue("usageStats_tipPending", monthlyStats["tipPending"]);
				}
			}

			mStatusView.setMessage("Restored! Restarting...");
			System.exit();
		} catch (ex) {
			mStatusView.setMessage("Error writing storage");
		}
	}

	function onBack() {
		mActive = false; // prevent any in-flight HTTP callback from touching the view stack
		Ui.popView(Ui.SLIDE_RIGHT);
		return true;
	}

	// Format epoch seconds as "15 Mar 2026 14:30"
	private function formatTimestamp(epochSeconds) {
		var info = Gregorian.info(new Time.Moment(epochSeconds), Time.FORMAT_SHORT);
		var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
		var month = info.month >= 1 && info.month <= 12 ? months[info.month - 1] : "?";
		var hour = info.hour.toString();
		var min = info.min < 10 ? "0" + info.min.toString() : info.min.toString();
		return info.day.toString() + " " + month + " " + info.year.toString() + " " + hour + ":" + min;
	}
}

// Thin delegate for the backup picker menu — delegates selection back to CloudRestore
class RestorePickerDelegate extends Ui.Menu2InputDelegate {
	private var mRestore;

	function initialize(restore) {
		Menu2InputDelegate.initialize();
		mRestore = restore;
	}

	function onSelect(item) {
		var timestampStr = item.getId();
		mRestore.onBackupSelected(timestampStr);
	}

	function onBack() {
		Ui.popView(Ui.SLIDE_RIGHT);
		return true;
	}
}
