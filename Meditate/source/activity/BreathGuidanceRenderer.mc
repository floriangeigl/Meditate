using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Math;

// Draws the eyes-open breath guidance: phase ring, phase verb, phase countdown, round counter.
class BreathGuidanceRenderer {
	private var mInhaleRing, mExhaleRing, mHoldRing;
	private var mInhaleText, mExhaleText, mHoldText;
	private var mNoseText, mMouthText;
	private var mCenterX, mCenterY;
	private var mWordY, mNumberY, mSmallY;
	private var mWordFont, mNumberFont;
	private var mForegroundColor;

	static const InhaleColor = Gfx.COLOR_BLUE;
	static const ExhaleColor = Gfx.COLOR_GREEN;

	function initialize(dc, foregroundColor) {
		me.mForegroundColor = foregroundColor;
		me.mInhaleText = Ui.loadResource(Rez.Strings.breathPhase_inhale);
		me.mExhaleText = Ui.loadResource(Rez.Strings.breathPhase_exhale);
		me.mHoldText = Ui.loadResource(Rez.Strings.breathPhase_hold);
		// cached so the 1 Hz redraw does not reload resources
		me.mNoseText = Ui.loadResource(Rez.Strings.breathRouteMenu_nose);
		me.mMouthText = Ui.loadResource(Rez.Strings.breathRouteMenu_mouth);
		me.layout(dc);
	}

	private function layout(dc) {
		var width = dc.getWidth();
		var height = dc.getHeight();
		me.mCenterX = width / 2;
		me.mCenterY = height / 2;
		var minDim = width < height ? width : height;

		// sits inside the interval-alert tick ring, which is the outermost element
		var ringWidth = Math.floor(minDim / 40.0).toNumber();
		if (ringWidth < 3) {
			ringWidth = 3;
		}
		// ElapsedDurationRenderer subtracts ceil(width/2) from the radius on first draw
		var ringRadius = (minDim / 2 - Math.floor(minDim / 9.0)).toNumber() + Math.ceil(ringWidth / 2.0).toNumber();
		me.mInhaleRing = new ElapsedDurationRenderer(BreathGuidanceRenderer.InhaleColor, ringRadius, ringWidth);
		me.mExhaleRing = new ElapsedDurationRenderer(BreathGuidanceRenderer.ExhaleColor, ringRadius, ringWidth);
		me.mHoldRing = new ElapsedDurationRenderer(me.foregroundColorOrDefault(), ringRadius, ringWidth);

		// usable text circle sits just inside the phase ring
		var textRadius = minDim / 2 - Math.floor(minDim / 9.0) - ringWidth;
		var spacing = Math.floor(minDim / 40.0).toNumber();

		me.mWordFont = Gfx.FONT_MEDIUM;
		me.mNumberFont = Gfx.FONT_NUMBER_MEDIUM;
		var wordHeight = dc.getFontHeight(me.mWordFont);
		var smallHeight = dc.getFontHeight(Gfx.FONT_XTINY);
		// step down the countdown font when the three lines cannot fit inside the circle
		if (wordHeight + dc.getFontHeight(me.mNumberFont) + smallHeight + 2 * spacing > 2 * textRadius) {
			me.mNumberFont = Gfx.FONT_NUMBER_MILD;
		}
		var numberHeight = dc.getFontHeight(me.mNumberFont);

		me.mNumberY = me.mCenterY - numberHeight / 2;
		me.mWordY = me.mNumberY - wordHeight - spacing;
		me.mSmallY = me.mNumberY + numberHeight + spacing;
	}

	private function foregroundColorOrDefault() {
		return me.mForegroundColor == null ? Gfx.COLOR_WHITE : me.mForegroundColor;
	}

	function draw(dc, runner) {
		if (runner == null) {
			return;
		}
		var phase = runner.phase;

		// phase progress ring
		var ring = me.mHoldRing;
		if (phase == BreathPhase.Inhale) {
			ring = me.mInhaleRing;
		} else if (phase == BreathPhase.Exhale) {
			ring = me.mExhaleRing;
		}
		if (runner.phaseTotal > 0) {
			// full ring on the last second of the phase, so the elapsed-time wrap must not apply
			ring.drawProgressPercentage(dc, (100.0 * (runner.phaseElapsed + 1)) / runner.phaseTotal);
		}

		dc.setColor(me.foregroundColorOrDefault(), Gfx.COLOR_TRANSPARENT);

		// phase verb
		var word = me.mHoldText;
		if (phase == BreathPhase.Inhale) {
			word = me.mInhaleText;
		} else if (phase == BreathPhase.Exhale) {
			word = me.mExhaleText;
		}
		var wordFont = me.mWordFont;
		// long localizations (de/uk) would otherwise run under the bezel
		if (dc.getTextWidthInPixels(word, wordFont) > dc.getWidth() * 0.75) {
			wordFont = Gfx.FONT_SMALL;
		}
		dc.drawText(me.mCenterX, me.mWordY, wordFont, word, Gfx.TEXT_JUSTIFY_CENTER);

		// phase countdown
		var remaining = runner.phaseRemaining();
		var remainingText = remaining >= 60 ? TimeFormatter.formatMinSec(remaining) : remaining.toString();
		dc.drawText(me.mCenterX, me.mNumberY, me.mNumberFont, remainingText, Gfx.TEXT_JUSTIFY_CENTER);

		// round counter and, since routes are per step, the route for this phase
		var detail = "";
		if (runner.roundsTotal > 1) {
			detail = (runner.roundIndex + 1).toString() + "/" + runner.roundsTotal.toString();
		}
		var route = runner.phaseRoute();
		if (route != BreathRoute.Unset) {
			var routeText = route == BreathRoute.Nose ? me.mNoseText : me.mMouthText;
			detail += detail.length() > 0 ? "  " + routeText : routeText;
		}
		if (detail.length() > 0) {
			dc.drawText(me.mCenterX, me.mSmallY, Gfx.FONT_XTINY, detail, Gfx.TEXT_JUSTIFY_CENTER);
		}
	}
}
