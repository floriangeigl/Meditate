using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Timer;
using Toybox.Sensor;
using StatusIconFonts;

class MeditateView extends ScreenPicker.ScreenPickerDetailsCenterView {
	private var mMeditateModel;
	private var mMainDurationRenderer;
	private var mIntervalAlertsRenderer;
	private var mElapsedTimeLine;
	private var mHrStatusLine;
	private var mHrvStatusLine;
	private var mRrStatusLine;
	private var mStressStatusLine;
	private var mExtSensorLine;
	private var mHrIcon;
	private var mHrvIcon;
	private var mHrvText;
	private var mStressIcon;
	private var mStressText;
	private var mBreathIcon;
	private var mBreathText;
	private var mRespirationRateYPosOffset;
	private var rrLoaded, stressLoaded, hrvLoaded, hrLoaded;

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
		me.mExtSensorLine = null;
		me.rrLoaded = false;
		me.stressLoaded = false;
		me.hrvLoaded = false;
		me.hrLoaded = false;

		me.mHrIcon = new ScreenPicker.Icon({
			:font => StatusIconFonts.fontAwesomeFreeSolid,
			:symbol => StatusIconFonts.Rez.Strings.IconHeart,
			:color => Graphics.COLOR_LT_GRAY,
		});

		me.mHrvIcon = new ScreenPicker.HrvIcon({});
		me.mHrvIcon.setStatusOff();

		me.mBreathIcon = new ScreenPicker.BreathIcon({});
		me.mBreathIcon.setInactive();

