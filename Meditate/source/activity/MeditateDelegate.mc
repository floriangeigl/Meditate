using Toybox.WatchUi as Ui;

class MeditateDelegate extends Ui.BehaviorDelegate {
	private var mMeditateModel;
	private var mMeditateActivity;
	private var mSummaryModels;
	private var mSessionPickerDelegate;
	private var mHeartbeatIntervalsSensor;
	private var mSummaryModel;
	private var mShouldAutoExit;

	function initialize(meditateModel, summaryModels, heartbeatIntervalsSensor, sessionPickerDelegate) {
		BehaviorDelegate.initialize();
		me.mMeditateModel = meditateModel;
		me.mSummaryModels = summaryModels;
		me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
		me.mMeditateActivity = new MediteActivity(meditateModel, heartbeatIntervalsSensor, me);
		me.mSessionPickerDelegate = sessionPickerDelegate;
		me.mSummaryModel = null;
	}

	public function startActivity() {
		me.mMeditateActivity.start();
	}

	public function stopActivity() {
		me.mMeditateActivity.stop();

		// Store auto-exit state as class member
		var confirmSaveActivity = GlobalSettings.loadConfirmSaveActivity();
		me.mShouldAutoExit = confirmSaveActivity == ConfirmSaveActivity.AutoYesExit;

		// If there is no finalize time, proceed directly to finishing flow
		if (GlobalSettings.loadFinalizeTime() == 0) {
			onShowDelayedFinishedView();
			return;
		}

		// Show finalize time view and delayed finished view session once the time is over
		var meditatePrepareView = new MeditatePrepareView(method(:onShowDelayedFinishedView), 0);
		var meditatePrepareDelegate = new MeditatePrepareDelegate(me, meditatePrepareView);
		Ui.switchToView(meditatePrepareView, meditatePrepareDelegate, Ui.SLIDE_IMMEDIATE);
	}

	function onShowDelayedFinishedView() {
		var calculatingResultsView = new DelayedFinishingView(method(:onFinishActivity), me.mShouldAutoExit);
		Ui.switchToView(calculatingResultsView, me, Ui.SLIDE_IMMEDIATE);
	}

	function onFinishActivity() {
		me.mSummaryModel = me.mMeditateActivity.calculateSummaryFields();

		var confirmSaveActivity = GlobalSettings.loadConfirmSaveActivity();
		var nextView = null;

		if (
			confirmSaveActivity == ConfirmSaveActivity.AutoYes ||
			confirmSaveActivity == ConfirmSaveActivity.AutoYesExit
		) {
			//Made sure reading/writing session settings for the next session in multi-session mode happens before saving the FIT file.
			//If both happen at the same time FIT file gets corrupted
			me.mMeditateActivity.finish();
			nextView = new DelayedFinishingView(me.method(:onShowNextView), me.mShouldAutoExit);
		} else if (confirmSaveActivity == ConfirmSaveActivity.AutoNo) {
			me.mMeditateActivity.discard();
			nextView = new DelayedFinishingView(method(:onShowNextView), me.mShouldAutoExit);
		} else {
			nextView = new DelayedFinishingView(method(:onShowNextViewConfirmDialog), me.mShouldAutoExit);
		}
		Ui.switchToView(nextView, me, Ui.SLIDE_IMMEDIATE);
	}

	//this reads/writes session settings and needs to happen before saving session to avoid FIT file corruption
	private function showSummaryView(summaryModel) {
		var summaryViewDelegate = new SummaryViewDelegate(
			summaryModel,
			me.mMeditateActivity.method(:discardDanglingActivity)
		);
		var view = summaryViewDelegate.createScreenPickerView();
		if (view != null) {
			Ui.switchToView(view, summaryViewDelegate, Ui.SLIDE_IMMEDIATE);
		}
	}

	function onShowNextViewConfirmDialog() {
		onShowNextView();

		var confirmSaveHeader = Ui.loadResource(Rez.Strings.ConfirmSaveHeader);
		var confirmSaveDialog = new Ui.Confirmation(confirmSaveHeader);
		Ui.pushView(
			confirmSaveDialog,
			new YesNoDelegate(me.mMeditateActivity.method(:finish), me.mMeditateActivity.method(:discard)),
			Ui.SLIDE_IMMEDIATE
		);
	}

	function onShowNextView() {
		var continueAfterFinishingSession = GlobalSettings.loadMultiSession();
		if (continueAfterFinishingSession == MultiSession.Yes) {
			showSessionPickerView(me.mSummaryModel);
		} else {
			if (me.mHeartbeatIntervalsSensor != null) {
				me.mHeartbeatIntervalsSensor.stop();
				me.mHeartbeatIntervalsSensor = null;
			}
			showSummaryView(me.mSummaryModel);
		}
	}

	private function showSessionPickerView(summaryModel) {
		me.mSessionPickerDelegate.addSummary(summaryModel);
		Ui.switchToView(
			me.mSessionPickerDelegate.createScreenPickerView(),
			me.mSessionPickerDelegate,
			Ui.SLIDE_IMMEDIATE
		);
	}

	function onBack() {
		// back button to pause/resume the activity
		me.mMeditateModel.isTimerRunning = me.mMeditateActivity.pauseResume();
		return true;
	}

	private const MinMeditateActivityStopTime = 1;

	function onKey(keyEvent) {
		if (keyEvent.getKey() == Ui.KEY_ENTER && me.mMeditateModel.elapsedTime >= MinMeditateActivityStopTime) {
			me.stopActivity();
			return true;
		}
		return false;
	}

	function toggleColorTheme() {
		// var currentColorTheme = me.mMeditateModel;
		// Dark results theme
		//if (currentColorTheme == ColorTheme.Dark) {
		//	me.mMeditateModel.
		//	me.mMeditateModel.backgroundColor = Gfx.COLOR_BLACK;
		//	me.mMeditateModel.foregroundColor = Gfx.COLOR_WHITE;
		//} else {
		//	// Light results theme
		//	me.mMeditateModel.backgroundColor = Gfx.COLOR_WHITE;
		//	me.mMeditateModel.foregroundColor = Gfx.COLOR_BLACK;
		//}
	}

	function onMenu() {
		toggleColorTheme();
	}

	function onHold(param) {
		toggleColorTheme();
	}
}
