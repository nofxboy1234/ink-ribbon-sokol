#!/usr/bin/env python3
"""Drive the native character game on a dedicated, isolated X display.

The game runs inside its own X server (Xephyr by default, so its screen is a
window you can park on a monitor; Xvfb as a headless fallback). That display has
its own pointer and input focus, completely separate from your desktop, so
driving the game never steals your focus or cursor.

Only the display is isolated; input is plain XTest (not XSendEvent), because the
game's window is the only thing that can ever hold focus there.
"""

from __future__ import annotations

import ctypes
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parent.parent
BINARY = ROOT / "zig-out/bin/ink_ribbon_character"
STATE_FILE = Path("/tmp/ink-ribbon-gamedrive.json")
LOG_FILE = Path("/tmp/ink-ribbon-gamedrive.log")
WINDOW_TITLE = "Character Mover"

# Default screen the game renders at (matches sapp.width/height = 1280x720).
GAME_W = 1280
GAME_H = 720

# eDP-1 is 1920x1080 at origin (0,0) on the desktop by default.
MONITOR = os.environ.get("INK_RIBBON_MONITOR", "eDP-1")
DISPLAY_NUM = os.environ.get("INK_RIBBON_DISPLAY", "1")

ALLOWED_KEYS = {
    "w", "a", "s", "d", "f", "i", "m", "p", "q", "r", "shift", "ctrl", "alt", "tab", "enter", "space",
    "f1", "f2", "f3", "f4", "escape",
    "left", "right", "up", "down",
}
MAX_HOLD_SECONDS = 30.0
MAX_LOOK_DELTA = 2000


def fail(message: str) -> None:
    raise SystemExit(message)


def _display(name: str) -> str:
    return f":{name}" if name.isdigit() else name


