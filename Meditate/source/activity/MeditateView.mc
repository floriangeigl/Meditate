using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

// one metrics page row: hourglass with countdown until the first value, then the metric icon
class MetricLine {
	var metric;
	private var mLine;
	private var mIcon;
	private var mLoadingIcon;
	private var mLoaded;

	function initialize(metric, line, icon) {
		me.metric = metric;
		me.mLine = line;
		me.mIcon = icon;
		me.mLoadingIcon = new LoadingIcon({});
		me.mLoaded = false;
		me.mLine.icon = me.mLoadingIcon;
	}

	function update(value, elapsed) {
		me.mLine.value.text = ScreenPickerBaseView.formatValue(value);
		if (value != null) {
			me.mLoaded = true;
			me.mLine.icon = me.mIcon;
			me.mIcon.setLive(value);
			me.mLine.value.color = null;
		} else if (me.mLoaded) {
			me.mIcon.setColorInactive();
		} else {
			me.mLoadingIcon.tick();
			var remain = me.metric.getLoadTime() - elapsed;
			if (remain > 0) {
				me.mLine.value.text = remain.toNumber().toString();
			}
			me.mLine.value.color = Gfx.COLOR_LT_GRAY;
		}
	}
}

class MeditateView extends ScreenPickerDetailsCenterView {
	private var mMeditateModel;
	private var mMainDurationRenderer;
	private var mIntervalAlertsRenderer;
	private var mLines;
	private var mBreathGuidanceRenderer;
	private var mBreathStepPercentages;
	private var mShowGuidancePage;
	private var mForceRedraw;

	function initialize(meditateModel) {
		// the up/down chevrons are the affordance for the guidance <-> metrics toggle
		ScreenPickerDetailsCenterView.initialize(meditateModel, meditateModel.hasBreathProgram());
		me.mMeditateModel = meditateModel;
		me.mMainDurationRenderer = null;
		me.mIntervalAlertsRenderer = null;
		me.mLines = null;
		me.mBreathGuidanceRenderer = null;
		me.mBreathStepPercentages = null;
		// guidance leads every breathwork session; metrics is one press away
		me.mShowGuidancePage = meditateModel.hasBreathProgram();
		me.mForceRedraw = false;
	}

	// the one icon per metric id, shared with the summary details page
	static function createIcon(id) {
		if (id == :hrv) {
			return new HrvIcon({});
		} else if (id == :stress) {
			return new StressIcon({});
		} else if (id == :rr) {
			return new BreathIcon({});
		}
		return new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconHeart,
			:color => Gfx.COLOR_RED,
		});
	}

	// Load your resources here
	function onLayout(dc) {
		ScreenPickerDetailsCenterView.onLayout(dc);

		// lines survive a re-layout so a loaded metric does not fall back to the hourglass
		if (me.mLines == null) {
			me.mLines = [];
			var metrics = me.mMeditateModel.liveMetrics;
			for (var i = 0; i < metrics.size(); i++) {
				var icon = MeditateView.createIcon(metrics[i].id);
				me.mLines.add(new MetricLine(metrics[i], me.mMeditateModel.getLine(i), icon));
			}
		}

		me.mMainDurationRenderer = new ElapsedDurationRenderer(me.mMeditateModel.getColor(), null, null);

		var hasIntervalAlerts = me.mMeditateModel.hasIntervalAlerts();
		if (hasIntervalAlerts || me.mMeditateModel.hasBreathProgram()) {
			me.mIntervalAlertsRenderer = new IntervalAlertsRenderer(
				dc,
				me.mMeditateModel.getSessionTime(),
				hasIntervalAlerts ? me.mMeditateModel.getIntervalAlerts() : null
			);
		}

		if (me.mMeditateModel.hasBreathProgram()) {
			me.setArrowsColor(null);
			me.mBreathGuidanceRenderer = new BreathGuidanceRenderer(dc, me.foregroundColor);
			me.mBreathStepPercentages = me.buildStepPercentages();
		}
	}

	// step boundaries as fractions of the session, for the tick ring on the guidance page
	private function buildStepPercentages() {
		var runner = me.mMeditateModel.getBreathRunner();
		if (runner == null) {
			return null;
		}
		var total = runner.getTotalTime();
		if (total < 1) {
			return null;
		}
		var offsets = runner.getStepOffsets();
		// skip offset 0 (session start) and the final offset (session end)
		var count = offsets.size() - 2;
		if (count < 1) {
			return null;
		}
		var percentages = new [count];
		for (var i = 0; i < count; i++) {
			percentages[i] = offsets[i + 1].toDouble() / total.toDouble();
		}
		return percentages;
	}

	function toggleBreathPage() {
		if (!me.mMeditateModel.hasBreathProgram()) {
			return false;
		}
		me.mShowGuidancePage = !me.mShowGuidancePage;
		// the 1 Hz gate below would otherwise swallow a switch made within the same second
		me.mForceRedraw = true;
		return true;
	}

	var lastElapsedTime = -1;

	// Update the view
	function onUpdate(dc) {
		var elapsedTime = me.mMeditateModel.elapsedTime;
		if (me.mShowGuidancePage) {
			if (elapsedTime != lastElapsedTime || !me.mMeditateModel.isTimerRunning || me.mForceRedraw) {
				me.drawGuidancePage(dc, elapsedTime);
			}
			lastElapsedTime = elapsedTime;
			me.mForceRedraw = false;
			return;
		}
		// Only update every second
		if (elapsedTime != lastElapsedTime || !me.mMeditateModel.isTimerRunning || me.mForceRedraw) {
			me.mMeditateModel.title = TimeFormatter.format(elapsedTime);
			// paused reads as no value: every icon goes grey
			var running = me.mMeditateModel.isTimerRunning;
			for (var i = 0; i < me.mLines.size(); i++) {
				var line = me.mLines[i];
				line.update(running ? line.metric.getValue() : null, elapsedTime);
			}

			ScreenPickerDetailsCenterView.onUpdate(dc);
			me.mMainDurationRenderer.drawOverallElapsedTime(dc, elapsedTime, me.mMeditateModel.getSessionTime());
			if (me.mIntervalAlertsRenderer != null) {
				me.mIntervalAlertsRenderer.drawAllIntervalAlerts(dc);
			}
		}
		lastElapsedTime = elapsedTime;
		me.mForceRedraw = false;
	}

	// Drawn without the DetailsCenterView chain: the metrics lines are not wanted here, and
	// reaching ScreenPickerBaseView.onUpdate would mean skipping a level in the class chain.
	private function drawGuidancePage(dc, elapsedTime) {
		dc.setColor(Gfx.COLOR_TRANSPARENT, me.backgroundColor);
		dc.clear();
		me.drawArrows(dc);

		me.mMainDurationRenderer.drawOverallElapsedTime(dc, elapsedTime, me.mMeditateModel.getSessionTime());
		if (me.mIntervalAlertsRenderer != null) {
			me.mIntervalAlertsRenderer.drawTicksAt(dc, me.mBreathStepPercentages, me.mMeditateModel.getColor());
		}
		me.mBreathGuidanceRenderer.draw(dc, me.mMeditateModel.getBreathRunner());
	}
}
