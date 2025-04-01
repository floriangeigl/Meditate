using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using HrvAlgorithms.HrvTracking;
using StatusIconFonts;

class SessionPickerDelegate extends ScreenPicker.ScreenPickerDelegate {
	private var mSessionStorage;
	private var mSelectedSessionDetails;
	private var mSummaryRollupModel;
	private var mHeartbeatIntervalsSensor;
	private var mLastHrvTracking;
	private var mSuccessiveEmptyHeartbeatIntervalsCount;
	private var timer;
	private var heartBeatIntervalsSize;
	private var heartBeatIntervalsLastValid;

	function initialize(sessionStorage, heartbeatIntervalsSensor) {
		ScreenPickerDelegate.initialize(sessionStorage.getSelectedSessionIndex(), sessionStorage.getSessionsCount());
		me.mSessionStorage = sessionStorage;
		me.mSummaryRollupModel = new SummaryRollupModel();
		me.mSelectedSessionDetails = new ScreenPicker.DetailsModel();
		me.mLastHrvTracking = null;
		me.initializeHeartbeatIntervalsSensor(heartbeatIntervalsSensor);
		me.setSelectedSessionDetails();

		me.timer = new Timer.Timer();
		me.timer.start(method(:updateHrvStatus), 1000, true);
		me.heartBeatIntervalsSize = 0;
		me.heartBeatIntervalsLastValid = Time.now().subtract(new Time.Duration(10));
	}

	private function initializeHeartbeatIntervalsSensor(heartbeatIntervalsSensor) {
		me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
	}

	function setTestModeHeartbeatIntervalsSensor(hrvTracking) {
		if (hrvTracking == me.mLastHrvTracking) {
			if (hrvTracking != HrvTracking.Off) {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(
					method(:onHeartbeatIntervalsListener)
				);
			} else {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
			}
		} else {
			if (hrvTracking != HrvTracking.Off) {
				me.mHeartbeatIntervalsSensor.start();
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(
					method(:onHeartbeatIntervalsListener)
				);
			} else {
				me.mHeartbeatIntervalsSensor.stop();
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
			}
		}
		me.mLastHrvTracking = hrvTracking;
	}

	function onMenu() {
		return me.showSessionSettingsMenu();
	}

	function onHold(param) {
		return me.onMenu();
	}

	private const RollupExitOption = :exitApp;

	function onBack() {
		var summaries = me.mSummaryRollupModel.getSummaries();
		if (summaries.size() > 0) {
			var summaryRollupMenu = new Ui.Menu();
			summaryRollupMenu.setTitle(Ui.loadResource(Rez.Strings.summaryRollupMenu_title));
			summaryRollupMenu.addItem(Ui.loadResource(Rez.Strings.summaryRollupMenuOption_exit), RollupExitOption);
			for (var i = 0; i < summaries.size(); i++) {
				summaryRollupMenu.addItem(TimeFormatter.format(summaries[i].elapsedTime), i);
			}
			var summaryRollupMenuDelegate = new MenuOptionsDelegate(method(:onSummaryRollupMenuOption));
			Ui.pushView(summaryRollupMenu, summaryRollupMenuDelegate, Ui.SLIDE_LEFT);
			return true;
		} else {
			me.mHeartbeatIntervalsSensor.stop();
			me.mHeartbeatIntervalsSensor.disableHrSensor();
			return false;
		}
	}

	function onSummaryRollupMenuOption(option) {
		if (option == RollupExitOption) {
			me.mHeartbeatIntervalsSensor.stop();
			me.mHeartbeatIntervalsSensor.disableHrSensor();
			System.exit();
		} else {
			var summaryIndex = option;
			var summaryModel = me.mSummaryRollupModel.getSummary(summaryIndex);
			var summaryViewDelegate = new SummaryViewDelegate(
				summaryModel,
				MeditateModel.isRespirationRateOn(),
				null
			);
			Ui.pushView(summaryViewDelegate.createScreenPickerView(), summaryViewDelegate, Ui.SLIDE_LEFT);
		}
	}