def geo_of_monitor(name: str) -> tuple[int, int, int, int]:
    """Return (x, y, width, height) for a monitor on the *desktop* display.

    xrandr --listmonitors emits lines like:
        0: +*HDMI-1 2560/597x1440/336+1920+0  HDMI-1
    """
    import re

    pattern = re.compile(r"(\d+)/\d+x(\d+)/\d+\+(\d+)\+(\d+)")
    result = subprocess.run(["xrandr", "--listmonitors"], check=True, capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if name not in line:
            continue
        match = pattern.search(line)
        if match:
            width, height, x, y = (int(match.group(i)) for i in range(1, 5))
            return x, y, width, height
    fail(f"Could not find monitor {name!r} via xrandr --listmonitors")


# --------------------------------------------------------------------------- #
# X11 helpers (ctypes over libX11 / libXtst).
# --------------------------------------------------------------------------- #
class XServer:
    _structs = []

    def __init__(self, display: str) -> None:
        self.display_name = display
        self.x11 = ctypes.CDLL("libX11.so.6")
        self.xtst = ctypes.CDLL("libXtst.so.6")
        self.x11.XOpenDisplay.restype = ctypes.c_void_p
        self.x11.XDefaultRootWindow.restype = ctypes.c_ulong
        self.x11.XStringToKeysym.restype = ctypes.c_ulong
        self.x11.XKeysymToKeycode.restype = ctypes.c_uint
        self.x11.XFetchName.restype = ctypes.c_int
        self.x11.XQueryTree.restype = ctypes.c_int
        self.x11.XSetInputFocus.restype = ctypes.c_int
        self.x11.XRaiseWindow.restype = ctypes.c_int
        self.x11.XFlush.restype = ctypes.c_int
        self.x11.XFree.restype = ctypes.c_int

        # A BadMatch (e.g. focusing a not-yet-viewable window) must not kill the
        # driver; the default X error handler calls exit(). Returning 0 defers it.
        error_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)

        @error_type
        def _ignore(display, event):
            return 0

        self.x11.XSetErrorHandler(_ignore)

        self.handle = ctypes.c_void_p(self.x11.XOpenDisplay(display.encode()))
        if not self.handle:
            fail(f"Could not open X display {display}")

        # XWindowAttributes: need map_state (offset 92) to test visibility.
        class XWindowAttributes(ctypes.Structure):
            _fields_ = [
                ("x", ctypes.c_int), ("y", ctypes.c_int),
                ("width", ctypes.c_int), ("height", ctypes.c_int),
                ("border_width", ctypes.c_int), ("depth", ctypes.c_int),
                ("visual", ctypes.c_void_p),
                ("root", ctypes.c_ulong),
                ("class", ctypes.c_int),
                ("bit_gravity", ctypes.c_int), ("win_gravity", ctypes.c_int),
                ("backing_store", ctypes.c_int),
                ("backing_planes", ctypes.c_ulong), ("backing_pixel", ctypes.c_ulong),
                ("save_under", ctypes.c_int),
                ("colormap", ctypes.c_ulong),
                ("map_installed", ctypes.c_int),
                ("map_state", ctypes.c_int),
                ("all_event_masks", ctypes.c_long),
                ("my_event_mask", ctypes.c_long),
                ("do_not_propagate_mask", ctypes.c_long),
                ("override_redirect", ctypes.c_int),
                ("screen", ctypes.c_void_p),
            ]

        self.XWindowAttributes = XWindowAttributes
        self.x11.XGetWindowAttributes.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(XWindowAttributes)]
        self.x11.XGetWindowAttributes.restype = ctypes.c_int
        self.x11.XGetInputFocus.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int)]
        self.x11.XGetInputFocus.restype = ctypes.c_int

    def close(self) -> None:
        self.x11.XCloseDisplay(self.handle)

    def flush(self) -> None:
        self.x11.XFlush(self.handle)

    def root(self) -> int:
        return int(self.x11.XDefaultRootWindow(self.handle))

    def raise_window(self, window: int) -> None:
        self.x11.XRaiseWindow(self.handle, window)
        self.flush()

    def is_viewable(self, window: int) -> bool:
        attrs = self.XWindowAttributes()
        if self.x11.XGetWindowAttributes(self.handle, window, ctypes.byref(attrs)):
            return attrs.map_state == 2  # IsViewable
        return False

    def set_focus(self, window: int) -> None:
        # Only focus a viewable window; RevertToParent=2, CurrentTime=0.
        if not self.is_viewable(window):
            return
        self.x11.XSetInputFocus(self.handle, window, 2, 0)
        self.flush()

    def input_focus(self) -> int:
        focus = ctypes.c_ulong()
        revert = ctypes.c_int()
        self.x11.XGetInputFocus(self.handle, ctypes.byref(focus), ctypes.byref(revert))
        return int(focus.value)

    def _windows(self, parent: int) -> list[int]:
        root = ctypes.c_ulong()
        par = ctypes.c_ulong()
        children = ctypes.POINTER(ctypes.c_ulong)()
        count = ctypes.c_uint()
        if not self.x11.XQueryTree(self.handle, parent, ctypes.byref(root), ctypes.byref(par), ctypes.byref(children), ctypes.byref(count)):
            return []
        result = [int(children[i]) for i in range(count.value)]
        if children:
            self.x11.XFree(ctypes.cast(children, ctypes.c_void_p))
        return result

    def _name(self, window: int) -> str | None:
        name = ctypes.c_char_p()
        if self.x11.XFetchName(self.handle, window, ctypes.byref(name)):
            value = name.value.decode("utf-8", "replace") if name.value else ""
            if name.value:
                self.x11.XFree(ctypes.cast(name, ctypes.c_void_p))
            return value
        return None

    def find_window(self, title: str) -> int | None:
        for win in self._windows(self.root()):
            if (self._name(win) or "") == title:
                return win
        # Fall back to any named top-level window (works if title has decorations).
        best = None
        for win in self._windows(self.root()):
            n = self._name(win)
            if n and title.lower() in n.lower():
                best = win
        return best

    def key_code(self, name: str) -> int:
        x_name = {
            "shift": "Shift_L",
            "ctrl": "Control_L",
            "alt": "Alt_L",
            "tab": "Tab",
            "f1": "F1",
            "f2": "F2",
            "f3": "F3",
            "f4": "F4",
            "escape": "Escape",
            "left": "Left",
            "right": "Right",
            "up": "Up",
            "down": "Down",
            "enter": "Return",
            "space": "space",
        }.get(name, name)
        symbol = self.x11.XStringToKeysym(x_name.encode())
        code = self.x11.XKeysymToKeycode(self.handle, symbol)
        if code == 0:
            fail(f"X11 could not resolve key {name!r}")
        return int(code)

    def set_key(self, name: str, down: bool) -> None:
        self.xtst.XTestFakeKeyEvent(self.handle, self.key_code(name), int(down), 0)
        self.flush()

    def move_mouse(self, dx: int, dy: int) -> None:
        self.xtst.XTestFakeRelativeMotionEvent(self.handle, int(dx), int(dy), 0)
        self.flush()

    def set_button(self, button: int, down: bool) -> None:
        self.xtst.XTestFakeButtonEvent(self.handle, int(button), int(down), 0)
        self.flush()


