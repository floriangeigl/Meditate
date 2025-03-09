using Toybox.WatchUi as Ui;

class YesDelegate extends Ui.ConfirmationDelegate {
	private var mOnYes;
	
    function initialize(onYes) {
        ConfirmationDelegate.initialize();
        me.mOnYes = onYes;
    }

    function onResponse(value) {
        // Simulator bug - value = 0, even tho it should be 1; 
        // works on real device
        if (value == Ui.CONFIRM_YES) {  
        	me.mOnYes.invoke();
            return true;
        }
        return false;
    }
}