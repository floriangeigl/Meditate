using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using HrvAlgorithms.HrvTracking;
using StatusIconFonts;

class AboutDelegate extends ScreenPicker.ScreenPickerDelegate {
	private var mSessionPickerDelegate;

	function initialize(sessionPickerDelegate) {
		ScreenPickerDelegate.initialize(0, 1);
		me.mGlobalSettingsTitle = Ui.loadResource(Rez.Strings.menuSessionSettings_about);
		me.mGlobalSettingsDetailsModel = new ScreenPicker.DetailsModel();
		me.mSessionPickerDelegate = sessionPickerDelegate;
		updateAboutDetails();
	}

	private var mGlobalSettingsTitle;
	private var mGlobalSettingsDetailsModel;

	function createScreenPickerView() {
		return new ScreenPicker.ScreenPickerDetailsView(me.mGlobalSettingsDetailsModel, false);
	}

	private function updateAboutDetails() {
		var details = me.mGlobalSettingsDetailsModel;
		details.title = me.mGlobalSettingsTitle;

		// Application version and developers
		var line = details.getLine(0);
		line.value.text = Ui.loadResource(Rez.Strings.about_AppVersion);
		line.icon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconSpa,
			:color => Gfx.COLOR_BLUE,
		});
		line = details.getLine(1);
		line.value.text = Ui.loadResource(Rez.Strings.about_floriangeigl);
		line = details.getLine(2);
		line.value.text = Ui.loadResource(Rez.Strings.about_vtrifonov);
		line = details.getLine(3);
		line.value.text = Ui.loadResource(Rez.Strings.about_dliedke);
		line = details.getLine(4);
		line.value.text = Ui.loadResource(Rez.Strings.about_falsetru);
	}

	function onBack() {
		Ui.switchToView(me.mSessionPickerDelegate.createScreenPickerView(), me.mSessionPickerDelegate, Ui.SLIDE_RIGHT);
		return true;
	}
}
