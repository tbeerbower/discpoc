import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;

// One stored mark: [hole, throw (0 = basket), latDeg, lonDeg, quality, epochSeconds]
typedef Mark as Array<Number or Double>;

// Round state with no display or sensor calls, so it can be unit tested.
class Round {
    const STORAGE_KEY = "round";
    const SCHEMA_VERSION = 1;

    var active as Boolean = false;
    var hole as Number = 1;
    // Number of the next throw to be marked on the current hole.
    var throwNum as Number = 1;
    var totalThrows as Number = 0;
    var marks as Array<Mark> = [] as Array<Mark>;

    function initialize() {
    }

    function start() as Void {
        active = true;
        hole = 1;
        throwNum = 1;
        totalThrows = 0;
        marks = [] as Array<Mark>;
    }

    function throwsThisHole() as Number {
        return throwNum - 1;
    }

    function holesCompleted() as Number {
        return hole - 1;
    }

    function addThrow(lat as Double, lon as Double, quality as Number, ts as Number) as Void {
        marks.add([hole, throwNum, lat, lon, quality, ts] as Mark);
        throwNum += 1;
        totalThrows += 1;
    }

    // Stores the basket position and moves to the next hole.
    function completeHole(lat as Double, lon as Double, quality as Number, ts as Number) as Void {
        marks.add([hole, 0, lat, lon, quality, ts] as Mark);
        hole += 1;
        throwNum = 1;
    }

    // Removes the last throw on the current hole. A completed hole is not
    // undone in the spike because its lap is already in the activity file.
    function undoThrow() as Boolean {
        if (marks.size() == 0 || throwsThisHole() == 0) {
            return false;
        }
        marks = marks.slice(0, marks.size() - 1) as Array<Mark>;
        throwNum -= 1;
        totalThrows -= 1;
        return true;
    }

    function save() as Void {
        var data = {
            "v" => SCHEMA_VERSION,
            "active" => active,
            "hole" => hole,
            "throw" => throwNum,
            "total" => totalThrows,
            "marks" => marks
        };
        Storage.setValue(STORAGE_KEY, data as Dictionary<Storage.KeyType, Storage.ValueType>);
    }

    // Returns true when a round in progress was restored.
    function load() as Boolean {
        var data = Storage.getValue(STORAGE_KEY);
        if (!(data instanceof Dictionary)) {
            return false;
        }
        var version = data["v"];
        var wasActive = data["active"];
        if (!(version instanceof Number) || version != SCHEMA_VERSION) {
            return false;
        }
        if (!(wasActive instanceof Boolean) || !wasActive) {
            return false;
        }
        active = true;
        hole = data["hole"] as Number;
        throwNum = data["throw"] as Number;
        totalThrows = data["total"] as Number;
        marks = data["marks"] as Array<Mark>;
        return true;
    }

    function clearStored() as Void {
        Storage.deleteValue(STORAGE_KEY);
    }

    // Distance in meters between two points given in degrees. Uses a flat-earth
    // approximation on the coordinate differences, which is accurate to well
    // under a centimeter at disc golf ranges and avoids float precision loss.
    static function distanceM(lat1 as Double, lon1 as Double, lat2 as Double, lon2 as Double) as Float {
        var earthRadiusM = 6371008.8d;
        var toRad = Math.PI / 180.0d;
        var dLat = (lat2 - lat1) * toRad;
        var dLon = (lon2 - lon1) * toRad;
        var meanLat = (lat1 + lat2) / 2.0d * toRad;
        var x = dLon * Math.cos(meanLat) * earthRadiusM;
        var y = dLat * earthRadiusM;
        return Math.sqrt(x * x + y * y).toFloat();
    }

    static function metersToFeet(m as Float) as Float {
        return m * 3.28084f;
    }
}
