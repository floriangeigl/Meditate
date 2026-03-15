using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;

// Dev-only menu: Backup to Cloud / Restore from Cloud / Device ID display.
// Triggered by long-pressing the About screen (hidden from normal users).
class DevToolsDelegate extends Ui.Menu2InputDelegate {
	function initialize() {
		Menu2InputDelegate.initialize();
	}

	static function show() {
		var deviceId = System.getDeviceSettings().uniqueIdentifier;
		var overrideId = App.Properties.getValue("restoreDeviceId");
		var restoreId = overrideId != null && overrideId.length() > 0 ? overrideId : deviceId;

		var menu = new Ui.Menu2({ :title => "Dev Tools" });
		menu.addItem(new Ui.MenuItem("Backup to Cloud", deviceId, :backup, {}));
		menu.addItem(new Ui.MenuItem("Restore from Cloud", restoreId, :restore, {}));
		menu.addItem(new Ui.MenuItem("Device ID", deviceId, :deviceId, {}));
		Ui.pushView(menu, new DevToolsDelegate(), Ui.SLIDE_LEFT);
	}

	function onSelect(item) {
		var id = item.getId();
		if (id == :backup) {
			CloudBackup.run();
		} else if (id == :restore) {
			CloudRestore.run();
		}
		// :deviceId — display-only, no action
	}

	function onBack() {
		Ui.popView(Ui.SLIDE_RIGHT);
		return true;
	}
}
