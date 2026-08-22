//! Data-oriented character mover scene.
//!
//! Plain state is kept separate from the systems that transform it. Box3D owns
//! collision geometry, Sokol owns rendering, and the character capsule belongs
//! to neither as a rigid body: it is moved explicitly by application code.

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("level.zig");
const controller = @import("character_controller.zig");
const hunter = @import("hunter.zig");
const navmesh = @import("navmesh.zig");
const saves = @import("saves.zig");
const camera = @import("third_person_camera.zig");
const shd = @import("generated/character_shader.zig");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const sshape = sokol.shape;
const sdtx = sokol.debugtext;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

// Physics advances in fixed 1/60 s ticks; the clock accumulates real frame
// time and releases ticks at that rate, so simulation speed is frame-rate
// independent. max_* bounds how much backlog a slow frame may process.
const fixed_dt: f64 = 1.0 / 60.0;
const max_frame_dt: f64 = 0.1;
const max_ticks_per_frame = 6;
const shadow_map_size = 2048;
// Half the character box's size along each axis (full size = 2x this).
const character_half_extents = Vec3{ .x = 0.32, .y = 0.9, .z = 0.22 };

// The hunter is a larger, red Tyrant-style box.
const hunter_half_extents = Vec3{ .x = 0.45, .y = 1.25, .z = 0.30 };
const hunter_color = Vec4{ .x = 0.92, .y = 0.12, .z = 0.14, .w = 1 };

// Capsule centre heights match each actor's capsule geometry, so they sit on
// the floor at the room-derived spawn points.
const player_spawn_y: f32 = 0.9;
const hunter_spawn_y: f32 = 1.5;

// How long a HUD notice (catch / save result) stays on screen.
const notice_seconds: f32 = 3;

// Transient centered HUD messages.
const HudNotice = enum { none, caught, saved, save_failed, deleted };

// Top-down map view tuning.
const map_pan_speed: f32 = 25.0; // metres/second the map pans with WASD
const map_pan_x_max: f32 = 40.0; // keep the pan center near the level
const map_pan_z_max: f32 = 30.0;
const map_route_capacity = navmesh.level_cols * navmesh.level_rows;
const map_route_width: f32 = 0.16;
const map_route_height: f32 = 0.04;
const map_route_danger_radius: f32 = 6.0;
const map_route_danger_penalty: f32 = 4.0;
const map_direction_color = rgb(0.741, 0.576, 0.976); // Dracula purple #BD93F9
const map_direction_instance_count = 3;

const Instance = extern struct {
    // One GPU instance record: 3 transform axes (xyz) + origin (w), then color.
    // Matches the vec4 attributes declared in character.glsl (inst_x/y/z/color).
    x: Vec4,
    y: Vec4,
    z: Vec4,
    color: Vec4,
};

const Clock = struct {
    accumulator: f64 = 0,

    // Add this frame's duration, clamped so a single slow frame can't flood
    // the physics backlog.
    fn addFrame(self: *Clock, frame_time: f64) void {
        self.accumulator += @min(frame_time, max_frame_dt);
    }

    // Pop one fixed tick whenever a full tick's worth of time has accrued.
    fn consumeTick(self: *Clock) bool {
        if (self.accumulator < fixed_dt) return false;
        self.accumulator -= fixed_dt;
        return true;
    }

    // Fraction of the way toward the next tick — used to interpolate the
    // character's render position between two physics states.
    fn alpha(self: Clock) f32 {
        return @floatCast(self.accumulator / fixed_dt);
    }
};

const InputState = struct {
    forward: bool = false,
    back: bool = false,
    left: bool = false,
    right: bool = false,
    run: bool = false,
    mouse_delta: math.Vec2 = .{},

    // Turn held keys into a movement intent. x is strafe (right-left),
    // y is forward-back (positive = toward where the camera looks).
    fn characterInput(self: *InputState) controller.Input {
        const move: controller.Vec2 = .{
            .x = @as(f32, @floatFromInt(@intFromBool(self.right))) - @as(f32, @floatFromInt(@intFromBool(self.left))),
            .y = @as(f32, @floatFromInt(@intFromBool(self.forward))) - @as(f32, @floatFromInt(@intFromBool(self.back))),
        };
        // Running is armed by Shift but only applies while a direction is held;
        // releasing the direction keys falls back to walking and disarms it.
        const running = self.run and (move.x != 0 or move.y != 0);
        if (!running) self.run = false;
        return .{
            .move = move,
            .run = running,
        };
    }
};

const DebugState = struct {
    draw_physics: bool = true,
};

const MapRouteStatus = enum { none, found, arrived, no_path };

// Typewriter save/load windows. While open they freeze the round exactly like
// map mode does; navigation is keyboard-only.
const MenuKind = enum { none, save, load };
const MenuState = struct {
    kind: MenuKind = .none,
    slot: usize = 0,
};

// Top-down map overlay state. The route is rebuilt from the current actor poses
// whenever the map opens, then remains fixed while the player is paused.
const MapState = struct {
    active: bool = false,
    hunter_paused: bool = true,
    pan: Vec3 = .{},
    route: [map_route_capacity]b3.b3Pos = undefined,
    route_instances: [map_route_capacity]Instance = undefined,
    route_start: b3.b3Pos = .{},
    route_len: usize = 0,
    route_segment_count: usize = 0,
    route_upload_pending: bool = false,
    route_status: MapRouteStatus = .none,
};

// Smooth 180-degree quick-turn (RE2R): the character and camera swing around
// over a short animation instead of snapping.
const QuickTurn = struct {
    active: bool = false,
    timer: f32 = 0,
    duration: f32 = 0.35,
    character_start: f32 = 0,
    character_target: f32 = 0,
    camera_start: f32 = 0,
    camera_target: f32 = 0,
};

