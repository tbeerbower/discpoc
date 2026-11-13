import Toybox.Lang;
import Toybox.Test;

(:test)
function testDistanceNorth(logger as Logger) as Boolean {
    // 0.001 degrees of latitude is 111.195 m.
    var d = Round.distanceM(40.0d, -105.0d, 40.001d, -105.0d);
    logger.debug("north: " + d);
    return (d - 111.195f).abs() < 0.05f;
}

(:test)
function testDistanceEast(logger as Logger) as Boolean {
    // 0.001 degrees of longitude at 40 N is 85.180 m.
    var d = Round.distanceM(40.0d, -105.0d, 40.0d, -104.999d);
    logger.debug("east: " + d);
    return (d - 85.180f).abs() < 0.05f;
}

(:test)
function testShortDistance(logger as Logger) as Boolean {
    // 15 ft is 4.572 m: about 0.00004112 degrees of latitude.
    var d = Round.metersToFeet(Round.distanceM(40.0d, -105.0d, 40.00004112d, -105.0d));
    logger.debug("short ft: " + d);
    return (d - 15.0f).abs() < 0.05f;
}

(:test)
function testRoundFlow(logger as Logger) as Boolean {
    var r = new Round();
    r.start();
    r.addThrow(40.0d, -105.0d, 4, 100);
    r.addThrow(40.001d, -105.0d, 4, 200);
    Test.assertEqual(r.throwsThisHole(), 2);
    r.completeHole(40.0012d, -105.0d, 4, 300);
    Test.assertEqual(r.hole, 2);
    Test.assertEqual(r.throwNum, 1);
    Test.assertEqual(r.totalThrows, 2);
    Test.assertEqual(r.marks.size(), 3);
    // A completed hole cannot be undone.
    Test.assert(!r.undoThrow());
    r.addThrow(40.002d, -105.0d, 4, 400);
    Test.assert(r.undoThrow());
    Test.assertEqual(r.throwNum, 1);
    Test.assertEqual(r.totalThrows, 2);
    Test.assertEqual(r.marks.size(), 3);
    return true;
}

(:test)
function testSaveAndLoad(logger as Logger) as Boolean {
    var r = new Round();
    r.start();
    r.addThrow(40.0d, -105.0d, 4, 100);
    r.completeHole(40.001d, -105.0d, 4, 200);
    r.addThrow(40.002d, -105.0d, 3, 300);
    r.save();
    var restored = new Round();
    Test.assert(restored.load());
    Test.assertEqual(restored.hole, 2);
    Test.assertEqual(restored.throwNum, 2);
    Test.assertEqual(restored.totalThrows, 2);
    Test.assertEqual(restored.marks.size(), 3);
    restored.clearStored();
    Test.assert(!(new Round()).load());
    return true;
}

(:test)
function testFixAverage(logger as Logger) as Boolean {
    var fixes = [
        new Fix(40.0d, -105.0d, 4, 1),
        new Fix(40.0002d, -105.0002d, 3, 2),
        new Fix(40.0004d, -105.0004d, 4, 3),
        new Fix(41.0d, -106.0d, 4, 4)
    ] as Array<Fix>;
    var avg = Fix.average(fixes, 3);
    Test.assert((avg.lat - 40.0002d).abs() < 0.0000001d);
    Test.assert((avg.lon + 105.0002d).abs() < 0.0000001d);
    Test.assertEqual(avg.quality, 3);
    Test.assertEqual(avg.ts, 3);
    return true;
}
