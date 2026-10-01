using Toybox.Test;
using Toybox.Graphics;
using Toybox.System;

// the running session's pages: which exist, where a session opens, how up/down move, how often they draw
(:test)
class SessionPagesTests {
	private static function same(pages, expected) {
		if (pages.size() != expected.size()) {
			return false;
		}
		for (var i = 0; i < pages.size(); i++) {
			if (pages[i] != expected[i]) {
				return false;
			}
		}
		return true;
	}

	// a running session of that length; a null program is a meditation
	private static function model(time, program) {
		var session = new SessionModel();
		session.time = time;
		session.color = 0xff0000;
		if (program != null) {
			session.setBreathProgram(program);
		}
		var model = new MeditateModel(session);
		model.liveMetrics = [new HrMetric()];
		model.isTimerRunning = true;
		return model;
	}

	private static function view(hasProgram) {
		var program = hasProgram ? BreathTemplates.createProgram(:box5) : null;
		return new MeditateView(SessionPagesTests.model(300, program));
	}

	private static function screen() {
		var settings = System.getDeviceSettings();
		var options = { :width => settings.screenWidth, :height => settings.screenHeight };
		if (Graphics has :createBufferedBitmap) {
			return Graphics.createBufferedBitmap(options).get();
		}
		return new Graphics.BufferedBitmap(options);
	}

	(:test)
	static function breathworkHasFourPagesMeditationTwo(logger) {
		return (
			SessionPagesTests.same(
				MeditateView.pagesFor(true),
				[SessionPage.Guidance, SessionPage.Ball, SessionPage.Zen, SessionPage.Metrics]
			) && SessionPagesTests.same(MeditateView.pagesFor(false), [SessionPage.Metrics, SessionPage.Zen])
		);
	}

	// a stored page the session has is kept; anything else opens the first page
	(:test)
	static function opensOnTheStoredPageItHas(logger) {
		var meditation = SessionPagesTests.view(false);
		meditation.setPage(SessionPage.Zen);
		var zen = meditation.getPage();
		meditation.setPage(SessionPage.Ball);
		var noBall = meditation.getPage();
		meditation.setPage(null);
		var nothingStored = meditation.getPage();
		var breathwork = SessionPagesTests.view(true);
		breathwork.setPage(SessionPage.Metrics);
		return (
			zen == SessionPage.Zen &&
			noBall == SessionPage.Metrics &&
			nothingStored == SessionPage.Metrics &&
			breathwork.getPage() == SessionPage.Metrics
		);
	}

	// kept off the ball page: entering it starts the frame timer
	(:test)
	static function upAndDownWrap(logger) {
		var breathwork = SessionPagesTests.view(true);
		breathwork.setPage(SessionPage.Metrics);
		breathwork.switchPage(1);
		var wrappedForward = breathwork.getPage();
		breathwork.switchPage(-1);
		var wrappedBack = breathwork.getPage();
		var meditation = SessionPagesTests.view(false);
		meditation.switchPage(-1);
		return (
			wrappedForward == SessionPage.Guidance &&
			wrappedBack == SessionPage.Metrics &&
			meditation.getPage() == SessionPage.Zen
		);
	}

	// zen draws once per percent of the session and during the peek, not every second
	(:test)
	static function zenRedrawsOncePerPercent(logger) {
		var screen = SessionPagesTests.screen();
		var dc = screen.getDc();
		var model = SessionPagesTests.model(300, null);
		var view = new MeditateView(model);
		view.onLayout(dc);
		view.setPage(SessionPage.Zen);
		view.onShow();
		var draws = 0;
		for (var t = 0; t < 300; t++) {
			model.elapsedTime = t;
			if (view.needsTickRedraw(t)) {
				view.onUpdate(dc);
				draws++;
			}
		}
		view.setPage(SessionPage.Metrics);
		// the peek draws seconds 0-3 (reaching step 1), then one draw per step 2..99 every 3 s
		return draws == 4 + 98 && view.needsTickRedraw(300);
	}

	// every page, and the ball through each phase, a rest and past the program's end, draws without error
	(:test)
	static function everyPageDraws(logger) {
		var screen = SessionPagesTests.screen();
		var dc = screen.getDc();
		var rest = new BreathStep();
		rest.durations = [0, 0, 0, 0];
		rest.repeatType = BreathRepeat.Duration;
		rest.repeatValue = 10;
		var program = new BreathProgram();
		program.addNew(BreathTemplates.createStep(:box));
		program.addNew(rest);

		var programs = [null, program];
		for (var s = 0; s < programs.size(); s++) {
			var model = SessionPagesTests.model(74, programs[s]);
			var view = new MeditateView(model);
			view.onLayout(dc);
			view.onShow();
			var pages = MeditateView.pagesFor(programs[s] != null);
			for (var p = 0; p < pages.size(); p++) {
				view.setPage(pages[p]);
				for (var t = 0; t <= 80; t++) {
					model.elapsedTime = t;
					model.updateBreathRunner();
					view.onSessionTick();
					view.onUpdate(dc);
					if (pages[p] == SessionPage.Ball) {
						view.onFrame();
					}
				}
			}
			view.onHide();
		}
		return true;
	}
}
