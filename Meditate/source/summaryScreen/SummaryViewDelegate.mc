using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Lang;

class SummaryViewDelegate extends ScreenPicker.ScreenPickerDelegate {
	private var mSummary;
	private var mIdleReminderTimer;
	// rows of [metric id, kind, title, yMin, yMax] in page order; a page exists when its data does
	private var pages;

	function initialize(summary, idleReminderTimer) {
		me.mSummary = summary;
		// resource ids are not safe in static initialisers
		var table = [
			[:hr, :graph, Rez.Strings.SummaryHR, 20, 150],
			[:hrv, :hrvGraph, Rez.Strings.SummaryHRVRMSSD, 0, 250],
			[:stress, :graph, Rez.Strings.SummaryStress, 0, 100],
			[:stress, :details, Rez.Strings.SummaryStress],
			[:hrv, :hrvRmssd],
			[:hrv, :hrvPnnx],
			[:hrv, :hrvSdrr],
			[:rr, :graph, Rez.Strings.SummaryRespiration, 1, 60],
		];
		me.pages = [];
		for (var i = 0; i < table.size(); i++) {
			if (me.isPresent(table[i])) {
				me.pages.add(table[i]);
			}
		}
		me.mPagesCount = me.pages.size();

		ScreenPickerDelegate.initialize(0, me.mPagesCount);
		me.mIdleReminderTimer = idleReminderTimer;
	}

	private function isPresent(row) {
		var metric = me.mSummary.metrics[row[0]];
		var kind = row[1];
		if (kind == :graph || kind == :details) {
			// the hr graph is always there so the picker never has zero pages
			return row[0] == :hr || (metric != null && metric.hasData());
		}
		if (kind == :hrvRmssd) {
			return metric != null;
		}
		return metric != null && metric.detailed;
	}

	function createScreenPickerView() {
		var row = me.mSelectedPageIndex < me.mPagesCount ? me.pages[me.mSelectedPageIndex] : me.pages[0];
		var metric = me.mSummary.metrics[row[0]];
		var kind = row[1];
		if (kind == :graph || kind == :hrvGraph) {
			return new GraphView(metric, me.mSummary.elapsedTime, row[2], row[3], row[4]);
		}
		var detailsModel;
		if (kind == :details) {
			detailsModel = me.createDetailsPage(metric, row[2]);
		} else if (kind == :hrvRmssd) {
			detailsModel = me.createDetailsPageHrvRmssd(metric);
		} else if (kind == :hrvPnnx) {
			detailsModel = me.createDetailsPageHrvPnnx(metric);
		} else {
			detailsModel = me.createDetailsPageHrvSdrr(metric);
		}
		return new ScreenPicker.ScreenPickerDetailsView(detailsModel, me.mPagesCount > 1);
	}

	private static function valueLine(detailsModel, lineNum, label, value) {
		var line = detailsModel.getLine(lineNum);
		line.value.text = Lang.format("$1$ $2$", [
			Ui.loadResource(label),
			ScreenPicker.ScreenPickerBaseView.formatValue(value),
		]);
	}

	// avg, start, end, min, max of any metric; the icon takes the colour of the average
	private function createDetailsPage(metric, title) {
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(title);

		var icon = MeditateView.createIcon(metric.id);
		icon.setLive(metric.getAvg());
		var line = detailsModel.getLine(0);
		line.icon = icon;
		line.value.text = Lang.format("$1$  $2$", [
			Ui.loadResource(Rez.Strings.SummaryAvg),
			ScreenPicker.ScreenPickerBaseView.formatValue(metric.getAvg()),
		]);
		valueLine(detailsModel, 1, Rez.Strings.SummaryStart, metric.first);
		valueLine(detailsModel, 2, Rez.Strings.SummaryEnd, metric.last);
		valueLine(detailsModel, 3, Rez.Strings.SummaryMin, metric.min);
		valueLine(detailsModel, 4, Rez.Strings.SummaryMax, metric.max);
		return detailsModel;
	}

	private function createDetailsPageHrvRmssd(hrv) {
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(Rez.Strings.SummaryHRVRMSSD);
		var line = detailsModel.getLine(0);
		line.icon = new ScreenPicker.HrvIcon({});
		line.value.text = Lang.format("$1$ ms", [ScreenPicker.ScreenPickerBaseView.formatValue(hrv.rmssd)]);
		return detailsModel;
	}

	private function createDetailsPageHrvPnnx(hrv) {
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(Rez.Strings.SummaryHRVpNNx);

		var line = detailsModel.getLine(0);
		var hrvIcon = new ScreenPicker.HrvIcon({});
		line.icon = hrvIcon;
		line.value.text = "HRV > 20";

		line = detailsModel.getLine(1);
		line.value.text = Lang.format("$1$% of time", [ScreenPicker.ScreenPickerBaseView.formatValue(hrv.pnn20)]);

		line = detailsModel.getLine(2);
		line.icon = hrvIcon;
		line.value.text = "HRV > 50";

		line = detailsModel.getLine(3);
		line.value.text = Lang.format("$1$% of time", [ScreenPicker.ScreenPickerBaseView.formatValue(hrv.pnn50)]);

		return detailsModel;
	}

	private function createDetailsPageHrvSdrr(hrv) {
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(Rez.Strings.SummaryHRVSDRR);

		var line = detailsModel.getLine(0);
		var hrvIcon = new ScreenPicker.HrvIcon({});
		line.icon = hrvIcon;
		line.value.text = Ui.loadResource(Rez.Strings.SummaryHRVRMSSDFirst5min);

		line = detailsModel.getLine(1);
		line.value.text = Lang.format("$1$ ms", [ScreenPicker.ScreenPickerBaseView.formatValue(hrv.sdrrFirst)]);

		line = detailsModel.getLine(2);
		line.icon = hrvIcon;
		line.value.text = Ui.loadResource(Rez.Strings.SummaryHRVRMSSDLast5min);
		line = detailsModel.getLine(3);
		line.value.text = Lang.format("$1$ ms", [ScreenPicker.ScreenPickerBaseView.formatValue(hrv.sdrrLast)]);
		return detailsModel;
	}

	function onBack() {
		if (me.mIdleReminderTimer != null) {
			me.mIdleReminderTimer.stop();
		}
		return false;
	}
}
