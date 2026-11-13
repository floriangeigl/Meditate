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

	private static function step(durations, rounds) {
		var step = new BreathStep();
		step.durations = durations;
		step.repeatType = BreathRepeat.Rounds;
		step.repeatValue = rounds;
		return step;
	}

	// the ring and the picker bar tick between steps only, never at start or end
	(:test)
	static function stepTicksSitBetweenSteps(logger) {
		var program = new BreathProgram();
		program.addNew(SessionPagesTests.step([4, 0, 4, 0], 3));
		var single = program.stepBoundaries();
		program.addNew(SessionPagesTests.step([4, 0, 4, 0], 6));
		program.addNew(SessionPagesTests.step([4, 0, 4, 0], 3));
		var ticks = program.stepBoundaries();
		return single == null && ticks.size() == 2 && ticks[0] == 0.25 && ticks[1] == 0.75;
	}

	// hold-only and rest steps get a coloured stretch, breathing steps none
	(:test)
	static function holdsAndRestsAreColouredSpans(logger) {
		var program = new BreathProgram();
		program.addNew(SessionPagesTests.step([4, 0, 4, 0], 5));
		var none = program.specialSpans();
		program.addNew(SessionPagesTests.step([0, 0, 0, 20], 1));
		var rest = new BreathStep();
		rest.durations = [0, 0, 0, 0];
		rest.repeatType = BreathRepeat.Duration;
		rest.repeatValue = 20;
		program.addNew(rest);
		var spans = program.specialSpans();
		return (
			none == null &&
			spans.size() == 6 &&
			spans[0] == 0.5 &&
			spans[1] == 0.75 &&
			spans[2] == BreathProgram.HoldStepColor &&
			spans[3] == 0.75 &&
			spans[4] == 1.0 &&
			spans[5] == BreathProgram.RestStepColor
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
		// opening on zen peeks seconds 0-10 (reaching step 3), then one draw per step 4..99 every 3 s
		return draws == 11 + 96 && view.needsTickRedraw(300);
	}

	// zen's hint line names where up and down lead: both to the metrics in a meditation, ball and metrics in breathwork
	(:test)
	static function zenNamesItsNeighbours(logger) {
		return (
			SessionPagesTests.same(MeditateView.zenNeighbours(MeditateView.pagesFor(false)), [SessionPage.Metrics, SessionPage.Metrics]) &&
			SessionPagesTests.same(MeditateView.zenNeighbours(MeditateView.pagesFor(true)), [SessionPage.Ball, SessionPage.Metrics])
		);
	}

	// a tap on zen brings the time back for a few seconds; on the metrics page it is not handled
	(:test)
	static function tapPeeksOnZen(logger) {
		var dc = SessionPagesTests.screen().getDc();
		// 30 s per percent, so seconds 100-104 stay in one ring step
		var model = SessionPagesTests.model(3000, null);
		var view = new MeditateView(model);
		view.onLayout(dc);
		view.setPage(SessionPage.Zen);
		view.onShow();
		model.elapsedTime = 100;
		view.onUpdate(dc);
		var quietBefore = !view.needsTickRedraw(100);
		var handled = view.onTap();
		var peeking = view.needsTickRedraw(101) && view.needsTickRedraw(103);
		var quietAfter = !view.needsTickRedraw(104);
		view.setPage(SessionPage.Metrics);
		return quietBefore && handled && peeking && quietAfter && !view.onTap();
	}

	// the session arrows sit inside the ring's tick band; the menus keep theirs at the screen edge
	(:test)
	static function arrowsClearTheRing(logger) {
		var dc = SessionPagesTests.screen().getDc();
		var fontHeight = dc.getFontHeight(StatusIconFonts.fontAwesomeFreeSolid);
		var height = dc.getHeight();
		var minDim = dc.getWidth() < height ? dc.getWidth() : height;
		var band = (height - minDim) / 2 + IntervalAlertsRenderer.bandDepth(minDim);
		var view = new MeditateView(SessionPagesTests.model(300, null));
		view.onLayout(dc);
		var session = view.getArrowsY();
		var menu = new ScreenPickerBaseView(true);
		menu.onLayout(dc);
		var edge = menu.getArrowsY();
		logger.debug("session arrows " + session + ", menu arrows " + edge + ", band " + band);
		return (
			edge[0] == fontHeight / 2 &&
			edge[1] == height - fontHeight / 2 &&
			session[0] - fontHeight * 0.2 >= band &&
			session[1] + fontHeight * 0.3 <= height - band
		);
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
