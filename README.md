# Disc Golf Tracker for Garmin Fenix

A Connect IQ watch app that records a disc golf round as an activity. You press a
button at each throw and the watch stores where you were standing, so it can report
the distance of every throw, the throws per hole, and the tee-to-basket distance.

## Status

**Phase 0 spike.** The code in this repository is a throwaway app that exists to
answer a handful of technical questions on a real watch (GPS scatter, button
behavior, activity recording, state recovery). It is not the product, and Phase 1
will start as a fresh project with its own app ID.

| Phase | Goal | State |
| --- | --- | --- |
| 0. Spike | Measure GPS accuracy and confirm platform behavior on a Fenix 7 Pro | In progress: app written, field test pending |
| 1. Watch MVP | Full round flow, summary, saved courses, resume after exit | Not started |
| 2. Upload and web map | Rounds upload through the phone; web app shows them on a map | Not started |
| 3. Store release | More watch models, settings, Connect IQ Store listing | Not started |

What works today, verified in the simulator: the app compiles for the Fenix 7 Pro,
launches, and its unit tests pass. The button flow, GPS capture and activity
recording have not yet been exercised on a watch.

## Documentation

- [User guide](docs/user-guide.md): how to use the app on the watch.

## Repository layout

```
discpoc/                 Connect IQ project
  manifest.xml           App ID, target watches, permissions
  monkey.jungle          Build configuration
  resources/             Strings, launcher icon, custom activity fields
  source/
    SpikeApp.mc          App entry point
    Spike.mc             Ties round, GPS and activity recording together; writes the log
    Round.mc             Round state and distance math (no display or sensor calls)
    Tracker.mc           GPS: latest fix, and averaging over a capture window
    SpikeView.mc         The one screen
    SpikeDelegate.mc     Button handling
    SpikeMenuDelegate.mc Menu and confirmation handling
    RoundTest.mc         Unit tests
docs/                    User guide
```

`discpoc/bin/` and `discpoc/device-build/` are build output and are not tracked.

## Requirements

- macOS (the commands below assume it; the SDK also runs on Windows and Ubuntu)
- Java runtime, version 11 or higher
- Visual Studio Code with Garmin's Monkey C extension
- Connect IQ SDK Manager, with an SDK installed (developed against 9.3.0) and the
  Fenix 7 Pro device files downloaded
- A Connect IQ developer key, generated with **Monkey C: Generate a Developer Key**
- An MTP file-transfer tool such as OpenMTP, for copying builds to the watch

Garmin's [getting started guide](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/)
covers installing the SDK Manager, the extension and the key.

## Build, test and run

### In Visual Studio Code

Open the `discpoc` project folder, then use the command palette:

- **Run > Run Without Debugging** runs the app in the simulator.
- **Monkey C: Run Tests** runs the unit tests in the simulator.
- **Monkey C: Build for Device** builds the file for the watch. Choose `fenix7pro`
  and the `device-build` folder.

### From the command line

Set two variables first. `SDK` is read from the SDK Manager's own configuration;
`KEY` is wherever you saved your developer key.

```bash
SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
```

```bash
KEY=/path/to/developer_key
```

Run these from the `discpoc` project folder.

Build for the watch:

```bash
"$SDK/bin/monkeyc" -f monkey.jungle -d fenix7pro -o device-build/discpoc.prg -y "$KEY" -l 2 -w -r
```

Build and run the unit tests (the simulator must be running; start it with
`"$SDK/bin/connectiq"`):

```bash
"$SDK/bin/monkeyc" -f monkey.jungle -d fenix7pro -o bin/discpoc-test.prg -y "$KEY" -l 2 -w --unit-test
```

```bash
"$SDK/bin/monkeydo" bin/discpoc-test.prg fenix7pro -t
```

Run the app in the simulator:

```bash
"$SDK/bin/monkeyc" -f monkey.jungle -d fenix7pro -o bin/discpoc.prg -y "$KEY" -l 2 -w
```

```bash
"$SDK/bin/monkeydo" bin/discpoc.prg fenix7pro
```

### Install on the watch

1. Connect the watch by USB and open OpenMTP. (Finder cannot show the watch.)
2. Copy `device-build/discpoc.prg` into `GARMIN/APPS` on the watch.
3. Unplug. The app appears in the activity list as **Disc Golf Spike**.

The watch consumes the file on install, so it will not be visible in `GARMIN/APPS`
afterward. Copying a new build replaces the installed app.

### Capture the debug log

Create an empty file named `discpoc.TXT` in `GARMIN/APPS/LOGS` on the watch. The
app's log output is appended to it. This is how the spike's GPS data is collected;
see the [user guide](docs/user-guide.md#the-log-file) for the format.

## Design notes

- Distances are stored in meters and converted to feet for display.
- Round state is written to on-watch storage after every mark, with a schema
  version, so a round survives the app closing.
- `Round.mc` has no display or sensor dependencies, which is what makes it unit
  testable.
- The target device is the Fenix 7 Pro. The manifest lists other Fenix models, but
  they are untested.
