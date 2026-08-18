# Native input testing

The native Sokol game can be controlled automatically on the local X11
desktop. This is more reliable than timing keyboard events in a headless WASM
browser because the native build runs at a stable frame rate.

## Requirements

- An X11 session (`DISPLAY=:0` in the current development environment).
- `wmctrl` to locate and raise the game window.
- X11's `libX11` and `libXtst` libraries. Python `ctypes` can call them
  directly, so `xdotool` is not required.
- ImageMagick's `import` command for window screenshots.

Commands that access the desktop may need permission to run outside a
filesystem sandbox.

## Repository helper

Use `tools/native-input-test` for routine native testing. It validates inputs,
only controls the game process it launched, re-focuses and clicks the Sokol
window before input, and always releases a held key. The `launch` command
always runs `zig build -Doptimize=safe` before starting the game, so every test
uses the current native source.

```sh
tools/native-input-test launch
tools/native-input-test hold a 2.05
tools/native-input-test screenshot /tmp/leg-1.png
tools/native-input-test sequence w:4.0 w:2.5 w:1.0 w:1.5
tools/native-input-test status
tools/native-input-test close
```

Granting persistent permission for the narrow `tools/native-input-test`
command prefix allows screenshot-driven input loops without a new desktop
approval prompt for every leg.

## Focus ownership during a test

Prefer keeping the game focused for a complete input and capture sequence. If
Codex asks the user a question or presents an approval prompt, the user must
move focus back to the Codex CLI. Before resuming the test, assume the game no
longer has focus: find its current window ID again, raise it, and send another
focus click before injecting more input.

Before focusing the game:

- Resolve questions and obtain every predictable permission.
- Prepare the complete bounded input/capture command.
- Tell the user that the native input run is beginning.

Questions and approval prompts are allowed during an active native test, but
they divide it into separate focus segments. Release every synthetic key
before pausing for the user. After the user responds, reacquire the game window
with `wmctrl`, click it through XTest, and only then resume keyboard or mouse
injection.

## Build and launch

```sh
zig build -Doptimize=safe
./zig-out/bin/ink_ribbon_character
```

Find the Sokol window after it opens:

```sh
wmctrl -l | awk '$0 ~ /Character Mover/ {print $1}' | tail -n 1
```

The title is currently `Character Mover`. Do not hard-code the returned X11
window ID because it changes between launches.

## Focus and inject a key

Raising the window with `wmctrl -ia WINDOW_ID` is not sufficient by itself.
Sokol starts with mouse capture enabled, but an automated test must send an
actual click into the window before injected keyboard events are accepted.

This example clicks the center of a 2048 by 1152 borderless window and holds D
for 0.75 seconds:

```sh
python3 -c '
import ctypes
import time

x11 = ctypes.CDLL("libX11.so.6")
xtst = ctypes.CDLL("libXtst.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XStringToKeysym.restype = ctypes.c_ulong

display = ctypes.c_void_p(x11.XOpenDisplay(None))

# Click once so the native Sokol window receives keyboard input.
xtst.XTestFakeMotionEvent(display, -1, 1024, 576, 0)
xtst.XTestFakeButtonEvent(display, 1, 1, 0)
xtst.XTestFakeButtonEvent(display, 1, 0, 0)
x11.XFlush(display)
time.sleep(0.25)

key_sym = x11.XStringToKeysym(b"d")
key_code = x11.XKeysymToKeycode(display, key_sym)
xtst.XTestFakeKeyEvent(display, key_code, 1, 0)
x11.XFlush(display)
time.sleep(0.75)
xtst.XTestFakeKeyEvent(display, key_code, 0, 0)
x11.XFlush(display)

x11.XCloseDisplay(display)
'
```

Adjust the click coordinates when the window or display dimensions differ.
Use the same `XTestFakeKeyEvent` calls for W, A, S, Shift, F1, and other keys.
Always send the matching key-release event, including when a test fails.

Relative camera movement can be injected with repeated
`XTestFakeRelativeMotionEvent` calls after the focus click. Prefer small mouse
deltas so camera collision and pitch changes remain easy to inspect.

## Verify movement

With F1 debugging enabled, the top-left HUD displays the character position.
Capture the native window before and after an input leg:

```sh
import -window WINDOW_ID /tmp/native-input-test.png
```

In the initial native test, a 0.75-second D press at 60 FPS moved the character
from `POS 0.0 0.9 17.0` to `POS 2.4 0.9 17.0`.

For longer routes, inject one movement leg at a time and inspect the HUD
coordinates between legs. This avoids accumulating route errors and provides
clear evidence of the floor and landing reached.

### Verified left grand-stair route

Starting from the default character pose, the following native 60 FPS route
reaches the second floor through the Main Hall's left staircase:

1. Hold A for 2.05 seconds.
2. Hold W for 9.00 seconds.

The route was discovered and checked in these smaller legs:

| Leg | Input | Resulting position |
| --- | --- | --- |
| 1 | A, 2.05 s | `(-6.3, 0.9, 17.0)` |
| 2 | W, 4.00 s | `(-6.3, 1.0, 4.9)` |
| 3 | W, 2.50 s | `(-6.3, 3.8, -1.7)` |
| 4 | W, 1.00 s | `(-6.3, 4.9, -4.4)` |
| 5 | W, 1.50 s | `(-6.3, 6.4, -8.4)` |

A fresh one-shot replay ended at approximately `(-6.4, 6.4, -7.9)`. Small
differences are expected from input start timing and character acceleration.

## Cleanup

Stop the launched game with Ctrl-C in its terminal/session. If a test aborts,
first release any held synthetic keys, then terminate only the specific game
process that the test launched.
