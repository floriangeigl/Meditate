using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class ColorPickerView extends ScreenPickerBaseView {
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
		if (me.mColor == Gfx.COLOR_WHITE) {
        	me.setArrowsColor(Gfx.COLOR_BLACK);
        }
		me.drawArrows(dc);
        
        if (me.mColor == Gfx.COLOR_TRANSPARENT) {
        	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        	var transparentText = Ui.loadResource(Rez.Strings.intervalAlertTransparentColorText);
        	var centerX = dc.getWidth() / 2;
        	var centerY = dc.getHeight() / 2 - dc.getFontHeight(Gfx.FONT_SYSTEM_MEDIUM) / 2;
        	dc.drawText(centerX, centerY, Gfx.FONT_SYSTEM_MEDIUM, transparentText, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
}