using Toybox.WatchUi as Ui;

class SessionSettingsMenuDelegate extends Ui.Menu2InputDelegate {
	private var mSessionStorage;
	private var mSessionPickerDelegate;
	private var mMenu;

	function initialize(sessionStorage, sessionPickerDelegate, menu) {
		Menu2InputDelegate.initialize();
		me.mSessionStorage = sessionStorage;
		me.mSessionPickerDelegate = sessionPickerDelegate;
		me.mMenu = menu;
	}

	// handle selections via Menu2's MenuItem
	function onSelect(item) {
		var id = item.getId();
		if (id == :start) {
			if (me.mSessionStorage.getSessionsCount() == 0) {
				return;
			}
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			me.mSessionPickerDelegate.startActivity();
		} else if (id == :addNew) {
			var newSession = me.mSessionStorage.newSession();
			var menu = me.createAddEditSessionMenu(me.mSessionStorage.getSessionsCount() - 1);

			var addEditDelegate = new AddEditSessionMenuDelegate(
				newSession,
				newSession.getIntervalAlerts(),
				method(:onChangeSession),
				menu
			);
			addEditDelegate.updateMenuItems();
			me.mSessionPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
			me.mSessionPickerDelegate.select(me.mSessionStorage.getSessionsCount() - 1);
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(menu, addEditDelegate, Ui.SLIDE_LEFT);
		} else if (id == :edit) {
			if (me.mSessionStorage.getSessionsCount() == 0) {
				return;
			}
			var existingSession = me.mSessionStorage.loadSelectedSession();
			var menu = me.createAddEditSessionMenu(me.mSessionStorage.getSelectedSessionIndex());

			var addEditDelegate = new AddEditSessionMenuDelegate(
				existingSession,
				existingSession.getIntervalAlerts(),
				method(:onChangeSession),
				menu
			);
			addEditDelegate.updateMenuItems();
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(menu, addEditDelegate, Ui.SLIDE_LEFT);
		} else if (id == :delete) {
			if (me.mSessionStorage.getSessionsCount() == 0) {
				return;
			}
			var confirmHeader = Ui.loadResource(Rez.Strings.confirmDeleteSessionHeader);
			var confirmDeleteSessionDialog = new Ui.Confirmation(confirmHeader);
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			Ui.pushView(confirmDeleteSessionDialog, new YesDelegate(method(:onConfirmedDeleteSession)), Ui.SLIDE_LEFT);
		} else if (id == :globalSettings) {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			var globalSettingsDelegate = new GlobalSettingsDelegate(me.mSessionPickerDelegate);
			globalSettingsDelegate.showGlobalSettingsMenu();
		} else if (id == :about) {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			var aboutDelegate = new AboutDelegate(me.mSessionPickerDelegate);
			Ui.switchToView(aboutDelegate.createScreenPickerView(), aboutDelegate, Ui.SLIDE_LEFT);
		}
	}

	// update the root session settings menu subtexts (if a Menu2 was provided)
	function updateMenuItems() {
		if (me.mMenu == null) {
			return;
		}
		// Build subtexts: we'll show counts and selection hints where possible
		// Item indices correspond to the original menu resource order

		// 0: start - show duration as subtext if available
		var selectedSession = me.mSessionStorage.loadSelectedSession();
		var startSubtext = "";
		if (selectedSession != null) {
			startSubtext = TimeFormatter.format(selectedSession.time);
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_start), startSubtext, :start, {}),
			0
		);

		// 1: edit - no subtext
		me.mMenu.updateItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_edit), "", :edit, {}), 1);

		// 2: delete - no subtext
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_delete), "", :delete, {}),
			2
		);

		// 3: addNew - show total sessions count
		var sessionsCountText = me.mSessionStorage.getSessionsCount() + "";
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_addNew), sessionsCountText, :addNew, {}),
			3
		);

		// 4: globalSettings - no subtext
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_globalSettings), "", :globalSettings, {}),
			4
		);

		// 5: about - no subtext
		me.mMenu.updateItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_about), "", :about, {}), 5);
	}

	private function createAddEditSessionMenu(selectedSessionIndex) {
		// Build a Menu2 programmatically for compatibility with Menu2 delegates
		var sessionNumber = selectedSessionIndex + 1;
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) + " " + sessionNumber,
		});
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), "", :time, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_name), "", :name, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_color), "", :color, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_vibeSound), "", :vibePattern, {}));
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_intervalAlerts), "", :intervalAlerts, {})
		);
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_activityType), "", :activityType, {})
		);
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_hrvTracking), "", :hrvTracking, {})
		);
		return menu;
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
