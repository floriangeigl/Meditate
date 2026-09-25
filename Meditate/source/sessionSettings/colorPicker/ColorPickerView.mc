using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class ColorPickerView extends ScreenPicker.ScreenPickerBaseView {
	private var mColor;
	
	function initialize(color) {
		ScreenPickerBaseView.initialize(true);
		me.mColor = color;
	}
	
	function onUpdate(dc) {		        
		ScreenPickerBaseView.onUpdate(dc);
		if(me.mColor != Gfx.COLOR_TRANSPARENT) {		        
        	dc.setColor(Gfx.COLOR_TRANSPARENT, me.mColor);
        }
		dc.clear();
		// the swatch is the background: black on white, the theme colour on transparent, else white
		if (me.mColor == Gfx.COLOR_WHITE) {
			me.setArrowsColor(Gfx.COLOR_BLACK);
		} else if (me.mColor == Gfx.COLOR_TRANSPARENT) {
			me.setArrowsColor(null);
		} else {
			me.setArrowsColor(Gfx.COLOR_WHITE);
		}
		me.drawArrows(dc);
        
        if (me.mColor == Gfx.COLOR_TRANSPARENT) {
        	dc.setColor(me.foregroundColor, Gfx.COLOR_TRANSPARENT);
        	var transparentText = Ui.loadResource(Rez.Strings.intervalAlertTransparentColorText);
        	var centerX = dc.getWidth() / 2;
        	var centerY = dc.getHeight() / 2 - dc.getFontHeight(Gfx.FONT_SYSTEM_MEDIUM) / 2;
        	dc.drawText(centerX, centerY, Gfx.FONT_SYSTEM_MEDIUM, transparentText, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}