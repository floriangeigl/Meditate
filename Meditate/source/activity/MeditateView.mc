using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.System;
using Toybox.Timer;

// one metrics page row: hourglass with countdown until the first value, then the metric icon
class MetricLine {
	var metric;
	private var mLine;
	private var mIcon;
	private var mLoadingIcon;
	private var mLoaded;

	function initialize(metric, line, icon) {
		me.metric = metric;
		me.mLine = line;
		me.mIcon = icon;
		me.mLoadingIcon = new LoadingIcon({});
		me.mLoaded = false;
		me.mLine.icon = me.mLoadingIcon;
	}

	function update(value, elapsed) {
		me.mLine.value.text = ScreenPickerBaseView.formatValue(value);
		if (value != null) {
			me.mLoaded = true;
			me.mLine.icon = me.mIcon;
			me.mIcon.setLive(value);
			me.mLine.value.color = null;
		} else if (me.mLoaded) {
			me.mIcon.setColorInactive();
		} else {
			me.mLoadingIcon.tick();
			var remain = me.metric.getLoadTime() - elapsed;
			if (remain > 0) {
				me.mLine.value.text = remain.toNumber().toString();
			}
			me.mLine.value.color = Gfx.COLOR_LT_GRAY;
		}
	}
}

class MeditateView extends ScreenPickerDetailsCenterView {
	private var mMeditateModel;
	private var mMainDurationRenderer;
	private var mIntervalAlertsRenderer;
	private var mLines;
	private var mBreathGuidanceRenderer;
	private var mBreathStepPercentages;
	private var mBreathStepSpans;
	private var mBallRenderer;
	private var mPages;
	private var mPageIndex;
	private var mForceRedraw;
	private var mPeekUntil;
	private var mTickElapsed;
	private var mTickMs;
	private var mZenDrawnStep;
	private var mFrameTimer;
	private var mFramesRunning;

	private var mTapHint;
	private var mZenNav;

	private const PeekSeconds = 3;
	// opening on zen shows the time longer, so a session left on zen does not look stopped
	private const OpenPeekSeconds = 10;
	// how far the visible caret reaches from the icon's centre, as a fraction of the icon font height
	// (fontAwesomeFreeSolid.fnt: up caret rows 7-15, down caret rows 10-18 of 23, centre 11.5)
	private const UpCaretTop = 0.2;
	private const DownCaretBottom = 0.3;
	private const ArrowGap = 2;
	// zen redraws once per percent of the session
	private const ZenSteps = 100;
	// the ball redraws only once it moved a whole pixel, so this caps the frame rate
	private const FrameMs = 66;

	function initialize(meditateModel) {
		// every session has a second page; the up/down chevrons are the affordance
		ScreenPickerDetailsCenterView.initialize(meditateModel, true);
		me.mMeditateModel = meditateModel;
		me.mMainDurationRenderer = null;
		me.mIntervalAlertsRenderer = null;
		me.mLines = null;
		me.mBreathGuidanceRenderer = null;
		me.mBreathStepPercentages = null;
		me.mBreathStepSpans = null;
		me.mBallRenderer = null;
		me.mPages = MeditateView.pagesFor(meditateModel.hasBreathProgram());
		me.mPageIndex = 0;
		me.mForceRedraw = false;
		me.mPeekUntil = 0;
		me.mTickElapsed = -1;
		me.mTickMs = System.getTimer();
		me.mZenDrawnStep = -1;
		me.mFrameTimer = null;
		me.mFramesRunning = false;
		me.mTapHint = System.getDeviceSettings().isTouchScreen ? Ui.loadResource(Rez.Strings.zen_tapForTime) : null;
		me.mZenNav = MeditateView.zenNavParts(MeditateView.zenNeighbours(me.mPages));
		me.applyPage();
	}

	// the pages up and down lead to from zen
	static function zenNeighbours(pages) {
		var count = pages.size();
		for (var i = 0; i < count; i++) {
			if (pages[i] == SessionPage.Zen) {
				return [pages[(i - 1 + count) % count], pages[(i + 1) % count]];
			}
		}
		return null;
	}

