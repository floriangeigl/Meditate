using Toybox.Lang;
using Toybox.WatchUi as Ui;

// a choose-one menu over a list of values. the item id is the position in the list, but the
// callback always gets the value, so what is stored is exactly what the hand-built menus stored
class OptionMenu {
	// labels are Rez ids or strings; hints map a position to a Rez id shown below that option.
	// onPicked(tag, value): the tag tells a shared callback which setting was picked
	static function push(titleRez, values, labels, current, hints, onPicked, tag) {
		var focus = OptionMenu.indexOf(values, current);
		var menu = new Ui.Menu2({
			:title => Ui.loadResource(titleRez),
			:focus => focus < 0 ? 0 : focus,
		});
		for (var i = 0; i < values.size(); i++) {
			var hint = hints != null && hints[i] != null ? Ui.loadResource(hints[i]) : "";
			menu.addItem(new Ui.MenuItem(OptionMenu.text(labels[i]), hint, i, {}));
		}
		Ui.pushView(menu, new OptionMenuDelegate(values, onPicked, tag), Ui.SLIDE_LEFT);
	}

	// -1 when the value is not in the list
	static function indexOf(values, value) {
		for (var i = 0; i < values.size(); i++) {
			if (values[i] == value) {
				return i;
			}
		}
		return -1;
	}

	static function text(label) {
		return label instanceof Lang.String ? label : Ui.loadResource(label);
	}

	static function activityTypes() {
		return [
			[ActivityType.Meditating, ActivityType.Yoga, ActivityType.Breathing, ActivityType.Generic],
			[
				Rez.Strings.menuNewActivityTypeOptions_meditating,
				Rez.Strings.menuNewActivityTypeOptions_yoga,
				Rez.Strings.menuNewActivityTypeOptions_breathing,
				Rez.Strings.menuNewActivityTypeOptions_generic,
			],
			null,
		];
	}

	static function hrvTracking() {
		return [
			[HrvTracking.On, HrvTracking.OnDetailed, HrvTracking.Off],
			[
				Rez.Strings.menuHrvTrackingOptions_on,
				Rez.Strings.menuHrvTrackingOptions_onDetailed,
				Rez.Strings.menuHrvTrackingOptions_off,
			],
			{ 1 => Rez.Strings.menuLabelDefault },
		];
	}

	static function sessionVibePatterns() {
		var values = [
			VibePattern.NoNotification,
			VibePattern.LongContinuous,
			VibePattern.LongSound,
			VibePattern.LongPulsating,
			VibePattern.LongAscending,
			VibePattern.LongDescending,
			VibePattern.MediumContinuous,
			VibePattern.MediumPulsating,
			VibePattern.MediumAscending,
			VibePattern.MediumDescending,
			VibePattern.ShortContinuous,
			VibePattern.ShortPulsating,
			VibePattern.ShortAscending,
			VibePattern.ShortDescending,
		];
		return [values, OptionMenu.vibeLabels(values), null];
	}

	// the session list plus the short patterns that only suit an alert inside a session
	static function intervalVibePatterns() {
		var values = OptionMenu.sessionVibePatterns()[0];
		values.addAll([
			VibePattern.Blip,
			VibePattern.ShortSound,
			VibePattern.ShorterAscending,
			VibePattern.ShorterContinuous,
		]);
		return [values, OptionMenu.vibeLabels(values), null];
	}

	private static function vibeLabels(values) {
		var labels = new [values.size()];
		for (var i = 0; i < values.size(); i++) {
			labels[i] = Utils.vibePatternLabel(values[i]);
		}
		return labels;
	}
}

class OptionMenuDelegate extends Ui.Menu2InputDelegate {
	private var mValues;
	private var mOnPicked;
	private var mTag;

	function initialize(values, onPicked, tag) {
		Menu2InputDelegate.initialize();
		me.mValues = values;
		me.mOnPicked = onPicked;
		me.mTag = tag;
	}

	function onSelect(item) {
		// pop first so the parent menu is visible when it refreshes its subtexts
		Ui.popView(Ui.SLIDE_RIGHT);
		me.mOnPicked.invoke(me.mTag, me.mValues[item.getId()]);
	}
}
