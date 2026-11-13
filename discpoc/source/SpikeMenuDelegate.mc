import Toybox.Lang;
import Toybox.WatchUi;

class SpikeMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :undo) {
            getSpike().undo();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :gps) {
            getSpike().tracker.toggleMode();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :save) {
            WatchUi.switchToView(new WatchUi.Confirmation("Save round?"), new EndRoundDelegate(true), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :discard) {
            WatchUi.switchToView(new WatchUi.Confirmation("Discard round?"), new EndRoundDelegate(false), WatchUi.SLIDE_IMMEDIATE);
        }
    }

}

class EndRoundDelegate extends WatchUi.ConfirmationDelegate {

    private var _save as Boolean;

    function initialize(save as Boolean) {
        ConfirmationDelegate.initialize();
        _save = save;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getSpike().endRound(_save);
        }
        return true;
    }

}
