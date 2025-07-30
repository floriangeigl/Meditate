import Toybox.Communications;

class TipMe {
    static function openTipMe(minutes) {
        Communications.openWebPage(
            "https://geigl.online/tipme/",
            {"m" => minutes.toString},
            null
            );    
    }
}
