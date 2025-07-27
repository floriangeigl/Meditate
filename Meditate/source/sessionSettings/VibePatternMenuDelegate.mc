using Toybox.WatchUi as Ui;

class VibePatternMenuDelegate extends Ui.MenuInputDelegate {
	private var mOnVibePatternPicked;

	function initialize(onVibePatternPicked) {
		MenuInputDelegate.initialize();
		me.mOnVibePatternPicked = onVibePatternPicked;
	}

	function onMenuItem(item) {
		if (item == :noNotification) {
			me.mOnVibePatternPicked.invoke(VibePattern.NoNotification);
		} else if (item == :longContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongContinuous);
		} else if (item == :longSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongSound);
		} else if (item == :longPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongPulsating);
		} else if (item == :longAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongAscending);
		} else if (item == :longDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.LongDescending);
		} else if (item == :mediumContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumContinuous);
		} else if (item == :mediumPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumPulsating);
		} else if (item == :mediumAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumAscending);
		} else if (item == :mediumDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.MediumDescending);
		} else if (item == :shortContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortContinuous);
		} else if (item == :shortPulsating) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortPulsating);
		} else if (item == :shortAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortAscending);
		} else if (item == :shortDescending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortDescending);
		} else if (item == :blip) {
			me.mOnVibePatternPicked.invoke(VibePattern.Blip);
		} else if (item == :shortSound) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShortSound);
		} else if (item == :shorterAscending) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterAscending);
		} else if (item == :shorterContinuous) {
			me.mOnVibePatternPicked.invoke(VibePattern.ShorterContinuous);
		}
	}
}