const RenderState = struct {
    // Shared mesh geometry (all shapes built into one vertex/index buffer).
    vertex_buffer: sg.Buffer = .{},
    index_buffer: sg.Buffer = .{},
    // Per-instance transform buffers: static level, dynamic character, debug capsule.
    level_instances: sg.Buffer = .{},
    roof_instance: sg.Buffer = .{},
    character_instance: sg.Buffer = .{},
    map_direction_instances: sg.Buffer = .{},
    hunter_instance: sg.Buffer = .{},
    route_instances: sg.Buffer = .{},
    capsule_instances: sg.Buffer = .{},
    level_instance_count: usize = 0,
    roof_instance_count: usize = 0,
    display_pipeline: sg.Pipeline = .{},
    route_pipeline: sg.Pipeline = .{},
    map_actor_pipeline: sg.Pipeline = .{},
    debug_pipeline: sg.Pipeline = .{},
    shadow_pipeline: sg.Pipeline = .{},
    shadow_pass: sg.Pass = .{},
    shadow_view: sg.View = .{},
    shadow_sampler: sg.Sampler = .{},
    light_view_projection: Mat4 = Mat4.identity(),
    // Element ranges into the shared buffers for each shape type.
    box_range: sshape.ElementRange = .{},
    capsule_cylinder_range: sshape.ElementRange = .{},
    capsule_sphere_range: sshape.ElementRange = .{},
    pass_action: sg.PassAction = .{},
};

const GameState = struct {
    world: b3.b3WorldId = b3.b3_nullWorldId,
    clock: Clock = .{},
    input: InputState = .{},
    debug: DebugState = .{},
    map: MapState = .{},
    menu: MenuState = .{},
    character_config: controller.Config = .{},
    character: controller.State = initialCharacter(),
    hunter_config: hunter.Config = .{},
    hunter: hunter.State = initialHunter(),
    // Current transient HUD message and its remaining seconds.
    notice: HudNotice = .none,
    notice_timer: f32 = 0,
    quick_turn: QuickTurn = .{},
    mover_scratch: controller.MoverScratch = .{},
    camera_config: camera.Config = .{},
    camera: camera.State = .{},
    render: RenderState = .{},
};

var game: GameState = .{};

fn initialCharacter() controller.State {
    var character = controller.State.init(.{ .x = 0, .y = 0.9, .z = 17 });
    // The initial camera looks toward -Z, so the character must face -Z too for
    // the shoulder camera to begin behind it rather than in front of it.
    character.yaw = std.math.pi;
    return character;
}

fn initialHunter() hunter.State {
    return hunter.State.init(.{ .x = 0, .y = 1.5, .z = -17 });
}

fn init() callconv(.c) void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
    sdtx.setup(.{
        .fonts = init: {
            var fonts: [8]sdtx.FontDesc = @splat(.{});
            fonts[0] = sdtx.fontKc853();
            break :init fonts;
        },
        .logger = .{ .func = slog.func },
    });
    seedSpawnRandomness();
    saves.loadFromCwd(app_io.io());
    loadValidatedLevel();
    initPhysics();
    initRenderer();
    spawnPlayerAndHunter();
    sapp.lockMouse(true);
}

// Advance the quick-turn swing. Runs each physics tick after the controller
// has had its say, so the animated yaw wins while it is active.
fn updateQuickTurn(dt: f32) void {
    if (!game.quick_turn.active) return;
    game.quick_turn.timer += dt;
    const t = std.math.clamp(game.quick_turn.timer / game.quick_turn.duration, 0, 1);
    // Smoothstep: accelerate into the turn, then ease to a stop.
    const eased = t * t * (3.0 - 2.0 * t);
    game.character.yaw = game.quick_turn.character_start + (game.quick_turn.character_target - game.quick_turn.character_start) * eased;
    game.camera.yaw = game.quick_turn.camera_start + (game.quick_turn.camera_target - game.quick_turn.camera_start) * eased;
    if (t >= 1) game.quick_turn.active = false;
}

fn frame() callconv(.c) void {
    const frame_time: f32 = @floatCast(@min(sapp.frameDuration(), max_frame_dt));
    game.clock.addFrame(frame_time);
    if (game.notice_timer > 0) {
        game.notice_timer = @max(0, game.notice_timer - frame_time);
        if (game.notice_timer == 0) game.notice = .none;
    }

    // Menus freeze the round exactly like map mode does.
    const gameplay_active = !game.map.active and game.menu.kind == .none;

    const render_position = blk: {
        var ticks: usize = 0;
        while (ticks < max_ticks_per_frame and game.clock.consumeTick()) : (ticks += 1) {
            // Map/menu modes always freeze the player. On the map the hunter
            // is independently paused by default and can be resumed with P.
            if (gameplay_active) {
                controller.update(
                    game.character_config,
                    &game.character,
                    &game.mover_scratch,
                    game.world,
                    game.input.characterInput(),
                    game.camera.basis,
                    @floatCast(fixed_dt),
                );
                updateQuickTurn(@floatCast(fixed_dt));
            }
            if (game.menu.kind == .none and (!game.map.active or !game.map.hunter_paused)) {
                hunter.update(
                    game.hunter_config,
                    &game.hunter,
                    &game.mover_scratch,
                    game.world,
                    game.character.position,
                    @floatCast(fixed_dt),
                );
                if (hunterContacted()) {
                    respawnAfterCatch();
                    break;
                }
            }
        }
        // Discard excess backlog after the bounded catch-up budget.
        if (ticks == max_ticks_per_frame and game.clock.accumulator >= fixed_dt) {
            game.clock.accumulator = @mod(game.clock.accumulator, fixed_dt);
        }
        // The clock keeps consuming ticks while the map or a menu is open so
        // no backlog accumulates. Render the exact paused pose instead of
        // using its cycling interpolation alpha, which would replay the last
        // movement every tick.
        break :blk if (gameplay_active)
            controller.interpolatedPosition(game.character, game.clock.alpha())
        else
            game.character.position;
    };

    if (game.map.active) {
        // WASD pans the map camera around the level.
        const pan_speed = map_pan_speed * frame_time;
        game.map.pan.x += (fbool(game.input.right) - fbool(game.input.left)) * pan_speed;
        game.map.pan.z += (fbool(game.input.back) - fbool(game.input.forward)) * pan_speed;
        game.map.pan.x = std.math.clamp(game.map.pan.x, -map_pan_x_max, map_pan_x_max);
        game.map.pan.z = std.math.clamp(game.map.pan.z, -map_pan_z_max, map_pan_z_max);
        game.camera.view_projection = mapViewProjection();
    } else if (game.menu.kind == .none) {
        camera.update(
            game.camera_config,
            &game.camera,
            render_position,
            game.input.mouse_delta,
            game.world,
            frame_time,
            sapp.widthf() / @max(sapp.heightf(), 1),
        );
        game.input.mouse_delta = .{};
    }
    uploadMapRoute();
    draw(render_position);
}

