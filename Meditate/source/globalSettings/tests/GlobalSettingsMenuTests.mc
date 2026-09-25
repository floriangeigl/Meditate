using Toybox.Test;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;

// the settings table replaces 13 hand-built menus: same rows in the same order, the same stored
// values behind each option, and subtitles that show what is stored
(:test)
class GlobalSettingsMenuTests {
	// [id, stored key, values in option order, hint positions]; the old menus as they were
	private static function oldMenus() {
		return [
			[:colorTheme, "globalSettings_colorTheme", [1, 0], [1]],
			[:autoStop, "globalSettings_autoStop", [1, 0], [0]],
			[:confirmSaveActivity, "globalSettings_confirmSaveActivity", [0, 2, 3, 1], [0]],
			[:prepareTime, "globalSettings_prapareTime", [0, 15, 30, 45, 60, 120, 180, 240, 300], []],
			[:finalizeTime, "globalSettings_finalizeTime", [0, 15, 30, 45, 60, 120, 180], []],
			[:notification, "globalSettings_notification", [1, 0], [0]],
			[:breathCues, "globalSettings_breathCues", [0, 1, 2], [1]],
			[:newActivityType, "globalSettings_activityType", [0, 1, 2, 3], []],
			[:useSessionName, "globalSettings_useSessionName", [true, false], [1]],
			[:hrvTracking, "globalSettings_hrvTracking", [1, 2, 0], [1]],
			[:hrvWindow, "globalSettings_hrvWindowTime", [30, 60, 120, 180, 300, 600], [1, 4]],
			[:respirationRate, "globalSettings_respirationRate", RrMetric.isSupported() ? [1, 0] : [0], RrMetric.isSupported() ? [0] : []],
			[:multiSession, "globalSettings_multiSession", [1, 0], [1]],
			[:sensorRestart, null, null, []],
		];
	}

	private static function hintPositions(hints) {
		if (hints == null) {
			return [];
		}
		var positions = hints.keys();
		// dictionary key order is not defined; sort the handful of positions
		for (var i = 1; i < positions.size(); i++) {
			for (var j = i; j > 0 && positions[j - 1] > positions[j]; j--) {
				var swap = positions[j];
				positions[j] = positions[j - 1];
				positions[j - 1] = swap;
			}
		}
		return positions;
	}

	(:test)
	static function rowsMatchTheOldMenus(logger) {
		var expected = GlobalSettingsMenuTests.oldMenus();
		var rows = GlobalSettingsMenuDelegate.rows();
		if (rows.size() != expected.size()) {
			logger.debug(rows.size() + " rows");
			return false;
		}
		for (var i = 0; i < rows.size(); i++) {
			var row = rows[i];
			var want = expected[i];
			var labelsFit = row[5] == null || row[5].size() == row[4].size();
			if (
				row[0] != want[0] ||
				!StorageSnapshot.deepEquals(row[3], want[1]) ||
				!StorageSnapshot.deepEquals(row[4], want[2]) ||
				!labelsFit ||
				!StorageSnapshot.deepEquals(GlobalSettingsMenuTests.hintPositions(row[6]), want[3])
			) {
				logger.debug("row " + i + " differs");
				return false;
			}
		}
		return true;
	}

	(:test)
	static function subtitlesShowTheStoredValue(logger) {
		var keys = [
			GlobalSettings.PrepareTimeKey,
			GlobalSettings.HrvWindowTimeKey,
			GlobalSettings.ColorThemeKey,
			GlobalSettings.UseSessionNameKey,
		];
		var saved = {};
		for (var i = 0; i < keys.size(); i++) {
			saved[keys[i]] = App.Storage.getValue(keys[i]);
		}
		try {
			GlobalSettings.save(GlobalSettings.PrepareTimeKey, 45);
			GlobalSettings.save(GlobalSettings.HrvWindowTimeKey, 300);
			GlobalSettings.save(GlobalSettings.ColorThemeKey, ColorTheme.Light);
			GlobalSettings.save(GlobalSettings.UseSessionNameKey, true);
			var rows = GlobalSettingsMenuDelegate.rows();
			var menu = new Ui.Menu2({ :title => "test" });
			for (var i = 0; i < rows.size(); i++) {
				menu.addItem(new Ui.MenuItem("", "", rows[i][0], {}));
			}
			new GlobalSettingsMenuDelegate(menu, rows).updateMenuItems();
			var ok =
				menu.getItem(0).getSubLabel().equals(Ui.loadResource(Rez.Strings.menuColorThemeOptions_light)) &&
				menu.getItem(3).getSubLabel().equals("00:45") &&
				menu.getItem(8).getSubLabel().equals(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName_on)) &&
				menu.getItem(10).getSubLabel().equals("05:00") &&
				menu.getItem(13).getSubLabel().equals("") &&
				menu.getItem(3).getId() == :prepareTime;
			var savedKeys = saved.keys();
			for (var i = 0; i < savedKeys.size(); i++) {
				StorageSnapshot.put(savedKeys[i], saved[savedKeys[i]]);
			}
			return ok;
		} catch (ex) {
			var savedKeys = saved.keys();
			for (var i = 0; i < savedKeys.size(); i++) {
				StorageSnapshot.put(savedKeys[i], saved[savedKeys[i]]);
			}
			throw ex;
		}
	}
}
