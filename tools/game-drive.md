# game-drive.py

Drive the native `ink_ribbon_game` game on a **dedicated, isolated X display**
so it never steals your desktop's focus or cursor.

## Why a separate display

X11 has a single input focus and a single pointer per display. Sending real input
to a game on your desktop therefore takes focus/cursor away from you. Running the
game inside its own X server gives it its **own** focus and pointer:

- **Xephyr** (default): a nested X server whose screen is a normal window you can
  park on a secondary monitor. The game is visible there and fully isolated.
- **Xvfb** (fallback): a headless X server for automated, invisible runs
  (screenshots only).

`sokol_app`'s X11 backend reads every event on the game's own connection and
processes key events without any focus or `send_event` checks, so keyboard input
sent on the isolated display reaches the game reliably.

## Setup

Install the X server (root required):

```bash
sudo dnf install -y xorg-x11-server-Xephyr xorg-x11-server-Xvfb
```

## Usage

```bash
# Verify the tool's dependencies
tools/game-drive.py check

# Launch the game on an isolated Xephyr display, parked on the eDP-1 monitor
tools/game-drive.py start --server xephyr

# Send input (never touches your desktop focus/cursor):
tools/game-drive.py hold w 1.5                 # walk forward
tools/game-drive.py sequence f4:0.15 w:1.0     # freeze hunter, then walk
tools/game-drive.py aimlook 450 30             # aim while turning the camera
tools/game-drive.py aimfire 0.5                # aim, then hold fire
tools/game-drive.py fire 0.3                   # just fire
tools/game-drive.py aim 1.0                    # hold the aim pose

# Capture the game:
tools/game-drive.py shot /tmp/shot.png         # game window only
tools/game-drive.py shot-root /tmp/root.png    # whole isolated display

# Inspect / stop:
tools/game-drive.py status
tools/game-drive.py stop
```

The isolation is what lets you keep typing/clicking on your primary monitor while
the game is controlled on its own display.

## Environment

- `INK_RIBBON_MONITOR` — which desktop monitor to park the Xephyr screen on
  (default `eDP-1`).
- `INK_RIBBON_DISPLAY` — number of the isolated display (default `1`).

## Notes

- The isolated display uses software rendering (llvmpipe), so the game's FPS is
  low (~10). Simulation is fixed-timestep, so gameplay is unaffected.
- Mouse-look now works on the isolated display. Fake input (XTest) cannot inject
  XI2 *raw* motion values on any X server, so the vendored sokol X11 backend is
  patched (`.toolchain/deps/sokol/src/sokol/c/sokol_app.h`) to detect synthetic
  `XI_RawMotion` events (empty valuators) and derive deltas from the cursor
  position, recentring the cursor so it never stalls at a window edge. Real mice
  (which do fill valuators) are unaffected. This patch is local to this repo's
  dependency checkout; re-fetching the sokol dependency would revert it.

## Additional commands

```bash
tools/game-drive.py clickat 155 51   # absolute left-click on the game window
```
`clickat` warps the cursor to window-relative coordinates (the game is fullscreen
at the origin of its own display) and presses the left button — useful for
imgui windows and other on-screen widgets.
