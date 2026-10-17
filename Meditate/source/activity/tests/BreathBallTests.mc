using Toybox.Test;

// the ball's size over a breath and its progress between ticks; the drawing is checked by eye
(:test)
class BreathBallTests {
	private static function near(a, b) {
		var d = a - b;
		return d < 0.001 && d > -0.001;
	}

	private static function oneStepRunner(durations) {
		var step = new BreathStep();
		step.durations = durations;
		step.repeatType = BreathRepeat.Rounds;
		step.repeatValue = 1;
		var program = new BreathProgram();
		program.addNew(step);
		return new BreathProgramRunner(program);
	}

	(:test)
	static function sizeFollowsTheBreath(logger) {
		var inhale = BreathPhase.Inhale;
		var exhale = BreathPhase.Exhale;
		return (
			near(BreathBallRenderer.fraction(inhale, 0), 0) &&
			near(BreathBallRenderer.fraction(inhale, 0.5), 0.5) &&
			near(BreathBallRenderer.fraction(inhale, 1), 1) &&
			near(BreathBallRenderer.fraction(exhale, 0), 1) &&
			near(BreathBallRenderer.fraction(exhale, 0.5), 0.5) &&
			near(BreathBallRenderer.fraction(exhale, 1), 0) &&
			// eased: slow at both ends of a breath
			BreathBallRenderer.fraction(inhale, 0.1) < 0.1 &&
			BreathBallRenderer.fraction(inhale, 0.9) > 0.9 &&
			near(BreathBallRenderer.fraction(BreathPhase.HoldFull, 0.3), 1) &&
			near(BreathBallRenderer.fraction(BreathPhase.HoldEmpty, 0.7), 0) &&
			near(BreathBallRenderer.fraction(BreathPhase.Rest, 0.2), 0.5)
		);
	}

	(:test)
	static function progressMovesBetweenTicks(logger) {
		var runner = BreathBallTests.oneStepRunner([4, 0, 4, 0]);
		runner.update(1);
		var between = BreathBallRenderer.progress(runner, 0.5);
		var beyond = BreathBallRenderer.progress(runner, 7.0);
		runner.update(3);
		var phaseEnd = BreathBallRenderer.progress(runner, 1.0);
		runner.phaseTotal = 0;
		var empty = BreathBallRenderer.progress(runner, 0.0);
		return (
			runner.phase == BreathPhase.Inhale &&
			near(between, 0.375) &&
			near(beyond, 1) &&
			near(phaseEnd, 1) &&
			near(empty, 1)
		);
	}

	// with Auto Stop off the session outlives the program; the ball must not pulse every second
	(:test)
	static function finishedProgramHoldsTheBall(logger) {
		var runner = BreathBallTests.oneStepRunner([4, 0, 4, 0]);
		runner.update(8);
		var atTick = BreathBallRenderer.progress(runner, 0.0);
		runner.update(20);
		var later = BreathBallRenderer.progress(runner, 0.5);
		return runner.isDone && runner.phase == BreathPhase.Exhale && near(atTick, 1) && near(later, 1);
	}
}