	private function showSessionSettingsMenu() {
		var sessionSettingsMenuDelegate = new SessionSettingsMenuDelegate(me.mSessionStorage, me);
		Ui.pushView(new Rez.Menus.sessionSettingsMenu(), sessionSettingsMenuDelegate, Ui.SLIDE_UP);
		return true;
	}

	private function startActivity() {
		me.timer.stop();
		// If there is no preparation time, start the meditate activity
		if (GlobalSettings.loadPrepareTime() == 0) {
			startMeditationSession();
			return;
		}

		// Show preparation time view and start meditation session once the time is over
		var meditatePrepareView = new MeditatePrepareView(method(:startMeditationSession), 1);
		var meditatePrepareDelegate = new MeditatePrepareDelegate(me, meditatePrepareView);
		Ui.switchToView(meditatePrepareView, meditatePrepareDelegate, Ui.SLIDE_IMMEDIATE);
	}

	function startMeditationSession() {
		var selectedSession = me.mSessionStorage.loadSelectedSession();
		var meditateModel = new MeditateModel(selectedSession);
		var meditateView = new MeditateView(meditateModel);
		me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
		var mediateDelegate = new MeditateDelegate(
			meditateModel,
			me.mSummaryRollupModel,
			me.mHeartbeatIntervalsSensor,
			me
		);
		mediateDelegate.startActivity();
		Ui.switchToView(meditateView, mediateDelegate, Ui.SLIDE_LEFT);
	}

	function onKey(keyEvent) {
		if (keyEvent.getKey() == Ui.KEY_ENTER) {
			me.startActivity();
			return true;
		}
		return false;
	}

	function onTap(clickEvent) {
		me.startActivity();
		return true;
	}

	private function setSelectedSessionDetails() {
		me.mSessionStorage.selectSession(me.mSelectedPageIndex);
		var session = me.mSessionStorage.loadSelectedSession();
		ScreenPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
		me.updateSelectedSessionDetails(session);
	}

