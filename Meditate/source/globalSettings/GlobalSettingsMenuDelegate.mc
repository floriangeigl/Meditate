using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Application as App;

// the global settings menu, one row per setting. show() builds the menu and updateMenuItems()
// rewrites it from the same rows, so a row's menu index is its position in rows() and nothing else
class GlobalSettingsMenuDelegate extends Ui.Menu2InputDelegate {
	private static const ColId = 0;
	private static const ColTitle = 1;
	private static const ColOptionsTitle = 2;
	private static const ColKey = 3;
	private static const ColValues = 4;
	private static const ColLabels = 5; // null: a duration in seconds, shown as mm:ss
	private static const ColHints = 6;

	private var mMenu;
	private var mRows;

	// [id, row title, options title, setting key, values, labels, hints] in menu order;
	// the options title differs from the row title for hrv tracking, multi-session and respiration
	static function rows() {
		var activity = OptionMenu.activityTypes();
		var hrv = OptionMenu.hrvTracking();
		var respiration = RrMetric.isSupported()
			? [
				[RespirationRate.On, RespirationRate.Off],
				[Rez.Strings.menuRespirationRateOptions_on, Rez.Strings.menuRespirationRateOptions_off],
				{ 0 => Rez.Strings.menuLabelDefault },
			]
			: [[RespirationRate.Off], [Rez.Strings.menuRespirationRateOptions_off], null];
		return [
			[
				:colorTheme,
				Rez.Strings.menuGlobalSettings_colorTheme,
				Rez.Strings.menuGlobalSettings_colorTheme,
				GlobalSettings.ColorThemeKey,
				[ColorTheme.Light, ColorTheme.Dark],
				[Rez.Strings.menuColorThemeOptions_light, Rez.Strings.menuColorThemeOptions_dark],
				{ 1 => Rez.Strings.menuLabelDefault },
			],
			[
				:autoStop,
				Rez.Strings.menuGlobalSettings_autoStop,
				Rez.Strings.menuGlobalSettings_autoStop,
				GlobalSettings.AutoStopKey,
				[AutoStop.On, AutoStop.Off],
				[Rez.Strings.menuAutoStopOptions_on, Rez.Strings.menuAutoStopOptions_off],
				{ 0 => Rez.Strings.menuLabelDefault },
			],
			[
				:confirmSaveActivity,
				Rez.Strings.menuGlobalSettings_confirmSaveActivity,
				Rez.Strings.menuGlobalSettings_confirmSaveActivity,
				GlobalSettings.ConfirmSaveActivityKey,
				[
					ConfirmSaveActivity.Ask,
					ConfirmSaveActivity.AutoYes,
					ConfirmSaveActivity.AutoYesExit,
					ConfirmSaveActivity.AutoNo,
				],
				[
					Rez.Strings.menuConfirmSaveActivityOptions_askSimple,
					Rez.Strings.menuConfirmSaveActivityOptions_autoYes,
					Rez.Strings.menuConfirmSaveActivityOptions_autoYesExit,
					Rez.Strings.menuConfirmSaveActivityOptions_autoNo,
				],
				{ 0 => Rez.Strings.menuLabelDefault },
			],
			[
				:prepareTime,
				Rez.Strings.menuGlobalSettings_prepareTime,
				Rez.Strings.menuGlobalSettings_prepareTime,
				GlobalSettings.PrepareTimeKey,
				[0, 15, 30, 45, 60, 120, 180, 240, 300],
				null,
				null,
			],
			[
				:finalizeTime,
				Rez.Strings.menuGlobalSettings_finalizeTime,
				Rez.Strings.menuGlobalSettings_finalizeTime,
				GlobalSettings.FinalizeTimeKey,
				[0, 15, 30, 45, 60, 120, 180],
				null,
				null,
			],
			[
				:notification,
				Rez.Strings.menuNotificationOptions_title,
				Rez.Strings.menuNotificationOptions_title,
				GlobalSettings.NotificationKey,
				[Notification.On, Notification.Off],
				[Rez.Strings.menuNotificationOptions_on, Rez.Strings.menuNotificationOptions_off],
				{ 0 => Rez.Strings.menuLabelDefault },
			],
			[
				:breathCues,
				Rez.Strings.menuGlobalSettings_breathCues,
				Rez.Strings.menuGlobalSettings_breathCues,
				GlobalSettings.BreathCuesKey,
				[BreathCues.Off, BreathCues.Vibration, BreathCues.VibrationTone],
				[
					Rez.Strings.menuNotificationOptions_off,
					Rez.Strings.menuBreathCuesOptions_vibration,
					Rez.Strings.menuBreathCuesOptions_vibrationTone,
				],
				{ 1 => Rez.Strings.menuLabelDefault },
			],
			[
				:newActivityType,
				Rez.Strings.menuGlobalSettings_newActivityType,
				Rez.Strings.menuGlobalSettings_newActivityType,
				GlobalSettings.ActivityTypeKey,
				activity[0],
				activity[1],
				activity[2],
			],
			[
				:useSessionName,
				Rez.Strings.menuGlobalSettings_useSessionName,
				Rez.Strings.menuGlobalSettings_useSessionName,
				GlobalSettings.UseSessionNameKey,
				[true, false],
				[Rez.Strings.menuGlobalSettings_useSessionName_on, Rez.Strings.menuGlobalSettings_useSessionName_off],
				{ 1 => Rez.Strings.menuLabelDefault },
			],
			[
				:hrvTracking,
				Rez.Strings.menuGlobalSettings_newHrvTracking,
				Rez.Strings.menuHrvTrackingOptions_title,
				GlobalSettings.HrvTrackingKey,
				hrv[0],
				hrv[1],
				hrv[2],
			],
			[
				:hrvWindow,
				Rez.Strings.menuHrvWindowSizeOptions_title,
				Rez.Strings.menuHrvWindowSizeOptions_title,
				GlobalSettings.HrvWindowTimeKey,
				[30, 60, 120, 180, 300, 600],
				null,
				{ 1 => Rez.Strings.menuLabelDefault, 4 => Rez.Strings.menuLabelRecommended },
			],
			[
				:respirationRate,
				Rez.Strings.menuGlobalSettings_respirationRate,
				Rez.Strings.menuRespirationRateOptions_title,
				GlobalSettings.RespirationRateKey,
				respiration[0],
				respiration[1],
				respiration[2],
			],
			[
				:multiSession,
				Rez.Strings.menuGlobalSettings_multiSession,
				Rez.Strings.menuMultiSessionOptions_title,
				GlobalSettings.MultiSessionKey,
				[MultiSession.Yes, MultiSession.No],
				[Rez.Strings.menuMultiSessionOptions_yes, Rez.Strings.menuMultiSessionOptions_no],
				{ 1 => Rez.Strings.menuLabelDefault },
			],
			// an action, not a setting
			[:sensorRestart, Rez.Strings.menuGlobalSettings_sensorRestart, null, null, null, null, null],
		];
	}

