using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

module ScreenPicker {
	class PercentageHighlightLine {
		function initialize(highlightsCount) {
			if (highlightsCount > 0) {
				me.highlights = new [MaxHighlightsCount];
			} else {
				me.highlights = [];
			}
			me.latestAddedIndex = -1;
			me.backgroundColor = Gfx.COLOR_WHITE;
		}

		private const MaxHighlightsCount = 50;
		private var highlights;
		private var latestAddedIndex;

		var backgroundColor;
		var startPosX;
		var yOffset;

		function addHighlight(color, progressPercentage) {
			if (latestAddedIndex + 1 < MaxHighlightsCount) {
				me.latestAddedIndex++;
				me.highlights[me.latestAddedIndex] = new LineHighlight(color, progressPercentage);
			}
		}

		function getHighlights() {
			if (me.highlights.size() == 0) {
				return [];
			} else {
				return me.highlights.slice(0, me.latestAddedIndex + 1);
			}
		}
	}

	class LineHighlight {
		function initialize(color, progressPercentage) {
			me.color = color;
			me.progressPercentage = progressPercentage;
		}
		var color;
		var progressPercentage;
	}

	class TextValue {
		function initialize() {
			me.text = "";
			me.font = Gfx.FONT_SYSTEM_TINY;
			me.color = null;
			me.xPos = 0;
			me.justification = Gfx.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
		}

		var text;
		var font;
		var color;
		var xPos;
		var justification;
	}

	class DetailsLine {
		function initialize() {
			me.icon = null;
			me.value = new TextValue();
		}

		var icon;
		var value;
	}

	class DetailsModel {
		var linesCount;
		var title;
		var titleColor;
		var detailLines;
		var foregroundColor;

		function initialize() {
			me.title = "";
			me.titleColor = null;
			me.detailLines = [];
			me.foregroundColor = null;
			me.linesCount = 0;
		}

		function newLine() {
			linesCount++;
			var line = new DetailsLine();
			me.detailLines.add(line);
			return line;
		}

		function getLine(lineNum) {
			while (lineNum >= linesCount) {
				me.detailLines.add(new DetailsLine());
				linesCount++;
			}
			return detailLines[lineNum];
		}
	}
}
