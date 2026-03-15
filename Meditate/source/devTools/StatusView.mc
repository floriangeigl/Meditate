using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Simple fullscreen status view used by CloudBackup and CloudRestore to show
// progress messages ("Backing up...", "Restore OK — restart app", etc.).
class StatusView extends Ui.View {
	private var mMessage;

	function initialize(message) {
		View.initialize();
		mMessage = message;
	}

	function setMessage(msg) {
		mMessage = msg;
		Ui.requestUpdate();
	}

	function onUpdate(dc) {
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		dc.clear();
		dc.drawText(
			dc.getWidth() / 2,
			dc.getHeight() / 2,
			Gfx.FONT_MEDIUM,
			mMessage,
			Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
		);
	}
}