fn cleanup() callconv(.c) void {
    b3.b3DestroyWorld(game.world);
    game.world = b3.b3_nullWorldId;
    sdtx.shutdown();
    sg.shutdown();
}

fn event(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const value = event_ptr[0];
    switch (value.type) {
        .KEY_DOWN, .KEY_UP => {
            const down = value.type == .KEY_DOWN;
            switch (value.key_code) {
                .W => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(-1);
                } else {
                    game.input.forward = down;
                },
                .S => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(1);
                } else {
                    game.input.back = down;
                },
                .A => game.input.left = down,
                .D => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) deleteSelectedSlot();
                } else {
                    game.input.right = down;
                },
                .LEFT_SHIFT, .RIGHT_SHIFT => if (down and !value.key_repeat) {
                    // Arm running. It only takes effect while a direction is
                    // held and is never toggled off by Shift again.
                    game.input.run = true;
                },
                .F1 => if (down and !value.key_repeat) {
                    game.debug.draw_physics = !game.debug.draw_physics;
                },
                .M => if (down and !value.key_repeat and game.menu.kind == .none) {
                    game.map.active = !game.map.active;
                    if (game.map.active) {
                        game.map.hunter_paused = true;
                        rebuildMapRoute();
                    }
                    // Drop held keys so the map doesn't immediately pan and
                    // gameplay doesn't resume with the character moving.
                    game.input = .{};
                },
                .P => if (down and !value.key_repeat and game.map.active) {
                    game.map.hunter_paused = !game.map.hunter_paused;
                },
                .UP => if (down and !value.key_repeat and game.menu.kind != .none) {
                    moveMenuSlot(-1);
                },
                .DOWN => if (down and !value.key_repeat and game.menu.kind != .none) {
                    moveMenuSlot(1);
                },
                .SPACE => if (down and !value.key_repeat) {
                    if (game.menu.kind != .none) {
                        confirmMenu();
                    } else if (!game.map.active and nearSaveFixture()) {
                        openMenu(.save);
                    }
                },
                .L => if (down and !value.key_repeat) {
                    if (game.menu.kind == .none and !game.map.active) openMenu(.load);
                },
                .ENTER => if (down and !value.key_repeat and game.menu.kind != .none) {
                    confirmMenu();
                },
                .E => if (down and !value.key_repeat) {
                    // RE2R quick-turn: while walking backward, swing the
                    // character and camera 180 degrees over a short animation.
                    if (game.input.back and !game.quick_turn.active) {
                        game.quick_turn = .{
                            .active = true,
                            .character_start = game.character.yaw,
                            .character_target = game.character.yaw + std.math.pi,
                            .camera_start = game.camera.yaw,
                            .camera_target = game.camera.yaw + std.math.pi,
                        };
                    }
                },
                .ESCAPE => if (down) {
                    if (game.menu.kind != .none) {
                        closeMenu();
                    } else {
                        sapp.lockMouse(false);
                    }
                },
                else => {},
            }
        },
        .MOUSE_DOWN => sapp.lockMouse(true),
        .MOUSE_MOVE => if (sapp.mouseLocked()) {
            game.input.mouse_delta.x += value.mouse_dx;
            game.input.mouse_delta.y += value.mouse_dy;
        },
        .UNFOCUSED => {
            game.input = .{};
            sapp.lockMouse(false);
        },
        else => {},
    }
}

fn initPhysics() void {
    // Give every visible, collidable level box and stair step a Box3D body so
    // the character and camera can collide against them.
    var world_def = b3.b3DefaultWorldDef();
    game.world = b3.b3CreateWorld(&world_def);
    for (level.current.boxSlice()) |box| if (box.collidable) addStaticBox(box);
}

fn addStaticBox(box: level.Box) void {
    var body_def = b3.b3DefaultBodyDef();
    body_def.position = .{ .x = box.center.x, .y = box.center.y, .z = box.center.z };
    // Build the X-axis quaternion locally. The generated Zig wrapper for
    // b3MakeQuatFromAxisAngle references Box3D's non-exported assert helper.
    const half_pitch = box.pitch * 0.5;
    body_def.rotation = .{ .v = .{ .x = @sin(half_pitch) }, .s = @cos(half_pitch) };
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    if (box.hunter_block) {
        // Save-room barrier: only the hunter's capsule collides with it.
        shape_def.filter.categoryBits = controller.hunter_block_category;
        shape_def.filter.maskBits = controller.hunter_query_category;
    } else {
        // The character and camera query these boxes; other objects ignore them.
        shape_def.filter.categoryBits = controller.level_category;
        shape_def.filter.maskBits = controller.player_query_category | camera.camera_query_category | controller.hunter_query_category;
    }
    var hull = b3.b3MakeBoxHull(box.half_extents.x, box.half_extents.y, box.half_extents.z);
    _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
}

// Mix ASLR-derived addresses into the PRNG seed: both a stack local and the
// global game state live at different addresses in each process. The level is
// hand-authored, so only the hunter's patrol randomness derives from this.
fn seedSpawnRandomness() void {
    var stack_marker: u32 = 0;
    const entropy = @as(u64, @bitCast(@intFromPtr(&stack_marker))) ^ @as(u64, @bitCast(@intFromPtr(&game)));
    hunter.seedRandom(@truncate(entropy));
}

fn loadValidatedLevel() void {
    level.load();
    navmesh.buildLevel();
    if (!navmesh.validateLevel()) @panic("authored level failed navmesh validation");
}

// Index of the most recently written occupied save slot, if any.
fn latestSaveIndex() ?usize {
    var best_index: ?usize = null;
    var best_timestamp: i64 = std.math.minInt(i64);
    for (saves.slots, 0..) |slot, index| {
        if (slot.occupied and slot.timestamp > best_timestamp) {
            best_timestamp = slot.timestamp;
            best_index = index;
        }
    }
    return best_index;
}

