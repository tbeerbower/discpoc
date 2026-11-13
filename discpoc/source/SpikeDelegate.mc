import Toybox.Lang;
import Toybox.WatchUi;

// START marks a throw, BACK/LAP completes the hole, long-press UP opens the menu.
class SpikeDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        getSpike().onStartPressed();
        return true;
    }

    function onBack() as Boolean {
        return getSpike().onBackPressed();
    }

    function onMenu() as Boolean {
        var spike = getSpike();
        var menu = new WatchUi.Menu2({ :title => "Spike" });
        if (spike.isRecording()) {
            menu.addItem(new WatchUi.MenuItem("Undo last throw", null, :undo, null));
            menu.addItem(new WatchUi.MenuItem("End and save", null, :save, null));
            menu.addItem(new WatchUi.MenuItem("Discard round", null, :discard, null));
        } else if (spike.resumed) {
            menu.addItem(new WatchUi.MenuItem("Discard stored round", null, :discard, null));
        }
        menu.addItem(new WatchUi.MenuItem("GPS mode", spike.tracker.modeLabel, :gps, null));
        WatchUi.pushView(menu, new SpikeMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}
