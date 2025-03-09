using Toybox.Attention;

class Vibe {
	static function vibrate(pattern) {
		// If no notification, or notifcations turned off -> just return
		if (
			pattern == VibePattern.NoNotification ||
			pattern == null ||
			GlobalSettings.loadNotification() == Notification.Off
		) {
			return;
		}

		var vibeProfile = null;
		var toneProfile = null;
		switch (pattern) {
			case VibePattern.LongContinuous:
				vibeProfile = getLongContinuous();
				break;
			case VibePattern.LongPulsating:
				vibeProfile = getLongPulsating();
				break;
			case VibePattern.LongAscending:
				vibeProfile = getLongAscending();
				break;
			case VibePattern.MediumContinuous:
				vibeProfile = getMediumContinuous();
				break;
			case VibePattern.MediumPulsating:
				vibeProfile = getMediumPulsating();
				break;
			case VibePattern.MediumAscending:
				vibeProfile = getMediumAscending();
				break;
			case VibePattern.ShortContinuous:
				vibeProfile = getShortContinuous();
				break;
			case VibePattern.ShortPulsating:
				vibeProfile = getShortPulsating();
				break;
			case VibePattern.ShortAscending:
				vibeProfile = getShortAscending();
				break;
			case VibePattern.ShorterAscending:
				vibeProfile = getShorterAscending();
				break;
			case VibePattern.ShorterContinuous:
				vibeProfile = getShorterContinuous();
				break;
			case VibePattern.Blip:
				vibeProfile = getBlip();
				break;
			case VibePattern.ShortDescending:
				vibeProfile = getShortDescending();
				break;
			case VibePattern.MediumDescending:
				vibeProfile = getMediumDescending();
				break;
			case VibePattern.LongDescending:
				vibeProfile = getLongDescending();
				break;
			case VibePattern.ShortSound:
				// Play single fast note sound
				if (Attention has :ToneProfile) {
					toneProfile = getShortSound();
				}
				break;

			case VibePattern.LongSound:
				// Play three notes sound
				if (Attention has :ToneProfile) {
					toneProfile = getLongSound();
				}
				break;

			default:
				vibeProfile = getLongContinuous();
				break;
		}

		if (vibeProfile != null) {
			Attention.vibrate(vibeProfile);
		}
		if (toneProfile != null) {
			Attention.playTone({ :toneProfile => toneProfile });
		}
	}

	static function getLongPulsating() {
		return [
			new Attention.VibeProfile(100, 1000),
			new Attention.VibeProfile(0, 1000),
			new Attention.VibeProfile(100, 1000),
			new Attention.VibeProfile(0, 1000),
			new Attention.VibeProfile(100, 1000),
			new Attention.VibeProfile(0, 1000),
			new Attention.VibeProfile(100, 1000),
		];
	}

	static function getLongAscending() {
		return [
			new Attention.VibeProfile(20, 1000),
			new Attention.VibeProfile(30, 1000),
			new Attention.VibeProfile(60, 1000),
			new Attention.VibeProfile(80, 1000),
			new Attention.VibeProfile(90, 1000),
			new Attention.VibeProfile(100, 1000),
		];
	}

	static function getLongDescending() {
		return getLongAscending().reverse();
	}

	static function getLongContinuous() {
		return [new Attention.VibeProfile(100, 4000)];
	}

	static function getMediumPulsating() {
		return [
			new Attention.VibeProfile(100, 1000),
			new Attention.VibeProfile(0, 1000),
			new Attention.VibeProfile(100, 1000),
		];
	}

	static function getMediumAscending() {
		return [
			new Attention.VibeProfile(33, 1000),
			new Attention.VibeProfile(66, 1000),
			new Attention.VibeProfile(100, 1000),
		];
	}

	static function getMediumDescending() {
		return getMediumAscending().reverse();
	}

	static function getMediumContinuous() {
		return [new Attention.VibeProfile(100, 2000)];
	}

	static function getShortPulsating() {
		return [
			new Attention.VibeProfile(100, 333),
			new Attention.VibeProfile(0, 333),
			new Attention.VibeProfile(100, 333),
		];
	}

	static function getShortAscending() {
		return [
			new Attention.VibeProfile(33, 333),
			new Attention.VibeProfile(66, 333),
			new Attention.VibeProfile(100, 333),
		];
	}

	static function getShortDescending() {
		return getShortAscending().reverse();
	}

	static function getShortContinuous() {
		return [new Attention.VibeProfile(100, 500)];
	}

	static function getShorterAscending() {
		return [
			new Attention.VibeProfile(33, 111),
			new Attention.VibeProfile(66, 111),
			new Attention.VibeProfile(100, 111),
		];
	}

	static function getShorterContinuous() {
		return [new Attention.VibeProfile(100, 100)];
	}

	static function getBlip() {
		return [new Attention.VibeProfile(100, 50)];
	}

	static function getLongSound() {
		return [
			new Attention.ToneProfile(523, 400),
			new Attention.ToneProfile(698, 400),
			new Attention.ToneProfile(932, 400),
		];
	}

	static function getShortSound() {
		return [new Attention.ToneProfile(650, 100)];
	}
}