// Teleport the player onto a recorded pose. The static world never changes,
// so a saved position is always a valid capsule spot.
fn placePlayerFromSlot(slot: saves.Slot) void {
    game.character.previous_position = .{ .x = slot.x, .y = slot.y, .z = slot.z };
    game.character.position = .{ .x = slot.x, .y = slot.y, .z = slot.z };
    game.character.velocity = .{};
    game.character.grounded = false;
    game.character.yaw = slot.yaw;
    // Re-seat the shoulder camera behind the restored heading.
    game.camera = .{};
    game.camera.yaw = slot.yaw;
    game.quick_turn = .{};
}

// Place both actors, then reset the round. The player resumes from the most
// recent save when one exists; otherwise they start at the level's spawn.
fn spawnPlayerAndHunter() void {
    if (latestSaveIndex()) |index| {
        placePlayerFromSlot(saves.slots[index]);
    } else {
        const player_spawn = b3.b3Pos{ .x = level.current.player_spawn.x, .y = player_spawn_y, .z = level.current.player_spawn.z };
        game.character = controller.State.init(player_spawn);
        // face -Z, matching the initial camera
        game.character.yaw = std.math.pi;
        game.camera = .{};
        game.quick_turn = .{};
    }
    resetHunter(game.character.position);
    game.clock = .{};
    game.map = .{};
    game.menu = .{};
    game.notice = .none;
    game.notice_timer = 0;
    game.input = .{};
}

// Send the hunter back to his authored spawn room facing the player, with a
// fresh patrol destination so he sets off walking immediately.
fn resetHunter(player_pos: b3.b3Pos) void {
    const hunter_spawn = b3.b3Pos{ .x = level.current.hunter_spawn.x, .y = hunter_spawn_y, .z = level.current.hunter_spawn.z };
    game.hunter = hunter.State.init(hunter_spawn);
    game.hunter.yaw = std.math.atan2(player_pos.x - hunter_spawn.x, player_pos.z - hunter_spawn.z);
    game.hunter.target = hunter.randomPatrolTarget(game.hunter_config, game.hunter.position);
    game.hunter.repath_timer = 0;
}

// The hunter catches the player when their capsules touch horizontally.
fn hunterContacted() bool {
    const dx = game.hunter.position.x - game.character.position.x;
    const dz = game.hunter.position.z - game.character.position.z;
    const radius = game.hunter_config.contact_radius;
    return dx * dx + dz * dz < radius * radius;
}

// Caught: the player is sent back to their most recent save slot (or the
// level start when nothing has been saved yet), and the hunter returns to his
// own spawn room so the chase restarts fair.
fn respawnAfterCatch() void {
    if (latestSaveIndex()) |index| {
        placePlayerFromSlot(saves.slots[index]);
    } else {
        const player_spawn = b3.b3Pos{ .x = level.current.player_spawn.x, .y = player_spawn_y, .z = level.current.player_spawn.z };
        game.character = controller.State.init(player_spawn);
        game.character.yaw = std.math.pi;
        game.camera = .{};
        game.quick_turn = .{};
    }

    resetHunter(game.character.position);
    game.notice = .caught;
    game.notice_timer = notice_seconds;
    game.input = .{};
}

// True while the character stands within 1 m of the pink typewriter table.
fn nearSaveFixture() bool {
    const fixture = level.current.save_fixture;
    const dx = game.character.position.x - fixture.x;
    const dz = game.character.position.z - fixture.z;
    return dx * dx + dz * dz <= 1.0;
}

fn openMenu(kind: MenuKind) void {
    game.menu = .{ .kind = kind, .slot = 0 };
    // Drop held keys so gameplay doesn't resume with the character moving.
    game.input = .{};
}

fn closeMenu() void {
    game.menu.kind = .none;
    game.input = .{};
}

fn moveMenuSlot(delta: i32) void {
    const count: i32 = saves.slot_count;
    const current: i32 = @intCast(game.menu.slot);
    game.menu.slot = @intCast(@mod(current + delta + count, count));
}

// Clear the selected slot (when it holds a save) and persist the change.
fn deleteSelectedSlot() void {
    if (!saves.slots[game.menu.slot].occupied) return;
    saves.slots[game.menu.slot] = .{};
    if (saves.writeToCwd(app_io.io())) |_| {
        game.notice = .deleted;
        game.notice_timer = notice_seconds;
    } else |_| {
        // The slot is cleared in memory either way, but flag the disk trouble.
        game.notice = .save_failed;
        game.notice_timer = notice_seconds;
    }
}

// Apply the highlighted slot: write the player's pose into it (save) or
// teleport the player to it (load), then close the window.
fn confirmMenu() void {
    switch (game.menu.kind) {
        .none => return,
        .save => {
            saves.slots[game.menu.slot] = .{
                .occupied = true,
                .x = game.character.position.x,
                .y = game.character.position.y,
                .z = game.character.position.z,
                .yaw = game.character.yaw,
                .timestamp = std.Io.Timestamp.now(app_io.io(), .real).toSeconds(),
            };
            if (saves.writeToCwd(app_io.io())) |_| {
                game.notice = .saved;
                game.notice_timer = notice_seconds;
            } else |_| {
                game.notice = .save_failed;
                game.notice_timer = notice_seconds;
            }
        },
        .load => {
            const slot = saves.slots[game.menu.slot];
            if (slot.occupied) {
                placePlayerFromSlot(slot);
            }
        },
    }
    closeMenu();
}

