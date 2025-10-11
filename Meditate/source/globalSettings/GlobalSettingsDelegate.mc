using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using HrvAlgorithms.HrvTracking;

class GlobalSettingsDelegate {
	private var mSessionPickerDelegate;

	function initialize(sessionPickerDelegate) {
		me.mSessionPickerDelegate = sessionPickerDelegate;
	}

	function showGlobalSettingsMenu() {
		// Build a Menu2 programmatically so we can set sublabels showing the current values
		var menu = new Ui.Menu2({:title => Ui.loadResource(Rez.Strings.menuGlobalSettings_title)});

		// Add placeholder items; sublabels will be updated by the delegate
		// Note: order matches resources/menus/globalSettings/globalSettingsMenu.xml
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_colorTheme), "", :colorTheme, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_autoStop), "", :autoStop, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_confirmSaveActivity), "", :confirmSaveActivity, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_prepareTime), "", :prepareTime, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_finalizeTime), "", :finalizeTime, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuNotificationOptions_title), "", :notification, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_newActivityType), "", :newActivityType, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_useSessionName), "", :useSessionName, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_newHrvTracking), "", :hrvTracking, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuHrvWindowSizeOptions_title), "", :hrvWindow, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_respirationRate), "", :respirationRate, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_multiSession), "", :multiSession, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuGlobalSettings_externalSensor), "", :externalSensor, {}));

		var delegate = new GlobalSettingsMenuDelegate(method(:onGlobalSettingsChanged), menu);
		// Initialize sublabels now
		delegate.updateMenuItems();

		Ui.pushView(menu, delegate, Ui.SLIDE_LEFT);
	}

	function onBack() {
		Ui.switchToView(me.mSessionPickerDelegate.createScreenPickerView(), me.mSessionPickerDelegate, Ui.SLIDE_RIGHT);
		return true;
	}

	function onGlobalSettingsChanged() {
		// overview removed; nothing to update here. Keep a requestUpdate in case callers expect UI refresh
		Ui.requestUpdate();
	}
}
