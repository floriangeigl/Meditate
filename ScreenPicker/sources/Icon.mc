using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

module ScreenPicker {
	class Icon {
		var color;
		function initialize(icon) {
			me.color = icon[:color];
			var iconDrawableParams = {};
			if (icon[:symbol] != null) {
				iconDrawableParams[:text] = Ui.loadResource(icon[:symbol]);
			} else {
				iconDrawableParams[:text] = "";
			}
			if (icon[:color] != null) {
				iconDrawableParams[:color] = icon[:color];
			}
			if (icon[:font] != null) {
				iconDrawableParams[:font] = icon[:font];
			}
			if (icon[:xPos] != null) {
				iconDrawableParams[:locX] = icon[:xPos];
			} else {
				iconDrawableParams[:locX] = 0;
			}
			if (icon[:yPos] != null) {
				iconDrawableParams[:locY] = icon[:yPos];
			}
			iconDrawableParams[:justification] = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
			me.mIconDrawable = new Ui.Text(iconDrawableParams);
		}

		private var mIconDrawable;

		function setXPos(xPos) {
			me.mIconDrawable.locX = xPos;
		}

		function setYPos(yPos) {
			me.mIconDrawable.locY = yPos;
		}

		function setColor(color) {
			me.mIconDrawable.setColor(color);
		}

		function setColorLoading() {
			me.mIconDrawable.setColor(0xa2adfa);
		}

		function setColorInactive() {
			me.setColor(Gfx.COLOR_LT_GRAY);
		}

		function draw(dc) {
			me.mIconDrawable.draw(dc);
		}
	}
}
