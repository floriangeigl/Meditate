using Toybox.WatchUi as Ui;

class VibePatternMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnVibePatternPicked;

	function initialize(onVibePatternPicked) {
		Menu2InputDelegate.initialize();
		me.mOnVibePatternPicked = onVibePatternPicked;
	}

	// Menu2 handler: receive the MenuItem and forward its id
	function onSelect(item) {
		if (item == null) {
			return;
		}
		me.onMenuItem(item.getId());
	}

	// Compatibility: resource-driven menus call onMenuItem(symbol)
	function onMenuItem(sym) {
		if (me.mOnVibePatternPicked == null) {
			return;
		}

		if (sym == :noNotification) {
			me.mOnVibePatternPicked.invoke(VibePattern.NoNotification);
		} else if (sym == :longContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongContinuous);
		} else if (sym == :longSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongSound);
		} else if (sym == :longPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongPulsating);
		} else if (sym == :longAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongAscending);
		} else if (sym == :longDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongDescending);
		} else if (sym == :mediumContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumContinuous);
		} else if (sym == :mediumPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumPulsating);
		} else if (sym == :mediumAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumAscending);
		} else if (sym == :mediumDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumDescending);
		} else if (sym == :shortContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortContinuous);
		} else if (sym == :shortPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortPulsating);
		} else if (sym == :shortAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortAscending);
		} else if (sym == :shortDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortDescending);
		} else if (sym == :blip) {
			me.mOnVibePatternPicked.invoke(VibePattern.Blip);
		} else if (sym == :shortSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortSound);
		} else if (sym == :shorterAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterAscending);
		} else if (sym == :shorterContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterContinuous);
		}
	}
}
