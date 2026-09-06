// Maps elapsed session seconds onto the current breath phase.
// Pure function of elapsedTime, so pause/resume needs no saved state.
class BreathProgramRunner {
	// outputs, valid after update()
	var phase;
	var phaseElapsed;
	var phaseTotal;
	var phaseStart; // absolute session second the current phase began; unique per occurrence
	var stepIndex;
	var roundIndex;
	var roundsTotal;
	var isDone;

	private var mProgram;
	private var mOffsets;
	private var mTotal;

	function initialize(breathProgram) {
		me.mProgram = breathProgram;
		me.mOffsets = breathProgram.stepStartOffsets();
		me.mTotal = me.mOffsets[me.mOffsets.size() - 1];
		me.phase = BreathPhase.Inhale;
		me.phaseElapsed = 0;
		me.phaseTotal = 0;
		me.phaseStart = 0;
		me.stepIndex = 0;
		me.roundIndex = 0;
		me.roundsTotal = 0;
		me.isDone = false;
		me.update(0);
	}

	function getProgram() {
		return me.mProgram;
	}

	function getTotalTime() {
		return me.mTotal;
	}

	function getStepOffsets() {
		return me.mOffsets;
	}

	function update(elapsedTime) {
		if (elapsedTime == null || elapsedTime < 0) {
			elapsedTime = 0;
		}
		me.isDone = elapsedTime >= me.mTotal;
		if (me.isDone) {
			// hold on the final phase rather than running off the end
			elapsedTime = me.mTotal > 0 ? me.mTotal - 1 : 0;
		}

		var stepCount = me.mProgram.size();
		var index = 0;
		while (index < stepCount - 1 && elapsedTime >= me.mOffsets[index + 1]) {
			index++;
		}
		me.stepIndex = index;

		var step = me.mProgram.get(index);
		if (step == null) {
			me.setEmptyPhase(elapsedTime);
			return;
		}
		me.roundsTotal = step.roundsCount();

		var cycle = step.cycleTime();
		if (cycle < 1) {
			me.setEmptyPhase(elapsedTime);
			return;
		}

		var local = elapsedTime - me.mOffsets[index];
		me.roundIndex = local / cycle;
		var withinCycle = local % cycle;

		var accumulated = 0;
		for (var i = 0; i < BreathStep.PhaseCount; i++) {
			var duration = step.durations[i];
			if (duration <= 0) {
				continue;
			}
			if (withinCycle < accumulated + duration) {
				me.phase = i;
				me.phaseElapsed = withinCycle - accumulated;
				me.phaseTotal = duration;
				me.phaseStart = elapsedTime - me.phaseElapsed;
				return;
			}
			accumulated += duration;
		}
		// unreachable while cycle > 0; keep outputs coherent rather than stale
		me.setEmptyPhase(elapsedTime);
	}

	// nose/mouth for the current phase; Unset during holds and when the step says nothing
	function phaseRoute() {
		var step = me.mProgram.get(me.stepIndex);
		return step == null ? BreathRoute.Unset : step.getRoute(me.phase);
	}

	// seconds left in the phase, counted down to 1 and never shown as 0
	function phaseRemaining() {
		var remaining = me.phaseTotal - me.phaseElapsed;
		return remaining < 1 ? 1 : remaining;
	}

	private function setEmptyPhase(elapsedTime) {
		me.phase = BreathPhase.HoldFull;
		me.phaseElapsed = 0;
		me.phaseTotal = 0;
		me.phaseStart = elapsedTime;
		me.roundIndex = 0;
	}
}
