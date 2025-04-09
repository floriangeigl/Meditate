using Toybox.Graphics as Gfx;
using StatusIconFonts;

module ScreenPicker {
	class LoadingIcon extends Icon {
		private var i = 0;
		private var symbols = new [3];
		function initialize(icon) {
			me.symbols[0] = StatusIconFonts.Rez.Strings.IconHourGlassStart;
			me.symbols[1] = StatusIconFonts.Rez.Strings.IconHourGlassHalf;
			me.symbols[2] = StatusIconFonts.Rez.Strings.IconHourGlassEnd;

			icon[:font] = StatusIconFonts.fontAwesomeFreeSolid;
			icon[:symbol] = me.symbols[i];
			if (icon[:color] == null) {
				icon[:color] = Gfx.COLOR_LT_GRAY;
			}
			Icon.initialize(icon);
		}

		function tick() {
			me.i = (i + 1) % me.symbols.size();
			me.setSymbol(me.symbols[me.i]);
		}
	}
}
