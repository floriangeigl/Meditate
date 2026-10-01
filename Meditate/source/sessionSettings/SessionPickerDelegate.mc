using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Attention;

class SessionPickerDelegate extends ScreenPickerDelegate {
	private var mSessionStorage;
	private var mSelectedSessionDetails;
	private var mSummaryRollupModel;
	private var mFeed;
	private var mHrvTracking;
	private var hrvStatusLineNum;
	// the session started last in this launch; the predecessor of the next one in a multi-session
	private var mLastStartedKey;

	function initialize(sessionStorage, beatIntervalFeed) {
		ScreenPickerDelegate.initialize(sessionStorage.getSelectedSessionIndex(), sessionStorage.getSessionsCount());
		me.mSessionStorage = sessionStorage;
		me.mHrvTracking = null;
		me.mSummaryRollupModel = new SummaryRollupModel();
		me.mSelectedSessionDetails = new DetailsModel();
		me.mFeed = beatIntervalFeed;
		me.mLastStartedKey = null;
		me.moveTo(SessionHistory.pickAtLaunch(sessionStorage.getSelectedSessionKey()));
		me.setSelectedSessionDetails();
		me.hrvStatusLineNum = null;
	}

	// a move the app makes, not the user; null or a key that is gone leaves the picker where it is
	function moveTo(key) {
		var index = me.mSessionStorage.indexOfKey(key);
		if (index != -1) {
			me.setPageIndex(index);
			SessionHistory.markAuto(key);
		}
	}

	// multi-session: what usually follows the session just done; null when nothing is learned
	function nextSessionKey() {
		var key = SessionHistory.suggest(me.mLastStartedKey);
		return me.mSessionStorage.indexOfKey(key) != -1 ? key : null;
	}

	function sessionName(key) {
		if (key == null) {
			return "";
		}
		return Utils.getSessionDisplayName(me.mSessionStorage.loadSessionByKey(key), me.mSessionStorage.indexOfKey(key));
	}

