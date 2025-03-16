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
		private static const InvalidValueString = "--";
		private static const colorThemeKey = "globalSettings_colorTheme";
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
			me.mUpArrow.setXPos(centerXPos);
			me.mUpArrow.setYPos(0);
			me.mDownArrow.setXPos(centerXPos);
			me.mDownArrow.setYPos(dc.getHeight() - dc.getFontHeight(StatusIconFonts.fontAwesomeFreeSolid));
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
			dc.drawText(
				dc.getWidth() / 2,
				dc.getHeight() * 0.1,
				App.getApp().getProperty("largeFont"),
				title,
				Graphics.TEXT_JUSTIFY_CENTER
			);
		}

		function onLayout(dc) {
			View.onLayout(dc);
			centerXPos = dc.getWidth() / 2;
			centerYPos = dc.getHeight() / 2;
			spaceXSmall = Math.ceil(dc.getWidth() * 0.01);
			spaceYSmall = Math.ceil(dc.getHeight() * 0.01);
			spaceXMed = spaceXSmall * 5;
			spaceYMed = spaceYSmall * 5;
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
