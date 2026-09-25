using Toybox.Test;
using Toybox.Graphics as Gfx;

(:test)
class MetricLineTests {
	(:test)
	static function hourglassCountsDownThenShowsTheValue(logger) {
		var line = new DetailsModel().getLine(0);
		var metric = new ScriptedMetric([60, 70, 80, null, null, null], 3);
		var icon = MeditateView.createIcon(:hr);
		var metricLine = new MetricLine(metric, line, icon);
		if (!(line.icon instanceof LoadingIcon)) {
			return false;
		}
		metric.sample(null);
		metricLine.update(metric.getValue(), 1);
		if (!line.value.text.equals("2") || line.value.color != Gfx.COLOR_LT_GRAY) {
			return false;
		}
		metric.sample(null);
		metricLine.update(metric.getValue(), 2);
		if (!line.value.text.equals("1") || !(line.icon instanceof LoadingIcon)) {
			return false;
		}
		// the window completes on this tick
		metric.sample(null);
		metricLine.update(metric.getValue(), 3);
		if (line.icon != icon || !line.value.text.equals(" 70") || line.value.color != null) {
			return false;
		}
		// a window without data after loading: icon stays, value gone
		for (var i = 0; i < 3; i++) {
			metric.sample(null);
		}
		metricLine.update(metric.getValue(), 6);
		return line.icon == icon && line.value.text.equals(" --");
	}

	(:test)
	static function pastTheLoadTimeWithoutDataShowsDashes(logger) {
		var line = new DetailsModel().getLine(0);
		var metric = new ScriptedMetric([null, null, null], 2);
		var metricLine = new MetricLine(metric, line, MeditateView.createIcon(:rr));
		for (var i = 1; i <= 3; i++) {
			metric.sample(null);
			metricLine.update(metric.getValue(), i);
		}
		return (
			line.icon instanceof LoadingIcon &&
			line.value.text.equals(" --") &&
			line.value.color == Gfx.COLOR_LT_GRAY
		);
	}

	(:test)
	static function pausedReadsAsNoValue(logger) {
		var line = new DetailsModel().getLine(0);
		var metric = new ScriptedMetric([50], 1).configure(null, null, false, true, true);
		var icon = MeditateView.createIcon(:stress);
		var metricLine = new MetricLine(metric, line, icon);
		metric.sample(null);
		metricLine.update(metric.getValue(), 1);
		if (line.icon != icon || !line.value.text.equals(" 50")) {
			return false;
		}
		// the view passes null while paused
		metricLine.update(null, 1);
		return line.icon == icon && line.value.text.equals(" --");
	}
}
