//! Data-oriented character mover scene.
//!
//! Plain state is kept separate from the systems that transform it. Box3D owns
//! collision geometry, Sokol owns rendering, and the character capsule belongs
//! to neither as a rigid body: it is moved explicitly by application code.

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("rpd_level.zig");
const controller = @import("character_controller.zig");
const hunter = @import("hunter.zig");
const navmesh = @import("navmesh.zig");
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

// Spawn sampling lives inside the walkable floor area, clear of walls and
// furniture. The capsule centre heights match each actor's capsule geometry
// (half_segment + radius), so the capsule sits on the floor.
const spawn_half_x: f32 = 24.0;
const spawn_half_z: f32 = 17.0;
const player_spawn_y: f32 = 0.9;
const hunter_spawn_y: f32 = 1.5;
// Keep the hunter from starting on top of the player — and beyond his
// perception radius, so he begins patrolling rather than instantly chasing.
const min_spawn_separation: f32 = 24.0;

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

// The roof lives in its own instance buffer so it can be hidden in map view.
const level_instance_count = count: {
    var count: usize = 0;
    for (level.boxes) |box| count += @intFromBool(box.visible and !box.is_roof);
    break :count count;
};
const roof_instance_count = count: {
    var count: usize = 0;
    for (level.boxes) |box| count += @intFromBool(box.visible and box.is_roof);
    break :count count;
};

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

