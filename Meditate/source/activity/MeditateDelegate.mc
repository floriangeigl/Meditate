using Toybox.WatchUi as Ui;
using Toybox.System;

class MeditateDelegate extends Ui.BehaviorDelegate {
	private var mMeditateModel;
	private var mMeditateActivity;
	private var mSummaryModels;
	private var mSessionPickerDelegate;
	private var mHeartbeatIntervalsSensor;
	private var mSummaryModel;
	private var mShouldAutoExit;
	private var mPauseMenuVisible;
	private const PauseReasonManual = 0;
	private const PauseReasonCompleted = 1;

	function initialize(meditateModel, summaryModels, heartbeatIntervalsSensor, sessionPickerDelegate) {
		BehaviorDelegate.initialize();
		me.mMeditateModel = meditateModel;
		me.mSummaryModels = summaryModels;
		me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
		me.mMeditateActivity = new MeditateActivity(meditateModel, heartbeatIntervalsSensor, me);
		me.mSessionPickerDelegate = sessionPickerDelegate;
		me.mSummaryModel = null;
		me.mPauseMenuVisible = false;
	}

	public function startActivity() {
		me.mMeditateActivity.start();
	}

	public function stopActivity() {
		me.mPauseMenuVisible = false;
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

		var menu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.ConfirmSaveHeader) });
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.finishMenu_save), "", :save, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.finishMenu_discard), "", :discard, {}));
		var saveDiscardDelegate = new SaveDiscardMenuDelegate(
			me.mMeditateActivity.method(:finish),
			me.mMeditateActivity.method(:discard)
		);
		Ui.pushView(menu, saveDiscardDelegate, Ui.SLIDE_IMMEDIATE);
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
		me.pauseForMenu();
		me.showPauseMenu(PauseReasonManual);
		return true;
	}

	private const MinMeditateActivityStopTime = 1;

	function onKey(keyEvent) {
		if (keyEvent.getKey() == Ui.KEY_ENTER && me.mMeditateModel.elapsedTime >= MinMeditateActivityStopTime) {
			me.pauseForMenu();
			me.showPauseMenu(PauseReasonManual);
			return true;
		}
		return false;
	}

	function onSessionAutoComplete() {
		me.pauseForMenu();
		me.showPauseMenu(PauseReasonCompleted);
	}

	private function pauseForMenu() {
		if (me.mMeditateModel.isTimerRunning) {
			if (me.mMeditateActivity != null) {
				me.mMeditateModel.isTimerRunning = me.mMeditateActivity.pauseResume();
			}
		}
		me.mMeditateModel.isTimerRunning = false;
		Ui.requestUpdate();
	}

	function resumeFromPauseMenu() {
		if (!me.mMeditateModel.isTimerRunning) {
			if (me.mMeditateActivity != null) {
				me.mMeditateModel.isTimerRunning = me.mMeditateActivity.pauseResume();
			}
		}
		Ui.requestUpdate();
	}

	function stopFromPauseMenu() {
		me.stopActivity();
	}

	function notifyPauseMenuClosed() {
		me.mPauseMenuVisible = false;
	}

	private function showPauseMenu(reason) {
		if (me.mPauseMenuVisible) {
			return;
		}
		var elapsedTime = me.mMeditateModel.elapsedTime;
		if (elapsedTime == null) {
			elapsedTime = 0;
		}
		var title = TimeFormatter.format(elapsedTime);
		var timeNow = System.getClockTime();
		timeNow = timeNow.hour.format("%02d")+":" + timeNow.min.format("%02d");
		var menu = new Ui.Menu2({ :title => title , :footer => timeNow});
		if (reason == PauseReasonCompleted) {
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.pauseMenu_stop), "", :stop, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.pauseMenu_resume), "", :resume, {}));
		} else {
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.pauseMenu_resume), "", :resume, {}));
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.pauseMenu_stop), "", :stop, {}));
		}		
		
		var pauseMenuDelegate = new PauseMenuDelegate(me);
		me.mPauseMenuVisible = true;
		Ui.pushView(menu, pauseMenuDelegate, Ui.SLIDE_UP);
	}
}


class PauseMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOwner;

	function initialize(owner) {
		Menu2InputDelegate.initialize();
		me.mOwner = owner;
	}

	function onSelect(item) {
		var id = item.getId();
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mOwner.notifyPauseMenuClosed();
		if (id == :resume) {
			me.mOwner.resumeFromPauseMenu();
		} else if (id == :stop) {
			me.mOwner.stopFromPauseMenu();
		}
	}

	function onBack() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mOwner.notifyPauseMenuClosed();
		me.mOwner.resumeFromPauseMenu();
		return true;
	}
}

class SaveDiscardMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnSave;
	private var mOnDiscard;

	function initialize(onSave, onDiscard) {
		Menu2InputDelegate.initialize();
		me.mOnSave = onSave;
		me.mOnDiscard = onDiscard;
	}

	function onSelect(item) {
		var id = item.getId();
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		if (id == :save) {
			if (me.mOnSave != null) {
				me.mOnSave.invoke();
			}
		} else if (id == :discard) {
			if (me.mOnDiscard != null) {
				me.mOnDiscard.invoke();
			}
		}
	}

	function onBack() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		return true;
	}
}
