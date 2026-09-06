using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

class MeditatePrepareView extends Ui.View {
	private var mOnShow;
	private var mMainDurationRenderer;
	private var mSeconds;
	private var mTotalSeconds;
	private var mPrepare;
	private var mviewDrawnTimer;
	private var mBreathProgram;
	private var mBriefingLines;

	private const MaxBriefingSteps = 4;

	function initialize(onShow, prepare, breathProgram) {
		View.initialize();
		me.mOnShow = onShow;
		me.mPrepare = prepare;
		me.mviewDrawnTimer = null;
		me.mBriefingLines = null;
		me.mBreathProgram = breathProgram;
		mSeconds = 0;

		if (prepare == 1) {
			mTotalSeconds = GlobalSettings.loadPrepareTime();
		} else {
			mTotalSeconds = GlobalSettings.loadFinalizeTime();
		}
	}

	function onViewDrawn() {
		if (mSeconds >= mTotalSeconds + 1) {
			return;
		}

		mSeconds += 1;
		Ui.requestUpdate();

		// Start the meditation session after XX seconds
		if (mSeconds == mTotalSeconds + 1) {
			// Vibrate short to notify only when session starts
			if (mPrepare == 1) {
				Vibe.vibrate(VibePattern.Blip);
			}

			// Starts the meditation session / saves the session
			continueToNextStep();

			return;
		}
	}

	function onLayout(dc) {
		// Clear the screen
		renderBackground(dc);

		// Green color for preparation and red color for finalization
		var color = Gfx.COLOR_GREEN;
		if (mPrepare == 0) {
			color = Gfx.COLOR_DK_RED;
		}

		// Configure the arc render for progress
		me.mMainDurationRenderer = new ElapsedDurationRenderer(color, null, null);

		// briefing is built once and stays up for the whole countdown
		if (me.mPrepare == 1 && me.mBreathProgram != null) {
			me.mBriefingLines = me.buildBriefingLines();
		}
	}

	// program summary plus a technique hint, capped so it fits the smallest round screen
	private function buildBriefingLines() {
		var lines = [];
		var stepCount = me.mBreathProgram.size();
		var shown = stepCount > MaxBriefingSteps ? MaxBriefingSteps : stepCount;
		for (var i = 0; i < shown; i++) {
			var step = me.mBreathProgram.get(i);
			lines.add(Utils.getBreathStepName(step) + "  " + Utils.getBreathStepDetail(step));
		}
		if (stepCount > shown) {
			lines.add("+" + (stepCount - shown).toString() + " " + Ui.loadResource(Rez.Strings.breathBriefing_more));
		}

		// routes are per step; only summarise here when every step agrees
		var inRoute = me.mBreathProgram.getCommonRoute(BreathPhase.Inhale);
		var outRoute = me.mBreathProgram.getCommonRoute(BreathPhase.Exhale);
		if (inRoute == BreathRoute.Unset && outRoute == BreathRoute.Unset) {
			lines.add(Ui.loadResource(Rez.Strings.breathBriefing_belly));
		} else {
			if (inRoute != BreathRoute.Unset) {
				lines.add(
					Ui.loadResource(Rez.Strings.breathBriefing_in) + " " + Utils.getBreathRouteText(inRoute)
				);
			}
			if (outRoute != BreathRoute.Unset) {
				lines.add(
					Ui.loadResource(Rez.Strings.breathBriefing_out) + " " + Utils.getBreathRouteText(outRoute)
				);
			}
		}
		return lines;
	}

	private function renderBackground(dc) {
		// Clear the screen
		dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
		dc.clear();
	}

	function onShow() {
		me.mviewDrawnTimer = new Timer.Timer();
		me.mviewDrawnTimer.start(method(:onViewDrawn), 1000, true);
	}

	function onUpdate(dc) {
		View.onUpdate(dc);

		// Draw arc with the progress
		me.mMainDurationRenderer.drawOverallElapsedTime(dc, mSeconds, mTotalSeconds);

		// Calculate center of the screen
		var centerX = dc.getWidth() / 2;
		var centerY = dc.getHeight() / 2;

		// Calculate minutes and seconds from the remaining seconds
		var remainingSeconds = mTotalSeconds - mSeconds;
		var minutes = remainingSeconds / 60;
		var seconds = remainingSeconds % 60;
		var textString;

		// Prepare or finalize text to display
		if (mPrepare == 1) {
			textString = Ui.loadResource(Rez.Strings.meditateActivityPrepare);
		} else {
			textString = Ui.loadResource(Rez.Strings.meditateActivityFinalize);
		}

		// Render main text with the remaining time in the format M:SS
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		var countdownText = textString + " " + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
		var countdownY = centerY - centerY / 3;

		if (me.mBriefingLines != null && me.mBriefingLines.size() > 0) {
			// stack the program summary above the countdown, keeping the whole block centred
			var lineHeight = dc.getFontHeight(Gfx.FONT_XTINY);
			var totalHeight = (me.mBriefingLines.size() + 1) * lineHeight;
			var y = centerY - totalHeight / 2;
			for (var i = 0; i < me.mBriefingLines.size(); i++) {
				dc.drawText(centerX, y, Gfx.FONT_XTINY, me.mBriefingLines[i], Graphics.TEXT_JUSTIFY_CENTER);
				y += lineHeight;
			}
			dc.drawText(centerX, y, Gfx.FONT_XTINY, countdownText, Graphics.TEXT_JUSTIFY_CENTER);
			return;
		}

		dc.drawText(centerX, countdownY, Gfx.FONT_SYSTEM_TINY, countdownText, Graphics.TEXT_JUSTIFY_CENTER);
	}

	function onHide() {
		// Abort the timer when view is closed
		me.mviewDrawnTimer.stop();
		me.mviewDrawnTimer = null;
	}

	function continueToNextStep() {
		// Starts the meditation session / saves the session
		me.mOnShow.invoke();
	}
}
