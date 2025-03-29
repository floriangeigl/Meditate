using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

module ScreenPicker {
	class ScreenPickerDetailsCenterView extends ScreenPickerDetailsView {
		function initialize(detailsModel, multiPage) {
			ScreenPickerDetailsView.initialize(detailsModel, multiPage);
		}
		function onLayout(dc) {
			ScreenPickerDetailsView.onLayout(dc);
			xIconOffset = Math.ceil(centerXPos - spaceXMed);
			xTextOffset = Math.ceil(centerXPos + spaceXSmall);
		}
	}
}
