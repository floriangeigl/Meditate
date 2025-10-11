using Toybox.WatchUi as Ui;

class MenuOptionsDelegate extends Ui.Menu2InputDelegate {
	function initialize(onMenuItem) {
		Menu2InputDelegate.initialize();
		mOnMenuItem = onMenuItem;
	}

	private var mOnMenuItem;

	function onSelect(item) {
		mOnMenuItem.invoke(item.getId());
	}
}
