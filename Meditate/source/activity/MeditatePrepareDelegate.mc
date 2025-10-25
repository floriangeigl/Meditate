using Toybox.Lang;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class MeditatePrepareDelegate extends Ui.BehaviorDelegate {
	
	var mSessionPickerDelegate;
	var mMeditatePrepareView;

    function initialize(sessionPickerDelegate, meditatePrepareView) {
		mSessionPickerDelegate = sessionPickerDelegate;
		mMeditatePrepareView = meditatePrepareView;
        Ui.BehaviorDelegate.initialize();
    }

	function onKey(keyEvent) {
	  	return true;
    }

	function onBack() {    
    	
		// Starts the meditation session / saves the session
		if (mMeditatePrepareView!=null) {
			mMeditatePrepareView.continueToNextStep();
		}

        return true;
    }
	function onTap(clickEvent) {
		return onBack();
	}
}