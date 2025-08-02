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

	function initialize(onShow, prepare) {
		View.initialize();
		me.mOnShow = onShow;
		me.mPrepare = prepare;
		me.mviewDrawnTimer = null;
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
		dc.drawText(
			centerX,
			centerY - centerY / 3,
			Gfx.FONT_SYSTEM_TINY,
			textString + " " + minutes + ":" + (seconds < 10 ? "0" : "") + seconds,
			Graphics.TEXT_JUSTIFY_CENTER
		);
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