# --------------------------------------------------------------------------- #
# State for the launched display + game process.
# --------------------------------------------------------------------------- #
def load_state() -> dict[str, object]:
    try:
        return json.loads(STATE_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(**payload: object) -> None:
    data = load_state()
    data.update(payload)
    STATE_FILE.write_text(json.dumps(data) + "\n")


def _process_exists(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except (ProcessLookupError, PermissionError):
        return False
    return True


def owned_game_pid() -> int:
    value = load_state().get("game_pid")
    if not isinstance(value, int) or not _process_exists(value):
        fail("No live game process is recorded; run the 'start' command first")
    return value


def owned_display_num() -> str:
    value = load_state().get("display_num", DISPLAY_NUM)
    return str(value)


def read_window_id() -> str:
    value = load_state().get("window_id")
    if isinstance(value, str) and value:
        return value
    fail("No game window id recorded; run the 'start' command first")


# --------------------------------------------------------------------------- #
# Display server management (Xephyr or Xvfb).
# --------------------------------------------------------------------------- #
def server_binary(server: str) -> str:
    name = "Xvfb" if server == "xvfb" else "Xephyr"
    found = shutil.which(name)
    if not found:
        fail(f"{name} is not installed. Install with: sudo dnf install -y "
             f"{'xorg-x11-server-Xvfb' if server == 'xvfb' else 'xorg-x11-server-Xephyr'}")
    return found


def start_server(server: str, display_num: str) -> tuple[subprocess.Popen, int]:
    display = _display(display_num)
    binary = server_binary(server)
    log = LOG_FILE.open("ab")
    args = [binary, display]
    if server == "xvfb":
        args += ["-screen", "0", f"{GAME_W}x{GAME_H}x24", "-nolisten", "tcp"]
    else:
        args += ["-screen", f"{GAME_W}x{GAME_H}x24", "-title", "ink-ribbon game screen", "-resizeable"]
    proc = subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    deadline = time.monotonic() + 10.0
    while time.monotonic() < deadline:
        try:
            result = subprocess.run(["xdpyinfo", "-display", display], check=True, capture_output=True, text=True)
            if "dimensions:" in result.stdout and "x" in result.stdout.split("dimensions:")[1]:
                break
        except (subprocess.CalledProcessError, FileNotFoundError):
            time.sleep(0.1)
    else:
        proc.terminate()
        fail(f"{binary} did not become ready on {display}")
    print(f"{server} up on {display} (pid={proc.pid})")
    return proc, proc.pid


def place_server_window(server: str, prev_active: str | None = None) -> None:
    """Park the Xephyr window on the chosen monitor of the desktop display.

    The Xephyr screen is a window on the user's desktop; without care the window
    manager focuses it on map and steals focus from the user. Make it
    non-focusable and restore the user's previous focus so they keep working.
    """
    if server != "xephyr":
        return
    mx, my, mw, mh = geo_of_monitor(MONITOR)
    x = mx + max(0, (mw - GAME_W) // 2)
    y = my + max(0, (mh - GAME_H) // 2)
    # The Xephyr window may take a moment to map; retry so wmctrl can find it.
    for _ in range(20):
        result = subprocess.run(
            ["wmctrl", "-r", "ink-ribbon game screen", "-e", f"0,{x},{y},{GAME_W},{GAME_H}"],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            break
        time.sleep(0.1)
    _make_desktop_window_nonfocusable("ink-ribbon game screen")
    # Give the user's focus back so opening the game never disrupts them.
    if prev_active:
        subprocess.run(["wmctrl", "-ia", prev_active], check=False)


def _desktop_window_by_title(title: str) -> str | None:
    try:
        result = subprocess.run(["wmctrl", "-l"], check=True, capture_output=True, text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    for line in result.stdout.splitlines():
        if title in line:
            return line.split(maxsplit=1)[0]
    return None


def _desktop_active_window() -> str | None:
    try:
        result = subprocess.run(["xprop", "-root", "_NET_ACTIVE_WINDOW"], check=True, capture_output=True, text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    for token in result.stdout.split():
        if token.startswith("0x"):
            return token.lower()
    return None


def _make_desktop_window_nonfocusable(title: str) -> None:
    """Tell the window manager not to give the desktop window keyboard focus.

    Setting WM_HINTS.input to False means the WM should not focus it on map
    (or on click-focus), which stops it from stealing focus from the user.
    """
    window = _desktop_window_by_title(title)
    if not window:
        return

    class XWMHints(ctypes.Structure):
        _fields_ = [
            ("flags", ctypes.c_long),
            ("input", ctypes.c_int),
            ("initial_state", ctypes.c_int),
            ("icon_pixmap", ctypes.c_ulong),
            ("icon_window", ctypes.c_ulong),
            ("icon_x", ctypes.c_int),
            ("icon_y", ctypes.c_int),
            ("icon_mask", ctypes.c_ulong),
            ("window_group", ctypes.c_ulong),
        ]

    try:
        x11 = ctypes.CDLL("libX11.so.6")
        x11.XOpenDisplay.restype = ctypes.c_void_p
        x11.XSetWMHints.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(XWMHints)]
        x11.XSetWMHints.restype = ctypes.c_int
        x11.XFlush.restype = ctypes.c_int
        x11.XCloseDisplay.restype = ctypes.c_int
        display = ctypes.c_void_p(x11.XOpenDisplay(None))  # the desktop display :0
        if not display:
            return
        hints = XWMHints()
        hints.flags = 1  # InputHint (1 << 0)
        hints.input = 0  # False: window does not want keyboard focus
        x11.XSetWMHints(display, int(window, 16), ctypes.byref(hints))
        x11.XFlush(display)
        x11.XCloseDisplay(display)
    except (OSError, AttributeError):
        pass


# --------------------------------------------------------------------------- #
# Game launch.
# --------------------------------------------------------------------------- #
def start(server: str) -> None:
    if isinstance(load_state().get("game_pid"), int) and _process_exists(load_state()["game_pid"]):
        fail("A game process is already running; run 'stop' first")
    display = _display(DISPLAY_NUM)
    display_num = DISPLAY_NUM
    # Remember the user's focused window so opening the game screen never steals it.
    prev_active = _desktop_active_window()
    # Reclaim the display if we previously owned it.
    server_proc, _ = start_server(server, display_num)
    place_server_window(server, prev_active)

    print("building native game...", flush=True)
    subprocess.run(["zig", "build", "-Doptimize=safe"], cwd=ROOT, check=True)
    if not BINARY.is_file():
        fail(f"Build succeeded without producing {BINARY}")

    run_directory = Path(tempfile.mkdtemp(prefix="ink-ribbon-gamedrive-"))
    env = dict(os.environ, DISPLAY=display)
    log = LOG_FILE.open("ab")
    game = subprocess.Popen(
        [str(BINARY)],
        cwd=run_directory,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=log,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    save_state(game_pid=game.pid, server_pid=server_proc.pid, server=server, display_num=display_num, window_id="", run_dir=str(run_directory))

    # Wait for the window, then give it input focus on the isolated display.
    x = XServer(display)
    try:
        deadline = time.monotonic() + 12.0
        window = None
        while time.monotonic() < deadline:
            if game.poll() is not None:
                fail(f"Game exited during launch; inspect {LOG_FILE}")
            window = x.find_window(WINDOW_TITLE)
            if window is not None and x.is_viewable(window):
                break
            time.sleep(0.1)
        if window is None:
            fail("Timed out waiting for the Character Mover window")
        _focus_game_window(x)
        time.sleep(0.3)
        # The isolated display has no window manager, so the game window can
        # receive a spurious UNFOCUSED event right after launch, which the game
        # treats by releasing its mouse capture (the frame log shows LOCK true
        # then LOCK false). Re-engage gameplay mouse-look with a left-button tap:
        # this locks the mouse without the aim/reticle. Without it the game never
        # accumulates mouse deltas, so plain mouse-look does nothing.
        x.raise_window(window)
        x.set_button(1, True)
        time.sleep(0.05)
        x.set_button(1, False)
        time.sleep(0.2)
    finally:
        x.close()
    save_state(window_id=str(window))
    print(f"game running in isolated display {display}; window={window} pid={game.pid}")


def stop() -> None:
    game_pid = load_state().get("game_pid")
    server_pid = load_state().get("server_pid")
    if isinstance(game_pid, int):
        _terminate_pid(game_pid, "game")
    if isinstance(server_pid, int):
        _terminate_pid(server_pid, "display server")
    STATE_FILE.unlink(missing_ok=True)
    print("stopped")


def _terminate_pid(pid: int, label: str) -> None:
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline:
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return
        time.sleep(0.05)
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


# --------------------------------------------------------------------------- #
# Input commands (run against the isolated display).
# --------------------------------------------------------------------------- #
def connect() -> XServer:
    owned_game_pid()
    return XServer(_display(owned_display_num()))


def hold(key: str, duration: float) -> None:
    x = connect()
    try:
        _ensure_focus(x)
        x.set_key(key, True)
        try:
            time.sleep(duration)
        finally:
            x.set_key(key, False)
        time.sleep(0.15)
    finally:
        x.close()


def sequence(items: list[str]) -> None:
    if not items:
        fail("sequence requires one or more KEY:SECONDS items")
    parsed: list[tuple[str, float]] = []
    for item in items:
        try:
            key_text, duration_text = item.split(":", 1)
        except ValueError:
            fail(f"Invalid sequence item {item!r}; expected KEY:SECONDS")
        key = key_text.lower()
        if key not in ALLOWED_KEYS:
            fail(f"Unsupported key {key_text!r}; allowed: {', '.join(sorted(ALLOWED_KEYS))}")
        try:
            duration = float(duration_text)
        except ValueError:
            fail(f"Invalid duration {duration_text!r}")
        if not 0 < duration <= MAX_HOLD_SECONDS:
            fail(f"Duration must be in (0, {MAX_HOLD_SECONDS:g}]")
        parsed.append((key, duration))
    x = connect()
    try:
        _ensure_focus(x)
        for key, duration in parsed:
            x.set_key(key, True)
            try:
                time.sleep(duration)
            finally:
                x.set_key(key, False)
            time.sleep(0.1)
        time.sleep(0.25)
    finally:
        x.close()


def look(dx: int, dy: int) -> None:
    x = connect()
    try:
        _ensure_focus(x)
        x.move_mouse(dx, dy)
        time.sleep(0.25)
    finally:
        x.close()


def aimlook(dx: int, dy: int) -> None:
    """Hold the right mouse button (aim, disables camera auto-recenter), move,
    then release — so the rotation is visible instead of recentred."""
    x = connect()
    try:
        _ensure_focus(x)
        x.set_button(3, True)  # right = aim
        try:
            time.sleep(1.1)
            x.move_mouse(dx, dy)
            time.sleep(0.4)
        finally:
            x.set_button(3, False)
        time.sleep(0.2)
    finally:
        x.close()


def aimfire(duration: float) -> None:
    """Aim (right button), settle, then hold the fire button for `duration`."""
    x = connect()
    try:
        _ensure_focus(x)
        x.set_button(3, True)
        try:
            time.sleep(1.1)
            x.set_button(1, True)
            try:
                time.sleep(duration)
            finally:
                x.set_button(1, False)
        finally:
            x.set_button(3, False)
        time.sleep(0.2)
    finally:
        x.close()


def fire(duration: float) -> None:
    x = connect()
    try:
        _ensure_focus(x)
        x.set_button(1, True)
        try:
            time.sleep(duration)
        finally:
            x.set_button(1, False)
        time.sleep(0.2)
    finally:
        x.close()


def aimonly(seconds: float) -> None:
    x = connect()
    try:
        _ensure_focus(x)
        x.set_button(3, True)
        time.sleep(seconds)
        x.set_button(3, False)
        time.sleep(0.2)
    finally:
        x.close()


def quickturn() -> None:
    """Turn the character and camera 180 degrees via the in-game quick turn.

    Holding S arms a backward quick-turn intent; pressing Q then rotates both
    the character and the camera by 180 degrees.
    """
    x = connect()
    try:
        _ensure_focus(x)
        x.set_key("s", True)
        try:
            time.sleep(0.1)
            x.set_key("q", True)
            x.set_key("q", False)
            time.sleep(0.55)
        finally:
            x.set_key("s", False)
        time.sleep(0.2)
    finally:
        x.close()


def _game_has_focus(x: XServer, window: int) -> bool:
    try:
        return x.input_focus() == window
    except Exception:
        return False


def _focus_game_window(x: XServer) -> int:
    """Find the game window on the isolated display and give it input focus."""
    window = x.find_window(WINDOW_TITLE)
    if window is None:
        fail("Game window not found on the isolated display")
    for _ in range(20):
        x.raise_window(window)
        x.set_focus(window)
        if _game_has_focus(x, window):
            return window
        time.sleep(0.1)
    fail("Could not give the game window input focus")
    return window  # unreachable


def _ensure_focus(x: XServer) -> None:
    window = _focus_game_window(x)
    save_state(window_id=str(window))


def screenshot(path_text: str) -> None:
    owned_game_pid()
    path = Path(path_text).expanduser().resolve()
    allowed = path.is_relative_to(ROOT) or path.is_relative_to(Path("/tmp"))
    if not allowed:
        fail("Screenshots must be written inside the repository or /tmp")
    path.parent.mkdir(parents=True, exist_ok=True)
    display = _display(owned_display_num())
    subprocess.run(["import", "-display", display, "-window", read_window_id(), str(path)], check=True)
    print(path)


def root_screenshot(path_text: str) -> None:
    owned_game_pid()
    path = Path(path_text).expanduser().resolve()
    allowed = path.is_relative_to(ROOT) or path.is_relative_to(Path("/tmp"))
    if not allowed:
        fail("Screenshots must be written inside the repository or /tmp")
    path.parent.mkdir(parents=True, exist_ok=True)
    display = _display(owned_display_num())
    subprocess.run(["import", "-display", display, "-window", "root", str(path)], check=True)
    print(path)


def status() -> None:
    owned_game_pid()
    num = owned_display_num()
    print(f"game pid={load_state().get('game_pid')} window={read_window_id()} display=:{num}")


def check_deps() -> None:
    servers = {"Xephyr": "xorg-x11-server-Xephyr", "Xvfb": "xorg-x11-server-Xvfb"}
    for binary in list(servers) + ["zig", "wmctrl", "import", "xrandr", "xdpyinfo"]:
        if shutil.which(binary) is None:
            print(f"MISSING  {binary}")
        else:
            print(f"ok       {binary}")
    ctypes.CDLL("libX11.so.6")
    ctypes.CDLL("libXtst.so.6")
    print("ok       libX11/libXtst")


def usage() -> None:
    print(
        "usage:\n"
        "  tools/game-drive.py start [--server xephyr|xvfb]\n"
        "  tools/game-drive.py stop\n"
        "  tools/game-drive.py hold KEY SECONDS\n"
        "  tools/game-drive.py sequence KEY:SECONDS [...]\n"
        "  tools/game-drive.py look DX DY\n"
        "  tools/game-drive.py aimlook DX DY  (aim while turning; recenter stays off)\n"
        "  tools/game-drive.py aimfire SEC  (aim then fire)\n"
        "  tools/game-drive.py fire SEC\n"
        "  tools/game-drive.py aim SEC\n"
        "  tools/game-drive.py quickturn  (rotate character + camera 180deg)\n"
        "  tools/game-drive.py shot PATH   (screenshot the game window)\n"
        "  tools/game-drive.py shot-root PATH (screenshot the whole isolated display)\n"
        "  tools/game-drive.py status\n"
        "  tools/game-drive.py check\n\n"
        "env: INK_RIBBON_MONITOR (default eDP-1), INK_RIBBON_DISPLAY (default 1)",
        file=sys.stderr,
    )
    raise SystemExit(2)


def main() -> None:
    argv = sys.argv[1:]
    if not argv:
        usage()
    command, rest = argv[0], argv[1:]

    def _server() -> str:
        for arg in rest:
            if arg == "--server":
                idx = rest.index(arg)
                if idx + 1 < len(rest):
                    value = rest[idx + 1].lower()
                    if value not in ("xephyr", "xvfb"):
                        fail("--server must be 'xephyr' or 'xvfb'")
                    return value
        return "xephyr"

    if command == "start":
        start(_server())
    elif command == "stop":
        stop()
    elif command == "hold" and len(rest) == 2:
        hold(rest[0].lower(), float(rest[1]))
    elif command == "sequence":
        sequence(rest)
    elif command == "look" and len(rest) == 2:
        look(int(rest[0]), int(rest[1]))
    elif command == "aimlook" and len(rest) == 2:
        aimlook(int(rest[0]), int(rest[1]))
    elif command == "aimfire" and len(rest) == 1:
        aimfire(float(rest[0]))
    elif command == "fire" and len(rest) == 1:
        fire(float(rest[0]))
    elif command == "aim" and len(rest) == 1:
        aimonly(float(rest[0]))
    elif command == "quickturn":
        quickturn()
    elif command in ("shot", "shot-root") and len(rest) == 1:
        (screenshot if command == "shot" else root_screenshot)(rest[0])
    elif command == "status":
        status()
    elif command == "check":
        check_deps()
    else:
        usage()


if __name__ == "__main__":
    main()
