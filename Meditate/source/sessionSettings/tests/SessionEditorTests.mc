using Toybox.Test;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

// the session editor's one write path through the real settings menu: an edit saves the whole
// session under its own key, and "follow the global default" (null) is never filled in
(:test)
class SessionEditorTests {
	// the stored session 101 and an editor on it; no menu, so nothing is drawn or pushed
	private static function openEditor() {
		SessionStorageTests.writeStore([SessionStorageTests.storedSession(101, null, null)], 0);
		var storage = new SessionStorage();
		var settings = new SessionSettingsMenuDelegate(storage, new PickerSpy());
		var session = storage.loadSelectedSession();
		return new AddEditSessionMenuDelegate(
			session,
			session.getIntervalAlerts(),
			settings.method(:onChangeSession),
			null
		);
	}

	(:test)
	static function anEditChangesOnlyThatFieldAndKeepsDefaultsUnset(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var editor = SessionEditorTests.openEditor();
			editor.onTimePicked(900);
			editor.onColorSelected(Gfx.COLOR_RED);
			var expected = SessionStorageTests.storedSession(101, null, null);
			expected["time"] = 900;
			expected["color"] = Gfx.COLOR_RED;
			var ok = StorageSnapshot.deepEquals(SessionStorageTests.stored(101), expected);
			if (!ok) {
				logger.debug("stored " + SessionStorageTests.stored(101));
			}
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function pickingAnActivityTypeStoresIt(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var editor = SessionEditorTests.openEditor();
			editor.onActivityTypePicked(null, ActivityType.Yoga);
			editor.onHrvTrackingPicked(null, HrvTracking.Off);
			var stored = SessionStorageTests.stored(101);
			var ok = stored["activityType"] == ActivityType.Yoga && stored["hrvTracking"] == HrvTracking.Off;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	(:test)
	static function anEmptiedProgramIsStoredAsNullAndKeepsTheTime(logger) {
		var snapshot = new StorageSnapshot();
		try {
			var editor = SessionEditorTests.openEditor();
			editor.onBreathProgramChanged(new BreathProgram());
			var stored = SessionStorageTests.stored(101);
			var ok = stored["breathProgram"] == null && stored["time"] == 754;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}

	// opening shows the effective values but writes nothing
	(:test)
	static function openingTheEditorWritesNothing(logger) {
		var snapshot = new StorageSnapshot();
		try {
			SessionStorageTests.writeStore([SessionStorageTests.storedSession(101, null, null)], 0);
			var storage = new SessionStorage();
			var session = storage.loadSelectedSession();
			var menu = AddEditSessionMenuDelegate.createMenu(1);
			var editor = new AddEditSessionMenuDelegate(
				session,
				session.getIntervalAlerts(),
				new SessionSettingsMenuDelegate(storage, new PickerSpy()).method(:onChangeSession),
				menu
			);
			editor.updateMenuItems();
			var activity = OptionMenu.activityTypes();
			var effective = OptionMenu.indexOf(activity[0], session.getActivityType());
			var ok =
				StorageSnapshot.deepEquals(
					SessionStorageTests.stored(101),
					SessionStorageTests.storedSession(101, null, null)
				) &&
				menu.getItem(0).getSubLabel().equals("Evening") &&
				menu.getItem(5).getSubLabel().equals("2") &&
				menu.getItem(6).getSubLabel().equals(Ui.loadResource(activity[1][effective])) &&
				menu.getItem(6).getId() == :activityType;
			snapshot.restore();
			return ok;
		} catch (ex) {
			snapshot.restore();
			throw ex;
		}
	}
}
