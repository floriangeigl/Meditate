using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Math;

// Draws the eyes-open breath guidance: phase ring, phase verb, phase countdown, round counter.
class BreathGuidanceRenderer {
	private var mInhaleRing, mExhaleRing, mHoldRing;
	private var mInhaleText, mExhaleText, mHoldText, mRestText;
	private var mNoseText, mMouthText;
	private var mCenterX, mCenterY;
	private var mWordCenterY, mNumberY, mSmallY;
	private var mWordFonts, mNumberFont; // word font per phase, indexed by BreathPhase
	private var mForegroundColor;

	static const InhaleColor = Gfx.COLOR_BLUE;
	static const ExhaleColor = Gfx.COLOR_GREEN;

	function initialize(dc, foregroundColor) {
		me.mForegroundColor = foregroundColor;
		me.mInhaleText = Ui.loadResource(Rez.Strings.breathPhase_inhale);
		me.mExhaleText = Ui.loadResource(Rez.Strings.breathPhase_exhale);
		me.mHoldText = Ui.loadResource(Rez.Strings.breathPhase_hold);
		me.mRestText = Ui.loadResource(Rez.Strings.breathPhase_rest);
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

		me.mNumberFont = Gfx.FONT_NUMBER_MEDIUM;
		var wordHeight = dc.getFontHeight(Gfx.FONT_MEDIUM);
		var smallHeight = dc.getFontHeight(Gfx.FONT_XTINY);
		// step down the countdown font when the three lines cannot fit inside the circle
		if (wordHeight + dc.getFontHeight(me.mNumberFont) + smallHeight + 2 * spacing > 2 * textRadius) {
			me.mNumberFont = Gfx.FONT_NUMBER_MILD;
		}
		var numberHeight = dc.getFontHeight(me.mNumberFont);

		me.mNumberY = me.mCenterY - numberHeight / 2;
		me.mWordCenterY = me.mNumberY - spacing - wordHeight / 2;
		me.mSmallY = me.mNumberY + numberHeight + spacing;

		// the word row sits above centre where the text circle is narrower than the screen;
		// long words (de/uk verbs, "Breathe freely") step down to stay inside that chord
		var wordDy = me.mCenterY - me.mWordCenterY;
		var chordSquared = textRadius * textRadius - wordDy * wordDy;
		var maxWordWidth = chordSquared > 0 ? 2 * Math.sqrt(chordSquared) : width * 0.5;
		var wordFonts = [Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY];
		me.mWordFonts = new [BreathPhase.Rest + 1];
		for (var phase = 0; phase <= BreathPhase.Rest; phase++) {
			me.mWordFonts[phase] = Utils.fitFont(dc, wordFonts, [me.wordFor(phase)], maxWordWidth);
		}
	}

	private function wordFor(phase) {
		if (phase == BreathPhase.Inhale) {
			return me.mInhaleText;
		}
		if (phase == BreathPhase.Exhale) {
			return me.mExhaleText;
		}
		if (phase == BreathPhase.Rest) {
			return me.mRestText;
		}
		return me.mHoldText;
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

		// phase verb, centred on its row so a stepped-down font keeps the same place
		dc.drawText(
			me.mCenterX,
			me.mWordCenterY,
			me.mWordFonts[phase],
			me.wordFor(phase),
			Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
		);

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
