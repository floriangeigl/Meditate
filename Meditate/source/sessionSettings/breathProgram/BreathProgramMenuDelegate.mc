using Toybox.WatchUi as Ui;
using Toybox.Lang;

// Root of the breath program editor: the step list, plus add step and delete all.
// Step rows are rewritten in place; the list is only rebuilt when the row count changes.
class BreathProgramMenuDelegate extends Ui.Menu2InputDelegate {
	private var mProgram;
	private var mOnProgramChanged;
	private var mMenu;
	private var mItemCount;
	private var mStepCount;
	private var mChanged;

	function initialize(breathProgram, onProgramChanged, menu) {
		Ui.Menu2InputDelegate.initialize();
		me.mProgram = breathProgram;
		me.mOnProgramChanged = onProgramChanged;
		me.mMenu = menu;
		me.mItemCount = 0;
		me.mStepCount = 0;
		me.mChanged = false;
	}

	function rebuildMenuItems() {
		if (me.mMenu == null) {
			return;
		}
		for (var i = me.mItemCount - 1; i >= 0; i--) {
			me.mMenu.deleteItem(i);
		}
		me.mItemCount = 0;

		for (var i = 0; i < me.mProgram.size(); i++) {
			var step = me.mProgram.get(i);
			me.addItem(new Ui.MenuItem(Utils.getBreathStepName(step), Utils.getBreathStepDetail(step), i, {}));
		}
		me.mStepCount = me.mProgram.size();
		me.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_addStep), "", :addStep, {}));
		me.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_deleteAll), "", :deleteAll, {}));
		me.updateTitle();
	}

	// rewrites the step rows in place; a rebuild would drop the focus back to the first row
	private function refreshStepItems() {
		for (var i = 0; i < me.mStepCount; i++) {
			var step = me.mProgram.get(i);
			me.mMenu.updateItem(
				new Ui.MenuItem(Utils.getBreathStepName(step), Utils.getBreathStepDetail(step), i, {}),
				i
			);
		}
		me.updateTitle();
	}

	private function updateTitle() {
		if (me.mMenu has :setTitle) {
			me.mMenu.setTitle(
				Ui.loadResource(Rez.Strings.addEditSessionMenu_breathProgram) +
					" " +
					TimeFormatter.formatMinSec(me.mProgram.totalTime())
			);
		}
	}

	private function addItem(item) {
		me.mMenu.addItem(item);
		me.mItemCount++;
	}

	function onSelect(item) {
		var id = item.getId();
		if (id instanceof Lang.Number) {
			me.editStep(id);
			return;
		}
		if (id == :addStep) {
			if (me.mProgram.size() >= BreathProgram.MaxSteps) {
				if (Ui has :showToast) {
					Ui.showToast(Ui.loadResource(Rez.Strings.breathProgramMenu_full), null);
				}
				return;
			}
			var templateMenu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.breathProgramMenu_addStep) });
			var ids = BreathTemplates.stepIds();
			for (var i = 0; i < ids.size(); i++) {
				templateMenu.addItem(new Ui.MenuItem(BreathTemplates.getStepLabel(ids[i]), "", ids[i], {}));
			}
			Ui.pushView(templateMenu, new MenuOptionsDelegate(method(:onStepTemplatePicked)), Ui.SLIDE_LEFT);
		} else if (id == :deleteAll) {
			if (me.mProgram.size() == 0) {
				return;
			}
			Ui.pushView(
				new Ui.Confirmation(Ui.loadResource(Rez.Strings.breathProgramMenu_deleteAll)),
				new YesDelegate(method(:onConfirmedDeleteAll)),
				Ui.SLIDE_IMMEDIATE
			);
		}
	}

	function onStepTemplatePicked(templateId) {
		var newIndex = me.mProgram.addNew(BreathTemplates.createStep(templateId));
		if (newIndex < 0) {
			return;
		}
		// focus the new step so backing out of its editor lands on it
		me.notifyChanged(newIndex);
		me.editStep(newIndex);
	}

	function onConfirmedDeleteAll() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mProgram.reset();
		me.notifyChanged(null);
	}

	function editStep(stepIndex) {
		var step = me.mProgram.get(stepIndex);
		if (step == null) {
			return;
		}
		var menu = AddEditBreathStepMenuDelegate.createMenu(step, stepIndex);
		var stepDelegate = new AddEditBreathStepMenuDelegate(
			me.mProgram,
			stepIndex,
			method(:notifyChanged),
			menu
		);
		stepDelegate.updateMenuItems();
		Ui.pushView(menu, stepDelegate, Ui.SLIDE_LEFT);
	}

	// focusRow is the row to land on afterwards, or null to leave the focus alone
	function notifyChanged(focusRow) {
		me.mChanged = true;
		if (me.mMenu != null && me.mProgram.size() == me.mStepCount) {
			// edits and reorders keep the row count, so keep the list and the focus put
			me.refreshStepItems();
		} else {
			me.rebuildMenuItems();
		}
		me.setFocusRow(focusRow);
		me.mOnProgramChanged.invoke(me.mProgram);
	}

	private function setFocusRow(focusRow) {
		if (focusRow == null || me.mMenu == null || !(me.mMenu has :setFocus)) {
			return;
		}
		if (focusRow < 0) {
			focusRow = 0;
		} else if (focusRow >= me.mItemCount) {
			focusRow = me.mItemCount - 1;
		}
		me.mMenu.setFocus(focusRow);
	}

	function onBack() {
		// opening the editor and leaving it untouched must not attach an empty program
		if (me.mChanged) {
			me.mOnProgramChanged.invoke(me.mProgram);
		}
		Menu2InputDelegate.onBack();
		return false;
	}
}
