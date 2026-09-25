using Toybox.Test;
using Toybox.WatchUi as Ui;

// the option lists replace hand-built menus; their values and order are what users pick and store
(:test)
class OptionMenuTests {
	private static function sameNumbers(actual, expected) {
		if (actual.size() != expected.size()) {
			return false;
		}
		for (var i = 0; i < expected.size(); i++) {
			if (actual[i] != expected[i]) {
				return false;
			}
		}
		return true;
	}

	// the order of the old session and interval vibe menus, as stored numbers
	(:test)
	static function vibeListsKeepTheOldMenuOrder(logger) {
		var session = OptionMenu.sessionVibePatterns();
		var interval = OptionMenu.intervalVibePatterns();
		var sessionOrder = [0, 15, 17, 16, 13, 14, 11, 12, 9, 10, 6, 7, 4, 5];
		var intervalOrder = [0, 15, 17, 16, 13, 14, 11, 12, 9, 10, 6, 7, 4, 5, 1, 8, 2, 3];
		return (
			OptionMenuTests.sameNumbers(session[0], sessionOrder) &&
			session[1].size() == sessionOrder.size() &&
			session[2] == null &&
			OptionMenuTests.sameNumbers(interval[0], intervalOrder) &&
			interval[1].size() == intervalOrder.size() &&
			interval[2] == null
		);
	}

	(:test)
	static function settingListsKeepTheirValuesAndHints(logger) {
		var activity = OptionMenu.activityTypes();
		var hrv = OptionMenu.hrvTracking();
		return (
			OptionMenuTests.sameNumbers(activity[0], [0, 1, 2, 3]) &&
			activity[1].size() == 4 &&
			activity[2] == null &&
			OptionMenuTests.sameNumbers(hrv[0], [1, 2, 0]) &&
			hrv[1].size() == 3 &&
			hrv[2].size() == 1 &&
			hrv[2][1] == Rez.Strings.menuLabelDefault
		);
	}

	// a session without a stored pattern; a switch on null throws, so the label must not reach one
	(:test)
	static function nullVibePatternReadsAsNoNotification(logger) {
		return Utils.getVibePatternText(null).equals(Ui.loadResource(Rez.Strings.vibePatternMenu_noNotification));
	}

	(:test)
	static function indexOfMatchesByValue(logger) {
		return (
			OptionMenu.indexOf([1, 2, 0], 0) == 2 &&
			OptionMenu.indexOf([true, false], false) == 1 &&
			OptionMenu.indexOf([15, 30], null) == -1 &&
			OptionMenu.indexOf([15, 30], 45) == -1
		);
	}
}
