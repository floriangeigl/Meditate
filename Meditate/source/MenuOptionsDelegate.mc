using Toybox.WatchUi as Ui;

class MenuOptionsDelegate extends Ui.Menu2InputDelegate {
	function initialize(onMenuItem) {
		Menu2InputDelegate.initialize();
		mOnMenuItem = onMenuItem;
	}

	private var mOnMenuItem;

	function onSelect(item) {
		// Pop this options view first so the parent menu is visible when it updates
		Ui.popView(Ui.SLIDE_RIGHT);
		mOnMenuItem.invoke(item.getId());
	}
}
