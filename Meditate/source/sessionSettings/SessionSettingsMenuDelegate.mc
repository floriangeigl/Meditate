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
		if (id == :addNew) {
			var newSession = me.mSessionStorage.newSession();
			var menu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) +
				" " +
				me.mSessionStorage.getSessionsCount(),
			});
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), "", :time, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_name), "", :name, {}));
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
			var menu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.addEditSessionMenu_title) +
				" " +
				(me.mSessionStorage.getSelectedSessionIndex() + 1),
			});
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_time), "", :time, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditSessionMenu_name), "", :name, {}));
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

		// 0: addNew - show total sessions count
		var sessionsCountText = me.mSessionStorage.getSessionsCount() + "";
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_addNew), sessionsCountText, :addNew, {}),
			0
		);

		// 1: edit - show currently selected session title (or a fallback) as subtext
		var selectedSession = me.mSessionStorage.loadSelectedSession();
		var editSubtext = "";
		if (selectedSession != null) {
			if (selectedSession.getName() != null && selectedSession.getName() != "") {
				editSubtext = selectedSession.getName();
			} else {
				// Fallback: activity type + 1-based index
				var idx = me.mSessionStorage.getSelectedSessionIndex() + 1;
				var act = Ui.loadResource(Rez.Strings.activityNameMeditate);
				if (selectedSession.getActivityType() == ActivityType.Yoga) {
					act = Ui.loadResource(Rez.Strings.activityNameYoga);
				} else if (selectedSession.getActivityType() == ActivityType.Breathing) {
					act = Ui.loadResource(Rez.Strings.activityNameBreathing);
				}
				editSubtext = act + " " + idx;
			}
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_edit), editSubtext, :edit, {}),
			1
		);

		// 2: delete - no subtext
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_delete), "", :delete, {}),
			2
		);

		// 3: globalSettings - no subtext
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_globalSettings), "", :globalSettings, {}),
			3
		);

		// 4: about - no subtext
		me.mMenu.updateItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_about), "", :about, {}), 4);
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