	// glyph and word pieces of zen's "where up/down go" line: "▲▼ Stats", or "▲ Ball  ▼ Stats"
	private static function zenNavParts(neighbours) {
		var up = Ui.loadResource(Rez.Strings.IconUp);
		var down = Ui.loadResource(Rez.Strings.IconDown);
		if (neighbours[0] == neighbours[1]) {
			return [up, "", down, " " + MeditateView.pageName(neighbours[1])];
		}
		return [up, " " + MeditateView.pageName(neighbours[0]) + "   ", down, " " + MeditateView.pageName(neighbours[1])];
	}

	// only the ball and metrics pages sit next to zen
	private static function pageName(page) {
		return Ui.loadResource(page == SessionPage.Ball ? Rez.Strings.zen_pageBall : Rez.Strings.zen_pageStats);
	}

	// The menus' edge position puts the carets on the session ring and its alert ticks, so here they
	// sit just inside the ring's tick band. The menus keep the edge position (base layoutArrows).
	function layoutArrows(dc) {
		ScreenPickerBaseView.layoutArrows(dc);
		var fontHeight = dc.getFontHeight(StatusIconFonts.fontAwesomeFreeSolid);
		var minDim = me.width < me.height ? me.width : me.height;
		var bandBottom = (me.height - minDim) / 2 + IntervalAlertsRenderer.bandDepth(minDim);
		me.placeArrows(
			bandBottom + ArrowGap + fontHeight * UpCaretTop,
			me.height - bandBottom - ArrowGap - fontHeight * DownCaretBottom
		);
	}

	// the page cycle: down steps forward, up back, both wrap
	static function pagesFor(hasProgram) {
		if (hasProgram) {
			return [SessionPage.Guidance, SessionPage.Ball, SessionPage.Zen, SessionPage.Metrics];
		}
		return [SessionPage.Metrics, SessionPage.Zen];
	}

