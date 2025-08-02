using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Application as App;

class DelayedFinishingView extends Ui.View {
	private var mOnShow;
	private var mShouldAutoExit;
	private var viewDrawnTimer;

	function initialize(onShow, shouldAutoExit) {
		View.initialize();
		me.mOnShow = onShow;
		me.mShouldAutoExit = shouldAutoExit;
		me.viewDrawnTimer = null;
	}

	function onViewDrawn() {
		// Exit app if required
		if (me.mShouldAutoExit) {
			System.exit();
		}

		me.mOnShow.invoke();
	}

	function onLayout(dc) {
		setLayout(Rez.Layouts.delayedFinishing(dc));
	}

	function onShow() {
		me.viewDrawnTimer = new Timer.Timer();
		viewDrawnTimer.start(method(:onViewDrawn), 1000, false);
	}

	function onUpdate(dc) {
		View.onUpdate(dc);
	}

	function onHide() {
		me.viewDrawnTimer = null;
	}
}
