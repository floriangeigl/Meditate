using Toybox.WatchUi as Ui;

class IntervalVibePatternMenuDelegate extends Ui.Menu2InputDelegate {
	private var mOnVibePatternPicked;

	function initialize(onVibePatternPicked) {
		Menu2InputDelegate.initialize();
		me.mOnVibePatternPicked = onVibePatternPicked;
	}

	function onSelect(item) {
		var id = item.getId();
		switch (id) {
			case :mediumContinuous:
				me.mOnVibePatternPicked.invoke(VibePattern.MediumContinuous);
				break;
			case :mediumPulsating:
				me.mOnVibePatternPicked.invoke(VibePattern.MediumPulsating);
				break;
			case :mediumAscending:
				me.mOnVibePatternPicked.invoke(VibePattern.MediumAscending);
				break;
			case :mediumDescending:
				me.mOnVibePatternPicked.invoke(VibePattern.MediumDescending);
				break;
			case :shortContinuous:
				me.mOnVibePatternPicked.invoke(VibePattern.ShortContinuous);
				break;
			case :shortPulsating:
				me.mOnVibePatternPicked.invoke(VibePattern.ShortPulsating);
				break;
			case :shortAscending:
				me.mOnVibePatternPicked.invoke(VibePattern.ShortAscending);
				break;
			case :shortDescending:
				me.mOnVibePatternPicked.invoke(VibePattern.ShortDescending);
				break;
			case :shorterAscending:
				me.mOnVibePatternPicked.invoke(VibePattern.ShorterAscending);
				break;
			case :shorterContinuous:
				me.mOnVibePatternPicked.invoke(VibePattern.ShorterContinuous);
				break;
			case :blip:
				me.mOnVibePatternPicked.invoke(VibePattern.Blip);
				break;
			case :shortSound:
				me.mOnVibePatternPicked.invoke(VibePattern.ShortSound);
				break;
			case :noNotification:
				me.mOnVibePatternPicked.invoke(VibePattern.NoNotification);
				break;
			case :longAscending:
				me.mOnVibePatternPicked.invoke(VibePattern.LongAscending);
				break;
			case :longContinuous:
				me.mOnVibePatternPicked.invoke(VibePattern.LongContinuous);
				break;
		}
	}
}
