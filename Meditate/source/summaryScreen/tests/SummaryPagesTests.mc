using Toybox.Test;
using Toybox.WatchUi as Ui;

// the summary page table: which pages exist for which data
(:test)
class SummaryPagesTests {
	private static function metricWithData(id, window) {
		var m = new ScriptedMetric([10, 20, 30, 40], window);
		m.id = id;
		for (var i = 0; i < 4; i++) {
			m.sample(null);
		}
		return m.flush();
	}

	private static function hrvEntry(detailed) {
		var hrv = new HrvSummary();
		hrv.detailed = detailed;
		hrv.rmssd = 30.0;
		hrv.history = [30.0];
		return hrv;
	}

	// page titles in order; the hr graph is unique and first, so its return marks the wrap
	private static function pageTitles(summary) {
		var delegate = new SummaryViewDelegate(summary, null);
		var titles = [];
		for (var i = 0; i < 9; i++) {
			delegate.setPageIndex(i);
			var view = delegate.createScreenPickerView();
			var title = view instanceof GraphView ? Ui.loadResource(view.title) : view.mDetailsModel.title;
			if (i > 0 && title.equals(titles[0]) && view instanceof GraphView) {
				break;
			}
			titles.add(title);
		}
		return titles;
	}

	private static function equalTitles(titles, expected) {
		if (titles.size() != expected.size()) {
			return false;
		}
		for (var i = 0; i < titles.size(); i++) {
			if (!titles[i].equals(Ui.loadResource(expected[i]))) {
				return false;
			}
		}
		return true;
	}

	(:test)
	static function hrOnlyIsOnePage(logger) {
		var summary = new ActivitySummary(60, "s");
		summary.metrics[:hr] = new ScriptedMetric([], 10).flush();
		var stress = new ScriptedMetric([null, null], 2);
		stress.id = :stress;
		stress.sample(null);
		stress.sample(null);
		summary.metrics[:stress] = stress.flush();
		// a stress metric without a single value adds no page
		return equalTitles(pageTitles(summary), [Rez.Strings.SummaryHR]);
	}

	(:test)
	static function stressAndRespirationPagesFollowTheirData(logger) {
		var summary = new ActivitySummary(60, "s");
		summary.metrics[:hr] = metricWithData(:hr, 2);
		summary.metrics[:stress] = metricWithData(:stress, 2);
		summary.metrics[:rr] = metricWithData(:rr, 2);
		return equalTitles(pageTitles(summary), [
			Rez.Strings.SummaryHR,
			Rez.Strings.SummaryStress,
			Rez.Strings.SummaryStress,
			Rez.Strings.SummaryRespiration,
		]);
	}

	(:test)
	static function hrvOnAddsTheRmssdPage(logger) {
		var summary = new ActivitySummary(60, "s");
		summary.metrics[:hr] = metricWithData(:hr, 2);
		summary.metrics[:hrv] = hrvEntry(false);
		return equalTitles(pageTitles(summary), [Rez.Strings.SummaryHR, Rez.Strings.SummaryHRVRMSSD]);
	}

	(:test)
	static function hrvDetailedShowsEveryPage(logger) {
		var summary = new ActivitySummary(60, "s");
		summary.metrics[:hr] = metricWithData(:hr, 2);
		summary.metrics[:hrv] = hrvEntry(true);
		summary.metrics[:stress] = metricWithData(:stress, 2);
		summary.metrics[:rr] = metricWithData(:rr, 2);
		return equalTitles(pageTitles(summary), [
			Rez.Strings.SummaryHR,
			Rez.Strings.SummaryHRVRMSSD,
			Rez.Strings.SummaryStress,
			Rez.Strings.SummaryStress,
			Rez.Strings.SummaryHRVRMSSD,
			Rez.Strings.SummaryHRVpNNx,
			Rez.Strings.SummaryHRVSDRR,
			Rez.Strings.SummaryRespiration,
		]);
	}
}
