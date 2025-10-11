using Toybox.WatchUi as Ui;

class SessionSettingsMenuDelegate extends Ui.MenuInputDelegate {
	private var mSessionStorage;
	private var mSessionPickerDelegate;

	function initialize(sessionStorage, sessionPickerDelegate) {
		MenuInputDelegate.initialize();
		me.mSessionStorage = sessionStorage;
		me.mSessionPickerDelegate = sessionPickerDelegate;
	}

	function onMenuItem(item) {
		if (item == :addNew) {
			var newSession = me.mSessionStorage.newSession();
			// Build a Menu2 so we can show subtexts with current values
			var menu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) +
				" " +
				me.mSessionStorage.getSessionsCount(),
			});
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), "", :time, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_color), "", :color, {}));
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_vibeSound), "", :vibePattern, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_intervalAlerts), "", :intervalAlerts, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_activityType), "", :activityType, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_hrvTracking), "", :hrvTracking, {})
			);

			var addEditSessionMenuMenuDelegate = new AddEditSessionMenuDelegate(
				newSession,
				newSession.getIntervalAlerts(),
				method(:onChangeSession),
				menu
			);
			addEditSessionMenuMenuDelegate.updateMenuItems();
			me.mSessionPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
			me.mSessionPickerDelegate.select(me.mSessionStorage.getSessionsCount() - 1);
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(menu, addEditSessionMenuMenuDelegate, Ui.SLIDE_LEFT);
		} else if (item == :edit) {
			var existingSession = me.mSessionStorage.loadSelectedSession();
			var menu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) +
				" " +
				(me.mSessionStorage.getSelectedSessionIndex() + 1),
			});
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), "", :time, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_color), "", :color, {}));
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_vibeSound), "", :vibePattern, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_intervalAlerts), "", :intervalAlerts, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_activityType), "", :activityType, {})
			);
			menu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_hrvTracking), "", :hrvTracking, {})
			);

			var addEditSessionMenuMenuDelegate = new AddEditSessionMenuDelegate(
				existingSession,
				existingSession.getIntervalAlerts(),
				method(:onChangeSession),
				menu
			);
			addEditSessionMenuMenuDelegate.updateMenuItems();
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(menu, addEditSessionMenuMenuDelegate, Ui.SLIDE_LEFT);
		} else if (item == :delete) {
			var confirmHeader = Ui.loadResource(Rez.Strings.confirmDeleteSessionHeader);
			var confirmDeleteSessionDialog = new Ui.Confirmation(confirmHeader);
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(confirmDeleteSessionDialog, new YesDelegate(method(:onConfirmedDeleteSession)), Ui.SLIDE_LEFT);
		} else if (item == :globalSettings) {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			var globalSettingsDelegate = new GlobalSettingsDelegate(me.mSessionPickerDelegate);
			// Directly open the Menu2 menu (skip overview screen)
			globalSettingsDelegate.showGlobalSettingsMenu();
		} else if (item == :about) {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			var aboutDelegate = new AboutDelegate(me.mSessionPickerDelegate);
			Ui.switchToView(aboutDelegate.createScreenPickerView(), aboutDelegate, Ui.SLIDE_LEFT);
		}
	}

	private function createAddEditSessionMenu(selectedSessionIndex) {
		// kept for compatibility but we now build a Menu2 programmatically in the caller
		var addEditSessionMenu = new Rez.Menus.addEditSessionMenu();
		var sessionNumber = selectedSessionIndex + 1;
		addEditSessionMenu.setTitle(Ui.loadResource(Rez.Strings.addEditSessionMenu_title) + " " + sessionNumber);
		return addEditSessionMenu;
	}

	function onConfirmedDeleteSession() {
		me.mSessionStorage.deleteSelectedSession();
		me.mSessionPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
		me.mSessionPickerDelegate.select(me.mSessionStorage.getSelectedSessionIndex() - 1);
	}

	function onChangeSession(changedSessionModel) {
		var existingSession = me.mSessionStorage.loadSelectedSession();
		existingSession.copyNonNullFieldsFromSession(changedSessionModel);
		me.mSessionStorage.saveSession(existingSession);
		me.mSessionPickerDelegate.updateSelectedSessionDetails(existingSession);
	}
}