	static function show() {
		var rows = GlobalSettingsMenuDelegate.rows();
		var menu = new Ui.Menu2({ :title => Ui.loadResource(Rez.Strings.menuGlobalSettings_title) });
		for (var i = 0; i < rows.size(); i++) {
			menu.addItem(
				new Ui.MenuItem(
					Ui.loadResource(rows[i][ColTitle]),
					GlobalSettingsMenuDelegate.subtitle(rows[i]),
					rows[i][ColId],
					{}
				)
			);
		}
		Ui.pushView(menu, new GlobalSettingsMenuDelegate(menu, rows), Ui.SLIDE_LEFT);
	}

	function initialize(menu, rows) {
		Menu2InputDelegate.initialize();
		me.mMenu = menu;
		me.mRows = rows;
	}

	function onSelect(item) {
		var id = item.getId();
		for (var i = 0; i < me.mRows.size(); i++) {
			var row = me.mRows[i];
			if (row[ColId] != id) {
				continue;
			}
			if (row[ColKey] == null) {
				// sensor restart: disable all HR sensors and exit the app cleanly
				App.getApp().beatIntervalFeed.shutdown();
				System.exit();
				return; // the row has no values; never fall through to an options menu
			}
			var labels = row[ColLabels] == null ? GlobalSettingsMenuDelegate.durationLabels(row[ColValues]) : row[ColLabels];
			OptionMenu.push(
				row[ColOptionsTitle],
				row[ColValues],
				labels,
				GlobalSettings.load(row[ColKey]),
				row[ColHints],
				method(:onSettingPicked),
				i
			);
			return;
		}
	}

	function onSettingPicked(rowIndex, value) {
		GlobalSettings.save(me.mRows[rowIndex][ColKey], value);
		me.updateMenuItems();
		Ui.requestUpdate();
	}

	// refresh every row's subtitle to the current value
	function updateMenuItems() {
		for (var i = 0; i < me.mRows.size(); i++) {
			var row = me.mRows[i];
			me.mMenu.updateItem(
				new Ui.MenuItem(
					Ui.loadResource(row[ColTitle]),
					GlobalSettingsMenuDelegate.subtitle(row),
					row[ColId],
					{}
				),
				i
			);
		}
	}

	// the label of the stored value; a value missing from the list shows the first label
	private static function subtitle(row) {
		if (row[ColKey] == null) {
			return "";
		}
		var value = GlobalSettings.load(row[ColKey]);
		if (row[ColLabels] == null) {
			return TimeFormatter.formatMinSec(value);
		}
		var index = OptionMenu.indexOf(row[ColValues], value);
		return OptionMenu.text(row[ColLabels][index < 0 ? 0 : index]);
	}

	private static function durationLabels(values) {
		var labels = new [values.size()];
		for (var i = 0; i < values.size(); i++) {
			labels[i] = TimeFormatter.formatMinSec(values[i]);
		}
		return labels;
	}
}
