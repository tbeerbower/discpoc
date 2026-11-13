import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class discpocApp extends Application.AppBase {

    var spike as Spike?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var s = new Spike();
        s.tracker.enable();
        spike = s;
    }

    function onStop(state as Dictionary?) as Void {
        var s = spike;
        if (s != null) {
            s.tracker.disable();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new discpocView(), new discpocDelegate() ];
    }

}

function getApp() as discpocApp {
    return Application.getApp() as discpocApp;
}

function getSpike() as Spike {
    return getApp().spike as Spike;
}
