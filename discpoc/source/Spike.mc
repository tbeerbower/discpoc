import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Ties the round, the GPS and the activity recording together and writes
// the log lines the field protocol needs.
class Spike {
    const LAP_THROWS_FIELD_ID = 0;
    const TOTAL_THROWS_FIELD_ID = 1;

    var round as Round;
    var tracker as Tracker;
    var status as String = "";
    var resumed as Boolean = false;
    // Distance of the last measured throw in feet, from the 5-fix average.
    var lastFeet as Float?;

    private var _session as ActivityRecording.Session?;
    private var _lapThrows as FitContributor.Field?;
    private var _totalThrows as FitContributor.Field?;
    private var _basketPending as Boolean = false;
    // Positions of the previous mark on this hole, by method.
    private var _prevSingle as Fix?;
    private var _prev3 as Fix?;
    private var _prev5 as Fix?;

    function initialize() {
        round = new Round();
        tracker = new Tracker(method(:onFix));
        resumed = round.load();
        if (resumed) {
            status = "Resume: START";
        }
        logStats("LAUNCH");
    }

    function isRecording() as Boolean {
        return _session != null;
    }

    function onFix() as Void {
        WatchUi.requestUpdate();
    }

    // START button: begins (or resumes) the round, then marks throws.
    function onStartPressed() as Void {
        if (tracker.isCapturing()) {
            return;
        }
        if (_session == null) {
            beginSession();
            return;
        }
        _basketPending = false;
        requestMark();
    }

    // BACK/LAP button. Returns false to let the app exit.
    function onBackPressed() as Boolean {
        if (_session == null) {
            return false;
        }
        if (tracker.isCapturing()) {
            return true;
        }
        if (round.throwsThisHole() == 0) {
            status = "No throws yet";
            buzz(400);
            WatchUi.requestUpdate();
            return true;
        }
        _basketPending = true;
        requestMark();
        return true;
    }

    function undo() as Void {
        if (round.undoThrow()) {
            round.save();
            _prevSingle = null;
            _prev3 = null;
            _prev5 = null;
            lastFeet = null;
            status = "Undone";
            System.println("UNDO,hole=" + round.hole + ",next=" + round.throwNum);
        } else {
            status = "Nothing to undo";
        }
        WatchUi.requestUpdate();
    }

    function endRound(save as Boolean) as Void {
        var session = _session;
        if (session != null) {
            var total = _totalThrows;
            if (total != null) {
                total.setData(round.totalThrows);
            }
            var lap = _lapThrows;
            if (lap != null) {
                lap.setData(round.throwsThisHole());
            }
            session.stop();
            if (save) {
                session.save();
            } else {
                session.discard();
            }
        }
        _session = null;
        _lapThrows = null;
        _totalThrows = null;
        logStats(save ? "SAVED" : "DISCARDED");
        status = (save ? "Saved: " : "Discarded: ") + round.holesCompleted() + " holes";
        round.active = false;
        round.clearStored();
        resumed = false;
        lastFeet = null;
        buzz(600);
        WatchUi.requestUpdate();
    }

    private function beginSession() as Void {
        if (!round.active) {
            round.start();
        }
        var sport = Activity.SPORT_GENERIC;
        if (Activity has :SPORT_DISC_GOLF) {
            sport = Activity.SPORT_DISC_GOLF;
        }
        var session = ActivityRecording.createSession({
            :name => "Disc Golf",
            :sport => sport,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        _lapThrows = session.createField("throws", LAP_THROWS_FIELD_ID, FitContributor.DATA_TYPE_UINT8,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :units => "throws" });
        _totalThrows = session.createField("total_throws", TOTAL_THROWS_FIELD_ID, FitContributor.DATA_TYPE_UINT16,
            { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "throws" });
        session.start();
        _session = session;
        round.save();
        status = "";
        logStats(resumed ? "RESUMED" : "STARTED");
        buzz(200);
        WatchUi.requestUpdate();
    }

    private function requestMark() as Void {
        if (tracker.last == null) {
            status = "No GPS fix";
            buzz(400);
        } else {
            status = "Hold still";
            buzz(100);
            tracker.capture(method(:onCaptured));
        }
        WatchUi.requestUpdate();
    }

    function onCaptured(single as Fix?, fixes as Array<Fix>) as Void {
        if (fixes.size() == 0) {
            status = "No GPS fix";
            buzz(400);
            WatchUi.requestUpdate();
            return;
        }
        var avg3 = Fix.average(fixes, 3);
        var avg5 = Fix.average(fixes, fixes.size());
        var one = single != null ? single : fixes[0];

        var d1 = feetBetween(_prevSingle, one);
        var d3 = feetBetween(_prev3, avg3);
        var d5 = feetBetween(_prev5, avg5);

        var throwLabel = _basketPending ? 0 : round.throwNum;
        System.println("MARK,hole=" + round.hole + ",throw=" + throwLabel + ",mode=" + tracker.modeLabel
            + ",ts=" + avg5.ts + ",n=" + fixes.size()
            + ",d1ft=" + fmtFeet(d1) + ",d3ft=" + fmtFeet(d3) + ",d5ft=" + fmtFeet(d5));
        System.println("  SINGLE," + fmtFix(one));
        for (var i = 0; i < fixes.size(); i++) {
            System.println("  FIX," + fmtFix(fixes[i]));
        }

        if (_basketPending) {
            var lap = _lapThrows;
            if (lap != null) {
                lap.setData(round.throwsThisHole());
            }
            round.completeHole(avg5.lat, avg5.lon, avg5.quality, avg5.ts);
            var session = _session;
            if (session != null) {
                session.addLap();
            }
            _prevSingle = null;
            _prev3 = null;
            _prev5 = null;
            logStats("HOLE_DONE");
        } else {
            round.addThrow(avg5.lat, avg5.lon, avg5.quality, avg5.ts);
            _prevSingle = one;
            _prev3 = avg3;
            _prev5 = avg5;
        }
        var total = _totalThrows;
        if (total != null) {
            total.setData(round.totalThrows);
        }
        if (d5 != null) {
            lastFeet = d5;
        }
        _basketPending = false;
        round.save();
        status = "";
        buzz(250);
        WatchUi.requestUpdate();
    }

    private function feetBetween(a as Fix?, b as Fix) as Float? {
        if (a == null) {
            return null;
        }
        return Round.metersToFeet(Round.distanceM(a.lat, a.lon, b.lat, b.lon));
    }

    private function fmtFeet(d as Float?) as String {
        return d == null ? "" : d.format("%.1f");
    }

    private function fmtFix(f as Fix) as String {
        return f.lat.format("%.7f") + "," + f.lon.format("%.7f") + ",q=" + f.quality + ",ts=" + f.ts;
    }

    private function logStats(event as String) as Void {
        var stats = System.getSystemStats();
        System.println(event + ",hole=" + round.hole + ",total=" + round.totalThrows
            + ",battery=" + stats.battery.format("%.1f")
            + ",memFree=" + stats.freeMemory + ",memTotal=" + stats.totalMemory);
    }

    private function buzz(ms as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, ms)]);
        }
    }
}
