using Toybox.WatchUi as Ui;

module ScreenPicker {
	class ScreenPickerDelegate extends Ui.BehaviorDelegate {
		protected var mSelectedPageIndex;
		protected var mPagesCount;

		function initialize(selectedPageIndex, pagesCount) {
			BehaviorDelegate.initialize();
			me.mSelectedPageIndex = selectedPageIndex;
			me.mPagesCount = pagesCount;
		}

		function createScreenPickerView() {}

		function setPagesCount(pagesCount) {
			me.mPagesCount = pagesCount;
			me.setPageIndex(me.mSelectedPageIndex);
		}

		function select(pageIndex) {
			me.setPageIndex(pageIndex);
			Ui.switchToView(me.createScreenPickerView(), me, Ui.SLIDE_IMMEDIATE);
		}

		function onNextPage() {
			me.changePage(+1);
		}

		function onPreviousPage() {
			me.changePage(-1);
		}

		private function changePage(change) {
			if (me.mPagesCount == 0) {
				me.mSelectedPageIndex = null;
			} else {
				me.setPageIndex(me.mSelectedPageIndex + change);
			}
			var slide = change > 0 ? Ui.SLIDE_UP : Ui.SLIDE_DOWN;
			Ui.switchToView(me.createScreenPickerView(), me, slide);
			return true;
		}

		function setPageIndex(index) {
			me.mSelectedPageIndex = index % me.mPagesCount;
			if (me.mSelectedPageIndex < 0) {
				me.mSelectedPageIndex = me.mPagesCount - 1;
			}
		}
	}
}
