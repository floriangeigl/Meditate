using Toybox.WatchUi as Ui;

class HrvProbeDelegate extends Ui.BehaviorDelegate {
	private var mProbe;

	function initialize(probe) {
		BehaviorDelegate.initialize();
		me.mProbe = probe;
	}

	// each launch is one cycle and the app exits by itself; back just ends it early
	function onBack() {
		me.mProbe.shutdown();
		return false;
	}
}
