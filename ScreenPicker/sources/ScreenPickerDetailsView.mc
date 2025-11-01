using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

module ScreenPicker {
	class ScreenPickerDetailsView extends ScreenPickerBaseView {
		var mDetailsModel;
		var titleColor;
		private var mUpArrow;
		private var mDownArrow;
		var lineHeight;
		var yOffset;
		var xIconOffset;
		var xTextOffset;
		private var progressBarWidth, progressBarHeight, highlightWidth;

		function initialize(detailsModel, multiPage) {
			ScreenPickerBaseView.initialize(multiPage);
			me.mDetailsModel = detailsModel;
			me.multiPage = multiPage;
			if (me.mDetailsModel.foregroundColor != null) {
				me.foregroundColor = me.mDetailsModel.foregroundColor;
			}
			if (me.mDetailsModel.titleColor != null) {
				me.titleColor = me.mDetailsModel.titleColor;
			}
		}

		function onLayout(dc) {
			ScreenPickerBaseView.onLayout(dc);
			me.lineHeight = me.height * 0.11;
			me.yOffset = me.yOffsetTitle + me.lineHeight * 2;
			me.xIconOffset = Math.ceil(me.width * 0.2);
			me.xTextOffset = Math.ceil(me.xIconOffset + me.width * 0.07);
			me.progressBarWidth = Math.ceil(me.width * 0.6);
			me.progressBarHeight = Math.ceil(me.lineHeight * 0.6); // line height
			me.highlightWidth = Math.ceil(0.02 * me.progressBarWidth);
		}

		function onUpdate(dc) {
			ScreenPickerBaseView.onUpdate(dc);
			me.drawTitle(dc, mDetailsModel.title);
			var line = null;
			var yPos = null;
			for (var lineNumber = 0; lineNumber < me.mDetailsModel.detailLines.size(); lineNumber++) {
				line = me.mDetailsModel.detailLines[lineNumber];
				yPos = me.yOffset + me.lineHeight * lineNumber;
				if (line.icon instanceof Icon) {
					me.displayFontIcon(dc, line.icon, me.xIconOffset, yPos);
				}
				if (line.value instanceof TextValue) {
					me.displayText(dc, line.value, me.xTextOffset, yPos, line.value.justification);
				} else if (line.value instanceof PercentageHighlightLine) {
					me.drawPercentageHighlightLine(
						dc,
						line.value.getHighlights(),
						line.value.backgroundColor,
						me.xTextOffset,
						yPos
					);
				}
			}
		}

		function drawTitle(dc, title) {
			ScreenPickerBaseView.drawTitle(dc, title, me.mDetailsModel.titleColor);
		}

		private function displayFontIcon(dc, icon, xPos, yPos) {
			if (icon.color == null) {
				icon.setColor(foregroundColor);
			}
			icon.setYPos(yPos);
			icon.setXPos(xPos);
			icon.draw(dc);
		}

		private function displayText(dc, value, xPos, yPos, justification) {
			if (value.color != null) {
				dc.setColor(value.color, Gfx.COLOR_TRANSPARENT);
			} else {
				dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
			}
			dc.drawText(xPos, yPos, value.font, value.text, justification);
		}

		private function drawPercentageHighlightLine(dc, highlights, backgroundColor, startPosX, posY) {
			dc.setColor(backgroundColor, Gfx.COLOR_TRANSPARENT);
			posY = posY - me.progressBarHeight / 2;
			dc.fillRectangle(startPosX, posY, me.progressBarWidth, me.progressBarHeight);
			var highlight = null;
			var valuePosX = null;
			for (var i = 0; i < highlights.size(); i++) {
				highlight = highlights[i];
				valuePosX = startPosX + highlight.progressPercentage * me.progressBarWidth;
				dc.setColor(highlight.color, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(valuePosX, posY, me.highlightWidth, me.progressBarHeight);
			}
		}
	}
}