fn rebuildMapRoute() void {
    game.map.route_len = 0;
    game.map.route_segment_count = 0;
    game.map.route_upload_pending = true;
    if (level.current.isInSaveRoom(game.character.position.x, game.character.position.z)) {
        game.map.route_status = .arrived;
        return;
    }

    const target = level.current.save_room_target;
    const influence = navmesh.HunterInfluence{
        .x = game.hunter.position.x,
        .z = game.hunter.position.z,
        .hard_radius = game.hunter_config.contact_radius,
        .danger_radius = map_route_danger_radius,
        .danger_penalty = map_route_danger_penalty,
    };
    const route_start_cell = navmesh.player_nav.nearestWalkableWithInfluence(
        game.character.position.x,
        game.character.position.z,
        influence,
    ) orelse {
        game.map.route_status = .no_path;
        return;
    };
    const player_cell = navmesh.player_nav.cellAt(game.character.position.x, game.character.position.z);
    game.map.route_start = if (player_cell != null and player_cell.? == route_start_cell)
        game.character.position
    else
        navmesh.player_nav.worldAt(route_start_cell);
    game.map.route_len = navmesh.player_nav.findPathWithInfluence(
        game.character.position.x,
        game.character.position.z,
        target.x,
        target.z,
        game.map.route[0..],
        influence,
    );
    if (game.map.route_len == 0) {
        game.map.route_status = .no_path;
        return;
    }

    var from = game.map.route_start;
    for (game.map.route[0..game.map.route_len]) |waypoint| {
        const dx = waypoint.x - from.x;
        const dz = waypoint.z - from.z;
        const segment_length = @sqrt(dx * dx + dz * dz);
        if (segment_length > 0.0001) {
            game.map.route_instances[game.map.route_segment_count] = makeScaledInstance(
                .{
                    .x = (from.x + waypoint.x) * 0.5,
                    .y = level.floor_height + 0.1,
                    .z = (from.z + waypoint.z) * 0.5,
                },
                .{ .x = map_route_width, .y = map_route_height, .z = segment_length },
                std.math.atan2(dx, dz),
                rgb(0.3137255, 0.9803922, 0.4823529),
            );
            game.map.route_segment_count += 1;
        }
        from = waypoint;
    }
    game.map.route_status = .found;
}

fn uploadMapRoute() void {
    if (!game.map.route_upload_pending) return;
    if (game.map.active and game.map.route_segment_count > 0) {
        sg.updateBuffer(
            game.render.route_instances,
            sg.asRange(game.map.route_instances[0..game.map.route_segment_count]),
        );
    }
    game.map.route_upload_pending = false;
}

fn uploadLevelInstances() void {
    var level_instances: [level.max_boxes]Instance = undefined;
    var roof_instances: [level.max_boxes]Instance = undefined;
    var level_count: usize = 0;
    var roof_count: usize = 0;
    for (level.current.boxSlice()) |box| {
        if (!box.visible) continue;
        const instance = makePitchedInstance(box.center, box.half_extents, box.pitch, box.color);
        if (box.is_roof) {
            roof_instances[roof_count] = instance;
            roof_count += 1;
        } else {
            level_instances[level_count] = instance;
            level_count += 1;
        }
    }
    if (level_count > 0) sg.updateBuffer(game.render.level_instances, sg.asRange(level_instances[0..level_count]));
    if (roof_count > 0) sg.updateBuffer(game.render.roof_instance, sg.asRange(roof_instances[0..roof_count]));
    game.render.level_instance_count = level_count;
    game.render.roof_instance_count = roof_count;
}

fn initRenderer() void {
    var vertices: [sshape.max_vertex_size * 4096]u8 = undefined;
    var indices: [4096]u16 = undefined;
    var builder: sshape.State = .{
        .vertices = .{ .buffer = sshape.asRange(&vertices) },
        .indices = .{ .buffer = sshape.asRange(&indices) },
        .disable = .{ .texcoords = true, .colors = true },
    };
    // Build all meshes into one shared vertex/index buffer, one shape at a
    // time. Each shape's element range records where it lives in the buffer.
    sshape.buildBox(&builder, .{ .width = 1, .height = 1, .depth = 1 });
    game.render.box_range = sshape.elementRange(builder);
    sshape.buildCylinder(&builder, .{ .radius = 1, .height = 1, .slices = 16, .stacks = 1 });
    game.render.capsule_cylinder_range = sshape.elementRange(builder);
    sshape.buildSphere(&builder, .{ .radius = 1, .slices = 16, .stacks = 8 });
    game.render.capsule_sphere_range = sshape.elementRange(builder);
    game.render.vertex_buffer = sg.makeBuffer(sshape.vertexBufferDesc(builder));
    game.render.index_buffer = sg.makeBuffer(sshape.indexBufferDesc(builder));

    // Runtime-sized instance counts are uploaded into capacity buffers whenever
    // the level is (re)loaded. The roof remains separate for map mode.
    game.render.level_instances = sg.makeBuffer(.{
        .size = level.max_boxes * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-level-instances",
    });
    game.render.roof_instance = sg.makeBuffer(.{
        .size = level.max_boxes * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-roof-instance",
    });
    uploadLevelInstances();
    // The character's instance is uploaded fresh every frame (stream_update).
    game.render.character_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-dynamic-instance",
    });
    game.render.map_direction_instances = sg.makeBuffer(.{
        .size = map_direction_instance_count * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-direction-instances",
    });
    // The hunter is a second dynamic single-instance buffer, drawn in red.
    game.render.hunter_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-hunter-instance",
    });
    game.render.route_instances = sg.makeBuffer(.{
        .size = map_route_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-route-instances",
    });
    game.render.capsule_instances = sg.makeBuffer(.{
        .size = 3 * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-capsule-debug-instances",
    });

    var layout: sg.VertexLayoutState = .{};
    // Buffer 0 = shared mesh (positions + normals), buffer 1 = per-instance
    // transform records (one per copy of the mesh, stepped PER_INSTANCE).
    layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    layout.attrs[shd.ATTR_display_position] = sshape.positionVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_normal] = sshape.normalVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_inst_x] = instanceAttr(0);
    layout.attrs[shd.ATTR_display_inst_y] = instanceAttr(16);
    layout.attrs[shd.ATTR_display_inst_z] = instanceAttr(32);
    layout.attrs[shd.ATTR_display_inst_color] = instanceAttr(48);
    game.render.display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-scene-pipeline",
    });

    var route_layout: sg.VertexLayoutState = .{};
    route_layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    route_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    route_layout.attrs[shd.ATTR_route_position] = sshape.positionVertexAttrState(builder);
    route_layout.attrs[shd.ATTR_route_inst_x] = instanceAttr(0);
    route_layout.attrs[shd.ATTR_route_inst_y] = instanceAttr(16);
    route_layout.attrs[shd.ATTR_route_inst_z] = instanceAttr(32);
    route_layout.attrs[shd.ATTR_route_inst_color] = instanceAttr(48);
    const route_shader = sg.makeShader(shd.routeShaderDesc(sg.queryBackend()));
    game.render.route_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = false, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-map-route-pipeline",
    });
    game.render.map_actor_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-map-actor-pipeline",
    });

    game.render.debug_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = layout,
        .depth = .{ .write_enabled = false, .compare = .LESS_EQUAL },
        .colors = blendingTargets(),
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-capsule-debug-pipeline",
    });

    // Depth-only 2048x2048 texture seen from the sun. Only depth is written,
    // so the shadow pixel format is DEPTH (no color).
    const shadow_image = sg.makeImage(.{
        .usage = .{ .depth_stencil_attachment = true },
        .width = shadow_map_size,
        .height = shadow_map_size,
        .pixel_format = .DEPTH,
        .sample_count = 1,
        .label = "character-shadow-map",
    });
    game.render.shadow_view = sg.makeView(.{ .texture = .{ .image = shadow_image } });
    game.render.shadow_sampler = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
        .compare = .LESS,
    });
    game.render.shadow_pass = .{
        .action = .{ .depth = .{ .load_action = .CLEAR, .store_action = .STORE, .clear_value = 1 } },
        .attachments = .{ .depth_stencil = sg.makeView(.{ .depth_stencil_attachment = .{ .image = shadow_image } }) },
        .label = "character-shadow-pass",
    };

    var shadow_layout: sg.VertexLayoutState = .{};
    shadow_layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    shadow_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    shadow_layout.attrs[shd.ATTR_shadow_position] = sshape.positionVertexAttrState(builder);
    shadow_layout.attrs[shd.ATTR_shadow_inst_x] = instanceAttr(0);
    shadow_layout.attrs[shd.ATTR_shadow_inst_y] = instanceAttr(16);
    shadow_layout.attrs[shd.ATTR_shadow_inst_z] = instanceAttr(32);
    game.render.shadow_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.shadowShaderDesc(sg.queryBackend())),
        .layout = shadow_layout,
        .depth = .{ .pixel_format = .DEPTH, .write_enabled = true, .compare = .LESS_EQUAL },
        .colors = noColorTargets(),
        .sample_count = 1,
        .index_type = .UINT16,
        .cull_mode = .FRONT,
        .label = "character-shadow-pipeline",
    });

    const light_position = Vec3{ .x = 20, .y = 32, .z = -24 };
    // Directional light = orthographic projection centered on the world origin.
    const light_view = Mat4.lookAtRh(light_position, .{}, .{ .y = 1 });
    const light_projection = Mat4.orthoOffCenterRh(-38, 38, -38, 38, 1, 100);
    game.render.light_view_projection = Mat4.mul(light_view, light_projection);
    game.render.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.045, .b = 0.055, .a = 1 } };
}

