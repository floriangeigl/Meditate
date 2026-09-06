using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// One screen, shown once, after an update worth announcing.
//
// To announce a release: bump NewsId and rewrite the whatsNew_* strings in every locale.
// Leave NewsId alone and the release ships silently, which is what most releases should do.
// Lines are drawn one per row and are not wrapped, so keep them short - the view shrinks the
// font to fit, but a long line on a small round screen ends up hard to read.
class WhatsNewDelegate extends Ui.BehaviorDelegate {
	// 1: guided breathwork
	static const NewsId = 1;

	private var mSessionPickerDelegate;

	static function hasUnseenNews() {
		return GlobalSettings.loadLastSeenNewsId() < WhatsNewDelegate.NewsId;
	}

	static function markSeen() {
		GlobalSettings.saveLastSeenNewsId(WhatsNewDelegate.NewsId);
	}

	function initialize(sessionPickerDelegate) {
		BehaviorDelegate.initialize();
		me.mSessionPickerDelegate = sessionPickerDelegate;
	}

	function createView() {
		return new WhatsNewView(Ui.loadResource(Rez.Strings.whatsNew_title), [
			Ui.loadResource(Rez.Strings.whatsNew_line1),
			Ui.loadResource(Rez.Strings.whatsNew_line2),
			Ui.loadResource(Rez.Strings.whatsNew_line3),
			Ui.loadResource(Rez.Strings.whatsNew_line4),
		]);
	}

	// this is the initial view, so back must not fall through and exit the app; every way out
	// marks the news seen so it never comes back
	private function dismiss() {
		WhatsNewDelegate.markSeen();
		Ui.switchToView(me.mSessionPickerDelegate.createScreenPickerView(), me.mSessionPickerDelegate, Ui.SLIDE_LEFT);
		return true;
	}

	function onBack() {
		return me.dismiss();
	}

	function onSelect() {
		return me.dismiss();
	}

	function onTap(clickEvent) {
		return me.dismiss();
	}
}

// Plain centred view. The About-style details layout indents every row to leave an icon
// column, which pushes news lines off the right edge of a round screen; these lines need the
// full width instead.
class WhatsNewView extends Ui.View {
	private var mTitle;
	private var mLines;
	private var mBackgroundColor, mForegroundColor;
	private var mTitleFont, mLineFont;
	private var mCenterX, mTitleY, mFirstLineY, mLineHeight;

	function initialize(title, lines) {
		View.initialize();
		me.mTitle = title;
		me.mLines = lines;
		if (GlobalSettings.loadColorTheme() == ColorTheme.Light) {
			me.mBackgroundColor = Gfx.COLOR_WHITE;
			me.mForegroundColor = Gfx.COLOR_BLACK;
		} else {
			me.mBackgroundColor = Gfx.COLOR_BLACK;
			me.mForegroundColor = Gfx.COLOR_WHITE;
		}
	}

	function onLayout(dc) {
		var width = dc.getWidth();
		var height = dc.getHeight();
		me.mCenterX = width / 2;
		// a round screen narrows towards the edges; 0.82 keeps the longest line off the bezel
		var maxWidth = width * 0.82;
		me.mTitleFont = WhatsNewView.fitFont(dc, [Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_XTINY], [me.mTitle], maxWidth);
		me.mLineFont = WhatsNewView.fitFont(dc, [Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY], me.mLines, maxWidth);
		me.mLineHeight = dc.getFontHeight(me.mLineFont);

		// centre title and lines as one block, so no font combination can overlap them
		var titleHeight = dc.getFontHeight(me.mTitleFont);
		var gap = height * 0.06;
		var blockHeight = titleHeight + gap + me.mLines.size() * me.mLineHeight;
		me.mTitleY = (height - blockHeight) / 2;
		me.mFirstLineY = me.mTitleY + titleHeight + gap;
	}

	// largest font whose widest text still fits, falling back to the last one
	private static function fitFont(dc, fonts, texts, maxWidth) {
		for (var f = 0; f < fonts.size() - 1; f++) {
			var fits = true;
			for (var i = 0; i < texts.size(); i++) {
				if (dc.getTextWidthInPixels(texts[i], fonts[f]) > maxWidth) {
					fits = false;
				}
			}
			if (fits) {
				return fonts[f];
			}
		}
		return fonts[fonts.size() - 1];
	}

	function onUpdate(dc) {
		dc.setColor(Gfx.COLOR_TRANSPARENT, me.mBackgroundColor);
		dc.clear();
		dc.setColor(me.mForegroundColor, Gfx.COLOR_TRANSPARENT);
		dc.drawText(me.mCenterX, me.mTitleY, me.mTitleFont, me.mTitle, Gfx.TEXT_JUSTIFY_CENTER);
		var y = me.mFirstLineY;
		for (var i = 0; i < me.mLines.size(); i++) {
			dc.drawText(me.mCenterX, y, me.mLineFont, me.mLines[i], Gfx.TEXT_JUSTIFY_CENTER);
			y += me.mLineHeight;
		}
	}
}
