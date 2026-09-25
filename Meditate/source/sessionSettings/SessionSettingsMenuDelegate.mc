using Toybox.WatchUi as Ui;
using Toybox.Communications;

class SessionSettingsMenuDelegate extends Ui.Menu2InputDelegate {
	private var mSessionStorage;
	private var mSessionPickerDelegate;

	// the root settings menu; start shows the session length, add new the session count
	static function createMenu(sessionStorage) {
		var selected = sessionStorage.loadSelectedSession();
		var items = [
			[:start, Rez.Strings.menuSessionSettings_start, selected != null ? TimeFormatter.format(selected.time) : ""],
			[:edit, Rez.Strings.menuSessionSettings_edit, ""],
			[:delete, Rez.Strings.menuSessionSettings_delete, ""],
			[:addNew, Rez.Strings.menuSessionSettings_addNew, sessionStorage.getSessionsCount().toString()],
			[:globalSettings, Rez.Strings.menuSessionSettings_globalSettings, ""],
			[:help, Rez.Strings.menuSessionSettings_help, ""],
			[:about, Rez.Strings.menuSessionSettings_about, ""],
		];
		var menu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuSessionSettings_Title) });
		for (var i = 0; i < items.size(); i++) {
			menu.addItem(new Ui.MenuItem(Ui.loadResource(items[i][1]), items[i][2], items[i][0], {}));
		}
		return menu;
	}

	function initialize(sessionStorage, sessionPickerDelegate) {
		Menu2InputDelegate.initialize();
		me.mSessionStorage = sessionStorage;
		me.mSessionPickerDelegate = sessionPickerDelegate;
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
			var menu = AddEditSessionMenuDelegate.createMenu(me.mSessionStorage.getSessionsCount());

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
			var menu = AddEditSessionMenuDelegate.createMenu(me.mSessionStorage.getSelectedSessionIndex() + 1);

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
			GlobalSettingsMenuDelegate.show();
		} else if (id == :help) {
			Communications.openWebPage(
				"https://geigl.online/meditate_app_user_guide/",
				{
					"utm_source" => "meditate_app",
					"utm_medium" => "garmin_watch",
					"utm_campaign" => "help",
				},
				null
			);
			if (Ui has :showToast) {
				Ui.showToast(Ui.loadResource(Rez.Strings.help_openingUserGuide), null);
			} else {
				Ui.popView(Ui.SLIDE_IMMEDIATE);
				var helpDelegate = new HelpDelegate(me.mSessionPickerDelegate);
				Ui.switchToView(helpDelegate.createScreenPickerView(), helpDelegate, Ui.SLIDE_LEFT);
			}
		} else if (id == :about) {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
			var aboutDelegate = new AboutDelegate(me.mSessionPickerDelegate);
			Ui.switchToView(aboutDelegate.createScreenPickerView(), aboutDelegate, Ui.SLIDE_LEFT);
		}
	}

	function onConfirmedDeleteSession() {
		me.mSessionStorage.deleteSelectedSession();
		me.mSessionPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
		me.mSessionPickerDelegate.select(me.mSessionStorage.getSelectedSessionIndex());
	}

	// the editor hands over the whole session; it is saved under its own key
	function onChangeSession(session) {
		me.mSessionStorage.saveSession(session);
		me.mSessionPickerDelegate.updateSelectedSessionDetails(session);
	}
}