fn draw(position: b3.b3Pos) void {
    // Rebuild the character's instance record from its interpolated position.
    const instance = makeInstance(
        .{ .x = position.x, .y = position.y, .z = position.z },
        character_half_extents,
        game.character.yaw,
        rgb(0.20, 0.694, 1.0), // Oxocarbon blue: #33B1FF
    );
    sg.updateBuffer(game.render.character_instance, sg.asRange(&instance));
    const direction_instances = makeMapDirectionInstances(position, game.character.yaw);
    sg.updateBuffer(game.render.map_direction_instances, sg.asRange(&direction_instances));
    if (game.debug.draw_physics) updateCapsuleInstances(position);

    // Interpolate during gameplay, but use the authoritative pose while paused
    // so the clock's cycling alpha cannot replay the hunter's last movement.
    const hunter_render = if ((game.map.active and game.map.hunter_paused) or game.menu.kind != .none)
        game.hunter.position
    else
        hunter.interpolatedPosition(game.hunter, game.clock.alpha());
    const hunter_instance = makeInstance(
        .{ .x = hunter_render.x, .y = hunter_render.y, .z = hunter_render.z },
        hunter_half_extents,
        game.hunter.yaw,
        hunter_color,
    );
    sg.updateBuffer(game.render.hunter_instance, sg.asRange(&hunter_instance));

    // Pass 1: render everything from the sun's viewpoint, depth-only, to the
    // shadow map. The character draws as a second single-instance call. The
    // roof is skipped in map mode so the interior is lit from above.
    const shadow_params: shd.ShadowVsParams = .{ .light_view_projection = game.render.light_view_projection };
    sg.beginPass(game.render.shadow_pass);
    sg.applyPipeline(game.render.shadow_pipeline);
    sg.applyUniforms(shd.UB_shadow_vs_params, sg.asRange(&shadow_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, game.render.level_instance_count, false);
    drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
    drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    if (!game.map.active) {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, false);
    }
    sg.endPass();

    // Pass 2: render the same instances to the window with full lighting, and
    // sample the shadow map to darken surfaces the sun can't see.
    const vs_params: shd.DisplayVsParams = .{
        .view_projection = game.camera.view_projection,
        .light_view_projection = game.render.light_view_projection,
    };
    const fs_params: shd.DisplayFsParams = .{
        .light_direction = Vec3.normalized(.{ .x = 20, .y = 32, .z = -24 }),
        .eye_position = game.camera.eye,
        // Fixture positions and radii are derived from authored room bounds.
        .indoor_light_0 = level.current.lights[0],
        .indoor_light_1 = level.current.lights[1],
        .indoor_light_2 = level.current.lights[2],
        .indoor_light_3 = level.current.lights[3],
        .indoor_light_4 = level.current.lights[4],
        .indoor_light_5 = level.current.lights[5],
        .indoor_light_6 = level.current.lights[6],
        .indoor_light_7 = level.current.lights[7],
    };

    sg.beginPass(.{ .action = game.render.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(game.render.display_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, game.render.level_instance_count, true);
    if (game.map.active) {
        const route_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        if (game.map.route_segment_count > 0) {
            drawInstances(game.render.route_instances, game.render.box_range, 0, game.map.route_segment_count, false);
        }
        drawInstances(game.render.map_direction_instances, game.render.box_range, 0, map_direction_instance_count, false);

        // Map actors use flat instance colors while still writing depth.
        sg.applyPipeline(game.render.map_actor_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
        drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    } else {
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, true);
        drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, true);
    }
    if (!game.map.active) {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, true);
    }
    sg.applyPipeline(game.render.debug_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    if (game.debug.draw_physics and !game.map.active) {
        drawInstances(game.render.capsule_instances, game.render.capsule_cylinder_range, 0, 1, true);
        drawInstances(game.render.capsule_instances, game.render.capsule_sphere_range, @sizeOf(Instance), 2, true);
    }
    drawHud(position);
    sg.endPass();
    sg.commit();
}

fn updateCapsuleInstances(position: b3.b3Pos) void {
    const radius = game.character_config.capsule_radius;
    const half_segment = game.character_config.capsule_half_segment;
    const color = Vec4{ .x = 0.25, .y = 1.0, .z = 0.55, .w = 0.32 };
    const instances = [_]Instance{
        makeScaledInstance(
            .{ .x = position.x, .y = position.y, .z = position.z },
            .{ .x = radius, .y = 2 * half_segment, .z = radius },
            0,
            color,
        ),
        makeScaledInstance(
            .{ .x = position.x, .y = position.y - half_segment, .z = position.z },
            .{ .x = radius, .y = radius, .z = radius },
            0,
            color,
        ),
        makeScaledInstance(
            .{ .x = position.x, .y = position.y + half_segment, .z = position.z },
            .{ .x = radius, .y = radius, .z = radius },
            0,
            color,
        ),
    };
    sg.updateBuffer(game.render.capsule_instances, sg.asRange(&instances));
}

fn drawHud(position: b3.b3Pos) void {
    const frame_duration = sapp.frameDuration();
    const fps = if (frame_duration > 0) 1.0 / frame_duration else 0;
    const text_width = 11.0; // "FPS: " plus a six-character numeric field.
    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(@max(1.0, sapp.widthf() / 8.0 - text_width - 1.0), 1.0);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:>6.1}", .{fps});
    if (game.map.active) {
        sdtx.pos(1.0, 1.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print("MAP (WASD pans, P toggles hunter, M exits)", .{});
        sdtx.pos(1.0, 2.2);
        sdtx.print("HUNTER: {s}", .{if (game.map.hunter_paused) "PAUSED" else "MOVING"});
        switch (game.map.route_status) {
            .arrived => {
                sdtx.pos(1.0, 3.4);
                sdtx.color3b(80, 250, 123);
                sdtx.print("SAVE ROOM REACHED", .{});
            },
            .no_path => {
                sdtx.pos(1.0, 3.4);
                sdtx.color3b(255, 85, 85);
                sdtx.print("NO SAFE ROUTE", .{});
            },
            else => {},
        }
    } else if (game.debug.draw_physics) {
        sdtx.pos(1.0, 1.0);
        sdtx.print("POS {d:.1} {d:.1} {d:.1}", .{ position.x, position.y, position.z });
    }
    switch (game.notice) {
        .caught => drawNotice("CAUGHT - RETURNED TO LAST SAVE", 255, 60, 60),
        .saved => drawNotice("GAME SAVED", 80, 250, 123),
        .deleted => drawNotice("SAVE DELETED", 255, 220, 120),
        .save_failed => drawNotice("SAVE FAILED", 255, 60, 60),
        .none => {},
    }
    if (game.menu.kind != .none) {
        drawSaveMenu();
    } else if (!game.map.active and nearSaveFixture()) {
        const prompt = "PRESS SPACE TO SAVE";
        sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(prompt.len)) / 2.0, sapp.heightf() / 8.0 - 2.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print(prompt, .{});
    }
    sdtx.draw();
}

