// Fires one cue per breath phase boundary. Edge-triggered on the phase start second,
// so a skipped or jittered timer tick fires late rather than not at all.
// Reads the runner; MeditateModel.updateBreathRunner() is what advances it.
class BreathCuesExecutor {
	private var mRunner;
	private var mLastPhaseStart;
	private var mCues;

	function initialize(meditateModel) {
		me.mRunner = meditateModel.getBreathRunner();
		me.mCues = GlobalSettings.loadBreathCues();
		// -1 so the opening phase cues at session start instead of one tick late
		me.mLastPhaseStart = -1;
		me.firePendingCues();
	}

	function firePendingCues() {
		if (me.mRunner == null || me.mRunner.isDone) {
			return;
		}
		if (me.mRunner.phaseStart == me.mLastPhaseStart) {
			return;
		}
		me.mLastPhaseStart = me.mRunner.phaseStart;
		me.fire(me.mRunner.phase);
	}

	private function fire(phase) {
		if (me.mCues == BreathCues.Off) {
			return;
		}
		Vibe.vibrate(BreathCuesExecutor.getVibePattern(phase));
		if (me.mCues == BreathCues.VibrationTone) {
			Vibe.playBreathTone(phase);
		}
	}

	// rising for in, falling for out, neutral for holds
	static function getVibePattern(phase) {
		if (phase == BreathPhase.Inhale) {
			return VibePattern.ShortAscending;
		}
		if (phase == BreathPhase.Exhale) {
			return VibePattern.ShortDescending;
		}
		return VibePattern.Blip;
	}
}
