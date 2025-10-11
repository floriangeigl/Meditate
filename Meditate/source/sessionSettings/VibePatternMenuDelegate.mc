using Toybox.WatchUi as Ui;

class VibePatternMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnVibePatternPicked;

	function initialize(onVibePatternPicked) {
		Menu2InputDelegate.initialize();
		me.mOnVibePatternPicked = onVibePatternPicked;
	}

	// Menu2 handler: receive the MenuItem and map its id to a VibePattern
	function onSelect(item) {
		if (item == null || me.mOnVibePatternPicked == null) {
			return;
		}

		var id = item.getId();
		// Pop first so the parent menu is visible when it refreshes its subtexts
		Ui.popView(Ui.SLIDE_RIGHT);
		if (id == :noNotification) {
			me.mOnVibePatternPicked.invoke(VibePattern.NoNotification);
		} else if (id == :longContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongContinuous);
		} else if (id == :longSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongSound);
		} else if (id == :longPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongPulsating);
		} else if (id == :longAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongAscending);
		} else if (id == :longDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongDescending);
		} else if (id == :mediumContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumContinuous);
		} else if (id == :mediumPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumPulsating);
		} else if (id == :mediumAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumAscending);
		} else if (id == :mediumDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumDescending);
		} else if (id == :shortContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortContinuous);
		} else if (id == :shortPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortPulsating);
		} else if (id == :shortAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortAscending);
		} else if (id == :shortDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortDescending);
		} else if (id == :blip) {
			me.mOnVibePatternPicked.invoke(VibePattern.Blip);
		} else if (id == :shortSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortSound);
		} else if (id == :shorterAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterAscending);
		} else if (id == :shorterContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterContinuous);
		}
	}
}
