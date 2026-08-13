using Toybox.WatchUi as Ui;
using Toybox.Lang;

// Editor for one breath step. Durations use the existing MM:SS two-column picker;
// changes are written straight through (no debounce timer, to stay clear of the 3-timer cap).
class AddEditBreathStepMenuDelegate extends Ui.Menu2InputDelegate {
	private var mProgram;
	private var mStepIndex;
	private var mOnStepChanged;
	private var mMenu;
	private var mPendingPhase;

	// updateMenuItems() rewrites rows by index, so createMenu() below is the only
	// place allowed to define the order; keep the two in step
	static const RowInhale = 0;
	static const RowHoldFull = 1;
	static const RowExhale = 2;
	static const RowHoldEmpty = 3;
	static const RowInRoute = 4;
	static const RowOutRoute = 5;
	static const RowRepeat = 6;

	static function createMenu(stepIndex) {
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.breathStepMenu_title) + " " + (stepIndex + 1),
		});
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_inhale), "", :inhale, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_hold), "", :holdFull, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_exhale), "", :exhale, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_holdEmpty), "", :holdEmpty, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_inRoute), "", :inRoute, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_outRoute), "", :outRoute, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_repeat), "", :repeat, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_moveUp), "", :moveUp, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_moveDown), "", :moveDown, {}));
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_delete), "", :deleteStep, {})
		);
		return menu;
	}

	function initialize(breathProgram, stepIndex, onStepChanged, menu) {
		Menu2InputDelegate.initialize();
		me.mProgram = breathProgram;
		me.mStepIndex = stepIndex;
		me.mOnStepChanged = onStepChanged;
		me.mMenu = menu;
		me.mPendingPhase = null;
	}

	private function getStep() {
		return me.mProgram.get(me.mStepIndex);
	}

	function updateMenuItems() {
		var step = me.getStep();
		if (me.mMenu == null || step == null) {
			return;
		}
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathPhase_inhale),
				TimeFormatter.formatMinSec(step.durations[BreathPhase.Inhale]),
				:inhale,
				{}
			),
			AddEditBreathStepMenuDelegate.RowInhale
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathPhase_hold),
				TimeFormatter.formatMinSec(step.durations[BreathPhase.HoldFull]),
				:holdFull,
				{}
			),
			AddEditBreathStepMenuDelegate.RowHoldFull
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathPhase_exhale),
				TimeFormatter.formatMinSec(step.durations[BreathPhase.Exhale]),
				:exhale,
				{}
			),
			AddEditBreathStepMenuDelegate.RowExhale
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathStepMenu_holdEmpty),
				TimeFormatter.formatMinSec(step.durations[BreathPhase.HoldEmpty]),
				:holdEmpty,
				{}
			),
			AddEditBreathStepMenuDelegate.RowHoldEmpty
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathProgramMenu_inRoute),
				Utils.getBreathRouteText(step.getRoute(BreathPhase.Inhale)),
				:inRoute,
				{}
			),
			AddEditBreathStepMenuDelegate.RowInRoute
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathProgramMenu_outRoute),
				Utils.getBreathRouteText(step.getRoute(BreathPhase.Exhale)),
				:outRoute,
				{}
			),
			AddEditBreathStepMenuDelegate.RowOutRoute
		);
		me.mMenu.updateItem(
			new Ui.MenuItem(
				Ui.loadResource(Rez.Strings.breathStepMenu_repeat),
				me.getRepeatText(step),
				:repeat,
				{}
			),
			AddEditBreathStepMenuDelegate.RowRepeat
		);
	}

	private function getRepeatText(step) {
		if (step.repeatType == BreathRepeat.Duration) {
			return TimeFormatter.formatMinSec(step.repeatValue);
		}
		return "x" + step.repeatValue.toString();
	}

	function onSelect(item) {
		var id = item.getId();
		if (id == :inhale) {
			me.pushPhasePicker(BreathPhase.Inhale);
		} else if (id == :holdFull) {
			me.pushPhasePicker(BreathPhase.HoldFull);
		} else if (id == :exhale) {
			me.pushPhasePicker(BreathPhase.Exhale);
		} else if (id == :holdEmpty) {
			me.pushPhasePicker(BreathPhase.HoldEmpty);
		} else if (id == :inRoute) {
			me.pushRouteMenu(BreathPhase.Inhale);
		} else if (id == :outRoute) {
			me.pushRouteMenu(BreathPhase.Exhale);
		} else if (id == :repeat) {
			me.pushRepeatTypeMenu();
		} else if (id == :moveUp) {
			me.moveStep(-1);
		} else if (id == :moveDown) {
			me.moveStep(1);
		} else if (id == :deleteStep) {
			Ui.pushView(
				new Ui.Confirmation(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_delete)),
				new YesDelegate(method(:onConfirmedDelete)),
				Ui.SLIDE_IMMEDIATE
			);
		}
	}

	private function pushPhasePicker(phase) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		me.mPendingPhase = phase;
		var seconds = step.durations[phase];
		me.pushMinSecPicker(seconds, method(:onPhasePicked));
	}

	private function pushMinSecPicker(seconds, callback) {
		var minutes = Utils.clampToRange(seconds / 60, 0, 59);
		var secs = Utils.clampToRange(seconds % 60, 0, 59);
		var view = new TwoColumnPickerView({
			:title => Ui.loadResource(Rez.Strings.pickMMSS),
			:isHourMinute => false,
			:leftMin => 0,
			:leftMax => 59,
			:leftPad => 1,
			:leftSuffix => "m",
			:rightMin => 0,
			:rightMax => 59,
			:rightPad => 2,
			:rightSuffix => "s",
			:leftValue => minutes,
			:rightValue => secs,
		});
		Ui.pushView(view, new TwoColumnPickerDelegate(view, callback, false), Ui.SLIDE_LEFT);
	}

	function onPhasePicked(totalSeconds) {
		var step = me.getStep();
		if (step == null || me.mPendingPhase == null) {
			return;
		}
		var previous = step.durations[me.mPendingPhase];
		step.durations[me.mPendingPhase] = Utils.clampToRange(totalSeconds, 0, BreathStep.MaxPhaseTime);
		// a step with every phase at zero has no duration and would stall the session
		if (!step.isValid()) {
			step.durations[me.mPendingPhase] = previous;
			if (Ui has :showToast) {
				Ui.showToast(Ui.loadResource(Rez.Strings.breathStepMenu_invalid), null);
			}
		}
		me.mPendingPhase = null;
		me.updateMenuItems();
		me.mOnStepChanged.invoke();
	}

	private function pushRouteMenu(phase) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		var isInhale = phase == BreathPhase.Inhale;
		var current = step.getRoute(phase);
		var focusIdx = 0;
		if (current == BreathRoute.Nose) {
			focusIdx = 1;
		} else if (current == BreathRoute.Mouth) {
			focusIdx = 2;
		}
		var titleId = isInhale ? Rez.Strings.breathProgramMenu_inRoute : Rez.Strings.breathProgramMenu_outRoute;
		var routeMenu = new Ui.Menu2({ :title => Ui.loadResource(titleId), :focus => focusIdx });
		routeMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathRouteMenu_unset), "", :unset, {}));
		routeMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathRouteMenu_nose), "", :nose, {}));
		routeMenu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathRouteMenu_mouth), "", :mouth, {}));
		// MenuOptionsDelegate hands back only the picked id, so the phase rides on the callback
		var callback = isInhale ? method(:onInRoutePicked) : method(:onOutRoutePicked);
		Ui.pushView(routeMenu, new MenuOptionsDelegate(callback), Ui.SLIDE_LEFT);
	}

	function onInRoutePicked(item) {
		me.applyRoute(BreathPhase.Inhale, item);
	}

	function onOutRoutePicked(item) {
		me.applyRoute(BreathPhase.Exhale, item);
	}

	private function applyRoute(phase, item) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		var route = BreathRoute.Unset;
		if (item == :nose) {
			route = BreathRoute.Nose;
		} else if (item == :mouth) {
			route = BreathRoute.Mouth;
		}
		step.setRoute(phase, route);
		me.updateMenuItems();
		me.mOnStepChanged.invoke();
	}

	private function pushRepeatTypeMenu() {
		var step = me.getStep();
		var focusIdx = step != null && step.repeatType == BreathRepeat.Duration ? 1 : 0;
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.breathStepMenu_repeat),
			:focus => focusIdx,
		});
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathRepeatMenu_rounds), "", :rounds, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathRepeatMenu_duration), "", :duration, {}));
		Ui.pushView(menu, new MenuOptionsDelegate(method(:onRepeatTypePicked)), Ui.SLIDE_LEFT);
	}

	function onRepeatTypePicked(item) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		if (item == :duration) {
			if (step.repeatType != BreathRepeat.Duration) {
				step.repeatType = BreathRepeat.Duration;
				step.repeatValue = Utils.clampToRange(step.cycleTime() * 4, 1, BreathStep.MaxDuration);
			}
			me.pushMinSecPicker(step.repeatValue, method(:onRepeatDurationPicked));
		} else {
			if (step.repeatType != BreathRepeat.Rounds) {
				step.repeatType = BreathRepeat.Rounds;
				step.repeatValue = 4;
			}
			me.pushRoundsPicker(step.repeatValue);
		}
	}

	private function pushRoundsPicker(rounds) {
		// a round count is not a duration, so the picker runs in single-column mode
		var view = new TwoColumnPickerView({
			:title => Ui.loadResource(Rez.Strings.breathRepeatMenu_rounds),
			:isHourMinute => false,
			:singleColumn => true,
			:rightMin => 1,
			:rightMax => BreathStep.MaxRounds,
			:rightPad => 1,
			:rightSuffix => "x",
			:rightValue => Utils.clampToRange(rounds, 1, BreathStep.MaxRounds),
		});
		Ui.pushView(view, new TwoColumnPickerDelegate(view, method(:onRoundsPicked), false), Ui.SLIDE_LEFT);
	}

	function onRoundsPicked(rounds) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		step.repeatType = BreathRepeat.Rounds;
		step.repeatValue = Utils.clampToRange(rounds, 1, BreathStep.MaxRounds);
		me.updateMenuItems();
		me.mOnStepChanged.invoke();
	}

	function onRepeatDurationPicked(totalSeconds) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		step.repeatType = BreathRepeat.Duration;
		step.repeatValue = Utils.clampToRange(totalSeconds, 1, BreathStep.MaxDuration);
		me.updateMenuItems();
		me.mOnStepChanged.invoke();
	}

	private function moveStep(delta) {
		var target = me.mStepIndex + delta;
		if (target < 0 || target >= me.mProgram.size()) {
			return;
		}
		me.mProgram.move(me.mStepIndex, delta);
		me.mStepIndex = target;
		me.mOnStepChanged.invoke();
		Ui.popView(Ui.SLIDE_RIGHT);
	}

	function onConfirmedDelete() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mProgram.delete(me.mStepIndex);
		me.mOnStepChanged.invoke();
		Ui.popView(Ui.SLIDE_RIGHT);
	}

	function onBack() {
		me.mOnStepChanged.invoke();
		Menu2InputDelegate.onBack();
		return false;
	}
}
