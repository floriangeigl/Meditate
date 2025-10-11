using Toybox.WatchUi as Ui;

class EditIntervalAlertsMenuDelegate extends Ui.Menu2InputDelegate {
	private var mEditIntervalAlert; // callback to open specific alert index
	private var mOnDismiss; // callback when this edit list menu is dismissed

	function initialize(editIntervalAlert, onDismiss) {
		Menu2InputDelegate.initialize();
		me.mEditIntervalAlert = editIntervalAlert;
		me.mOnDismiss = onDismiss;
	}

	function onSelect(item) {
		// Pop this edit list and notify parent so it can clear any references
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		if (me.mOnDismiss != null) {
			me.mOnDismiss.invoke();
		}
		me.mEditIntervalAlert.invoke(item.getId().toNumber());
	}

	// Ensure we also notify when user backs out without selecting
	function onBack() {
		if (me.mOnDismiss != null) {
			me.mOnDismiss.invoke();
		}
		Menu2InputDelegate.onBack();
		return false;
	}
}
