using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Timer;

class MeditateView extends ScreenPicker.ScreenPickerDetailsCenterView {
	private var mMeditateModel;
	private var mMainDurationRenderer;
	private var mIntervalAlertsRenderer;
	private var mElapsedTimeLine;
	private var mHrStatusLine;
	private var mHrvStatusLine;
	private var mRrStatusLine;
	private var mStressStatusLine;
	private var mHrvIcon;
	private var mHrvText;
	private var mStressIcon;
	private var mStressText;
	private var mBreathIcon;
	private var mBreathText;
	private var mMeditateIcon;
	private var mRespirationRateYPosOffset;

	function initialize(meditateModel) {
		ScreenPicker.ScreenPickerDetailsCenterView.initialize(meditateModel, false);
		me.mMeditateModel = meditateModel;
		me.mMainDurationRenderer = null;
		me.mIntervalAlertsRenderer = null;
		me.mElapsedTimeLine = null;
		me.mHrStatusLine = null;
		me.mHrvStatusLine = null;
		me.mStressStatusLine = null;
		me.mRrStatusLine = null;
		me.mMeditateIcon = null;
	}

	private static const TextFont = App.getApp().getProperty("largeFont");

	// Load your resources here
	function onLayout(dc) {
		ScreenPicker.ScreenPickerDetailsCenterView.onLayout(dc);

		var lineNum = 0;
		me.mHrStatusLine = me.mMeditateModel.getLine(lineNum);
		lineNum++;

		if (me.mMeditateModel.isHrvOn()) {
			me.mHrvStatusLine = me.mMeditateModel.getLine(lineNum);
			lineNum++;
		}
		me.mStressStatusLine = me.mMeditateModel.getLine(lineNum);
		lineNum++;
		
		if (me.mMeditateModel.isRespirationRateOn()){
			me.mRrStatusLine = me.mMeditateModel.getLine(lineNum);
		}

		me.mMainDurationRenderer = new ElapsedDurationRenderer(me.mMeditateModel.getColor(), null, null);

		if (me.mMeditateModel.hasIntervalAlerts()) {
			var intervalAlertsArcRadius = dc.getWidth() / 2;
			var intervalAlertsArcWidth = dc.getWidth() / 16;
			me.mIntervalAlertsRenderer = new IntervalAlertsRenderer(
				me.mMeditateModel.getSessionTime(),
				me.mMeditateModel.getOneOffIntervalAlerts(),
				me.mMeditateModel.getRepeatIntervalAlerts(),
				intervalAlertsArcRadius,
				intervalAlertsArcWidth
			);
		}
	}

	var lastElapsedTime = -1;

	// Update the view
	function onUpdate(dc) {
		ScreenPicker.ScreenPickerDetailsCenterView.onUpdate(dc);
		var elapsedTime = me.mMeditateModel.elapsedTime;
		// Only update every second
		if (elapsedTime != lastElapsedTime || !me.mMeditateModel.isTimerRunning) {
			var currentHr = null;
			var currentHrv = null;
			var currentRr = null;
			var currentStress = null;
			var currentElapsedTime = null;
			if (me.mMeditateModel.isTimerRunning) {
				if (me.mMeditateIcon != null) {
					mMeditateIcon.draw(dc);
				}

				var timeText = TimeFormatter.format(elapsedTime);
				currentElapsedTime = timeText.substring(0, timeText.length() - 3);

				currentHr = me.mMeditateModel.currentHr;

				if (me.mMeditateModel.isHrvOn() == true) {
					currentHrv = me.mMeditateModel.hrvValue;
				}

				if (me.mMeditateModel.isRespirationRateOn()) {
					currentRr = me.mMeditateModel.getRespirationRate();
				}
				currentStress = me.mMeditateModel.getStress();
			} else {
				// if activity is paused, render the [Paused] text
				currentElapsedTime = Ui.loadResource(Rez.Strings.meditateActivityPaused);
			}
			var iconColor = null;
			me.mMeditateModel.title = currentElapsedTime;
			me.mHrStatusLine.value.text = me.formatValue(currentHr);
			if (currentHr != null) {
				iconColor = Graphics.COLOR_RED;
			} else {
				iconColor = Graphics.COLOR_LT_GRAY;
			}
			me.mHrStatusLine.icon = new ScreenPicker.Icon({
				:font => StatusIconFonts.fontAwesomeFreeSolid,
				:symbol => StatusIconFonts.Rez.Strings.IconHeart,
				:color => iconColor,
			});
			if (me.mMeditateModel.isHrvOn()) {
				me.mHrvStatusLine.value.text = me.formatValue(currentHrv);
				if (me.mMeditateModel.isHrvOn() == true && currentHr != null) {
					iconColor = Graphics.COLOR_RED;
				} else {
					iconColor = Graphics.COLOR_LT_GRAY;
				}
				me.mHrvStatusLine.icon = new ScreenPicker.HrvIcon({
					:color => iconColor,
				});
			}
			if (me.mMeditateModel.isRespirationRateOn()){
				me.mRrStatusLine.value.text = me.formatValue(currentRr);
				me.mRrStatusLine.icon = new ScreenPicker.BreathIcon({});
				if (currentRr != null) {
					me.mRrStatusLine.icon.setActive();
				} else {
					me.mRrStatusLine.icon.setInactive();
				}
			}

			me.mStressStatusLine.value.text = me.formatValue(currentStress);
			me.mStressStatusLine.icon = new ScreenPicker.StressIcon({});
			me.mStressStatusLine.icon.setStress(currentStress);

			ScreenPicker.ScreenPickerDetailsCenterView.onUpdate(dc);
			var alarmTime = me.mMeditateModel.getSessionTime();

			// Fix issues with OLED screens for prepare time 45 seconds
			try {
				if (Attention has :backlight) {
					if (elapsedTime <= 1) {
						Attention.backlight(false);
					}

					// Enable backlight in the first 8 seconds then turn off to save battery
					if (elapsedTime > 0 && elapsedTime <= 8) {
						Attention.backlight(true);
					}

					if (elapsedTime == 9) {
						Attention.backlight(false);
					}
				}
			} catch (ex) {
				// Just in case we get a BacklightOnTooLongException for OLED display devices (ex: Venu2)
				if (Attention has :backlight) {
					Attention.backlight(false);
				}
			}
			me.mMainDurationRenderer.drawOverallElapsedTime(dc, elapsedTime, alarmTime);
			if (me.mIntervalAlertsRenderer != null) {
				me.mIntervalAlertsRenderer.drawRepeatIntervalAlerts(dc);
				me.mIntervalAlertsRenderer.drawOneOffIntervalAlerts(dc);
			}
		}
		lastElapsedTime = elapsedTime;
	}
}