// Centered transient HUD message on its own row near the top of the screen.
fn drawNotice(text: []const u8, r: u8, g: u8, b: u8) void {
    sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(text.len)) / 2.0, 2.0);
    sdtx.color3b(r, g, b);
    sdtx.print("{s}", .{text});
}

// Centered RE2R-style slot list: eight numbered lines, cursor on the selected
// one, EMPTY or a date stamp per row.
fn drawSaveMenu() void {
    const text_w = sapp.widthf() / 8.0;
    const text_h = sapp.heightf() / 8.0;
    const title = if (game.menu.kind == .save) "SAVE GAME" else "LOAD GAME";
    var line_buffer: [64]u8 = undefined;

    sdtx.pos(text_w / 2.0 - 10.0, text_h / 2.0 - 6.0);
    sdtx.color3b(255, 220, 120);
    sdtx.print("{s}", .{title});
    for (saves.slots, 0..) |slot, index| {
        sdtx.pos(text_w / 2.0 - 12.0, text_h / 2.0 - 4.0 + @as(f32, @floatFromInt(index)));
        if (index == game.menu.slot) {
            sdtx.color3b(80, 250, 123);
            sdtx.print("> ", .{});
        } else {
            sdtx.color3b(255, 255, 255);
            sdtx.print("  ", .{});
        }
        if (slot.occupied) {
            sdtx.print("SLOT {d}   {s}", .{ index + 1, formatTimestamp(&line_buffer, slot.timestamp) });
        } else {
            sdtx.print("SLOT {d}   EMPTY", .{index + 1});
        }
    }
    const footer = "W/S SELECT   SPACE CONFIRM   D DELETE   ESC CANCEL";
    sdtx.pos(text_w / 2.0 - @as(f32, @floatFromInt(footer.len)) / 2.0, text_h / 2.0 + 5.0);
    sdtx.color3b(160, 160, 160);
    sdtx.print(footer, .{});
}

// "YYYY-MM-DD HH:MM" in local wall-clock-free UTC from epoch seconds.
fn formatTimestamp(buffer: []u8, timestamp: i64) []const u8 {
    const epoch: std.time.epoch.EpochSeconds = .{ .secs = @intCast(@max(timestamp, 0)) };
    const day = epoch.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch.getDaySeconds();
    return std.fmt.bufPrint(buffer, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
    }) catch "";
}

