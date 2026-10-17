using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class HelpDelegate extends ScreenPickerDelegate {
	private var mSessionPickerDelegate;

	function initialize(sessionPickerDelegate) {
		ScreenPickerDelegate.initialize(0, 1);
		me.mSessionPickerDelegate = sessionPickerDelegate;

		me.mDetailsModel = new DetailsModel();
		me.mDetailsModel.title = Ui.loadResource(Rez.Strings.menuSessionSettings_help);

		var line = me.mDetailsModel.getLine(0);
		line.value.text = Ui.loadResource(Rez.Strings.help_openingUserGuide);
		line.icon = new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconInfo,
			:color => Gfx.COLOR_BLUE,
		});
	}

	private var mDetailsModel;

	function createScreenPickerView() {
		return new ScreenPickerDetailsView(me.mDetailsModel, false);
	}

	function onBack() {
		Ui.switchToView(me.mSessionPickerDelegate.createScreenPickerView(), me.mSessionPickerDelegate, Ui.SLIDE_RIGHT);
		return true;
	}

	function onSelect() {
		return onBack();
	}
}
