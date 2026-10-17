using Toybox.Graphics as Gfx;

class BreathIcon extends Icon {
	function initialize(icon) {
		icon[:font] = StatusIconFonts.fontAwesomeFreeSolid;
		icon[:symbol] = Rez.Strings.IconBreath;
		if (icon[:color] == null) {
			icon[:color] = Gfx.COLOR_BLUE;
		}
		Icon.initialize(icon);
	}

	function setActive() {
		me.setColor(Gfx.COLOR_BLUE);
	}
	function setInactive() {
		me.setColor(Gfx.COLOR_LT_GRAY);
	}
}
