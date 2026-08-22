using Toybox.Application as App;

class HrvProbeApp extends App.AppBase {
	private var mProbe;

	function initialize() {
		AppBase.initialize();
		me.mProbe = null;
	}

	function onStart(state) {}

	function onStop(state) {
		if (me.mProbe != null) {
			me.mProbe.shutdown();
		}
	}

	function getInitialView() {
		me.mProbe = new HrvProbe();
		me.mProbe.start();
		return [new HrvProbeView(me.mProbe), new HrvProbeDelegate(me.mProbe)];
	}
}