	// the feed has one listener slot; the picker holds it while browsing, the activity during a session
	function updatePickerHrvListener() {
		if (me.mHrvTracking != HrvTracking.Off) {
			me.mFeed.start();
			me.mFeed.setListener(method(:updateHrvStatus));
		} else {
			me.mFeed.stop();
			me.mFeed.setListener(null);
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
			var summaryRollupMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.summaryRollupMenu_title) });
			summaryRollupMenu.addItem(
				new Ui.MenuItem(Ui.loadResource(Rez.Strings.summaryRollupMenuOption_exit), "", RollupExitOption, {})
			);
			for (var i = 0; i < summaries.size(); i++) {
				var summaryModel = summaries[i];
				var sessionName =
					summaryModel.sessionName != null && summaryModel.sessionName.length() > 0
						? summaryModel.sessionName.toString()
						: "";
				var elapsedText = TimeFormatter.format(summaryModel.elapsedTime);
				summaryRollupMenu.addItem(new Ui.MenuItem(sessionName, elapsedText, i, {}));
			}
			var summaryRollupMenuDelegate = new SummaryRollupMenuDelegate(method(:onSummaryRollupMenuOption));
			Ui.pushView(summaryRollupMenu, summaryRollupMenuDelegate, Ui.SLIDE_LEFT);
			return true;
		} else {
			me.mFeed.stop();
			return false;
		}
	}

	function onSummaryRollupMenuOption(option) {
		if (option == RollupExitOption) {
			me.mFeed.stop();
			System.exit();
		} else {
			var summaryIndex = option;
			var summaryModel = me.mSummaryRollupModel.getSummary(summaryIndex);
			var summaryViewDelegate = new SummaryViewDelegate(summaryModel, null);
			Ui.pushView(summaryViewDelegate.createScreenPickerView(), summaryViewDelegate, Ui.SLIDE_LEFT);
		}
	}

	// Custom delegate so we keep the rollup menu in the stack when opening a summary view.
	// Unlike MenuOptionsDelegate, we do NOT pop the menu first; this allows user to press Back
	// from a summary view and return to the rollup menu instead of the session picker.
	class SummaryRollupMenuDelegate extends Ui.Menu2InputDelegate {
		private var mOnSelectCb;

		function initialize(onSelectCb) {
			Menu2InputDelegate.initialize();
			mOnSelectCb = onSelectCb;
		}

		function onSelect(item) {
			// Directly invoke callback without popping the menu view
			mOnSelectCb.invoke(item.getId());
		}
	}

	private function showSessionSettingsMenu() {
		Ui.pushView(
			SessionSettingsMenuDelegate.createMenu(me.mSessionStorage),
			new SessionSettingsMenuDelegate(me.mSessionStorage, me),
			Ui.SLIDE_UP
		);
		return true;
	}

	function startActivity() {
		// If there is no preparation time, start the meditate activity
		if (GlobalSettings.load(GlobalSettings.PrepareTimeKey) == 0) {
			startMeditationSession();
			return;
		}

		// Show preparation time view and start meditation session once the time is over
		var selectedSession = me.mSessionStorage.loadSelectedSession();
		var meditatePrepareView = new MeditatePrepareView(
			method(:startMeditationSession),
			1,
			selectedSession.getActiveBreathProgram()
		);
		var meditatePrepareDelegate = new MeditatePrepareDelegate(me, meditatePrepareView);
		Ui.switchToView(meditatePrepareView, meditatePrepareDelegate, Ui.SLIDE_IMMEDIATE);
	}

	function startMeditationSession() {
		var selectedSession = me.mSessionStorage.loadSelectedSession();
		// before the activity opens its fit session
		SessionHistory.record(selectedSession.key, me.mLastStartedKey);
		me.mLastStartedKey = selectedSession.key;
		var meditateModel = new MeditateModel(selectedSession);
		var displayName = Utils.getSessionDisplayName(selectedSession, me.mSelectedPageIndex);
		meditateModel.setDisplayName(displayName);
		var meditateView = new MeditateView(meditateModel);
		var meditateDelegate = new MeditateDelegate(meditateModel, me.mFeed, me);
		meditateDelegate.setMeditateView(meditateView);
		meditateDelegate.startActivity();
		Ui.switchToView(meditateView, meditateDelegate, Ui.SLIDE_LEFT);
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
		// keep the hrv off presentation set by setInitialHrvStatus; pollStatus counts error seconds
		if (me.hrvStatusLineNum == null || me.mHrvTracking == HrvTracking.Off) {
			return;
		}
		var hrvStatusLine = me.mSelectedSessionDetails.getLine(me.hrvStatusLineNum);
		var errorsBefore = me.mFeed.errorSeconds();
		var sensorStatus = me.mFeed.pollStatus();
		var errors = me.mFeed.errorSeconds();
		// the counter only moves while on screen, so these are exactly the recovery and the fifth error second
		if (sensorStatus == HeartbeatIntervalsSensorStatus.Good && errorsBefore > 0 && errors == 0) {
			Vibe.vibrate(VibePattern.Blip);
		} else if (sensorStatus == HeartbeatIntervalsSensorStatus.Error && errors > errorsBefore && errors % 5 == 0) {
			me.pulseBacklight();
		}
		if (sensorStatus != HeartbeatIntervalsSensorStatus.Error) {
			if (!(hrvStatusLine.icon instanceof HrvIcon)) {
				hrvStatusLine.icon = new HrvIcon({});
			}
			if (me.mHrvTracking == HrvTracking.On) {
				hrvStatusLine.icon.setStatusOn();
			} else {
				hrvStatusLine.icon.setStatusOnDetailed();
			}
		} else {
			if (!(hrvStatusLine.icon instanceof LoadingIcon)) {
				hrvStatusLine.icon = new LoadingIcon({});
			}
			hrvStatusLine.icon.tick();
		}
		hrvStatusLine.value.text = Utils.getHrvStatusText(sensorStatus, errors);
		Ui.requestUpdate();
	}

	private function pulseBacklight() {
		if (Attention has :backlight) {
			try {
				Attention.backlight(true);
			} catch (e instanceof Attention.BacklightOnTooLongException) {
				// burn in protection kicked in; backlight disabled; ignore
			}
		}
	}

	private function setInitialHrvStatus(hrvStatusLine, session) {
		if (hrvStatusLine.icon == null) {
			hrvStatusLine.icon = new HrvIcon({});
			hrvStatusLine.icon.setStatusWarning();
		}
		if (session.getHrvTracking() == HrvTracking.Off) {
			hrvStatusLine.icon.setStatusOff();
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVoff);
		} else {
			hrvStatusLine.value.text = Ui.loadResource(Rez.Strings.HRVstarting);
		}
		me.updateHrvStatus([]);
	}

	function addSummary(summaryModel) {
		me.mSummaryRollupModel.addSummary(summaryModel);
	}

	function updateSelectedSessionDetails(session) {
		if (me.mSelectedSessionDetails == null) {
			me.mSelectedSessionDetails = new DetailsModel();
		}
		var details = me.mSelectedSessionDetails;
		// Reset the details model in-place
		details.title = "";
		details.titleColor = null;
		details.detailLines = [];
		details.foregroundColor = null;
		details.linesCount = 0;

		var displayName = Utils.getSessionDisplayName(session, me.mSelectedPageIndex);
		details.title = displayName;
		details.titleColor = session.color;
		var lineNum = 0;
		var line = details.getLine(lineNum);

		var timeIcon = new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconTimeHalf,
		});
		line.icon = timeIcon;
		line.value.text = TimeFormatter.format(session.time);
		lineNum++;

		line = details.getLine(lineNum);
		var vibePatternIcon = new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconBell,
		});
		line.icon = vibePatternIcon;
		line.value.text = Utils.getVibePatternText(session.vibePattern);
		lineNum++;

		line = details.getLine(lineNum);
		var alertsLineIcon = new Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => Rez.Strings.IconTimeline,
		});
		line.icon = alertsLineIcon;
		var alertsToHighlightsLine = new AlertsToHighlightsLine(session);
		line.value = alertsToHighlightsLine.getAlertsLine();
		lineNum++;

		me.mHrvTracking = session.getHrvTracking();
		me.hrvStatusLineNum = lineNum;
		var hrvStatusLine = details.getLine(me.hrvStatusLineNum);
		me.setInitialHrvStatus(hrvStatusLine, session);
		me.updatePickerHrvListener();
		// Ensure the screen updates immediately when session details change
		Ui.requestUpdate();
	}

	function createScreenPickerView() {
		me.setSelectedSessionDetails();
		return new ScreenPickerDetailsView(me.mSelectedSessionDetails, true);
	}

	class AlertsToHighlightsLine {
		function initialize(session) {
			me.mSession = session;
		}

		private var mSession;

		function getAlertsLine() {
			var alertsLine = new PercentageHighlightLine(me.mSession.getIntervalAlerts().size());

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