// Draw `count` instances of one mesh from the shared buffers. The debug
// capsule uses 3 records: cylinder + two spheres, offset through the buffer.
fn drawInstances(
    instance_buffer: sg.Buffer,
    range: sshape.ElementRange,
    instance_offset: usize,
    count: usize,
    with_shadow_texture: bool,
) void {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = game.render.vertex_buffer;
    bindings.vertex_buffers[1] = instance_buffer;
    bindings.vertex_buffer_offsets[1] = @intCast(instance_offset);
    bindings.index_buffer = game.render.index_buffer;
    if (with_shadow_texture) {
        bindings.views[shd.VIEW_shadow_map] = game.render.shadow_view;
        bindings.samplers[shd.SMP_shadow_sampler] = game.render.shadow_sampler;
    }
    sg.applyBindings(bindings);
    sg.draw(
        @intCast(range.base_element),
        @intCast(range.num_elements),
        @intCast(count),
    );
}

fn noColorTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].pixel_format = .NONE;
    return colors;
}

fn blendingTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].blend = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
        .src_factor_alpha = .ONE,
        .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
    };
    return colors;
}

// Half-extents -> full scale (a unit box spans -1..1 before scaling).
fn makeInstance(center: Vec3, half: Vec3, yaw: f32, color: Vec4) Instance {
    return makeScaledInstance(center, Vec3.scale(half, 2), yaw, color);
}

// Like makeScaledInstance, but pitched about the X axis (used by level boxes,
// which the level data leans over rather than yawing).
fn makePitchedInstance(center: Vec3, half: Vec3, pitch: f32, color: Vec4) Instance {
    const scale = Vec3.scale(half, 2);
    const c = @cos(pitch);
    const s = @sin(pitch);
    return .{
        .x = .{ .x = scale.x, .w = center.x },
        .y = .{ .y = scale.y * c, .z = -scale.z * s, .w = center.y },
        .z = .{ .y = scale.y * s, .z = scale.z * c, .w = center.z },
        .color = color,
    };
}

fn makeScaledInstance(center: Vec3, scale: Vec3, yaw: f32, color: Vec4) Instance {
    const c = @cos(yaw);
    const s = @sin(yaw);
    // Each row maps the unit box directly into world space. Scale is baked in,
    // so the shader needs no per-object uniform or matrix multiplication.
    return .{
        .x = .{ .x = scale.x * c, .y = 0, .z = scale.z * s, .w = center.x },
        .y = .{ .x = 0, .y = scale.y, .z = 0, .w = center.y },
        .z = .{ .x = -scale.x * s, .y = 0, .z = scale.z * c, .w = center.z },
        .color = color,
    };
}

fn makeMapDirectionInstances(position: b3.b3Pos, yaw: f32) [map_direction_instance_count]Instance {
    const forward = Vec3{ .x = @sin(yaw), .z = @cos(yaw) };
    const arrow_y = position.y + character_half_extents.y + 0.12;
    const tip = Vec3{
        .x = position.x + forward.x * 0.9,
        .y = arrow_y,
        .z = position.z + forward.z * 0.9,
    };
    const shaft_center = Vec3{
        .x = position.x + forward.x * 0.525,
        .y = arrow_y,
        .z = position.z + forward.z * 0.525,
    };
    const head_length: f32 = 0.36;
    const head_angle: f32 = std.math.pi / 4.0;
    var result: [map_direction_instance_count]Instance = undefined;
    result[0] = makeScaledInstance(shaft_center, .{ .x = 0.08, .y = 0.04, .z = 0.75 }, yaw, map_direction_color);
    for ([_]f32{ -head_angle, head_angle }, 0..) |offset, index| {
        const branch_yaw = yaw + std.math.pi + offset;
        const branch_forward = Vec3{ .x = @sin(branch_yaw), .z = @cos(branch_yaw) };
        const center = Vec3{
            .x = tip.x + branch_forward.x * head_length * 0.5,
            .y = arrow_y,
            .z = tip.z + branch_forward.z * head_length * 0.5,
        };
        result[index + 1] = makeScaledInstance(center, .{ .x = 0.08, .y = 0.04, .z = head_length }, branch_yaw, map_direction_color);
    }
    return result;
}

fn instanceAttr(offset: i32) sg.VertexAttrState {
    return .{ .format = .FLOAT4, .buffer_index = 1, .offset = offset };
}

// Orthographic top-down view of the level, centred on the map pan position.
// North (-Z) points up on screen; the roof is hidden so interiors are visible.
fn mapViewProjection() Mat4 {
    const aspect = sapp.widthf() / @max(sapp.heightf(), 1);
    const half_w: f32 = 36.0; // visible half-width in metres (covers x +-26)
    const half_h = @max(19.5, half_w / aspect); // covers z +-19
    const center = game.map.pan;
    const eye = Vec3{ .x = center.x, .y = 80, .z = center.z };
    const at = Vec3{ .x = center.x, .y = 0, .z = center.z };
    const view = Mat4.lookAtRh(eye, at, .{ .x = 0, .y = 0, .z = -1 });
    const projection = Mat4.orthoOffCenterRh(-half_w, half_w, -half_h, half_h, 1, 200);
    return Mat4.mul(view, projection);
}

fn fbool(value: bool) f32 {
    return @floatFromInt(@intFromBool(value));
}

fn rgb(r: f32, g: f32, b: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = 1 };
}

// The save-file APIs need an Io instance; the app owns one for its lifetime.
var app_io: std.Io.Threaded = undefined;

pub fn main() void {
    app_io = .init(std.heap.page_allocator, .{});
    defer app_io.deinit();
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 1280,
        .height = 720,
        // Sokol implements desktop fullscreen as a borderless fullscreen window.
        .fullscreen = true,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "Character Mover",
        .logger = .{ .func = slog.func },
    });
}

test "clock consumes fixed ticks independent of frame chunks" {
    var a: Clock = .{};
    var b: Clock = .{};
    var count_a: usize = 0;
    var count_b: usize = 0;
    for (0..30) |_| {
        a.addFrame(1.0 / 30.0);
        while (a.consumeTick()) count_a += 1;
    }
    for (0..120) |_| {
        b.addFrame(1.0 / 120.0);
        while (b.consumeTick()) count_b += 1;
    }
    try std.testing.expectEqual(count_a, count_b);
}

test "hunter AI tests" {
    std.testing.refAllDecls(@import("hunter.zig"));
}