	private static function getVibePatternText(vibePattern) {
		if (vibePattern == null) {
			vibePattern = VibePattern.NoNotification;
		}
		switch (vibePattern) {
			case VibePattern.LongPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longPulsating);
			case VibePattern.LongSound:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longSound);
			case VibePattern.LongAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longAscending);
			case VibePattern.LongContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longContinuous);
			case VibePattern.LongDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_longDescending);
			case VibePattern.MediumAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumAscending);
			case VibePattern.MediumContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumContinuous);
			case VibePattern.MediumPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumPulsating);
			case VibePattern.MediumDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_mediumDescending);
			case VibePattern.ShortAscending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortAscending);
			case VibePattern.ShortContinuous:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortContinuous);
			case VibePattern.ShortPulsating:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortPulsating);
			case VibePattern.ShortDescending:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_shortDescending);
			default:
				return Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification);
		}
	}

	function onHeartbeatIntervalsListener(heartBeatIntervals) {
		me.heartBeatIntervalsSize = heartBeatIntervals.size();
		if (me.heartBeatIntervalsSize > 0) 
		{
			me.heartBeatIntervalsLastValid = Time.now();
		}
	}

	function updateHrvStatus() {
		var timeSinceLastValid = Time.now().value() - me.heartBeatIntervalsLastValid.value();
		var hrvStatusLine = me.mSelectedSessionDetails.getLine(3);
		if (timeSinceLastValid <= 5) {
			if (me.mLastHrvTracking == HrvTracking.On) {
				hrvStatusLine.icon.setStatusOn();
			} else {
				hrvStatusLine.icon.setStatusOnDetailed();
			}
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVready);
		} else {
			hrvStatusLine.icon.setStatusWarning();
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVwaiting);
		}
		Ui.requestUpdate();

		if (timeSinceLastValid >= 30 && timeSinceLastValid % 30 == 0) {
			System.println("Restart HR sensor");
			if (me.mHeartbeatIntervalsSensor != null) {
				me.mHeartbeatIntervalsSensor.stop();
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
			}
			me.mHeartbeatIntervalsSensor = new HrvAlgorithms.HeartbeatIntervalsSensor();
			me.mHeartbeatIntervalsSensor.enableHrSensor();
			me.mHeartbeatIntervalsSensor.start();
			me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(
					method(:onHeartbeatIntervalsListener)
				);
		}
	}

	private function setInitialHrvStatus(hrvStatusLine, session) {
		hrvStatusLine.icon = new ScreenPicker.HrvIcon({});
		if (session.getHrvTracking() == HrvTracking.Off) {
			hrvStatusLine.icon.setStatusOff();
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVoff);
		} else {
			hrvStatusLine.icon.setStatusWarning();
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVwaiting);
		}
	}

	function addSummary(summaryModel) {
		me.mSummaryRollupModel.addSummary(summaryModel);
	}

	function updateSelectedSessionDetails(session) {
		me.setTestModeHeartbeatIntervalsSensor(session.getHrvTracking());
		me.mSelectedSessionDetails = new ScreenPicker.DetailsModel();
		var details = me.mSelectedSessionDetails;

		var activityTypeText;
		if (session.getActivityType() == ActivityType.Yoga) {
			activityTypeText = Ui.loadResource(Rez.Strings.activityNameYoga); // Due to bug in Connect IQ API for breath activity to get respiration rate, we will use Yoga as default meditate activity
		} else if (session.getActivityType() == ActivityType.Breathing) {
			activityTypeText = Ui.loadResource(Rez.Strings.activityNameBreathing);
		} else {
			// Meditation
			activityTypeText = Ui.loadResource(Rez.Strings.activityNameMeditate);
		}
		if (session.name != null) {
			details.title = session.name;
		} else {
			details.title = activityTypeText + " " + (me.mSelectedPageIndex + 1);
		}
		details.titleColor = session.color;
		var lineNum = 0;
		var line = details.getLine(lineNum);

		var timeIcon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconTimeHalf,
		});
		line.icon = timeIcon;
		line.value.text = TimeFormatter.format(session.time);
		lineNum++;

		line = details.getLine(lineNum);
		var vibePatternIcon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconBell,
		});
		line.icon = vibePatternIcon;
		line.value.text = getVibePatternText(session.vibePattern);
		lineNum++;

		line = details.getLine(lineNum);
		var alertsLineIcon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconTimeline,
		});
		line.icon = alertsLineIcon;
		var alertsToHighlightsLine = new AlertsToHighlightsLine(session);
		line.value = alertsToHighlightsLine.getAlertsLine();
		lineNum++;

		var hrvStatusLine = details.getLine(lineNum);
		me.setInitialHrvStatus(hrvStatusLine, session);
		lineNum++;

		line = details.getLine(lineNum);
		var settingsIcon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconSettings,
		});
		line.icon = settingsIcon;
		line.value.text = Ui.loadResource(Rez.Strings.optionsMenuHelp);
	}

	function createScreenPickerView() {
		me.setSelectedSessionDetails();
		return new ScreenPicker.ScreenPickerDetailsView(me.mSelectedSessionDetails, true);
	}

	class AlertsToHighlightsLine {
		function initialize(session) {
			me.mSession = session;
		}

		private var mSession;

		function getAlertsLine() {
			var alertsLine = new ScreenPicker.PercentageHighlightLine(me.mSession.intervalAlerts.count());

			alertsLine.backgroundColor = me.mSession.color;

			me.AddHighlights(alertsLine, IntervalAlertType.Repeat);
			me.AddHighlights(alertsLine, IntervalAlertType.OneOff);

			return alertsLine;
		}

		private function AddHighlights(alertsLine, alertsType) {
			var intervalAlerts = me.mSession.intervalAlerts;

			for (var i = 0; i < intervalAlerts.count(); i++) {
				var alert = intervalAlerts.get(i);
				if (alert.type == alertsType) {
					var percentageTimes = alert.getAlertProgressBarPercentageTimes(me.mSession.time);
					for (var percentageIndex = 0; percentageIndex < percentageTimes.size(); percentageIndex++) {
						alertsLine.addHighlight(alert.color, percentageTimes[percentageIndex]);
					}
				}
			}
		}
	}
}
