using Toybox.WatchUi as Ui;
using Toybox.Lang;

// Editor for one breath step. Durations use the existing MM:SS two-column picker;
// changes are written straight through (no debounce timer, to stay clear of the 3-timer cap).
//
// Two rules keep this editor honest, because a picker can always be backed out of:
//   1. nothing mutates the step before a picker returns - a seed value goes in, and the step
//      changes only in the accept callback, so backing out is a real cancel;
//   2. no state is parked across a push - whatever is being edited is carried by its own
//      callback, never by a field that outlives the picker.
// Every mutation ends in publishStepChange(), the one place that refreshes and notifies.
class AddEditBreathStepMenuDelegate extends Ui.Menu2InputDelegate {
	private var mProgram;
	private var mStepIndex;
	private var mOnStepChanged;
	private var mMenu;
	private var mChanged;

	// updateMenuItems() rewrites rows by index, so createMenu() below is the only
	// place allowed to define the order; keep the two in step
	static const RowInhale = 0;
	static const RowHoldFull = 1;
	static const RowExhale = 2;
	static const RowHoldEmpty = 3;
	static const RowInRoute = 4;
	static const RowOutRoute = 5;
	static const RowRepeat = 6;
	// rest steps get a reduced menu: duration, move, delete
	static const RowRestDuration = 0;

	static function createMenu(step, stepIndex) {
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(Rez.Strings.breathStepMenu_title) + " " + (stepIndex + 1),
		});
		if (step.isRest()) {
			menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStep_rest), "", :restDuration, {}));
			AddEditBreathStepMenuDelegate.addOrderItems(menu);
			return menu;
		}
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_inhale), "", :inhale, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_hold), "", :holdFull, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathPhase_exhale), "", :exhale, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_holdEmpty), "", :holdEmpty, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_inRoute), "", :inRoute, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_outRoute), "", :outRoute, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_repeat), "", :repeat, {}));
		AddEditBreathStepMenuDelegate.addOrderItems(menu);
		return menu;
	}

	private static function addOrderItems(menu) {
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_moveUp), "", :moveUp, {}));
		menu.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathStepMenu_moveDown), "", :moveDown, {}));
		menu.addItem(
			new Ui.MenuItem(Ui.loadResource(Rez.Strings.addEditIntervalAlertMenu_delete), "", :deleteStep, {})
		);
	}

	function initialize(breathProgram, stepIndex, onStepChanged, menu) {
		Menu2InputDelegate.initialize();
		me.mProgram = breathProgram;
		me.mStepIndex = stepIndex;
		me.mOnStepChanged = onStepChanged;
		me.mMenu = menu;
		me.mChanged = false;
	}

	private function getStep() {
		return me.mProgram.get(me.mStepIndex);
	}

	function updateMenuItems() {
		var step = me.getStep();
		if (me.mMenu == null || step == null) {
			return;
		}
		if (step.isRest()) {
			me.mMenu.updateItem(
				new Ui.MenuItem(
					Ui.loadResource(Rez.Strings.breathStep_rest),
					TimeFormatter.formatMinSec(step.repeatValue),
					:restDuration,
					{}
				),
				AddEditBreathStepMenuDelegate.RowRestDuration
			);
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
			me.pushPhasePicker(BreathPhase.Inhale, method(:onInhalePicked));
		} else if (id == :holdFull) {
			me.pushPhasePicker(BreathPhase.HoldFull, method(:onHoldFullPicked));
		} else if (id == :exhale) {
			me.pushPhasePicker(BreathPhase.Exhale, method(:onExhalePicked));
		} else if (id == :holdEmpty) {
			me.pushPhasePicker(BreathPhase.HoldEmpty, method(:onHoldEmptyPicked));
		} else if (id == :inRoute) {
			me.pushRouteMenu(BreathPhase.Inhale);
		} else if (id == :outRoute) {
			me.pushRouteMenu(BreathPhase.Exhale);
		} else if (id == :repeat) {
			me.pushRepeatTypeMenu();
		} else if (id == :restDuration) {
			me.pushRestDurationPicker();
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

	// one callback per phase, so a picked value can never land on the wrong slot
	private function pushPhasePicker(phase, callback) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		me.pushMinSecPicker(step.durations[phase], callback);
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

	function onInhalePicked(totalSeconds) {
		me.applyPhase(BreathPhase.Inhale, totalSeconds);
	}

	function onHoldFullPicked(totalSeconds) {
		me.applyPhase(BreathPhase.HoldFull, totalSeconds);
	}

	function onExhalePicked(totalSeconds) {
		me.applyPhase(BreathPhase.Exhale, totalSeconds);
	}

	function onHoldEmptyPicked(totalSeconds) {
		me.applyPhase(BreathPhase.HoldEmpty, totalSeconds);
	}

	private function applyPhase(phase, totalSeconds) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		var previous = step.durations[phase];
		step.durations[phase] = Utils.clampToRange(totalSeconds, 0, BreathStep.MaxPhaseTime);
		// all phases zero would stall a rounds step and silently turn a duration step into a rest step
		if (step.cycleTime() == 0) {
			step.durations[phase] = previous;
			if (Ui has :showToast) {
				Ui.showToast(Ui.loadResource(Rez.Strings.breathStepMenu_invalid), null);
			}
		}
		me.publishStepChange();
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
		me.publishStepChange();
	}

	// the accept callback writes duration type and value together, so a rest step stays a rest step
	private function pushRestDurationPicker() {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		me.pushMinSecPicker(step.repeatValue, method(:onRepeatDurationPicked));
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

	// seeds the value picker for the chosen type; the accept callbacks write both type and
	// value together, so picking a type and then backing out changes nothing
	function onRepeatTypePicked(item) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		if (item == :duration) {
			var seconds =
				step.repeatType == BreathRepeat.Duration
					? step.repeatValue
					: Utils.clampToRange(step.cycleTime() * 4, 1, BreathStep.MaxDuration);
			me.pushMinSecPicker(seconds, method(:onRepeatDurationPicked));
		} else {
			var rounds = step.repeatType == BreathRepeat.Rounds ? step.repeatValue : 4;
			me.pushRoundsPicker(rounds);
		}
	}

	private function publishStepChange() {
		me.mChanged = true;
		me.updateMenuItems();
		me.mOnStepChanged.invoke(null);
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
		me.publishStepChange();
	}

	function onRepeatDurationPicked(totalSeconds) {
		var step = me.getStep();
		if (step == null) {
			return;
		}
		step.repeatType = BreathRepeat.Duration;
		step.repeatValue = Utils.clampToRange(totalSeconds, 1, BreathStep.MaxDuration);
		me.publishStepChange();
	}

	// the step list is left focused on the row the step moved to
	private function moveStep(delta) {
		var target = me.mStepIndex + delta;
		if (target < 0 || target >= me.mProgram.size()) {
			return;
		}
		me.mProgram.move(me.mStepIndex, delta);
		me.mStepIndex = target;
		me.mOnStepChanged.invoke(target);
		Ui.popView(Ui.SLIDE_RIGHT);
	}

	// the confirmation pops itself, so this single pop leaves the step menu for the step list,
	// which is left focused on the step before the deleted one
	function onConfirmedDelete() {
		Ui.popView(Ui.SLIDE_RIGHT);
		me.mProgram.delete(me.mStepIndex);
		me.mOnStepChanged.invoke(me.mStepIndex - 1);
	}

	function onBack() {
		if (me.mChanged) {
			me.mOnStepChanged.invoke(null);
		}
		Menu2InputDelegate.onBack();
		return false;
	}
}
