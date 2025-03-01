using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

module ScreenPicker {
	class ScreenPickerViewDetails extends ScreenPickerViewBase {
		var mDetailsModel;
		var titleColor;
		private var mUpArrow;
		private var mDownArrow;
		private var progressBarWidth;
	    private var progressBarHeight;

		function initialize(detailsModel, multi) {
			ScreenPickerViewBase.initialize();
			me.mDetailsModel = detailsModel;
			if(me.mDetailsModel.color != null) {
				me.foregroundColor = me.mDetailsModel.color;
			}
			if(me.mDetailsModel.titleColor != null) {
				me.titleColor = me.mDetailsModel.titleColor;
			}

			if (me.multi) {
				me.mUpArrow = new Icon({        
	        	:font => StatusIconFonts.fontAwesomeFreeSolid,
	        	:symbol => StatusIconFonts.Rez.Strings.faSortUp,
	        	:color=>detailsModel.color,
	        	:justify => Gfx.TEXT_JUSTIFY_CENTER
	        });
			me.mDownArrow = new Icon({        
	        	:font => StatusIconFonts.fontAwesomeFreeSolid,
	        	:symbol => StatusIconFonts.Rez.Strings.faSortDown,
	        	:color=>detailsModel.color,
	        	:justify => Gfx.TEXT_JUSTIFY_CENTER
	        });
			}
		}

		function onUpdate(dc) {	
			ScreenPickerViewBase.onUpdate(dc);
			ScreenPickerViewBase.drawTitle(dc, mDetailsModel.title);
			var lineHeight = dc.getHeight() * 0.11;
			var yOffset = dc.getHeight() * 0.25;
			var xIconOffset = dc.getWidth() * 0.2;
			var xTextOffset = xIconOffset + dc.getWidth() * 0.05; 
			var line = null;
			var yPos = null;
			me.progressBarWidth = dc.getWidth() * 0.7;
			me.progressBarHeight = lineHeight * 0.8;
			for (var lineNumber = 0; lineNumber < me.mDetailsModel.detailLines.size(); lineNumber++) {
				dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
				line = me.mDetailsModel.detailLines[lineNumber];
				yPos = yOffset + lineHeight * lineNumber;
				if (line.icon != null) {
					me.displayFontIcon(dc, line.icon, xIconOffset, yPos);
				}
				if (line.value instanceof TextValue) {
					me.displayText(dc, line.value, xTextOffset, yPos);
	   			}
	   			else if	(line.value instanceof PercentageHighlightLine) {
	   				me.drawPercentageHighlightLine(dc, line.value.getHighlights(), line.value.backgroundColor, xTextOffset, yPos);
	   			}
	   		} 
	    }

		function drawTitle(dc, title){
			dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
			ScreenPickerViewBase.drawTitle(dc, title);
		}

		private function displayFontIcon(dc, icon, xPos, yPos) {
			dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
			icon.setYPos(yPos);
			icon.setXPos(xPos);
			icon.draw(dc);
		}
		    
	    private function displayText(dc, value, xPos, yPos) {
			if (value.color != null) {
				dc.setColor(value.color, Gfx.COLOR_TRANSPARENT);
			} else {
				dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
			}
	        dc.drawText(xPos, yPos, value.font, value.text, Gfx.TEXT_JUSTIFY_LEFT);
	    }
		
		private function drawPercentageHighlightLine(dc, highlights, backgroundColor, startPosX, posY) {		
			dc.setColor(backgroundColor, Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(startPosX, posY, progressBarWidth, progressBarHeight);   
			
			var highlightWidth = 0.03 * progressBarWidth;		
	    	for (var i = 0; i < highlights.size(); i++) {
	    		var highlight = highlights[i];
	    		var valuePosX = startPosX + highlight.progressPercentage * progressBarWidth;
	    		dc.setColor(highlight.color, Gfx.COLOR_TRANSPARENT);
	    		dc.fillRectangle(valuePosX, posY, highlightWidth, progressBarHeight);    		
	    	}
	    }  
	}
}