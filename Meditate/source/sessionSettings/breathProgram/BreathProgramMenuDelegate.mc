using Toybox.WatchUi as Ui;
using Toybox.Lang;

// Root of the breath program editor: the step list, plus add step and delete all.
// The step rows are dynamic, so the whole item list is rebuilt after every change.
class BreathProgramMenuDelegate extends Ui.Menu2InputDelegate {
	private var mProgram;
	private var mOnProgramChanged;
	private var mMenu;
	private var mItemCount;

	function initialize(breathProgram, onProgramChanged, menu) {
		Ui.Menu2InputDelegate.initialize();
		me.mProgram = breathProgram;
		me.mOnProgramChanged = onProgramChanged;
		me.mMenu = menu;
		me.mItemCount = 0;
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
		me.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_addStep), "", :addStep, {}));
		me.addItem(new Ui.MenuItem(Ui.loadResource(Rez.Strings.breathProgramMenu_deleteAll), "", :deleteAll, {}));

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
		me.notifyChanged();
		me.editStep(newIndex);
	}

	function onConfirmedDeleteAll() {
		Ui.popView(Ui.SLIDE_IMMEDIATE);
		me.mProgram.reset();
		me.notifyChanged();
	}

	function editStep(stepIndex) {
		if (me.mProgram.get(stepIndex) == null) {
			return;
		}
		var menu = AddEditBreathStepMenuDelegate.createMenu(stepIndex);
		var stepDelegate = new AddEditBreathStepMenuDelegate(
			me.mProgram,
			stepIndex,
			method(:notifyChanged),
			menu
		);
		stepDelegate.updateMenuItems();
		Ui.pushView(menu, stepDelegate, Ui.SLIDE_LEFT);
	}

	function notifyChanged() {
		me.rebuildMenuItems();
		me.mOnProgramChanged.invoke(me.mProgram);
	}

	function onBack() {
		me.mOnProgramChanged.invoke(me.mProgram);
		Menu2InputDelegate.onBack();
		return false;
	}
}
