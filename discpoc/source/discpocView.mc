import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class discpocView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var spike = getSpike();
        var round = spike.round;
        var tracker = spike.tracker;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // GPS quality and mode.
        var fix = tracker.last;
        var quality = fix == null ? 0 : fix.quality;
        var gpsColor = Graphics.COLOR_RED;
        if (quality >= Position.QUALITY_USABLE) {
            gpsColor = Graphics.COLOR_GREEN;
        } else if (quality == Position.QUALITY_POOR) {
            gpsColor = Graphics.COLOR_YELLOW;
        }
        dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
        line(dc, cx, h * 0.12, Graphics.FONT_XTINY, "GPS " + qualityLabel(quality));
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        line(dc, cx, h * 0.21, Graphics.FONT_XTINY, tracker.modeLabel);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (!spike.isRecording()) {
            line(dc, cx, h * 0.40, Graphics.FONT_MEDIUM, spike.resumed ? "Hole " + round.hole : "Disc Golf");
            line(dc, cx, h * 0.56, Graphics.FONT_SMALL, spike.resumed ? "Resume: START" : "Press START");
            if (!spike.resumed && !spike.status.equals("")) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                line(dc, cx, h * 0.72, Graphics.FONT_TINY, spike.status);
            }
        } else {
            line(dc, cx, h * 0.34, Graphics.FONT_MEDIUM, "Hole " + round.hole);
            line(dc, cx, h * 0.50, Graphics.FONT_LARGE, "Throw " + round.throwNum);
            var feet = spike.lastFeet;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            line(dc, cx, h * 0.66, Graphics.FONT_SMALL, feet == null ? "Last: --" : "Last: " + feet.format("%d") + " ft");
            if (tracker.isCapturing()) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                line(dc, cx, h * 0.79, Graphics.FONT_TINY, "Hold still " + tracker.capturedCount() + "/" + tracker.WINDOW);
            } else if (!spike.status.equals("")) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                line(dc, cx, h * 0.79, Graphics.FONT_TINY, spike.status);
            }
        }

        var stats = System.getSystemStats();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        line(dc, cx, h * 0.90, Graphics.FONT_XTINY, (stats.freeMemory / 1024) + "k free");
    }

    private function line(dc as Dc, x as Number, y as Float, font as Graphics.FontDefinition, text as String) as Void {
        dc.drawText(x, y.toNumber(), font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function qualityLabel(quality as Number) as String {
        if (quality >= Position.QUALITY_GOOD) {
            return "good";
        } else if (quality == Position.QUALITY_USABLE) {
            return "usable";
        } else if (quality == Position.QUALITY_POOR) {
            return "poor";
        } else if (quality == Position.QUALITY_LAST_KNOWN) {
            return "last known";
        }
        return "none";
    }

}
