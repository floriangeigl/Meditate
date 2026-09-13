using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Lang;

class SummaryViewDelegate extends ScreenPicker.ScreenPickerDelegate {
	private var mSummary;
	private var mIdleReminderTimer;
	private var pages;
	private static const pageHeartRateGraph = "HeartRateGraph";
	private static const pageRespirationRateGraph = "RespirationRateGraph";
	private static const pageStressGraph = "StressGraph";
	private static const pageStress = "Stress";
	private static const pageHrvRmssd = "HrvRmssd";
	private static const pageHrvPnnx = "HrvPnnx";
	private static const pageHrvSdrr = "HrvSdrr";
	private static const pageHrvRmssdGraph = "HrvRmssdGraph";

	function initialize(summary, idleReminderTimer) {
		me.mSummary = summary;
		me.setPageIndexes();
		me.mPagesCount = me.pages.size();

		ScreenPickerDelegate.initialize(0, me.mPagesCount);
		me.mIdleReminderTimer = idleReminderTimer;
	}

	// page order is fixed; a page exists when its data does
	private function setPageIndexes() {
		var metrics = me.mSummary.metrics;
		var hrv = metrics[:hrv];
		var detailed = hrv != null && hrv.detailed;
		var stress = metrics[:stress];
		me.pages = new [0];
		me.pages.add(me.pageHeartRateGraph);
		if (detailed) {
			me.pages.add(me.pageHrvRmssdGraph);
		}
		if (stress != null && stress.hasData()) {
			me.pages.add(me.pageStressGraph);
			me.pages.add(me.pageStress);
		}
		if (hrv != null) {
			me.pages.add(me.pageHrvRmssd);
			if (detailed) {
				me.pages.add(me.pageHrvPnnx);
				me.pages.add(me.pageHrvSdrr);
			}
		}
		if (metrics[:rr] != null) {
			me.pages.add(me.pageRespirationRateGraph);
		}
	}

	private function createGraphView(id, title, minCut, maxCut) {
		var metric = me.mSummary.metrics[id];
		return new GraphView(metric != null ? metric.history : null, me.mSummary.elapsedTime, title, minCut, maxCut);
	}

	function createScreenPickerView() {
		var detailsModel;

		if (me.mSelectedPageIndex < me.mPagesCount) {
			var page = me.pages[me.mSelectedPageIndex];
			if (page.equals(me.pageHeartRateGraph)) {
				return me.createGraphView(:hr, Rez.Strings.SummaryHR, 20, 150);
			} else if (page.equals(me.pageRespirationRateGraph)) {
				return me.createGraphView(:rr, Rez.Strings.SummaryRespiration, 1, 60);
			} else if (page.equals(me.pageStressGraph)) {
				return me.createGraphView(:stress, Rez.Strings.SummaryStress, 0, 100);
			} else if (page.equals(me.pageStress)) {
				detailsModel = me.createDetailsPageStress();
			} else if (page.equals(me.pageHrvRmssd)) {
				detailsModel = me.createDetailsPageHrvRmssd();
			} else if (page.equals(me.pageHrvPnnx)) {
				detailsModel = me.createDetailsPageHrvPnnx();
			} else if (page.equals(me.pageHrvSdrr)) {
				detailsModel = me.createDetailsPageHrvSdrr();
			} else if (page.equals(me.pageHrvRmssdGraph)) {
				return me.createGraphView(:hrv, Rez.Strings.SummaryHRVRMSSD, 0, 250);
			} else {
				return me.createGraphView(:hr, Rez.Strings.SummaryHR, 20, 150);
			}
		} else {
			return me.createGraphView(:hr, Rez.Strings.SummaryHR, 20, 150);
		}
		return new ScreenPicker.ScreenPickerDetailsView(detailsModel, me.mPagesCount > 1);
	}

	private function createDetailsPageStress() {
		var stress = me.mSummary.metrics[:stress];
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(Rez.Strings.SummaryStress);

		var line = null;
		var lowStressIcon = new ScreenPicker.StressIcon({});
		lowStressIcon.setStress(stress.getAvg());

		line = detailsModel.getLine(0);
		line.icon = lowStressIcon;
		line.value.text = Lang.format("$1$  $2$", [
			Ui.loadResource(Rez.Strings.SummaryAvg),
			ScreenPicker.ScreenPickerBaseView.formatValue(stress.getAvg()),
		]);
		var offset = 0;
		if (stress.first != null && stress.last != null) {
			line = detailsModel.getLine(1);
			line.value.text = Lang.format("$1$ $2$", [
				Ui.loadResource(Rez.Strings.SummaryStart),
				ScreenPicker.ScreenPickerBaseView.formatValue(stress.first),
			]);
			line = detailsModel.getLine(2);
			line.value.text = Lang.format("$1$ $2$", [
				Ui.loadResource(Rez.Strings.SummaryEnd),
				ScreenPicker.ScreenPickerBaseView.formatValue(stress.last),
			]);
			offset = 2;
		}

		if (stress.min != null && stress.max != null) {
			line = detailsModel.getLine(1 + offset);
			line.value.text = Lang.format("$1$ $2$", [
				Ui.loadResource(Rez.Strings.SummaryMin),
				ScreenPicker.ScreenPickerBaseView.formatValue(stress.min),
			]);
			line = detailsModel.getLine(2 + offset);
			line.value.text = Lang.format("$1$ $2$", [
				Ui.loadResource(Rez.Strings.SummaryMax),
				ScreenPicker.ScreenPickerBaseView.formatValue(stress.max),
			]);
		}
		return detailsModel;
	}

	private function createDetailsPageHrvRmssd() {
		var detailsModel = new ScreenPicker.DetailsModel();
		detailsModel.title = Ui.loadResource(Rez.Strings.SummaryHRVRMSSD);
		var line = detailsModel.getLine(0);
		line.icon = new ScreenPicker.HrvIcon({});
		line.value.text = Lang.format("$1$ ms", [
			ScreenPicker.ScreenPickerBaseView.formatValue(me.mSummary.metrics[:hrv].rmssd),
		]);
		return detailsModel;
	}

	private function createDetailsPageHrvPnnx() {
		var hrv = me.mSummary.metrics[:hrv];
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

	private function createDetailsPageHrvSdrr() {
		var hrv = me.mSummary.metrics[:hrv];
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
