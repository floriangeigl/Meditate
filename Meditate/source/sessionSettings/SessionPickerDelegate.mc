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
	private var mHrvTracking;
	private var hrvStatusLineNum;

	function initialize(sessionStorage, heartbeatIntervalsSensor) {
		ScreenPickerDelegate.initialize(sessionStorage.getSelectedSessionIndex(), sessionStorage.getSessionsCount());
		me.mSessionStorage = sessionStorage;
		me.mHrvTracking = null;
		me.mSummaryRollupModel = new SummaryRollupModel();
		me.mSelectedSessionDetails = new ScreenPicker.DetailsModel();
		me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
		me.setSelectedSessionDetails();
		me.hrvStatusLineNum = null;
	}

	function setTestModeHeartbeatIntervalsSensor() {
		if (me.mHrvTracking != HrvTracking.Off) {
			me.mHeartbeatIntervalsSensor.start();
			me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(method(:updateHrvStatus));
		} else {
			me.mHeartbeatIntervalsSensor.stop();
			me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
		}
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
			return false;
		}
	}

	function onSummaryRollupMenuOption(option) {
		if (option == RollupExitOption) {
			me.mHeartbeatIntervalsSensor.stop();
			System.exit();
		} else {
			var summaryIndex = option;
			var summaryModel = me.mSummaryRollupModel.getSummary(summaryIndex);
			var summaryViewDelegate = new SummaryViewDelegate(summaryModel, null);
			Ui.pushView(summaryViewDelegate.createScreenPickerView(), summaryViewDelegate, Ui.SLIDE_LEFT);
		}
	}

	private function showSessionSettingsMenu() {
		// Build a Menu2 root so the delegate can update subtexts (counts, selected index)
		var menu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuSessionSettings_Title) });
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_start), "", :start, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_edit), "", :edit, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_delete), "", :delete, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_addNew), "", :addNew, {}));
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_globalSettings), "", :globalSettings, {})
		);
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.menuSessionSettings_about), "", :about, {}));

		var sessionSettingsMenuDelegate = new SessionSettingsMenuDelegate(me.mSessionStorage, me, menu);
		sessionSettingsMenuDelegate.updateMenuItems();
		Ui.pushView(menu, sessionSettingsMenuDelegate, Ui.SLIDE_UP);
		return true;
	}

	function startActivity() {
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
			return me.showSessionSettingsMenu();
		}
		return false;
	}

	function onTap(clickEvent) {
		return me.showSessionSettingsMenu();
	}

	private function setSelectedSessionDetails() {
		me.mSessionStorage.selectSession(me.mSelectedPageIndex);
		var session = me.mSessionStorage.loadSelectedSession();
		ScreenPickerDelegate.setPagesCount(me.mSessionStorage.getSessionsCount());
		me.updateSelectedSessionDetails(session);
	}

	function updateHrvStatus(data) {
		if (me.hrvStatusLineNum == null) {
			return;
		}
		var hrvStatusLine = me.mSelectedSessionDetails.getLine(me.hrvStatusLineNum);
		var sensorStatus = me.mHeartbeatIntervalsSensor.getStatus();
		if (sensorStatus != HeartbeatIntervalsSensorStatus.Error) {
			if (me.mHrvTracking == HrvTracking.On) {
				hrvStatusLine.icon.setStatusOn();
			} else {
				hrvStatusLine.icon.setStatusOnDetailed();
			}
		} else {
			hrvStatusLine.icon.setStatusWarning();
		}
		hrvStatusLine.value.text = Utils.getHrvStatusText(sensorStatus);
		Ui.requestUpdate();
	}

	private function setInitialHrvStatus(hrvStatusLine, session) {
		if (hrvStatusLine.icon == null) {
			hrvStatusLine.icon = new ScreenPicker.HrvIcon({});
			hrvStatusLine.icon.setStatusWarning();
		}
		if (session.getHrvTracking() == HrvTracking.Off) {
			hrvStatusLine.icon.setStatusOff();
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVoff);
		} else {
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVwaiting);
		}
		me.updateHrvStatus([]);
	}

	function addSummary(summaryModel) {
		me.mSummaryRollupModel.addSummary(summaryModel);
	}

	function updateSelectedSessionDetails(session) {
		// Reuse the existing DetailsModel instance so the active view (which may
		// hold a reference to it) sees mutations immediately. If it doesn't
		// exist yet, create it.
		if (me.mSelectedSessionDetails == null) {
			me.mSelectedSessionDetails = new ScreenPicker.DetailsModel();
		}
		var details = me.mSelectedSessionDetails;
		// Reset the details model in-place
		details.title = "";
		details.titleColor = null;
		details.detailLines = [];
		details.foregroundColor = null;
		details.linesCount = 0;

		var activityTypeText = Utils.getActivityTypeText(session.getActivityType());
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
		line.value.text = Utils.getVibePatternText(session.vibePattern);
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

		me.mHrvTracking = session.getHrvTracking();
		me.hrvStatusLineNum = lineNum;
		var hrvStatusLine = details.getLine(me.hrvStatusLineNum);
		me.setInitialHrvStatus(hrvStatusLine, session);
		me.setTestModeHeartbeatIntervalsSensor();
		// Ensure the screen updates immediately when session details change
		Ui.requestUpdate();
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
			var alertsLine = new ScreenPicker.PercentageHighlightLine(me.mSession.getIntervalAlerts().size());

			alertsLine.backgroundColor = me.mSession.color;

			me.AddHighlights(alertsLine, IntervalAlertType.Repeat);
			me.AddHighlights(alertsLine, IntervalAlertType.OneOff);

			return alertsLine;
		}

		private function AddHighlights(alertsLine, alertsType) {
			var intervalAlerts = me.mSession.getIntervalAlerts();

			for (var i = 0; i < intervalAlerts.size(); i++) {
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
