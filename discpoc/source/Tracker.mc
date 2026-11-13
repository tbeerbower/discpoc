import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Timer;

class Fix {
    var lat as Double;
    var lon as Double;
    var quality as Number;
    var ts as Number;

    function initialize(lat_ as Double, lon_ as Double, quality_ as Number, ts_ as Number) {
        lat = lat_;
        lon = lon_;
        quality = quality_;
        ts = ts_;
    }

    // Average of the first `count` fixes (or all, if fewer).
    static function average(fixes as Array<Fix>, count as Number) as Fix {
        var n = fixes.size() < count ? fixes.size() : count;
        var lat = 0.0d;
        var lon = 0.0d;
        var worst = 4;
        for (var i = 0; i < n; i++) {
            lat += fixes[i].lat;
            lon += fixes[i].lon;
            if (fixes[i].quality < worst) {
                worst = fixes[i].quality;
            }
        }
        return new Fix(lat / n, lon / n, worst, fixes[n - 1].ts);
    }
}

typedef CaptureCallback as Method(single as Fix?, fixes as Array<Fix>) as Void;

// Owns the GPS. Keeps the latest fix and, on request, collects the next
// WINDOW fixes so a mark can be averaged while the player stands still.
class Tracker {
    const WINDOW = 5;
    const TIMEOUT_MS = 9000;

    var last as Fix?;
    var multiBand as Boolean = true;
    var modeLabel as String = "--";

    private var _capture as Array<Fix>?;
    private var _single as Fix?;
    private var _done as CaptureCallback?;
    private var _onFix as (Method() as Void)?;
    private var _timer as Timer.Timer;

    function initialize(onFix as Method() as Void) {
        _onFix = onFix;
        _timer = new Timer.Timer();
    }

    function enable() as Void {
        var options = {
            :acquisitionType => Position.LOCATION_CONTINUOUS
        } as { :acquisitionType as Position.LocationAcquisitionType, :configuration as Position.Configuration };
        modeLabel = "default";
        if (Position has :hasConfigurationSupport) {
            if (multiBand && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5)) {
                options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
                modeLabel = "multi-band";
            } else if (multiBand && Position.hasConfigurationSupport(Position.CONFIGURATION_SAT_IQ)) {
                options[:configuration] = Position.CONFIGURATION_SAT_IQ;
                modeLabel = "SatIQ";
            } else if (!multiBand && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS)) {
                options[:configuration] = Position.CONFIGURATION_GPS;
                modeLabel = "GPS only";
            }
        }
        Position.enableLocationEvents(options, method(:onPosition));
    }

    function disable() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function toggleMode() as Void {
        multiBand = !multiBand;
        enable();
    }

    function isCapturing() as Boolean {
        return _capture != null;
    }

    function capturedCount() as Number {
        var c = _capture;
        return c == null ? 0 : c.size();
    }

    // Collects the next WINDOW fixes, then calls done(single, fixes), where
    // single is the fix that was current at the moment of the request.
    function capture(done as CaptureCallback) as Void {
        if (_capture != null) {
            return;
        }
        _single = last;
        _capture = [] as Array<Fix>;
        _done = done;
        _timer.start(method(:onTimeout), TIMEOUT_MS, false);
    }

    function onPosition(info as Position.Info) as Void {
        var position = info.position;
        var accuracy = info.accuracy;
        if (position != null && accuracy != null) {
            var deg = position.toDegrees();
            var fix = new Fix(deg[0], deg[1], accuracy as Number, Time.now().value());
            last = fix;
            var c = _capture;
            if (c != null && fix.quality >= Position.QUALITY_POOR) {
                c.add(fix);
                if (c.size() >= WINDOW) {
                    finish();
                }
            }
        }
        var cb = _onFix;
        if (cb != null) {
            cb.invoke();
        }
    }

    function onTimeout() as Void {
        finish();
    }

    private function finish() as Void {
        _timer.stop();
        var fixes = _capture;
        var done = _done;
        var single = _single;
        _capture = null;
        _done = null;
        _single = null;
        if (fixes != null && done != null) {
            done.invoke(single, fixes);
        }
    }
}