	// the one icon per metric id, shared with the summary details page
	static function createIcon(id) {
		if (id == :hrv) {
			return new HrvIcon({});
		} else if (id == :stress) {
			return new StressIcon({});
		} else if (id == :rr) {
			return new BreathIcon({});
		}
		return new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconHeart,
			:color => Gfx.COLOR_RED,
		});
	}

	// Load your resources here
	function onLayout(dc) {
		ScreenPickerDetailsCenterView.onLayout(dc);

		// lines survive a re-layout so a loaded metric does not fall back to the hourglass
		if (me.mLines == null) {
			me.mLines = [];
			var metrics = me.mMeditateModel.liveMetrics;
			for (var i = 0; i < metrics.size(); i++) {
				var icon = MeditateView.createIcon(metrics[i].id);
				me.mLines.add(new MetricLine(metrics[i], me.mMeditateModel.getLine(i), icon));
			}
		}

		me.mMainDurationRenderer = new ElapsedDurationRenderer(me.mMeditateModel.getColor(), null, null);

		var hasIntervalAlerts = me.mMeditateModel.hasIntervalAlerts();
		if (hasIntervalAlerts || me.mMeditateModel.hasBreathProgram()) {
			me.mIntervalAlertsRenderer = new IntervalAlertsRenderer(
				dc,
				me.mMeditateModel.getSessionTime(),
				hasIntervalAlerts ? me.mMeditateModel.getIntervalAlerts() : null
			);
		}

		if (me.mMeditateModel.hasBreathProgram()) {
			me.mBreathGuidanceRenderer = new BreathGuidanceRenderer(dc, me.foregroundColor);
			var program = me.mMeditateModel.getBreathRunner().getProgram();
			me.mBreathStepPercentages = program.stepBoundaries();
			me.mBreathStepSpans = program.specialSpans();
		}
	}

	function getPage() {
		return me.mPages[me.mPageIndex];
	}

	// the page to open on; one this session does not have (or nothing stored) opens the first
	function setPage(page) {
		me.mPageIndex = 0;
		for (var i = 0; i < me.mPages.size(); i++) {
			if (me.mPages[i] == page) {
				me.mPageIndex = i;
			}
		}
		me.applyPage();
	}

	function switchPage(step) {
		var count = me.mPages.size();
		me.mPageIndex = (me.mPageIndex + step + count) % count;
		me.applyPage();
		me.startPeek();
		// the 1 Hz gate below would otherwise swallow a switch made within the same second
		me.mForceRedraw = true;
		if (me.getPage() == SessionPage.Ball) {
			me.startFrames();
		} else {
			me.stopFrames();
		}
	}

	// arrows readable on the always-black pages; the ball is only made once it is visited
	private function applyPage() {
		var page = me.getPage();
		me.setArrowsColor(page == SessionPage.Ball || page == SessionPage.Zen ? Gfx.COLOR_LT_GRAY : null);
		if (page == SessionPage.Ball && me.mBallRenderer == null) {
			me.mBallRenderer = new BreathBallRenderer();
		}
	}

	private function startPeek() {
		me.mPeekUntil = me.mMeditateModel.elapsedTime + PeekSeconds;
	}

	// a tap on the dark pages brings the time and arrows back; the other pages show them anyway
	function onTap() {
		var page = me.getPage();
		if (page != SessionPage.Zen && page != SessionPage.Ball) {
			return false;
		}
		me.startPeek();
		Ui.requestUpdate();
		return true;
	}

	function onShow() {
		me.startPeek();
		if (me.getPage() == SessionPage.Zen) {
			me.mPeekUntil = me.mMeditateModel.elapsedTime + OpenPeekSeconds;
		}
		if (me.getPage() == SessionPage.Ball) {
			me.startFrames();
		}
	}

	// the pause menu and the finish flow both hide this view
	function onHide() {
		me.stopFrames();
	}

	// every recorder tick: note when the second began, and redraw unless zen shows nothing new
	function onSessionTick() {
		var elapsed = me.mMeditateModel.elapsedTime;
		if (elapsed != me.mTickElapsed) {
			me.mTickElapsed = elapsed;
			me.mTickMs = System.getTimer();
		}
		if (me.needsTickRedraw(elapsed)) {
			Ui.requestUpdate();
		}
	}

	// zen redraws only when its ring crosses a whole percent or while the peek shows
	function needsTickRedraw(elapsed) {
		return me.getPage() != SessionPage.Zen || elapsed <= me.mPeekUntil || me.zenStep(elapsed) != me.mZenDrawnStep;
	}

	private function zenStep(elapsed) {
		var total = me.mMeditateModel.getSessionTime();
		return total < 1 ? elapsed : ((elapsed % total) * ZenSteps) / total;
	}

	private function startFrames() {
		if (me.mFramesRunning) {
			return;
		}
		if (me.mFrameTimer == null) {
			me.mFrameTimer = new Timer.Timer();
		}
		me.mFrameTimer.start(method(:onFrame), FrameMs, true);
		me.mFramesRunning = true;
	}

	private function stopFrames() {
		if (me.mFramesRunning) {
			me.mFrameTimer.stop();
			me.mFramesRunning = false;
		}
	}

	// ball page only; no frames while paused or while the display is off
	function onFrame() {
		if (!me.mMeditateModel.isTimerRunning) {
			return;
		}
		if (System has :getDisplayMode && System.getDisplayMode() != System.DISPLAY_MODE_HIGH_POWER) {
			return;
		}
		if (me.mBallRenderer.needsRedraw(me.mMeditateModel.getBreathRunner(), me.secondFraction())) {
			Ui.requestUpdate();
		}
	}

	// how far into the current recording second, so the ball moves between ticks
	private function secondFraction() {
		var fraction = (System.getTimer() - me.mTickMs) / 1000.0;
		return fraction > 1 ? 1.0 : (fraction < 0 ? 0.0 : fraction);
	}

	var lastElapsedTime = -1;

	// ball and zen gate their redraws where they are requested; the other pages redraw once a second
	function onUpdate(dc) {
		var elapsedTime = me.mMeditateModel.elapsedTime;
		var page = me.getPage();
		if (page == SessionPage.Ball) {
			me.drawBallPage(dc, elapsedTime);
		} else if (page == SessionPage.Zen) {
			me.drawZenPage(dc, elapsedTime);
		} else if (elapsedTime != lastElapsedTime || !me.mMeditateModel.isTimerRunning || me.mForceRedraw) {
			if (page == SessionPage.Guidance) {
				me.drawGuidancePage(dc, elapsedTime);
			} else {
				me.drawMetricsPage(dc, elapsedTime);
			}
		}
		lastElapsedTime = elapsedTime;
		me.mForceRedraw = false;
	}

	private function drawMetricsPage(dc, elapsedTime) {
		me.mMeditateModel.title = TimeFormatter.format(elapsedTime);
		// paused reads as no value: every icon goes grey
		var running = me.mMeditateModel.isTimerRunning;
		for (var i = 0; i < me.mLines.size(); i++) {
			var line = me.mLines[i];
			line.update(running ? line.metric.getValue() : null, elapsedTime);
		}

		ScreenPickerDetailsCenterView.onUpdate(dc);
		me.drawSessionRing(dc, elapsedTime);
	}

	// Drawn without the DetailsCenterView chain: the metrics lines are not wanted here, and
	// reaching ScreenPickerBaseView.onUpdate would mean skipping a level in the class chain.
	private function drawGuidancePage(dc, elapsedTime) {
		dc.setColor(Gfx.COLOR_TRANSPARENT, me.backgroundColor);
		dc.clear();
		me.drawArrows(dc);
		me.drawSessionRing(dc, elapsedTime);
		me.mBreathGuidanceRenderer.draw(dc, me.mMeditateModel.getBreathRunner());
	}

	private function drawBallPage(dc, elapsedTime) {
		me.drawDarkPage(dc, elapsedTime);
		me.mBallRenderer.draw(dc, me.mMeditateModel.getBreathRunner(), me.secondFraction());
	}

	private function drawZenPage(dc, elapsedTime) {
		me.drawDarkPage(dc, elapsedTime);
		me.mZenDrawnStep = me.zenStep(elapsedTime);
		if (elapsedTime >= me.mPeekUntil) {
			return;
		}
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		dc.drawText(
			me.centerXPos,
			me.centerYPos,
			Gfx.FONT_MEDIUM,
			TimeFormatter.format(elapsedTime),
			Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
		);
		// below the time: "Tap for time" on touch screens, then where up and down lead
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
		var lineHeight = dc.getFontHeight(Gfx.FONT_XTINY);
		var y = me.centerYPos + dc.getFontHeight(Gfx.FONT_MEDIUM) / 2 + lineHeight / 2;
		var justify = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
		if (me.mTapHint != null) {
			dc.drawText(me.centerXPos, y, Gfx.FONT_XTINY, me.mTapHint, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
			y += lineHeight;
		}
		// [up, word, down, word]: carets in the icon font, words in the text font, centred as one line.
		// The up caret sits high in its cell and the down caret low, so each moves toward the text.
		var fonts = [StatusIconFonts.fontAwesomeFreeSolid, Gfx.FONT_XTINY];
		var shift = dc.getFontHeight(fonts[0]) / 10;
		var shifts = [shift, 0, -shift, 0];
		var width = 0;
		for (var i = 0; i < 4; i++) {
			width += dc.getTextWidthInPixels(me.mZenNav[i], fonts[i % 2]);
		}
		var x = me.centerXPos - width / 2;
		for (var i = 0; i < 4; i++) {
			dc.drawText(x, y + shifts[i], fonts[i % 2], me.mZenNav[i], justify);
			x += dc.getTextWidthInPixels(me.mZenNav[i], fonts[i % 2]);
		}
	}

	// ball and zen stay black whatever the theme; the chevrons show only while peeking
	private function drawDarkPage(dc, elapsedTime) {
		dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
		dc.clear();
		me.drawSessionRing(dc, elapsedTime);
		if (elapsedTime < me.mPeekUntil) {
			me.drawArrows(dc);
		}
	}

	// session progress over the hold/rest spans, then step ticks and interval alerts; same on every page
	private function drawSessionRing(dc, elapsedTime) {
		me.mMainDurationRenderer.drawSpans(dc, me.mBreathStepSpans);
		me.mMainDurationRenderer.drawOverallElapsedTime(dc, elapsedTime, me.mMeditateModel.getSessionTime());
		if (me.mIntervalAlertsRenderer == null) {
			return;
		}
		me.mIntervalAlertsRenderer.drawTicksAt(dc, me.mBreathStepPercentages, me.mMeditateModel.getColor());
		me.mIntervalAlertsRenderer.drawAllIntervalAlerts(dc);
	}
}
