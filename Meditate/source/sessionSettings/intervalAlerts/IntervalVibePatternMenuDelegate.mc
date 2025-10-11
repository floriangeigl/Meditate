using Toybox.WatchUi as Ui;

class IntervalVibePatternMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnVibePatternPicked;

	function initialize(onVibePatternPicked) {
		Menu2InputDelegate.initialize();
		me.mOnVibePatternPicked = onVibePatternPicked;
	}

	function onSelect(item) {
		var id = item.getId();
		var picked = null;
		switch (id) {
			case :mediumContinuous:
				picked = VibePattern.MediumContinuous;
				break;
			case :mediumPulsating:
				picked = VibePattern.MediumPulsating;
				break;
			case :mediumAscending:
				picked = VibePattern.MediumAscending;
				break;
			case :mediumDescending:
				picked = VibePattern.MediumDescending;
				break;
			case :shortContinuous:
				picked = VibePattern.ShortContinuous;
				break;
			case :shortPulsating:
				picked = VibePattern.ShortPulsating;
				break;
			case :shortAscending:
				picked = VibePattern.ShortAscending;
				break;
			case :shortDescending:
				picked = VibePattern.ShortDescending;
				break;
			case :shorterAscending:
				picked = VibePattern.ShorterAscending;
				break;
			case :shorterContinuous:
				picked = VibePattern.ShorterContinuous;
				break;
			case :blip:
				picked = VibePattern.Blip;
				break;
			case :shortSound:
				picked = VibePattern.ShortSound;
				break;
			case :noNotification:
				picked = VibePattern.NoNotification;
				break;
			case :longAscending:
				picked = VibePattern.LongAscending;
				break;
			case :longContinuous:
				picked = VibePattern.LongContinuous;
				break;
		}

		// If a valid pattern was chosen, pop this menu first so the parent is visible,
		// then invoke the callback which will update the parent's subtexts.
		if (picked != null && me.mOnVibePatternPicked != null) {
			Ui.popView(Ui.SLIDE_RIGHT);
			me.mOnVibePatternPicked.invoke(picked);
		}
	}
}
