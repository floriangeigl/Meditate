using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Math;
using Toybox.System;

// Draws the breath ball: grows on the inhale, shrinks on the exhale, stays put on holds and rests.
// Pure renderer; MeditateView decides when to draw and passes the fraction of the current second.
class BreathBallRenderer {
	private var mCenterX, mCenterY;
	private var mMinRadius, mMaxRadius;
	private var mEdgeWidth;
	private var mWords; // indexed by BreathPhase
	private var mWordFont, mRestFont;
	private var mDrawnRadius;
	// amoled only: on the 64-colour MIP screens the halo quantises into a hard dark band
	private var mGlow;

	private static const InhaleFill = 0x0055aa;
	private static const ExhaleFill = 0x005500;
	private static const ThinRim = 2;
	private static const GlowSteps = 4;

	function initialize() {
		me.mCenterX = null;
		me.mDrawnRadius = -1;
	}

	// laid out on the first draw: the ball is created on page entry, where there is no dc
	private function layout(dc) {
		var width = dc.getWidth();
		var height = dc.getHeight();
		me.mCenterX = width / 2;
		me.mCenterY = height / 2;
		var minDim = width < height ? width : height;
		me.mMaxRadius = BreathGuidanceRenderer.phaseRadius(minDim);
		me.mMinRadius = (me.mMaxRadius * 0.4).toNumber();
		me.mEdgeWidth = Math.floor(minDim / 60.0).toNumber();
		if (me.mEdgeWidth < 2) {
			me.mEdgeWidth = 2;
		}
		var settings = System.getDeviceSettings();
		me.mGlow = settings has :requiresBurnInProtection && settings.requiresBurnInProtection;

		var hold = Ui.loadResource(Rez.Strings.breathPhase_hold);
		me.mWords = [
			Ui.loadResource(Rez.Strings.breathPhase_inhale),
			hold,
			Ui.loadResource(Rez.Strings.breathPhase_exhale),
			hold,
			Ui.loadResource(Rez.Strings.breathPhase_rest),
		];
		// one size for the breath words, fitted inside the smallest ball so they never run over the
		// edge; the rest word only ever shows in the half-size ball
		var fonts = [Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY];
		var breathWords = [me.mWords[BreathPhase.Inhale], hold, me.mWords[BreathPhase.Exhale]];
		me.mWordFont = Utils.fitFont(dc, fonts, breathWords, 1.8 * (me.mMinRadius - me.mEdgeWidth));
		me.mRestFont = Utils.fitFont(dc, fonts, [me.mWords[BreathPhase.Rest]], 1.8 * (me.radiusAt(0.5) - me.mEdgeWidth));
	}

	// 0..1 through the current phase; a finished program or an empty phase holds its end
	static function progress(runner, frac) {
		if (runner.isDone || runner.phaseTotal < 1) {
			return 1.0;
		}
		var p = (runner.phaseElapsed + frac) / runner.phaseTotal.toFloat();
		return p < 0 ? 0.0 : (p > 1 ? 1.0 : p);
	}

	// ball size 0..1 for a phase at progress p, eased like a breath
	static function fraction(phase, p) {
		if (phase == BreathPhase.Inhale) {
			return BreathBallRenderer.ease(p);
		}
		if (phase == BreathPhase.Exhale) {
			return 1 - BreathBallRenderer.ease(p);
		}
		if (phase == BreathPhase.HoldFull) {
			return 1.0;
		}
		if (phase == BreathPhase.Rest) {
			return 0.5;
		}
		return 0.0;
	}

	private static function ease(p) {
		return (1 - Math.cos(Math.PI * p)) / 2;
	}

	private function radiusAt(size) {
		return Math.round(me.mMinRadius + (me.mMaxRadius - me.mMinRadius) * size).toNumber();
	}

	private function radiusFor(runner, frac) {
		return me.radiusAt(BreathBallRenderer.fraction(runner.phase, BreathBallRenderer.progress(runner, frac)));
	}

	// the frame gate: only a ball that moved a whole pixel is worth a redraw
	function needsRedraw(runner, frac) {
		return me.mCenterX == null || me.radiusFor(runner, frac) != me.mDrawnRadius;
	}

	function draw(dc, runner, frac) {
		if (me.mCenterX == null) {
			me.layout(dc);
		}
		var phase = runner.phase;
		var radius = me.radiusFor(runner, frac);
		me.mDrawnRadius = radius;

		// a hold keeps the colour of the breath before it: blue on full lungs, green on empty; rest is grey
		var fill = Gfx.COLOR_DK_GRAY;
		var edge = Gfx.COLOR_LT_GRAY;
		if (phase == BreathPhase.Inhale || phase == BreathPhase.HoldFull) {
			fill = InhaleFill;
			edge = BreathGuidanceRenderer.InhaleColor;
		} else if (phase == BreathPhase.Exhale || phase == BreathPhase.HoldEmpty) {
			fill = ExhaleFill;
			edge = BreathGuidanceRenderer.ExhaleColor;
		}
		var antiAlias = dc has :setAntiAlias;
		if (antiAlias) {
			dc.setAntiAlias(true);
		}
		var outer = radius + me.mEdgeWidth / 2;
		if (me.mGlow) {
			me.drawGlow(dc, outer, edge);
		}
		// a thin rim while breathing; the thick one is the countdown of holds and rests, draining
		// clockwise from 12 in whole seconds like the other rings
		var moving = phase == BreathPhase.Inhale || phase == BreathPhase.Exhale;
		if (moving || runner.phaseTotal < 1 || runner.phaseElapsed < 1) {
			// a full rim is two discs: an arc's two ends leave a gap where they meet
			me.fillDisc(dc, edge, outer);
			me.fillDisc(dc, fill, outer - (moving ? ThinRim : me.mEdgeWidth));
		} else {
			me.fillDisc(dc, fill, outer);
			var sweep = (360.0 * (runner.phaseTotal - runner.phaseElapsed)) / runner.phaseTotal;
			var start = sweep - 270;
			dc.setColor(edge, Gfx.COLOR_TRANSPARENT);
			dc.setPenWidth(me.mEdgeWidth);
			dc.drawArc(me.mCenterX, me.mCenterY, radius, Gfx.ARC_CLOCKWISE, start, start - sweep);
		}

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(
			me.mCenterX,
			me.mCenterY,
			phase == BreathPhase.Rest ? me.mRestFont : me.mWordFont,
			me.mWords[phase],
			Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
		);
		// the rest of the page draws as before
		if (antiAlias) {
			dc.setAntiAlias(false);
		}
	}

	// darker shades of the rim colour, fading outwards
	private function drawGlow(dc, outer, color) {
		var step = me.mEdgeWidth / 2 + 1;
		for (var k = GlowSteps; k >= 1; k--) {
			me.fillDisc(dc, BreathBallRenderer.shade(color, 0.1 * (GlowSteps + 1 - k)), outer + k * step);
		}
	}

	private function fillDisc(dc, color, radius) {
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(me.mCenterX, me.mCenterY, radius);
	}

	private static function shade(color, factor) {
		var r = (((color >> 16) & 0xff) * factor).toNumber();
		var g = (((color >> 8) & 0xff) * factor).toNumber();
		var b = ((color & 0xff) * factor).toNumber();
		return (r << 16) | (g << 8) | b;
	}
}