		me.mStressIcon = new ScreenPicker.StressIcon({});
		me.mStressIcon.setStressInvalid();
	}

	private static const TextFont = App.getApp().getProperty("largeFont");

	// Load your resources here
	function onLayout(dc) {
		ScreenPicker.ScreenPickerDetailsCenterView.onLayout(dc);

		var lineNum = 0;
		me.mHrStatusLine = me.mMeditateModel.getLine(lineNum);
		me.mHrStatusLine.icon = new ScreenPicker.LoadingIcon({});
		me.mHrIcon.setColorLoading();
		lineNum++;

		if (me.mMeditateModel.isHrvOn()) {
			me.mHrvStatusLine = me.mMeditateModel.getLine(lineNum);
			me.mHrvStatusLine.icon = new ScreenPicker.LoadingIcon({});
			me.mHrvIcon.setColorLoading();
			lineNum++;
		}
		if (me.mMeditateModel.isStressSupported()) {
			me.mStressStatusLine = me.mMeditateModel.getLine(lineNum);
			me.mStressStatusLine.icon = new ScreenPicker.LoadingIcon({});
			me.mStressIcon.setColorLoading();
			lineNum++;
		}

		if (me.mMeditateModel.isRespirationRateOn()) {
			me.mRrStatusLine = me.mMeditateModel.getLine(lineNum);
			me.mRrStatusLine.icon = new ScreenPicker.LoadingIcon({});
			me.mBreathIcon.setColorLoading();
			lineNum++;
		}
		me.mExtSensorLine = me.mMeditateModel.getLine(lineNum);
		lineNum++;

		me.mMainDurationRenderer = new ElapsedDurationRenderer(me.mMeditateModel.getColor(), null, null);

		if (me.mMeditateModel.hasIntervalAlerts()) {
			var intervalAlertsArcRadius = dc.getWidth() / 2;
			var intervalAlertsArcWidth = dc.getWidth() / 16;
			me.mIntervalAlertsRenderer = new IntervalAlertsRenderer(
				me.mMeditateModel.getSessionTime(),
				me.mMeditateModel.getIntervalAlerts(),
				intervalAlertsArcRadius,
				intervalAlertsArcWidth
			);
			me.mIntervalAlertsRenderer.layoutIntervalAlerts(dc);
		}
	}

	var lastElapsedTime = -1;

	// Update the view
	function onUpdate(dc) {
		var elapsedTime = me.mMeditateModel.elapsedTime;
		// Only update every second
		if (elapsedTime != lastElapsedTime || !me.mMeditateModel.isTimerRunning) {
			var currentHr = null;
			var currentHrv = null;
			var currentRr = null;
			var currentStress = null;
			var currentElapsedTime = null;
			if (me.mMeditateModel.isTimerRunning) {
				currentElapsedTime = TimeFormatter.format(elapsedTime);

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

			me.mMeditateModel.title = currentElapsedTime;
			me.mHrStatusLine.value.text = me.formatValue(currentHr);
			if (currentHr != null) {
				me.hrLoaded = true;
				me.mHrStatusLine.icon = me.mHrIcon;
				me.mHrIcon.setColor(Graphics.COLOR_RED);
				me.mHrStatusLine.value.color = null;
			} else if (me.hrLoaded) {
				me.mHrIcon.setColorInactive();
			} else if (me.mHrStatusLine.icon instanceof ScreenPicker.LoadingIcon) {
				me.mHrStatusLine.icon.tick();
			}

			if (me.mMeditateModel.isHrvOn()) {
				me.mHrvStatusLine.value.text = me.formatValue(currentHrv);
				if (me.mMeditateModel.isHrvOn() == true && currentHrv != null) {
					me.hrvLoaded = true;
					me.mHrvStatusLine.icon = me.mHrvIcon;
					me.mHrvIcon.setColor(Graphics.COLOR_RED);
					me.mHrvStatusLine.value.color = null;
				} else if (me.hrvLoaded) {
					me.mHrvIcon.setColorInactive();
				} else if (me.mHrvStatusLine.icon instanceof ScreenPicker.LoadingIcon) {
					me.mHrvStatusLine.icon.tick();
					me.setLoadTimeText(me.mHrvStatusLine, HrvAlgorithms.HrvMonitorDetailed.getLoadTime(), elapsedTime);
				}
			}
			if (me.mMeditateModel.isRespirationRateOn()) {
				me.mRrStatusLine.value.text = me.formatValue(currentRr);
				if (currentRr != null) {
					me.rrLoaded = true;
					me.mRrStatusLine.icon = me.mBreathIcon;
					me.mBreathIcon.setActive();
					me.mRrStatusLine.value.color = null;
				} else if (me.rrLoaded) {
					me.mBreathIcon.setColorInactive();
				} else if (me.mRrStatusLine.icon instanceof ScreenPicker.LoadingIcon) {
					me.mRrStatusLine.icon.tick();
					me.setLoadTimeText(me.mRrStatusLine, HrvAlgorithms.RrActivity.getLoadTime(), elapsedTime);
				}
			}
			if (me.mMeditateModel.isStressSupported()) {
				me.mStressStatusLine.value.text = me.formatValue(currentStress);
				if (currentStress != null) {
					me.stressLoaded = true;
					me.mStressStatusLine.icon = me.mStressIcon;
					me.mStressIcon.setStress(currentStress);
					me.mStressStatusLine.value.color = null;
				} else if (me.stressLoaded) {
					me.mStressIcon.setColorInactive();
				} else if (me.mStressStatusLine.icon instanceof ScreenPicker.LoadingIcon) {
					me.mStressStatusLine.icon.tick();
					me.setLoadTimeText(me.mStressStatusLine, HrvAlgorithms.StressActivity.getLoadTime(), elapsedTime);
				}
			}

			// if (elapsedTime < 10 || elapsedTime % 60 == 0){
			// 	var externalSensorConnected = me.mMeditateModel.externalSensorConnected;
			// 	if(externalSensorConnected){
			// 		me.mExtSensorLine.value.text = "ext. sensor";
			// 		me.mExtSensorLine.icon = new ScreenPicker.Icon({
			// 			:font => StatusIconFonts.fontAwesomeFreeSolid,
			// 			:symbol => StatusIconFonts.Rez.Strings.IconInfo,
			// 			:color => Gfx.COLOR_BLUE,
			// 		});
			// 	} else {
			// 		me.mExtSensorLine.icon = null;
			// 		me.mExtSensorLine.value.text = "";
			// 	}
			// }

			ScreenPicker.ScreenPickerDetailsCenterView.onUpdate(dc);
			me.mMainDurationRenderer.drawOverallElapsedTime(dc, elapsedTime, me.mMeditateModel.getSessionTime());
			if (me.mIntervalAlertsRenderer != null) {
				me.mIntervalAlertsRenderer.drawAllIntervalAlerts(dc);
			}

			// Fix issues with OLED screens for prepare time 45 seconds
			try {
				if (elapsedTime < 10 && Attention has :backlight) {
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
		}
		lastElapsedTime = elapsedTime;
	}

	function setLoadTimeText(line, total, elapsed) {
		var remain_time = (total - elapsed).toNumber();
		line.value.text = remain_time > 0 ? remain_time.toString() : "0";
		line.value.color = Graphics.COLOR_LT_GRAY;
	}

	function isExternalSensorConnected() {
		if (Sensor has :getRegisteredSensors) {
        	var iter = Sensor.getRegisteredSensors(Sensor.SENSOR_HEARTRATE);
			var sensor = iter.next();
			while (sensor != null) {
				if(sensor.enabled) {
					return sensor.name;
				}
				sensor = iter.next();
			}
    	}
		return null;
	}
}
