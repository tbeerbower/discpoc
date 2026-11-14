# User Guide

This guide covers the Phase 0 spike app, **Disc Golf Spike**. It will grow as
features are added. Sections marked *not yet verified on the watch* describe how
the app is written to behave; they will be confirmed or corrected after field
testing.

## Contents

- [Before you start](#before-you-start)
- [Buttons at a glance](#buttons-at-a-glance)
- [Playing a round](#playing-a-round)
- [The screen](#the-screen)
- [The menu](#the-menu)
- [If the app closes mid-round](#if-the-app-closes-mid-round)
- [After the round](#after-the-round)
- [The log file](#the-log-file)
- [Known limitations](#known-limitations)

## Before you start

- Install the app on the watch (see the [README](../README.md#install-on-the-watch)).
- For best accuracy, wait outside until the GPS line at the top of the screen turns
  green before starting.
- If you want the GPS log, create the empty log file first (see
  [The log file](#the-log-file)).

## Buttons at a glance

| Button | Before the round | During the round |
| --- | --- | --- |
| START (top right) | Starts the round and the recording | Marks a throw |
| BACK/LAP (bottom right) | Exits the app | Marks the basket and finishes the hole |
| UP, long press (middle left) | Opens the menu | Opens the menu |

A tap on the touchscreen acts like START.

## Playing a round

*Not yet verified on the watch.*

1. **Open the app.** Press START from the watch face and choose **Disc Golf Spike**.
2. **Start the round.** Press START. The watch vibrates and the screen shows
   **Hole 1, Throw 1**. Recording has begun.
3. **Mark each throw.** Stand where you are about to throw from and press START.
   - The watch gives a short vibration and shows **Hold still** with a count up to 5.
   - Stand still for about five seconds while it collects GPS fixes.
   - A second, longer vibration means the mark is saved. The throw number goes up.
4. **Walk to your disc and repeat** step 3 for each throw, including putts.
5. **Finish the hole.** After your disc is in the basket, stand at the basket and
   press BACK/LAP. The watch again asks you to hold still, then saves the basket
   position and moves to the next hole.
6. **End the round.** Long-press UP, choose **End and save**, and confirm.

From the second throw of a hole onward, the screen shows the distance of the
throw you just completed: the distance from the previous mark to the new one.

### Tips

- Press the button at the spot the disc lies, before you pick it up and step back.
- If you press BACK/LAP before marking any throw on a hole, the watch shows
  **No throws yet** and does nothing.
- If the watch shows **No GPS fix**, the mark was not saved. Wait for the GPS line
  to recover and press again.

## The screen

| Line | Meaning |
| --- | --- |
| GPS good / usable / poor / last known / none | Current GPS quality. Green is usable or better, yellow is poor, red is no usable fix |
| multi-band / SatIQ / GPS only / default | The satellite mode in use |
| Hole *n* | The hole you are playing |
| Throw *n* | The number of the next throw you will mark |
| Last: *n* ft | Distance of the last completed throw |
| Hold still *n*/5 | The watch is collecting fixes for a mark |
| *n*k free | Free app memory, shown for the spike only |

## The menu

Long-press UP to open it.

| Item | What it does |
| --- | --- |
| Undo last throw | Removes the most recent throw on the current hole |
| End and save | Ends the round and saves the activity, after a confirmation |
| Discard round | Ends the round without saving, after a confirmation |
| GPS mode | Switches between multi-band and GPS-only satellite modes |

Before a round starts, the menu shows only **GPS mode**, plus **Discard stored
round** if an unfinished round was found.

## If the app closes mid-round

*Not yet verified on the watch.*

The app saves its state after every mark. If it closes during a round, open it
again: the screen shows the hole you were on and **Resume: START**. Press START to
continue from the same hole and throw number.

The recording itself does not continue across a restart. A resumed round starts a
new activity recording, so the saved activity covers only the part after the
resume.

To abandon the stored round instead, long-press UP and choose **Discard stored
round**.

## After the round

*Not yet verified on the watch.*

A saved round syncs to Garmin Connect like any other activity. It should appear as
a Disc Golf activity with:

- the GPS track, time and heart rate
- one lap per hole, with a **Throws** value for each lap
- a **Total Throws** value in the activity summary

The per-throw distances are not yet in the activity. For the spike they are only in
the log file.

## The log file

The app writes a line of text for every event. To capture it on the watch, create
an empty file named `discpoc.TXT` in the watch's `GARMIN/APPS/LOGS` folder (create
`LOGS` if it does not exist). After a round, copy the file back to your computer
with OpenMTP.

Each mark produces a block like this:

```
MARK,hole=1,throw=2,mode=multi-band,ts=1794600123,n=5,d1ft=248.3,d3ft=251.0,d5ft=250.6
  SINGLE,40.0150012,-105.2705034,q=4,ts=1794600118
  FIX,40.0150020,-105.2705041,q=4,ts=1794600119
  FIX,40.0150018,-105.2705039,q=4,ts=1794600120
  ...
```

| Field | Meaning |
| --- | --- |
| hole, throw | Which mark this is. `throw=0` is the basket |
| mode | Satellite mode in use |
| n | Number of fixes collected |
| d1ft | Distance from the previous mark using a single fix at each end |
| d3ft | The same distance using the average of 3 fixes at each end |
| d5ft | The same distance using the average of 5 fixes at each end |
| SINGLE | The fix that was current when the button was pressed |
| FIX | Each fix collected during the hold-still window |
| q | GPS quality, 0 (none) to 4 (good) |

The distance fields are empty for the first throw of a hole, because there is no
previous mark to measure from.

Other lines (`LAUNCH`, `STARTED`, `RESUMED`, `HOLE_DONE`, `SAVED`, `DISCARDED`,
`UNDO`) record the event along with battery level and free memory.

## Known limitations

These apply to the spike and are expected to change in Phase 1.

- A completed hole cannot be undone.
- There is no way to add a penalty stroke or correct a throw count.
- There is no end-of-round summary screen on the watch.
- Courses are not named or saved, and there is no par.
- Distances are shown in feet only.
- A stray tap on the touchscreen marks a throw.
- Short distances, such as putts, are within GPS error and should be read as
  approximate.