// Top-down map overlay state. The route is rebuilt from the current actor poses
// whenever the map opens, then remains fixed while the simulation is paused.
const MapState = struct {
    active: bool = false,
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
    character_config: controller.Config = .{},
    character: controller.State = initialCharacter(),
    hunter_config: hunter.Config = .{},
    hunter: hunter.State = initialHunter(),
    game_over: bool = false,
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
    initPhysics();
    navmesh.buildLevel();
    initRenderer();
    // Randomize the spawn PRNG per launch so each run starts at fresh random
    // positions. Entropy comes from ASLR (a stack address plus the data
    // segment address both differ between processes). Restarts then continue
    // the PRNG sequence rather than re-seeding.
    seedSpawnRandomness();
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

    const render_position = if (game.game_over) blk: {
        // Game over: everything freezes behind the overlay. Drain pending
        // physics ticks so restarting doesn't burst-catch-up the simulation.
        while (game.clock.consumeTick()) {}
        break :blk game.character.position;
    } else blk: {
        var ticks: usize = 0;
        while (ticks < max_ticks_per_frame and game.clock.consumeTick()) : (ticks += 1) {
            // Map mode pauses the whole simulation: the player character and
            // the hunter both freeze so the map can be studied without risk.
            if (!game.map.active) {
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
                hunter.update(
                    game.hunter_config,
                    &game.hunter,
                    &game.mover_scratch,
                    game.world,
                    game.character.position,
                    @floatCast(fixed_dt),
                );
                if (hunterContacted()) {
                    game.game_over = true;
                    break;
                }
            }
        }
        // Discard excess backlog after the bounded catch-up budget.
        if (ticks == max_ticks_per_frame and game.clock.accumulator >= fixed_dt) {
            game.clock.accumulator = @mod(game.clock.accumulator, fixed_dt);
        }
        // The clock keeps consuming ticks while the map is open so no backlog
        // accumulates. Render the exact paused pose instead of using its cycling
        // interpolation alpha, which would replay the last movement every tick.
        break :blk if (game.map.active)
            game.character.position
        else
            controller.interpolatedPosition(game.character, game.clock.alpha());
    };

    if (game.map.active) {
        // WASD pans the map camera around the level.
        const pan_speed = map_pan_speed * frame_time;
        game.map.pan.x += (fbool(game.input.right) - fbool(game.input.left)) * pan_speed;
        game.map.pan.z += (fbool(game.input.back) - fbool(game.input.forward)) * pan_speed;
        game.map.pan.x = std.math.clamp(game.map.pan.x, -map_pan_x_max, map_pan_x_max);
        game.map.pan.z = std.math.clamp(game.map.pan.z, -map_pan_z_max, map_pan_z_max);
        game.camera.view_projection = mapViewProjection();
    } else if (!game.game_over) {
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
                .W => game.input.forward = down,
                .S => game.input.back = down,
                .A => game.input.left = down,
                .D => game.input.right = down,
                .LEFT_SHIFT, .RIGHT_SHIFT => if (down and !value.key_repeat) {
                    // Arm running. It only takes effect while a direction is
                    // held and is never toggled off by Shift again.
                    game.input.run = true;
                },
                .F1 => if (down and !value.key_repeat) {
                    game.debug.draw_physics = !game.debug.draw_physics;
                },
                .M => if (down and !value.key_repeat) {
                    game.map.active = !game.map.active;
                    if (game.map.active) rebuildMapRoute();
                    // Drop held keys so the map doesn't immediately pan and
                    // gameplay doesn't resume with the character moving.
                    game.input = .{};
                },
                .R => if (down and !value.key_repeat and game.game_over) {
                    spawnPlayerAndHunter();
                },
                .E => if (down and !value.key_repeat) {
                    // RE2R quick-turn: while walking backward, swing the
                    // character and camera 180 degrees over a short animation.
                    if (!game.game_over and game.input.back and !game.quick_turn.active) {
                        game.quick_turn = .{
                            .active = true,
                            .character_start = game.character.yaw,
                            .character_target = game.character.yaw + std.math.pi,
                            .camera_start = game.camera.yaw,
                            .camera_target = game.camera.yaw + std.math.pi,
                        };
                    }
                },
                .ESCAPE => if (down) sapp.lockMouse(false),
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
    for (level.boxes) |box| if (box.collidable) addStaticBox(box);
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
// global game state live at different addresses in each process.
fn seedSpawnRandomness() void {
    var stack_marker: u32 = 0;
    const entropy = @as(u64, @bitCast(@intFromPtr(&stack_marker))) ^ @as(u64, @bitCast(@intFromPtr(&game)));
    hunter.seedRandom(@truncate(entropy));
}

// Place the player and hunter at collision-free random positions, then reset
// the whole round (clock, camera, map, game-over flag).
fn spawnPlayerAndHunter() void {
    const player_spawn = randomValidSpawn(
        player_spawn_y,
        game.character_config.capsule_half_segment,
        game.character_config.capsule_radius,
        false,
    );
    var hunter_spawn = randomValidSpawn(
        hunter_spawn_y,
        game.hunter_config.capsule_half_segment,
        game.hunter_config.capsule_radius,
        true,
    );
    // Resample the hunter until it starts far enough from the player to give a
    // fair opening, but fall back to the first sample if the level is crowded.
    var attempts: usize = 0;
    while (attempts < 64) : (attempts += 1) {
        const dx = hunter_spawn.x - player_spawn.x;
        const dz = hunter_spawn.z - player_spawn.z;
        if (dx * dx + dz * dz >= min_spawn_separation * min_spawn_separation) break;
        hunter_spawn = randomValidSpawn(
            hunter_spawn_y,
            game.hunter_config.capsule_half_segment,
            game.hunter_config.capsule_radius,
            true,
        );
    }

    game.character = controller.State.init(player_spawn);
    game.character.yaw = std.math.pi; // face -Z, matching the initial camera
    game.hunter = hunter.State.init(hunter_spawn);
    // Face the player from the start (Mr X's head sweep then scans around this
    // heading), and give him a real patrol destination so he sets off walking
    // immediately instead of idling at his spawn point.
    game.hunter.yaw = std.math.atan2(player_spawn.x - hunter_spawn.x, player_spawn.z - hunter_spawn.z);
    game.hunter.target = hunter.randomPatrolTarget(game.hunter_config, game.hunter.position);
    game.hunter.repath_timer = 0;
    game.camera = .{};
    game.clock = .{};
    game.map = .{};
    game.game_over = false;
    game.input = .{};
}

// Rejection-sample a capsule-sized clear spot inside the walkable floor area.
fn randomValidSpawn(y: f32, half_segment: f32, radius: f32, include_hunter_blocks: bool) b3.b3Pos {
    var attempts: usize = 0;
    while (attempts < 256) : (attempts += 1) {
        const position = b3.b3Pos{
            .x = hunter.randomRange(-spawn_half_x, spawn_half_x),
            .y = y,
            .z = hunter.randomRange(-spawn_half_z, spawn_half_z),
        };
        if (!level.isInSaveRoom(position.x, position.z) and capsuleClear(position, half_segment, radius, include_hunter_blocks)) return position;
    }
    // Fallback: the middle of the Main Hall is always open.
    return .{ .x = 0, .y = y, .z = 0 };
}

const SpawnCheck = struct { hit: bool = false };

fn overlapHit(_: b3.b3ShapeId, context: ?*anyopaque) callconv(.c) bool {
    const check: *SpawnCheck = @ptrCast(@alignCast(context.?));
    check.hit = true;
    return false; // stop at the first overlap
}

// True when no level geometry intersects the capsule at `position`. The two
// probe points (mid height and top) sit well above the floor slab so the floor
// itself never counts as a blocker; walls and furniture span that height range,
// so anything the capsule would collide with still overlaps one of them.
fn capsuleClear(position: b3.b3Pos, half_segment: f32, radius: f32, include_hunter_blocks: bool) bool {
    var check: SpawnCheck = .{};
    const points = [_]b3.b3Vec3{
        .{},
        .{ .y = half_segment },
    };
    var proxy: b3.b3ShapeProxy = .{ .points = &points, .count = 2, .radius = radius };
    var filter = b3.b3DefaultQueryFilter();
    filter.categoryBits = if (include_hunter_blocks) controller.hunter_query_category else controller.player_query_category;
    filter.maskBits = controller.level_category;
    if (include_hunter_blocks) filter.maskBits |= controller.hunter_block_category;
    _ = b3.b3World_OverlapShape(game.world, position, &proxy, filter, overlapHit, &check);
    return !check.hit;
}

// The hunter catches the player when their capsules touch horizontally.
fn hunterContacted() bool {
    const dx = game.hunter.position.x - game.character.position.x;
    const dz = game.hunter.position.z - game.character.position.z;
    const radius = game.hunter_config.contact_radius;
    return dx * dx + dz * dz < radius * radius;
}

fn rebuildMapRoute() void {
    game.map.route_len = 0;
    game.map.route_segment_count = 0;
    game.map.route_upload_pending = true;
    if (level.isInSaveRoom(game.character.position.x, game.character.position.z)) {
        game.map.route_status = .arrived;
        return;
    }

    const target = level.save_room_target;
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

    // Bake every visible level box into one static instance array, keeping the
    // roof separate so the map view can hide it.
    var level_instances: [level_instance_count]Instance = undefined;
    var roof_instances: [roof_instance_count]Instance = undefined;
    var level_count: usize = 0;
    var roof_count: usize = 0;
    for (level.boxes) |box| {
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
    std.debug.assert(level_count == level_instance_count);
    std.debug.assert(roof_count == roof_instance_count);
    game.render.level_instances = sg.makeBuffer(.{ .data = sg.asRange(&level_instances), .label = "character-level-instances" });
    game.render.roof_instance = sg.makeBuffer(.{ .data = sg.asRange(&roof_instances), .label = "character-roof-instance" });
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
    const hunter_render = if (game.map.active or game.game_over)
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
    drawInstances(game.render.level_instances, game.render.box_range, 0, level_instance_count, false);
    drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
    drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    if (!game.map.active) {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, roof_instance_count, false);
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
        // xyz is fixture position; w is its attenuation radius. Fixtures sit
        // just under the 5.5m roof, one per room cluster.
        .indoor_light_0 = .{ .x = 0, .y = 4.2, .z = 0, .w = 10 }, // Main Hall
        .indoor_light_1 = .{ .x = -20, .y = 4.0, .z = 0, .w = 9 }, // W2 office
        .indoor_light_2 = .{ .x = 20, .y = 4.0, .z = 0, .w = 9 }, // E2 office
        .indoor_light_3 = .{ .x = -20, .y = 4.0, .z = -8, .w = 9 }, // W1 storage
        .indoor_light_4 = .{ .x = 20, .y = 4.0, .z = -8, .w = 9 }, // E1
        .indoor_light_5 = .{ .x = -6, .y = 4.0, .z = -16, .w = 9 }, // NW2/NW corner
        .indoor_light_6 = .{ .x = -6, .y = 4.0, .z = 16, .w = 9 }, // SW2
        .indoor_light_7 = .{ .x = 20, .y = 4.0, .z = 8, .w = 9 }, // E3
    };

    sg.beginPass(.{ .action = game.render.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(game.render.display_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, level_instance_count, true);
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
        drawInstances(game.render.roof_instance, game.render.box_range, 0, roof_instance_count, true);
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
        sdtx.print("MAP (WASD pans, M exits - simulation paused)", .{});
        switch (game.map.route_status) {
            .arrived => {
                sdtx.pos(1.0, 2.2);
                sdtx.color3b(80, 250, 123);
                sdtx.print("SAVE ROOM REACHED", .{});
            },
            .no_path => {
                sdtx.pos(1.0, 2.2);
                sdtx.color3b(255, 85, 85);
                sdtx.print("NO SAFE ROUTE", .{});
            },
            else => {},
        }
    } else if (game.debug.draw_physics and !game.game_over) {
        sdtx.pos(1.0, 1.0);
        sdtx.print("POS {d:.1} {d:.1} {d:.1}", .{ position.x, position.y, position.z });
    }
    if (game.game_over) {
        const title = "YOU WERE CAUGHT BY THE HUNTER";
        const prompt = "PRESS R TO PLAY AGAIN";
        // The 8x8 font renders in text units of 8 px, so dividing the pixel
        // canvas by 8 centres a line of `len` characters.
        sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(title.len)) / 2.0, sapp.heightf() / 8.0 / 2.0 - 1.0);
        sdtx.color3b(255, 60, 60);
        sdtx.print(title, .{});
        sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(prompt.len)) / 2.0, sapp.heightf() / 8.0 / 2.0 + 1.0);
        sdtx.color3b(255, 255, 255);
        sdtx.print(prompt, .{});
    }
    sdtx.draw();
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

pub fn main() void {
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
