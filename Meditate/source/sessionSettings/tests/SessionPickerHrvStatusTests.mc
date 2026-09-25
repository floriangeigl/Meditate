using Toybox.Test;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

// the picker hrv line driven through the real delegate against a feed that never delivers
(:test)
class SessionPickerHrvStatusTests {
	private static function hrvLine(picker, view) {
		var session = new SessionModel();
		session.time = 60;
		session.setHrvTracking(HrvTracking.On);
		// rebuilds the details the view already holds; the hrv line is the fourth row
		picker.updateSelectedSessionDetails(session);
		return view.mDetailsModel.getLine(3);
	}

	private static function isText(line, id) {
		return line.value.text.equals(Ui.loadResource(id));
	}

	(:test)
	static function startingThenRestartThenReady(logger) {
		App.getApp().beatIntervalFeed.discardWakeupSession();
		var feed = new BeatIntervalFeed();
		var picker = new SessionPickerDelegate(new SessionStorage(), feed);
		var view = picker.createScreenPickerView();
		var line = hrvLine(picker, view);
		// every details rebuild polls one error second; the two starting texts alternate in 2s blocks
		var errors = feed.errorSeconds();
		var alt = ((errors - 1) / 2) % 2 == 1;
		if (errors < 1 || !isText(line, alt ? Rez.Strings.HRVstartingAlt : Rez.Strings.HRVstarting)) {
			return false;
		}
		if (!(line.icon instanceof LoadingIcon)) {
			return false;
		}
		// past 18 error seconds the hint is a restart, and it stays
		for (var i = 0; i < 20; i++) {
			picker.updateHrvStatus([]);
		}
		if (feed.errorSeconds() != errors + 20 || !isText(line, Rez.Strings.HRVrestart)) {
			return false;
		}
		for (var i = 0; i < 45; i++) {
			picker.updateHrvStatus([]);
		}
		if (feed.errorSeconds() != errors + 65 || !isText(line, Rez.Strings.HRVrestart)) {
			return false;
		}
		// beats arrive: weak, then good with the ready blip and a reset counter
		feed.update(new FakeSensorData([1000]));
		picker.updateHrvStatus([1000]);
		if (!isText(line, Rez.Strings.HRVweak) || !(line.icon instanceof HrvIcon)) {
			return false;
		}
		feed.update(new FakeSensorData([1000]));
		picker.updateHrvStatus([1000]);
		var ready = isText(line, Rez.Strings.HRVready) && feed.errorSeconds() == 0;
		feed.shutdown();
		return ready;
	}
}
