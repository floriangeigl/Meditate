using Toybox.Graphics as Gfx;

class HrvIcon extends Icon {
	function initialize(icon) {
		icon[:font] = StatusIconFonts.fontAwesomeFreeSolid;
		icon[:symbol] = Rez.Strings.IconHeartBeat;
		if (icon[:color] == null) {
			icon[:color] = HeartBeatRedColor;
		}

		Icon.initialize(icon);
	}

	const HeartBeatGreenColor = Gfx.COLOR_GREEN;
	const HeartBeatRedColor = Gfx.COLOR_RED;

	function setStatusOn() {
		me.setColor(HeartBeatGreenColor);
	}

	function setStatusOnDetailed() {
		me.setColor(HeartBeatGreenColor);
	}

	function setStatusOff() {
		me.setColorInactive();
	}

	function setStatusWarning() {
		me.setColor(Gfx.COLOR_YELLOW);
	}
}
