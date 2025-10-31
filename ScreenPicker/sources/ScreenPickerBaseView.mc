using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Math as Math;
using StatusIconFonts;

module ScreenPicker {
	class ScreenPickerBaseView extends Ui.View {
		var multiPage;
		var mUpArrow, mDownArrow;
		var centerXPos;
		var centerYPos;
		var colorTheme;
		var backgroundColor, foregroundColor;
		var spaceXSmall, spaceYSmall, spaceXMed, spaceYMed;
		private static const TextFont = App.getApp().getProperty("largeFont");
		private static const InvalidValueString = " --";
		private static const colorThemeKey = "globalSettings_colorTheme";
		protected var height, width;
		protected var yOffsetTitle;

		function initialize(multiPage) {
			View.initialize();
			if (multiPage != null && multiPage) {
				me.multiPage = true;
				me.mUpArrow = new Icon({
					:font => StatusIconFonts.fontAwesomeFreeSolid,
					:symbol => StatusIconFonts.Rez.Strings.IconUp,
					:color => foregroundColor,
					:justify => Gfx.TEXT_JUSTIFY_CENTER,
				});
				me.mDownArrow = new Icon({
					:font => StatusIconFonts.fontAwesomeFreeSolid,
					:symbol => StatusIconFonts.Rez.Strings.IconDown,
					:color => foregroundColor,
					:justify => Gfx.TEXT_JUSTIFY_CENTER,
				});
			} else {
				me.multiPage = false;
			}
			colorTheme = GlobalSettings.loadColorTheme();
			// Dark results theme
			if (colorTheme == ColorTheme.Dark) {
				backgroundColor = Gfx.COLOR_BLACK;
				foregroundColor = Gfx.COLOR_WHITE;
			} else {
				// Light results theme
				backgroundColor = Gfx.COLOR_WHITE;
				foregroundColor = Gfx.COLOR_BLACK;
			}
		}

		protected function setArrowsColor(color) {
			if (me.multiPage) {
				if (color == null) {
					color = foregroundColor;
				}
				me.mUpArrow.setColor(color);
				me.mDownArrow.setColor(color);
			}
		}

		static function formatValue(val) {
			if (val == null) {
				return ScreenPickerBaseView.InvalidValueString;
			} else {
				return Math.round(val).format("%3.0f");
			}
		}

		function layoutArrows(dc) {
			var fontHeightHalf = dc.getFontHeight(StatusIconFonts.fontAwesomeFreeSolid) / 2;
			me.mUpArrow.setXPos(centerXPos);
			me.mUpArrow.setYPos(fontHeightHalf);
			me.mDownArrow.setXPos(centerXPos);
			me.mDownArrow.setYPos(me.height - fontHeightHalf);
		}

		function drawArrows(dc) {
			if (me.multiPage) {
				me.mUpArrow.draw(dc);
				me.mDownArrow.draw(dc);
			}
		}

		function drawTitle(dc, title, color) {
			if (color == null) {
				color = foregroundColor;
			}
			dc.setColor(color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(me.centerXPos, me.yOffsetTitle, me.TextFont, title, Graphics.TEXT_JUSTIFY_CENTER);
		}

		function onLayout(dc) {
			View.onLayout(dc);
			me.height = dc.getHeight();
			me.width = dc.getWidth();
			me.centerXPos = me.width / 2;
			me.centerYPos = me.height / 2;
			me.spaceXSmall = Math.ceil(me.width * 0.01);
			me.spaceYSmall = Math.ceil(me.height * 0.01);
			me.spaceXMed = spaceXSmall * 5;
			me.spaceYMed = spaceYSmall * 5;
			me.yOffsetTitle = Math.ceil(me.height * 0.15);
			if (me.multiPage) {
				me.layoutArrows(dc);
			}
		}

		function onUpdate(dc) {
			View.onUpdate(dc);
			dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
			dc.clear();
			dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
			me.drawArrows(dc);
		}
	}
}
