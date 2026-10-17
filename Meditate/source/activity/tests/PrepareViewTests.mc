using Toybox.Test;

// the countdown hands over once, however taps, back and its own timer interleave; 3700 ticks outlast any finalize time
(:test)
class PrepareViewTests {
	(:test)
	static function continuesOnlyOnce(logger) {
		var counter = new PrepareViewCounter();
		var view = new MeditatePrepareView(counter.method(:onContinue), 0, null);
		view.continueToNextStep();
		view.continueToNextStep();
		for (var i = 0; i < 3700; i++) {
			view.onViewDrawn();
		}
		logger.debug("continued " + counter.count);
		return counter.count == 1;
	}

	(:test)
	static function countdownContinuesOnce(logger) {
		var counter = new PrepareViewCounter();
		var view = new MeditatePrepareView(counter.method(:onContinue), 0, null);
		for (var i = 0; i < 3700; i++) {
			view.onViewDrawn();
		}
		view.continueToNextStep();
		logger.debug("continued " + counter.count);
		return counter.count == 1;
	}
}

(:test)
class PrepareViewCounter {
	var count = 0;

	function onContinue() {
		me.count += 1;
	}
}
