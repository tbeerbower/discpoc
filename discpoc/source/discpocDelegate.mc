import Toybox.Lang;
import Toybox.WatchUi;

class discpocDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new discpocMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}