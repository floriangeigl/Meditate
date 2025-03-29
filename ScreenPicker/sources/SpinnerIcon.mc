using Toybox.Graphics as Gfx;
using StatusIconFonts;

module ScreenPicker {
	class SpinnerIcon extends Icon {
		function initialize(icon) {
			icon[:font] = StatusIconFonts.fontAwesomeFreeSolid;
			icon[:symbol] = StatusIconFonts.Rez.Strings.IconSpinner;
			if (icon[:color] == null) {
				icon[:color] = Gfx.COLOR_LT_GRAY;
			}
			Icon.initialize(icon);
		}
	}
}
