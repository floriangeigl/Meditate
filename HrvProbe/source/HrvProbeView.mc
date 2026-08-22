using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class HrvProbeView extends Ui.View {
	private var mProbe;

	function initialize(probe) {
		View.initialize();
		me.mProbe = probe;
	}

	function onUpdate(dc) {
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		dc.clear();

		var cx = dc.getWidth() / 2;
		var font = Gfx.FONT_XTINY;
		var lh = dc.getFontHeight(font);
		var y = dc.getHeight() / 2 - lh * 5 / 2;

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		me.line(dc, cx, y, font, "cycle " + me.mProbe.cycle + "   t=" + me.mProbe.elapsed + "s");
		y += lh;

		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		me.line(dc, cx, y, font, "since last launch " + me.mProbe.gapText());
		y += lh + lh / 4;

		dc.setColor(me.mProbe.firstRr != null ? Gfx.COLOR_GREEN : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		if (me.mProbe.firstRr == null) {
			me.line(dc, cx, y, font, "no RR yet");
		} else {
			me.line(dc, cx, y, font, "RR at t=" + me.mProbe.firstRr + "s");
		}
		y += lh;

		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		me.line(dc, cx, y, font, me.mProbe.dataCallbacks + "/" + me.mProbe.callbacks + " cb  hr " + me.mProbe.hrText());
		y += lh + lh / 4;

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		me.line(dc, cx, y, font, "exits by itself - relaunch");
	}

	private function line(dc, cx, y, font, text) {
		dc.drawText(cx, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
	}
}
