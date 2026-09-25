using Toybox.Test;
using Toybox.WatchUi as Ui;

// the icon font and its glyph strings; a glyph that got blanked or retyped draws nothing
(:test)
class IconGlyphTests {
	(:test)
	static function fontLoads(logger) {
		return StatusIconFonts.fontAwesomeFreeSolid != null;
	}

	// every glyph the code uses is one character of the private use area the font maps
	(:test)
	static function everyUsedGlyphIsOnePrivateUseCharacter(logger) {
		var ids = [
			Rez.Strings.IconBell,
			Rez.Strings.IconBreath,
			Rez.Strings.IconDown,
			Rez.Strings.IconHeart,
			Rez.Strings.IconHeartBeat,
			Rez.Strings.IconHourGlassEnd,
			Rez.Strings.IconHourGlassHalf,
			Rez.Strings.IconHourGlassStart,
			Rez.Strings.IconInfo,
			Rez.Strings.IconSpa,
			Rez.Strings.IconStress,
			Rez.Strings.IconTimeHalf,
			Rez.Strings.IconTimeline,
			Rez.Strings.IconUp,
		];
		for (var i = 0; i < ids.size(); i++) {
			var chars = Ui.loadResource(ids[i]).toCharArray();
			if (chars.size() != 1) {
				logger.debug("glyph " + i + " has " + chars.size() + " characters");
				return false;
			}
			var code = chars[0].toNumber();
			if (code < 0xE000 || code > 0xF8FF) {
				logger.debug("glyph " + i + " is U+" + code.format("%04X"));
				return false;
			}
		}
		return true;
	}
}
