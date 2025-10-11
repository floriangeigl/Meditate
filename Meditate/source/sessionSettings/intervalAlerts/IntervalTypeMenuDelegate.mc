using Toybox.WatchUi as Ui;

class IntervalTypeMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnTypeChanged;

	function initialize(onTypeChanged) {
		Menu2InputDelegate.initialize();
		me.mOnTypeChanged = onTypeChanged;
	}

	// Menu2 selection handler
	function onSelect(item) {
		if (item.getId() == :oneOff) {
			// Pop this menu first so the parent is visible when it refreshes its subtexts
			Ui.popView(Ui.SLIDE_RIGHT);
			me.mOnTypeChanged.invoke(IntervalAlertType.OneOff);
		} else if (item.getId() == :repeat) {
			// Pop this menu first so the parent is visible when it refreshes its subtexts
			Ui.popView(Ui.SLIDE_RIGHT);
			me.mOnTypeChanged.invoke(IntervalAlertType.Repeat);
		}
	}
}
