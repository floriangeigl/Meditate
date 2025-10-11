using Toybox.WatchUi as Ui;

class EditIntervalAlertsMenuDelegate extends Ui.Menu2InputDelegate {
	private var mEditIntervalAlert;

	function initialize(editIntervalAlert) {
		Menu2InputDelegate.initialize();
		me.mEditIntervalAlert = editIntervalAlert;
	}

	function onSelect(item) {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mEditIntervalAlert.invoke(item.getId().toNumber());
	}
}
