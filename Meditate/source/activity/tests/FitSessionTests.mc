using Toybox.Test;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;

// one mapping from activity type to fit sport, and the activity name; both were inline in
// MeditateActivity.initialize and the wakeup session before. activities must keep their sport and name
(:test)
class FitSessionTests {
	// stored as the wakeup session kind; renumbering changes what every user has saved
	(:test)
	static function kindNumbersNeverChange(logger) {
		return (
			FitSessionKind.Training == 0 &&
			FitSessionKind.Meditation == 1 &&
			FitSessionKind.Yoga == 2 &&
			FitSessionKind.Breathing == 3
		);
	}

	(:test)
	static function kindForEachActivityType(logger) {
		return (
			MeditateActivity.fitKindFor(ActivityType.Meditating, true) == FitSessionKind.Meditation &&
			MeditateActivity.fitKindFor(ActivityType.Yoga, true) == FitSessionKind.Yoga &&
			MeditateActivity.fitKindFor(ActivityType.Breathing, true) == FitSessionKind.Breathing &&
			MeditateActivity.fitKindFor(ActivityType.Generic, true) == FitSessionKind.Training &&
			MeditateActivity.fitKindFor(ActivityType.Meditating, false) == FitSessionKind.Training &&
			MeditateActivity.fitKindFor(ActivityType.Yoga, false) == FitSessionKind.Training &&
			MeditateActivity.fitKindFor(ActivityType.Breathing, false) == FitSessionKind.Training &&
			MeditateActivity.fitKindFor(ActivityType.Generic, false) == FitSessionKind.Training
		);
	}

	// FIT profile numbers: sport training 10, meditation 67; sub-sport yoga 43, breathing 62, strength 20
	(:test)
	static function specPerKind(logger) {
		var meditation = FitSessionSpec.create(FitSessionKind.Meditation, "m");
		var yoga = FitSessionSpec.create(FitSessionKind.Yoga, "y");
		var breathing = FitSessionSpec.create(FitSessionKind.Breathing, "b");
		var training = FitSessionSpec.create(FitSessionKind.Training, "t");
		var nothingStored = FitSessionSpec.create(null, "n");
		return (
			meditation[:sport] == 67 &&
			meditation[:subSport] == null &&
			meditation[:name].equals("m") &&
			yoga[:sport] == 10 &&
			yoga[:subSport] == 43 &&
			breathing[:sport] == 10 &&
			breathing[:subSport] == 62 &&
			training[:sport] == 10 &&
			training[:subSport] == 20 &&
			nothingStored[:sport] == 10 &&
			nothingStored[:subSport] == 20 &&
			nothingStored[:name].equals("n")
		);
	}

	(:test)
	static function nameFormatsTheTimeToken(logger) {
		return (
			FitSessionName.format("[time]", 300).equals("5min") &&
			FitSessionName.format("[time]", 3600).equals("1h") &&
			FitSessionName.format("[time]", 5400).equals("1h 30min") &&
			FitSessionName.format("[time]", 89).equals("1min") &&
			FitSessionName.format("[time] and [time]", 600).equals("10min and 10min") &&
			FitSessionName.format("A very long activity name here", 60).equals("A very long activity ") &&
			FitSessionName.format("Calm", 300).equals("Calm")
		);
	}

	// session name when enabled, else the phone setting, else the title of the chosen type
	(:test)
	static function nameFollowsTheSettings(logger) {
		var savedUse = App.Storage.getValue(GlobalSettings.UseSessionNameKey);
		var savedProperty = App.Properties.getValue("activityName");
		try {
			GlobalSettings.save(GlobalSettings.UseSessionNameKey, true);
			var own = FitSessionName.resolve("Morning", ActivityType.Yoga).equals("Morning");
			GlobalSettings.save(GlobalSettings.UseSessionNameKey, false);
			App.Properties.setValue("activityName", "");
			var title = FitSessionName.resolve("Morning", ActivityType.Yoga).equals(
				Ui.loadResource(Rez.Strings.sessionTitleYoga)
			);
			var generic = FitSessionName.resolve(null, ActivityType.Generic).equals(
				Ui.loadResource(Rez.Strings.sessionTitleMeditate)
			);
			App.Properties.setValue("activityName", "Calm [time]");
			var phone = FitSessionName.resolve("Morning", ActivityType.Yoga).equals("Calm [time]");
			StorageSnapshot.put(GlobalSettings.UseSessionNameKey, savedUse);
			App.Properties.setValue("activityName", savedProperty == null ? "" : savedProperty);
			return own && title && generic && phone;
		} catch (ex) {
			StorageSnapshot.put(GlobalSettings.UseSessionNameKey, savedUse);
			App.Properties.setValue("activityName", savedProperty == null ? "" : savedProperty);
			throw ex;
		}
	}
}
