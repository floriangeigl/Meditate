using Toybox.Graphics as Gfx;

module ScreenPicker {
	class StressIcon extends Icon {
		function initialize(icon) {
			icon[:font] = StatusIconFonts.garminIcons;
			icon[:symbol] = StatusIconFonts.Rez.Strings.IconStress;
			if (icon[:color] == null) {
				icon[:color] = Gfx.COLOR_DK_GREEN;
			}

			Icon.initialize(icon);
		}

		function setStress(val) {
			// https://support.garmin.com/en-US/?faq=WT9BmhjacO4ZpxbCc0EKn9
			if (val == null) {
				me.setStressInvalid();
			} else if (val <= 25) {
				me.setStressRest();
			} else if (val <= 50) {
				me.setStressLow();
			} else if (val <= 75) {
				me.setStressMed();
			} else {
				me.setStressHigh();
			}
		}

		function setStressInvalid() {
			me.setColor(Gfx.COLOR_LT_GRAY);
		}

		function setStressRest() {
			me.setColor(Gfx.COLOR_DK_GREEN);
		}

		function setStressLow() {
			me.setColor(Gfx.COLOR_YELLOW);
		}
		function setStressMed() {
			me.setColor(Gfx.COLOR_ORANGE);
		}

		function setStressHigh() {
			me.setColor(Gfx.COLOR_DK_RED);
		}
	}
}
