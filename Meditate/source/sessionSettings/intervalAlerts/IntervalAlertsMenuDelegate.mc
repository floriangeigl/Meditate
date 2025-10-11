using Toybox.WatchUi as Ui;
using Toybox.Lang;

class IntervalAlertsMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnIntervalAlertsChanged;
	private var mIntervalAlerts;
	private var mMenu;
	private var mEditIntervalAlertsMenu;

	function initialize(intervalAlerts, onIntervalAlertsChanged, menu) {
		Menu2InputDelegate.initialize();
		me.mIntervalAlerts = intervalAlerts;
		me.mOnIntervalAlertsChanged = onIntervalAlertsChanged;
		me.mMenu = menu;
	}

	// Menu2 selection handler
	function onSelect(item) {
		var id = item.getId();
		if (id == :addNew) {
			me.editIntervalAlert(me.mIntervalAlerts.addNew());
		} else if (id == :edit) {
			if (me.mIntervalAlerts.size() == 0) {
				return;
			}
			var editIntervalAlertsMenu = new Ui.Menu2({
				:title => Ui.loadResource(Rez.Strings.editIntervalAlertsMenu_title),
			});
			// keep a reference so we can refresh items after edits
			me.mEditIntervalAlertsMenu = editIntervalAlertsMenu;

			for (var i = 0; i < me.mIntervalAlerts.size(); i++) {
				var intervalAlert = me.mIntervalAlerts.get(i);
				var typeText;
				if (intervalAlert.type == IntervalAlertType.OneOff) {
					typeText = Ui.loadResource(Rez.Strings.intervalTypeMenu_oneOff);
					editIntervalAlertsMenu.addItem(
						new Ui.MenuItem(
							Lang.format("$1$ $2$", [typeText, TimeFormatter.format(intervalAlert.time)]),
							"",
							i,
							{}
						)
					);
				} else {
					typeText = Ui.loadResource(Rez.Strings.intervalTypeMenu_repeat);
					editIntervalAlertsMenu.addItem(
						new Ui.MenuItem(
							Lang.format("$1$ $2$", [typeText, TimeFormatter.formatMinSec(intervalAlert.time)]),
							"",
							i,
							{}
						)
					);
				}
			}

			var editIntervalAlertsMenuDelegate = new EditIntervalAlertsMenuDelegate(method(:editIntervalAlert));
			Ui.pushView(editIntervalAlertsMenu, editIntervalAlertsMenuDelegate, Ui.SLIDE_LEFT);
		} else if (id == :deleteAll) {
			if (me.mIntervalAlerts.size() == 0) {
				return;
			}
			var confirmDeleteAllIntervalAlertsHeader = Ui.loadResource(
				Rez.Strings.confirmDeleteAllIntervalAlertsHeader
			);
			var confirmDeleteAllDialog = new Ui.Confirmation(confirmDeleteAllIntervalAlertsHeader);
			Ui.pushView(
				confirmDeleteAllDialog,
				new YesDelegate(method(:onConfirmedDeleteAllIntervalAlerts)),
				Ui.SLIDE_IMMEDIATE
			);
		}
	}

	function onDeleteIntervalAlert(intervalAlertIndex) {
		me.mIntervalAlerts.delete(intervalAlertIndex);
		me.mOnIntervalAlertsChanged.invoke(me.mIntervalAlerts);
	}

	function editIntervalAlert(selectedIntervalAlertIndex) {
		me.mOnIntervalAlertsChanged.invoke(me.mIntervalAlerts);
		var selectedIntervalAlert = me.mIntervalAlerts.get(selectedIntervalAlertIndex);
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_title) +
			" " +
			(selectedIntervalAlertIndex + 1),
		});
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_vibeSound), "", :vibePattern, {})
		);
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_time), "", :time, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_offset), "", :offset, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_color), "", :color, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_delete), "", :delete, {}));

		var intervalAlertMenuDelegate = new AddEditIntervalAlertMenuDelegate(
			selectedIntervalAlert,
			selectedIntervalAlertIndex,
			method(:onIntervalAlertChanged),
			method(:onDeleteIntervalAlert),
			menu
		);
		intervalAlertMenuDelegate.updateMenuItems();
		Ui.pushView(menu, intervalAlertMenuDelegate, Ui.SLIDE_LEFT);
	}

	function onConfirmedDeleteAllIntervalAlerts() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mIntervalAlerts.reset();
		me.mOnIntervalAlertsChanged.invoke(me.mIntervalAlerts);
	}

	function onIntervalAlertChanged(intervalAlertIndex, intervalAlert) {
		me.mIntervalAlerts.set(intervalAlertIndex, intervalAlert);

		// If the edit list is visible, refresh the specific item so the summary updates
		if (me.mEditIntervalAlertsMenu != null) {
			var updatedAlert = me.mIntervalAlerts.get(intervalAlertIndex);
			var typeText;
			if (updatedAlert.type == IntervalAlertType.OneOff) {
				typeText = Ui.loadResource(Rez.Strings.intervalTypeMenu_oneOff);
				me.mEditIntervalAlertsMenu.updateItem(
					new Ui.MenuItem(
						Lang.format("$1$ $2$", [typeText, TimeFormatter.format(updatedAlert.time)]),
						"",
						intervalAlertIndex,
						{}
					),
					intervalAlertIndex
				);
			} else {
				typeText = Ui.loadResource(Rez.Strings.intervalTypeMenu_repeat);
				me.mEditIntervalAlertsMenu.updateItem(
					new Ui.MenuItem(
						Lang.format("$1$ $2$", [typeText, TimeFormatter.formatMinSec(updatedAlert.time)]),
						"",
						intervalAlertIndex,
						{}
					),
					intervalAlertIndex
				);
			}
		}

		me.mOnIntervalAlertsChanged.invoke(me.mIntervalAlerts);
	}

	// Allow callers to ask the delegate to refresh its root Menu2 subtexts
	function updateMenuItems() {
		if (me.mMenu == null) {
			return;
		}
		var count = 0;
		if (me.mIntervalAlerts != null) {
			count = me.mIntervalAlerts.size();
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuIntervalAlertSettings_addNew), count + "", :addNew, {}),
			0
		);
	}
}
