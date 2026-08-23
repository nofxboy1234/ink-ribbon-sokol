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
const combat = @import("combat.zig");
const inventory = @import("inventory.zig");
const player_condition = @import("player_condition.zig");
const hunter = @import("hunter.zig");
const deformation = @import("character_deformation.zig");
const deformed_box = @import("deformed_box.zig");
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
const save_interaction_radius: f32 = 2.0;

// How long a HUD notice (catch / save result) stays on screen.
const notice_seconds: f32 = 3;
const impact_capacity = 32;
const impact_seconds: f32 = 0.35;
const hunter_hit_flash_seconds: f32 = 0.09;
const hunter_flinch_seconds: f32 = 0.32;
const hunter_knockdown_enter_seconds: f32 = 0.75;
const hunter_knockdown_exit_seconds: f32 = 1.15;
const shot_recoil_radians: f32 = 0.008;

// Transient centered HUD messages.
const HudNotice = enum {
    none,
    caught,
    saved,
    save_failed,
    deleted,
    hunter_friendly,
    hunter_hostile,
    ammo_found,
    health_found,
    inventory_full,
    healed,
    full_health,
};

// Top-down map view tuning.
const map_pan_speed: f32 = 25.0; // metres/second the map pans with WASD
const map_pan_x_max: f32 = 40.0; // keep the pan center near the level
const map_pan_z_max: f32 = 30.0;
const map_half_width: f32 = 36.0;
const map_min_half_height: f32 = 19.5;
const map_route_capacity = navmesh.level_cols * navmesh.level_rows;
const map_route_width: f32 = 0.16;
const map_route_height: f32 = 0.04;
const map_route_danger_radius: f32 = 6.0;
const map_route_danger_penalty: f32 = 4.0;
const map_direction_color = rgb(0.741, 0.576, 0.976); // Dracula purple #BD93F9
const map_direction_instance_count = 3;
const map_save_capacity = 2;

const PickupDef = struct {
    position: Vec3,
    item: inventory.Item,
    name: []const u8,
};

// The first two pickups sit in the entrance path so the inventory interaction
// is discoverable immediately. Later entries are deliberately spread through
// both wings and appended so old save-file collection bits keep their meaning.
const pickup_defs = [_]PickupDef{
    .{ .position = .{ .x = -1.0, .y = 0.18, .z = 9.2 }, .item = .{ .kind = .ammo, .amount = 30 }, .name = "Handgun Ammo" },
    .{ .position = .{ .x = 1.0, .y = 0.18, .z = 8.0 }, .item = .{ .kind = .health, .amount = 1 }, .name = "First Aid Spray" },
    .{ .position = .{ .x = 0.0, .y = 0.18, .z = 6.5 }, .item = .{ .kind = .ammo, .amount = 24 }, .name = "Handgun Ammo" },
    .{ .position = .{ .x = -10.5, .y = 0.18, .z = -9.3 }, .item = .{ .kind = .health, .amount = 1 }, .name = "First Aid Spray" },
    .{ .position = .{ .x = 0.0, .y = 0.18, .z = 0.0 }, .item = .{ .kind = .ammo, .amount = 18 }, .name = "Handgun Ammo" },
    .{ .position = .{ .x = -9.2, .y = 0.18, .z = -9.3 }, .item = .{ .kind = .ammo, .amount = 24 }, .name = "Handgun Ammo" },
    .{ .position = .{ .x = 7.0, .y = 0.18, .z = -2.0 }, .item = .{ .kind = .health, .amount = 1 }, .name = "First Aid Spray" },
    .{ .position = .{ .x = 0.0, .y = 0.18, .z = -7.0 }, .item = .{ .kind = .ammo, .amount = 30 }, .name = "Handgun Ammo" },
    .{ .position = .{ .x = 2.0, .y = 0.18, .z = -7.0 }, .item = .{ .kind = .health, .amount = 1 }, .name = "First Aid Spray" },
    .{ .position = .{ .x = 8.2, .y = 0.18, .z = -2.0 }, .item = .{ .kind = .ammo, .amount = 36 }, .name = "Handgun Ammo" },
};

const BreakableDef = struct {
    position: Vec3,
    name: []const u8 = "Wooden Item Box",
};

const breakable_defs = [_]BreakableDef{
    .{ .position = .{ .x = -1.55, .y = 0.42, .z = 7.4 } },
    .{ .position = .{ .x = 1.45, .y = 0.42, .z = 6.3 } },
    .{ .position = .{ .x = -2.4, .y = 0.42, .z = 3.4 } },
    // Appended so existing save-file broken-box bits retain their meaning.
    .{ .position = .{ .x = -2.2, .y = 0.42, .z = -1.0 } },
    .{ .position = .{ .x = 0.0, .y = 0.42, .z = -4.5 } },
    .{ .position = .{ .x = 6.0, .y = 0.42, .z = -0.8 } },
    .{ .position = .{ .x = -0.8, .y = 0.42, .z = -8.0 } },
    .{ .position = .{ .x = -10.7, .y = 0.42, .z = -8.2 } },
};
const world_item_count = pickup_defs.len + breakable_defs.len;
const interaction_radius: f32 = 2.0;
const debris_capacity = breakable_defs.len * 8;
const debris_seconds: f32 = 4.0;
const action_duration: f32 = 0.68;
const action_contact_time: f32 = 0.30;

const InteractionKind = enum { pickup, breakable };
const InteractionTarget = struct {
    kind: InteractionKind,
    index: usize,
};

const KickState = struct {
    active: bool = false,
    timer: f32 = 0,
    target: usize = 0,
    broke_box: bool = false,
};

const PickupAction = struct {
    const Events = struct {
        collect: bool = false,
        finished: bool = false,
    };

    active: bool = false,
    timer: f32 = 0,
    target: usize = 0,
    committed: bool = false,

    fn advance(self: *PickupAction, dt: f32) Events {
        var events = Events{};
        if (!self.active) return events;
        self.timer += dt;
        if (!self.committed and self.timer >= action_contact_time) {
            self.committed = true;
            events.collect = true;
        }
        if (self.timer >= action_duration) {
            self.active = false;
            events.finished = true;
        }
        return events;
    }

    fn amount(self: PickupAction) f32 {
        if (!self.active) return 0;
        return @sin(std.math.pi * std.math.clamp(self.timer / action_duration, 0, 1));
    }
};

const Debris = struct {
    active: bool = false,
    position: Vec3 = .{},
    velocity: Vec3 = .{},
    yaw: f32 = 0,
    pitch: f32 = 0,
    angular_velocity: f32 = 0,
    timer: f32 = 0,
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
    aiming: bool = false,
    firing: bool = false,
    reload_queued: bool = false,
    mouse_delta: math.Vec2 = .{},

    fn moving(self: InputState) bool {
        return self.forward or self.back or self.left or self.right;
    }

    // Turn held keys into a movement intent. x is strafe (right-left),
    // y is forward-back (positive = toward where the camera looks).
    fn characterInput(self: *InputState) controller.Input {
        const move: controller.Vec2 = .{
            .x = @as(f32, @floatFromInt(@intFromBool(self.right))) - @as(f32, @floatFromInt(@intFromBool(self.left))),
            .y = @as(f32, @floatFromInt(@intFromBool(self.forward))) - @as(f32, @floatFromInt(@intFromBool(self.back))),
        };
        // Running is armed by Shift but only applies while a direction is held;
        // releasing the direction keys falls back to walking and disarms it.
        const running = self.run and !self.aiming and (move.x != 0 or move.y != 0);
        if (!running) self.run = false;
        return .{
            .move = move,
            .run = running,
            .aiming = self.aiming,
        };
    }
};

const Impact = struct {
    position: Vec3 = .{},
    timer: f32 = 0,
};

const CombatVisuals = struct {
    impacts: [impact_capacity]Impact = @splat(.{}),
    next_impact: usize = 0,
    hunter_hit_flash: f32 = 0,
};

const HunterReaction = struct {
    elapsed: f32 = 0,
    duration: f32 = 0,
    side: f32 = 1,

    fn begin(self: *HunterReaction, side: f32) void {
        self.elapsed = 0;
        self.duration = hunter_flinch_seconds;
        self.side = if (side < 0) -1 else 1;
    }

    fn update(self: *HunterReaction, dt: f32) void {
        if (!self.active()) return;
        self.elapsed = @min(self.duration, self.elapsed + dt);
    }

    fn active(self: HunterReaction) bool {
        return self.elapsed < self.duration;
    }

    fn amount(self: HunterReaction) f32 {
        if (!self.active() or self.duration <= 0) return 0;
        const t = std.math.clamp(self.elapsed / self.duration, 0, 1);
        // A fast recoil followed by a longer ease back to the neutral pose.
        if (t < 0.18) return smoothstep(t / 0.18);
        return 1.0 - smoothstep((t - 0.18) / 0.82);
    }
};

const DebugState = struct {
    draw_physics: bool = false,
};

const MapRouteStatus = enum { none, found, arrived, no_path };

// Typewriter save/load windows. While open they freeze the round exactly like
// map mode does; navigation is keyboard-only.
const MenuKind = enum { none, save, load };
const MenuState = struct {
    kind: MenuKind = .none,
    slot: usize = 0,
};

const InventoryUi = struct {
    active: bool = false,
    moving_cell: ?usize = null,
    popup_cell: ?usize = null,
};

// Top-down map overlay state. The route is rebuilt from the current actor poses
// whenever the map opens, then remains fixed while the player is paused.
const MapState = struct {
    active: bool = false,
    hunter_paused: bool = true,
    selected_save: usize = 0,
    pan: Vec3 = .{},
    route: [map_route_capacity]b3.b3Pos = undefined,
    route_instances: [map_route_capacity]Instance = undefined,
    route_start: b3.b3Pos = .{},
    route_len: usize = 0,
    route_segment_count: usize = 0,
    route_upload_pending: bool = false,
    route_status: MapRouteStatus = .none,
    cursor: math.Vec2 = .{},
};

// Smooth directional quick-turn (RE2R): the character and camera swing toward
// the held backward direction over a short animation instead of snapping.
const QuickTurn = struct {
    active: bool = false,
    timer: f32 = 0,
    duration: f32 = 0.35 / 1.5,
    character_start: f32 = 0,
    character_target: f32 = 0,
    camera_start: f32 = 0,
    camera_target: f32 = 0,
};

const RenderState = struct {
    // Shared mesh geometry (all shapes built into one vertex/index buffer).
    vertex_buffer: sg.Buffer = .{},
    index_buffer: sg.Buffer = .{},
    // The actors use a separate vertically subdivided mesh so only they bend.
    actor_vertex_buffer: sg.Buffer = .{},
    actor_index_buffer: sg.Buffer = .{},
    // Per-instance transform buffers: static level, dynamic character, debug capsule.
    level_instances: sg.Buffer = .{},
    roof_instance: sg.Buffer = .{},
    character_instance: sg.Buffer = .{},
    map_direction_instances: sg.Buffer = .{},
    map_save_instances: sg.Buffer = .{},
    hunter_instance: sg.Buffer = .{},
    impact_instances: sg.Buffer = .{},
    pickup_instances: sg.Buffer = .{},
    map_item_instances: sg.Buffer = .{},
    debris_instances: sg.Buffer = .{},
    route_instances: sg.Buffer = .{},
    capsule_instances: sg.Buffer = .{},
    level_instance_count: usize = 0,
    roof_instance_count: usize = 0,
    display_pipeline: sg.Pipeline = .{},
    actor_display_pipeline: sg.Pipeline = .{},
    route_pipeline: sg.Pipeline = .{},
    map_actor_pipeline: sg.Pipeline = .{},
    debug_pipeline: sg.Pipeline = .{},
    reticle_pipeline: sg.Pipeline = .{},
    ui_rect_pipeline: sg.Pipeline = .{},
    hud_circle_pipeline: sg.Pipeline = .{},
    shadow_pipeline: sg.Pipeline = .{},
    actor_shadow_pipeline: sg.Pipeline = .{},
    shadow_pass: sg.Pass = .{},
    shadow_view: sg.View = .{},
    shadow_sampler: sg.Sampler = .{},
    light_view_projection: Mat4 = Mat4.identity(),
    // Element ranges into the shared buffers for each shape type.
    box_range: sshape.ElementRange = .{},
    capsule_cylinder_range: sshape.ElementRange = .{},
    capsule_sphere_range: sshape.ElementRange = .{},
    pass_action: sg.PassAction = .{},
    impact_instance_count: usize = 0,
    pickup_instance_count: usize = 0,
    map_item_instance_count: usize = 0,
    debris_instance_count: usize = 0,
};

const GameState = struct {
    world: b3.b3WorldId = b3.b3_nullWorldId,
    clock: Clock = .{},
    input: InputState = .{},
    debug: DebugState = .{},
    map: MapState = .{},
    menu: MenuState = .{},
    inventory_ui: InventoryUi = .{},
    inventory: inventory.State = .{},
    collected_pickups: u32 = 0,
    discovered_items: u32 = 0,
    broken_boxes: u32 = 0,
    interaction_target: ?InteractionTarget = null,
    kick: KickState = .{},
    pickup_action: PickupAction = .{},
    debris: [debris_capacity]Debris = @splat(.{}),
    character_config: controller.Config = .{},
    character: controller.State = initialCharacter(),
    hunter_config: hunter.Config = .{},
    hunter: hunter.State = initialHunter(),
    combat_config: combat.Config = .{},
    combat: combat.State = .{},
    combat_visuals: CombatVisuals = .{},
    hunter_reaction: HunterReaction = .{},
    condition_config: player_condition.Config = .{},
    condition: player_condition.State = .{},
    deformation_config: deformation.Config = .{},
    player_deformation: deformation.State = .{},
    hunter_deformation: deformation.State = .{},
    hunter_friendly: bool = false,
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

// Advance the quick-turn swing at render cadence. The controller may update on
// fixed simulation ticks, but orientation is presentation-only here; updating
// it once per rendered frame avoids visible 60 Hz stepping on faster displays.
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

// Signed shortest turn from forward toward the held keyboard direction. In
// this yaw convention local right is negative rotation: S+A is +135 degrees,
// S+D is -135 degrees, and S alone uses the deterministic +180-degree case.
fn keyboardQuickTurnDelta(left: bool, right: bool) f32 {
    const lateral = fbool(right) - fbool(left);
    if (lateral == 0) return std.math.pi;
    return std.math.atan2(-lateral, -1.0);
}

fn beginQuickTurn() void {
    camera.cancelRecenter(&game.camera);
    const delta = keyboardQuickTurnDelta(game.input.left, game.input.right);
    game.quick_turn = .{
        .active = true,
        .character_start = game.character.yaw,
        .character_target = game.character.yaw + delta,
        .camera_start = game.camera.yaw,
        .camera_target = game.camera.yaw + delta,
    };
}

fn frame() callconv(.c) void {
    const frame_time: f32 = @floatCast(@min(sapp.frameDuration(), max_frame_dt));
    game.clock.addFrame(frame_time);
    if (game.notice_timer > 0) {
        game.notice_timer = @max(0, game.notice_timer - frame_time);
        if (game.notice_timer == 0) game.notice = .none;
    }
    updateCombatVisuals(frame_time);

    // Menus freeze the round exactly like map mode does.
    const gameplay_active = !game.map.active and game.menu.kind == .none and !game.inventory_ui.active;

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
                    if (game.condition.canMove() and !playerActionActive()) game.input.characterInput() else .{},
                    game.camera.basis,
                    @floatCast(fixed_dt),
                );
                if (game.condition.canMove() and !playerActionActive()) {
                    const reserve_before = game.combat.reserve;
                    const combat_events = combat.update(game.combat_config, &game.combat, .{
                        .aiming = game.input.aiming,
                        .firing = game.input.firing,
                        .reload_pressed = game.input.reload_queued,
                        .moving = game.input.moving(),
                    }, @floatCast(fixed_dt));
                    game.input.reload_queued = false;
                    if (game.combat.reserve < reserve_before) {
                        _ = game.inventory.consumeAmmo(reserve_before - game.combat.reserve);
                    }
                    for (combat_events.shot_focus[0..combat_events.shot_count]) |shot_focus| fireShot(shot_focus);
                }
                updateActionsAndDebris(@floatCast(fixed_dt));
                if (game.condition.update(game.condition_config, game.character.grounded, @floatCast(fixed_dt)) == .defeated) {
                    respawnAfterCatch();
                    break;
                }
            }
            const hunter_sim_active = game.menu.kind == .none and !game.inventory_ui.active and (!game.map.active or !game.map.hunter_paused);
            if (hunter_sim_active) {
                game.hunter_reaction.update(@floatCast(fixed_dt));
                if (!game.combat.hunterKnockedDown() and !game.hunter_reaction.active()) {
                    if (game.condition.hunter_watch_timer > 0) {
                        faceHunterTowardPlayer(@floatCast(fixed_dt));
                    } else {
                        hunter.update(
                            game.hunter_config,
                            &game.hunter,
                            &game.mover_scratch,
                            game.world,
                            game.character.position,
                            @floatCast(fixed_dt),
                        );
                        if (hunterContacted()) punchPlayer();
                    }
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

    if (gameplay_active and game.condition.canMove() and !playerActionActive() and !game.input.aiming) updateQuickTurn(frame_time);

    if (game.map.active) {
        // WASD pans the map camera around the level.
        const pan_speed = map_pan_speed * frame_time;
        game.map.pan.x += (fbool(game.input.right) - fbool(game.input.left)) * pan_speed;
        game.map.pan.z += (fbool(game.input.back) - fbool(game.input.forward)) * pan_speed;
        game.map.pan.x = std.math.clamp(game.map.pan.x, -map_pan_x_max, map_pan_x_max);
        game.map.pan.z = std.math.clamp(game.map.pan.z, -map_pan_z_max, map_pan_z_max);
        game.camera.view_projection = mapViewProjection();
    } else if (game.menu.kind == .none and !game.inventory_ui.active) {
        camera.update(
            game.camera_config,
            &game.camera,
            render_position,
            game.input.mouse_delta,
            game.input.aiming,
            game.world,
            frame_time,
            sapp.widthf() / @max(sapp.heightf(), 1),
        );
        game.input.mouse_delta = .{};
    }
    if (gameplay_active and game.condition.canMove() and !playerActionActive()) {
        updateInteractionTarget();
    } else {
        game.interaction_target = null;
    }
    uploadMapRoute();
    draw(render_position, frame_time, gameplay_active);
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
            if (game.inventory_ui.active) {
                if (down and !value.key_repeat and (value.key_code == .I or value.key_code == .ESCAPE)) closeInventory();
                return;
            }
            switch (value.key_code) {
                .W => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(-1);
                } else {
                    game.input.forward = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .S => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(1);
                } else {
                    game.input.back = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .A => {
                    game.input.left = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .D => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) deleteSelectedSlot();
                } else {
                    game.input.right = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .LEFT_SHIFT, .RIGHT_SHIFT => if (down and !value.key_repeat) {
                    if (!game.input.moving() and game.menu.kind == .none and !game.map.active and game.condition.canMove() and !playerActionActive()) {
                        game.input.run = false;
                        game.quick_turn.active = false;
                        camera.beginRecenter(&game.camera, game.character.yaw);
                    } else {
                        // Arm running when Shift accompanies a movement key.
                        game.input.run = true;
                    }
                },
                .Q => if (game.menu.kind == .none and !game.map.active) {
                    if (down and playerActionActive()) return;
                    game.input.aiming = down;
                    if (down) {
                        game.input.run = false;
                        game.quick_turn.active = false;
                        camera.cancelRecenter(&game.camera);
                    }
                },
                .R => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active) {
                    game.input.reload_queued = true;
                },
                .F1 => if (down and !value.key_repeat) {
                    game.debug.draw_physics = !game.debug.draw_physics;
                },
                .F => if (down and !value.key_repeat and game.menu.kind == .none) {
                    game.hunter_friendly = !game.hunter_friendly;
                    game.notice = if (game.hunter_friendly) .hunter_friendly else .hunter_hostile;
                    game.notice_timer = notice_seconds;
                },
                .M => if (down and !value.key_repeat and game.menu.kind == .none and (game.map.active or !playerActionActive())) {
                    game.map.active = !game.map.active;
                    if (game.map.active) {
                        game.map.hunter_paused = true;
                        game.map.cursor = .{ .x = sapp.widthf() * 0.5, .y = sapp.heightf() * 0.5 };
                        rebuildMapRoute();
                        game.camera.aim_alpha = 0;
                        game.combat.focus = 0;
                        game.combat.aiming_last_tick = false;
                    }
                    sapp.lockMouse(!game.map.active);
                    sapp.showMouse(!game.map.active);
                    // Drop held keys so the map doesn't immediately pan and
                    // gameplay doesn't resume with the character moving.
                    game.input = .{};
                },
                .I => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active and game.condition.canMove() and !playerActionActive()) {
                    openInventory();
                },
                .X => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active and game.condition.canMove() and !playerActionActive()) {
                    activateInteraction();
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
                    } else if (!game.map.active and !playerActionActive() and nearSaveFixture()) {
                        openMenu(.save);
                    }
                },
                .L => if (down and !value.key_repeat) {
                    if (game.menu.kind == .none and !game.map.active and !playerActionActive()) openMenu(.load);
                },
                .ENTER => if (down and !value.key_repeat and game.menu.kind != .none) {
                    confirmMenu();
                },
                .E => if (down and !value.key_repeat) {
                    // Turn toward the held backward/diagonal direction using
                    // the shortest clockwise or counter-clockwise arc.
                    if (game.input.back and !game.input.aiming and !game.quick_turn.active) {
                        beginQuickTurn();
                    }
                },
                .ESCAPE => if (down) {
                    if (game.menu.kind != .none) {
                        closeMenu();
                    } else {
                        game.input.aiming = false;
                        game.input.firing = false;
                        sapp.lockMouse(false);
                    }
                },
                else => {},
            }
        },
        .MOUSE_DOWN => if (value.mouse_button == .LEFT) {
            if (game.inventory_ui.active) {
                inventoryClick(value.mouse_x, value.mouse_y);
            } else if (game.map.active) {
                selectMapSaveAt(value.mouse_x, value.mouse_y);
            } else if (game.menu.kind == .none and !playerActionActive()) {
                sapp.lockMouse(true);
                game.input.firing = true;
            }
        } else if (!game.map.active and game.menu.kind == .none) {
            sapp.lockMouse(true);
        },
        .MOUSE_UP => if (value.mouse_button == .LEFT) {
            game.input.firing = false;
        },
        .MOUSE_MOVE => if (game.map.active) {
            game.map.cursor = .{ .x = value.mouse_x, .y = value.mouse_y };
        } else if (sapp.mouseLocked()) {
            game.input.mouse_delta.x += value.mouse_dx;
            game.input.mouse_delta.y += value.mouse_dy;
        },
        .UNFOCUSED => {
            game.input = .{};
            sapp.lockMouse(false);
            sapp.showMouse(true);
        },
        else => {},
    }
}

fn updateCombatVisuals(dt: f32) void {
    game.combat_visuals.hunter_hit_flash = @max(0, game.combat_visuals.hunter_hit_flash - dt);
    for (&game.combat_visuals.impacts) |*impact| impact.timer = @max(0, impact.timer - dt);
}

fn fireShot(focus: f32) void {
    const forward = game.camera.forward;
    const right = Vec3.normalized(Vec3.cross(forward, .{ .y = 1 }));
    const up = Vec3.normalized(Vec3.cross(right, forward));
    const spread = 0.035 + (0.0015 - 0.035) * focus;
    const spread_x = game.combat.randomSigned() * spread;
    const spread_y = game.combat.randomSigned() * spread;
    const direction = Vec3.normalized(Vec3.add(forward, Vec3.add(Vec3.scale(right, spread_x), Vec3.scale(up, spread_y))));
    const translation = Vec3.scale(direction, game.combat_config.shot_range);
    const ray_translation = b3.b3Vec3{ .x = translation.x, .y = translation.y, .z = translation.z };
    const origin = b3.b3Pos{ .x = game.camera.eye.x, .y = game.camera.eye.y, .z = game.camera.eye.z };

    var filter = b3.b3DefaultQueryFilter();
    filter.maskBits = controller.level_category;
    const level_hit = b3.b3World_CastRayClosest(game.world, origin, ray_translation, filter);
    const level_fraction = if (level_hit.hit) level_hit.fraction else 1.0;

    const hunter_local_origin = b3.b3Vec3{
        .x = origin.x - game.hunter.position.x,
        .y = origin.y - game.hunter.position.y,
        .z = origin.z - game.hunter.position.z,
    };
    const hunter_capsule = b3.b3Capsule{
        .center1 = .{ .y = -game.hunter_config.capsule_half_segment },
        .center2 = .{ .y = game.hunter_config.capsule_half_segment },
        .radius = game.hunter_config.capsule_radius,
    };
    var ray_input: b3.b3RayCastInput = .{
        .origin = hunter_local_origin,
        .translation = ray_translation,
        .maxFraction = level_fraction,
    };
    const hunter_hit = b3.b3RayCastCapsule(&hunter_capsule, &ray_input);
    if (hunter_hit.hit and !game.combat.hunterKnockedDown()) {
        const knocked_down = game.combat.applyHunterHit(game.combat_config, focus);
        game.hunter.previous_position = game.hunter.position;
        if (knocked_down) {
            game.hunter_reaction = .{};
        } else {
            game.hunter_reaction.begin(if (spread_x < 0) -1 else 1);
        }
        game.combat_visuals.hunter_hit_flash = hunter_hit_flash_seconds;
    } else if (level_hit.hit) {
        addImpact(.{ .x = level_hit.point.x, .y = level_hit.point.y, .z = level_hit.point.z }, level_hit.normal);
    }
    alertHunterToGunshot();
    camera.addRecoil(&game.camera, shot_recoil_radians);
}

fn addImpact(point: Vec3, normal: b3.b3Vec3) void {
    const index = game.combat_visuals.next_impact;
    game.combat_visuals.impacts[index] = .{
        .position = Vec3.add(point, Vec3.scale(.{ .x = normal.x, .y = normal.y, .z = normal.z }, 0.02)),
        .timer = impact_seconds,
    };
    game.combat_visuals.next_impact = (index + 1) % impact_capacity;
}

fn alertHunterToGunshot() void {
    if (game.combat.hunterKnockedDown()) return;
    game.hunter.acquired = false;
    game.hunter.investigating = true;
    game.hunter.investigate_timer = game.hunter_config.search_time;
    game.hunter.last_known = game.character.position;
    game.hunter.repath_timer = 0;
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
    const entropy = @as(u64, @intCast(@intFromPtr(&stack_marker))) ^ @as(u64, @intCast(@intFromPtr(&game)));
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
    game.kick = .{};
    game.pickup_action = .{};
    game.interaction_target = null;
    game.combat = combat.State.init(game.combat_config, slot.magazine, slot.reserve);
    game.inventory = slot.inventory;
    game.collected_pickups = slot.collected_pickups;
    game.discovered_items = slot.discovered_items;
    game.broken_boxes = slot.broken_boxes;
    game.condition.reset(game.condition_config, slot.health);
    game.combat_visuals = .{};
    game.player_deformation = .{};
    game.interaction_target = null;
    game.kick = .{};
    game.pickup_action = .{};
    game.debris = @splat(.{});
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
        game.combat = combat.State.init(game.combat_config, game.combat_config.magazine_capacity, game.combat_config.starting_reserve);
        game.inventory = inventory.State.defaultLoadout(game.combat_config.starting_reserve);
        game.collected_pickups = 0;
        game.discovered_items = 0;
        game.broken_boxes = 0;
        game.condition.reset(game.condition_config, game.condition_config.max_health);
    }
    game.player_deformation = .{};
    resetHunter(game.character.position);
    game.clock = .{};
    game.map = .{};
    game.menu = .{};
    game.inventory_ui = .{};
    game.interaction_target = null;
    game.kick = .{};
    game.pickup_action = .{};
    game.debris = @splat(.{});
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
    game.combat.hunter_health = game.combat_config.hunter_health;
    game.combat.knockdown_timer = 0;
    game.combat_visuals.hunter_hit_flash = 0;
    game.hunter_reaction = .{};
    game.hunter_deformation = .{};
}

// The hunter catches the player when their capsules touch horizontally.
fn hunterContacted() bool {
    if (game.hunter_friendly or game.combat.hunterKnockedDown() or !game.condition.canBeHit()) return false;
    const dx = game.hunter.position.x - game.character.position.x;
    const dz = game.hunter.position.z - game.character.position.z;
    const radius = game.hunter_config.contact_radius;
    return dx * dx + dz * dz < radius * radius;
}

fn punchPlayer() void {
    if (!game.condition.punch(game.condition_config)) return;
    var dx = game.character.position.x - game.hunter.position.x;
    var dz = game.character.position.z - game.hunter.position.z;
    const length = @sqrt(dx * dx + dz * dz);
    if (length > 0.001) {
        dx /= length;
        dz /= length;
    } else {
        dx = @sin(game.hunter.yaw);
        dz = @cos(game.hunter.yaw);
    }
    game.character.velocity = .{
        .x = dx * game.condition_config.launch_speed,
        .y = game.condition_config.lift_speed,
        .z = dz * game.condition_config.launch_speed,
    };
    game.character.grounded = false;
    game.quick_turn = .{};
    game.kick = .{};
    game.pickup_action = .{};
    game.interaction_target = null;
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
}

// During the player's knockdown the hunter holds position and tracks them,
// recreating the deliberate pause after Mr X's punch.
fn faceHunterTowardPlayer(dt: f32) void {
    game.hunter.previous_position = game.hunter.position;
    const dx = game.character.position.x - game.hunter.position.x;
    const dz = game.character.position.z - game.hunter.position.z;
    const target = std.math.atan2(dx, dz);
    var delta = @mod(target - game.hunter.yaw + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    delta = std.math.clamp(delta, -game.hunter_config.turn_speed * dt, game.hunter_config.turn_speed * dt);
    game.hunter.yaw += delta;
}

fn targetPosition(target: InteractionTarget) Vec3 {
    return switch (target.kind) {
        .pickup => pickup_defs[target.index].position,
        .breakable => breakable_defs[target.index].position,
    };
}

fn targetName(target: InteractionTarget) []const u8 {
    return switch (target.kind) {
        .pickup => pickup_defs[target.index].name,
        .breakable => breakable_defs[target.index].name,
    };
}

fn targetColor(target: InteractionTarget) Vec4 {
    return switch (target.kind) {
        .pickup => switch (pickup_defs[target.index].item.kind) {
            .ammo => .{ .x = 0.12, .y = 0.43, .z = 0.98, .w = 1 },
            .health => .{ .x = 0.12, .y = 0.76, .z = 0.30, .w = 1 },
            .empty => .{},
        },
        .breakable => .{ .x = 1.0, .y = 0.48, .z = 0.08, .w = 1 },
    };
}

fn targetDiscoveryBit(target: InteractionTarget) u32 {
    const index = switch (target.kind) {
        .pickup => target.index,
        .breakable => pickup_defs.len + target.index,
    };
    return @as(u32, 1) << @intCast(index);
}

fn interactionScore(position: Vec3) ?f32 {
    const dx = position.x - game.character.position.x;
    const dz = position.z - game.character.position.z;
    const distance_squared = dx * dx + dz * dz;
    if (distance_squared > interaction_radius * interaction_radius) return null;
    const distance = @sqrt(distance_squared);
    if (distance < 0.001) return 10;
    const forward_length = @sqrt(game.camera.forward.x * game.camera.forward.x + game.camera.forward.z * game.camera.forward.z);
    if (forward_length < 0.001) return null;
    const alignment = (dx * game.camera.forward.x + dz * game.camera.forward.z) / (distance * forward_length);
    if (alignment < 0.05) return null;
    return alignment * 4.0 - distance * 0.12;
}

fn updateInteractionTarget() void {
    var best: ?InteractionTarget = null;
    var best_score: f32 = -std.math.inf(f32);
    for (pickup_defs, 0..) |pickup, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.collected_pickups & bit != 0) continue;
        const score = interactionScore(pickup.position) orelse continue;
        if (score > best_score) {
            best = .{ .kind = .pickup, .index = index };
            best_score = score;
        }
    }
    for (breakable_defs, 0..) |box, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.broken_boxes & bit != 0) continue;
        const score = interactionScore(box.position) orelse continue;
        if (score > best_score) {
            best = .{ .kind = .breakable, .index = index };
            best_score = score;
        }
    }
    game.interaction_target = best;
    if (best) |target| game.discovered_items |= targetDiscoveryBit(target);
}

fn activateInteraction() void {
    const target = game.interaction_target orelse return;
    switch (target.kind) {
        .pickup => {
            const pickup = pickup_defs[target.index];
            var inventory_preview = game.inventory;
            if (inventory_preview.add(pickup.item) == null) {
                game.notice = .inventory_full;
                game.notice_timer = notice_seconds;
                return;
            }
            const dx = pickup.position.x - game.character.position.x;
            const dz = pickup.position.z - game.character.position.z;
            game.character.yaw = std.math.atan2(dx, dz);
            game.character.velocity.x = 0;
            game.character.velocity.z = 0;
            game.pickup_action = .{ .active = true, .target = target.index };
            game.input = .{};
            game.interaction_target = null;
        },
        .breakable => {
            const box = breakable_defs[target.index];
            const dx = box.position.x - game.character.position.x;
            const dz = box.position.z - game.character.position.z;
            game.character.yaw = std.math.atan2(dx, dz);
            game.character.velocity.x = 0;
            game.character.velocity.z = 0;
            game.kick = .{ .active = true, .target = target.index };
            game.input = .{};
            game.interaction_target = null;
        },
    }
}

fn updateActionsAndDebris(dt: f32) void {
    const pickup_events = game.pickup_action.advance(dt);
    if (pickup_events.collect) collectPickup(game.pickup_action.target);
    if (pickup_events.finished) game.pickup_action = .{};

    if (game.kick.active) {
        game.kick.timer += dt;
        if (!game.kick.broke_box and game.kick.timer >= 0.30) {
            game.kick.broke_box = true;
            game.broken_boxes |= @as(u32, 1) << @intCast(game.kick.target);
            spawnBoxDebris(game.kick.target);
        }
        if (game.kick.timer >= action_duration) game.kick = .{};
    }

    for (&game.debris) |*piece| {
        if (!piece.active) continue;
        piece.timer -= dt;
        if (piece.timer <= 0) {
            piece.* = .{};
            continue;
        }
        piece.velocity.y -= 12.0 * dt;
        piece.position = Vec3.add(piece.position, Vec3.scale(piece.velocity, dt));
        if (piece.position.y < 0.07) {
            piece.position.y = 0.07;
            if (@abs(piece.velocity.y) > 0.45) {
                piece.velocity.y = -piece.velocity.y * 0.34;
            } else {
                piece.velocity.y = 0;
            }
            piece.velocity.x *= 0.82;
            piece.velocity.z *= 0.82;
            piece.angular_velocity *= 0.78;
        }
        piece.yaw += piece.angular_velocity * dt;
        piece.pitch += piece.angular_velocity * 0.73 * dt;
    }
}

fn collectPickup(index: usize) void {
    const bit = @as(u32, 1) << @intCast(index);
    if (game.collected_pickups & bit != 0) return;
    const pickup = pickup_defs[index];
    if (game.inventory.add(pickup.item) == null) {
        game.notice = .inventory_full;
        game.notice_timer = notice_seconds;
        return;
    }
    game.collected_pickups |= bit;
    if (pickup.item.kind == .ammo) {
        game.combat.reserve +|= pickup.item.amount;
        game.notice = .ammo_found;
    } else {
        game.notice = .health_found;
    }
    game.notice_timer = notice_seconds;
}

fn spawnBoxDebris(box_index: usize) void {
    const origin = breakable_defs[box_index].position;
    for (0..8) |piece_index| {
        const angle = @as(f32, @floatFromInt(piece_index)) * std.math.pi * 0.25;
        const direction = Vec3{ .x = @sin(angle), .z = @cos(angle) };
        var slot: ?*Debris = null;
        for (&game.debris) |*candidate| if (!candidate.active) {
            slot = candidate;
            break;
        };
        const piece = slot orelse return;
        const speed = 1.4 + @as(f32, @floatFromInt(piece_index % 3)) * 0.35;
        piece.* = .{
            .active = true,
            .position = .{
                .x = origin.x + direction.x * 0.12,
                .y = origin.y + 0.10 + @as(f32, @floatFromInt(piece_index % 2)) * 0.14,
                .z = origin.z + direction.z * 0.12,
            },
            .velocity = .{
                .x = direction.x * speed,
                .y = 2.8 + @as(f32, @floatFromInt(piece_index % 4)) * 0.38,
                .z = direction.z * speed,
            },
            .yaw = angle,
            .angular_velocity = 3.5 + @as(f32, @floatFromInt(piece_index)) * 0.31,
            .timer = debris_seconds,
        };
    }
}

fn kickAmount() f32 {
    if (!game.kick.active) return 0;
    return @sin(std.math.pi * std.math.clamp(game.kick.timer / action_duration, 0, 1));
}

fn playerActionActive() bool {
    return game.kick.active or game.pickup_action.active;
}

// Defeated: restore the most recent save (or the initial loadout) and move the
// hunter home so the next chase starts fairly.
fn respawnAfterCatch() void {
    if (latestSaveIndex()) |index| {
        placePlayerFromSlot(saves.slots[index]);
    } else {
        const player_spawn = b3.b3Pos{ .x = level.current.player_spawn.x, .y = player_spawn_y, .z = level.current.player_spawn.z };
        game.character = controller.State.init(player_spawn);
        game.character.yaw = std.math.pi;
        game.camera = .{};
        game.quick_turn = .{};
        game.combat = combat.State.init(game.combat_config, game.combat_config.magazine_capacity, game.combat_config.starting_reserve);
        game.inventory = inventory.State.defaultLoadout(game.combat_config.starting_reserve);
        game.collected_pickups = 0;
        game.discovered_items = 0;
        game.broken_boxes = 0;
        game.condition.reset(game.condition_config, game.condition_config.max_health);
    }

    game.player_deformation = .{};
    resetHunter(game.character.position);
    game.notice = .caught;
    game.notice_timer = notice_seconds;
    game.input = .{};
    game.inventory_ui = .{};
    game.interaction_target = null;
    game.kick = .{};
    game.pickup_action = .{};
    game.debris = @splat(.{});
}

// True while the character stands within the interaction area of a typewriter.
fn nearSaveFixture() bool {
    const radius_squared = save_interaction_radius * save_interaction_radius;
    for (level.current.save_fixtures[0..level.current.save_fixture_count]) |fixture| {
        const dx = game.character.position.x - fixture.x;
        const dz = game.character.position.z - fixture.z;
        if (dx * dx + dz * dz <= radius_squared) return true;
    }
    return false;
}

fn openMenu(kind: MenuKind) void {
    game.menu = .{ .kind = kind, .slot = 0 };
    // Drop held keys so gameplay doesn't resume with the character moving.
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
}

fn closeMenu() void {
    game.menu.kind = .none;
    game.input = .{};
}

const InventoryLayout = struct {
    left: f32,
    top: f32,
    cell: f32,
    gap: f32,
};

const ScreenRect = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,

    fn contains(self: ScreenRect, x: f32, y: f32) bool {
        return x >= self.x and y >= self.y and x <= self.x + self.w and y <= self.y + self.h;
    }
};

fn inventoryLayout() InventoryLayout {
    const gap: f32 = 10;
    const cell = std.math.clamp(sapp.heightf() * 0.105, 58, 92);
    const width = cell * @as(f32, @floatFromInt(inventory.columns)) + gap * @as(f32, @floatFromInt(inventory.columns - 1));
    const height = cell * @as(f32, @floatFromInt(inventory.rows)) + gap * @as(f32, @floatFromInt(inventory.rows - 1));
    return .{
        .left = (sapp.widthf() - width) * 0.5,
        .top = (sapp.heightf() - height) * 0.5 + 22,
        .cell = cell,
        .gap = gap,
    };
}

fn inventoryCellRect(layout: InventoryLayout, cell: usize) ScreenRect {
    const column = cell % inventory.columns;
    const row = cell / inventory.columns;
    return .{
        .x = layout.left + @as(f32, @floatFromInt(column)) * (layout.cell + layout.gap),
        .y = layout.top + @as(f32, @floatFromInt(row)) * (layout.cell + layout.gap),
        .w = layout.cell,
        .h = layout.cell,
    };
}

fn inventoryCellAt(x: f32, y: f32) ?usize {
    const layout = inventoryLayout();
    for (0..inventory.cell_count) |cell| if (inventoryCellRect(layout, cell).contains(x, y)) return cell;
    return null;
}

fn inventoryPopupRect(cell: usize) ScreenRect {
    const item_rect = inventoryCellRect(inventoryLayout(), cell);
    const width: f32 = 150;
    const height: f32 = 82;
    var x = item_rect.x + item_rect.w + 12;
    if (x + width > sapp.widthf() - 12) x = item_rect.x - width - 12;
    return .{ .x = x, .y = item_rect.y, .w = width, .h = height };
}

fn openInventory() void {
    game.inventory_ui = .{ .active = true };
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
    sapp.lockMouse(false);
    sapp.showMouse(true);
}

fn closeInventory() void {
    game.inventory_ui = .{};
    game.input = .{};
    sapp.lockMouse(true);
}

fn inventoryClick(x: f32, y: f32) void {
    if (game.inventory_ui.popup_cell) |popup_cell| {
        const popup = inventoryPopupRect(popup_cell);
        if (popup.contains(x, y)) {
            if (y < popup.y + popup.h * 0.5) {
                if (game.inventory.useHealth(
                    popup_cell,
                    &game.condition.health,
                    game.condition_config.max_health,
                    game.condition_config.heal_amount,
                )) {
                    game.notice = .healed;
                } else {
                    game.notice = .full_health;
                }
                game.notice_timer = notice_seconds;
            } else {
                game.inventory_ui.moving_cell = popup_cell;
            }
            game.inventory_ui.popup_cell = null;
            return;
        }
        game.inventory_ui.popup_cell = null;
    }

    const cell = inventoryCellAt(x, y) orelse {
        game.inventory_ui.moving_cell = null;
        return;
    };
    if (game.inventory_ui.moving_cell) |from| {
        _ = game.inventory.moveOrSwap(from, cell);
        game.inventory_ui.moving_cell = null;
        return;
    }
    switch (game.inventory.cells[cell].kind) {
        .empty => {},
        .ammo => game.inventory_ui.moving_cell = cell,
        .health => game.inventory_ui.popup_cell = cell,
    }
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
                .magazine = game.combat.magazine,
                .reserve = game.combat.reserve,
                .health = game.condition.health,
                .inventory = game.inventory,
                .collected_pickups = game.collected_pickups,
                .discovered_items = game.discovered_items,
                .broken_boxes = game.broken_boxes,
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
    const selected = @min(game.map.selected_save, level.current.save_target_count - 1);
    if (level.current.isInSaveRoomIndex(selected, game.character.position.x, game.character.position.z)) {
        game.map.route_status = .arrived;
        return;
    }

    const target = level.current.save_targets[selected];
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

fn mapHalfHeight() f32 {
    return @max(map_min_half_height, map_half_width / (sapp.widthf() / @max(sapp.heightf(), 1)));
}

fn mapWorldAtScreen(screen_x: f32, screen_y: f32) Vec3 {
    const normalized_x = screen_x / @max(sapp.widthf(), 1) * 2.0 - 1.0;
    const normalized_y = screen_y / @max(sapp.heightf(), 1) * 2.0 - 1.0;
    return .{
        .x = game.map.pan.x + normalized_x * map_half_width,
        .z = game.map.pan.z + normalized_y * mapHalfHeight(),
    };
}

fn selectMapSaveAt(screen_x: f32, screen_y: f32) void {
    const world = mapWorldAtScreen(screen_x, screen_y);
    const selected = level.current.saveRoomAt(world.x, world.z) orelse return;
    game.map.selected_save = selected;
    rebuildMapRoute();
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
    const actor_mesh = deformed_box.build();
    game.render.actor_vertex_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&actor_mesh.vertices),
        .label = "character-deformed-actor-vertices",
    });
    game.render.actor_index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&actor_mesh.indices),
        .label = "character-deformed-actor-indices",
    });

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
    game.render.map_save_instances = sg.makeBuffer(.{
        .size = map_save_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-save-instances",
    });
    // The hunter is a second dynamic single-instance buffer, drawn in red.
    game.render.hunter_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-hunter-instance",
    });
    game.render.impact_instances = sg.makeBuffer(.{
        .size = impact_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-combat-impact-instances",
    });
    game.render.pickup_instances = sg.makeBuffer(.{
        .size = world_item_count * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-pickup-instances",
    });
    game.render.map_item_instances = sg.makeBuffer(.{
        .size = world_item_count * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-item-instances",
    });
    game.render.debris_instances = sg.makeBuffer(.{
        .size = debris_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-breakable-debris-instances",
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

    var actor_layout: sg.VertexLayoutState = .{};
    actor_layout.buffers[0].stride = @sizeOf(deformed_box.Vertex);
    actor_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    actor_layout.attrs[shd.ATTR_deformed_display_position] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "position"),
    };
    actor_layout.attrs[shd.ATTR_deformed_display_normal] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "normal"),
    };
    actor_layout.attrs[shd.ATTR_deformed_display_inst_x] = instanceAttr(0);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_y] = instanceAttr(16);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_z] = instanceAttr(32);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_color] = instanceAttr(48);
    game.render.actor_display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.deformedDisplayShaderDesc(sg.queryBackend())),
        .layout = actor_layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        // Strong bends can briefly invert a projected triangle at grazing
        // camera angles. Actors are tiny meshes, so render them double-sided
        // instead of allowing one of their six faces to disappear.
        .cull_mode = .NONE,
        .label = "character-deformed-actor-pipeline",
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

    game.render.reticle_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.reticleShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-aim-reticle-pipeline",
    });
    game.render.ui_rect_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.uiRectShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-inventory-rect-pipeline",
    });
    game.render.hud_circle_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.hudCircleShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-hud-circle-pipeline",
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

    var actor_shadow_layout: sg.VertexLayoutState = .{};
    actor_shadow_layout.buffers[0].stride = @sizeOf(deformed_box.Vertex);
    actor_shadow_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_position] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "position"),
    };
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_x] = instanceAttr(0);
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_y] = instanceAttr(16);
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_z] = instanceAttr(32);
    game.render.actor_shadow_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.deformedShadowShaderDesc(sg.queryBackend())),
        .layout = actor_shadow_layout,
        .depth = .{ .pixel_format = .DEPTH, .write_enabled = true, .compare = .LESS_EQUAL },
        .colors = noColorTargets(),
        .sample_count = 1,
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .label = "character-deformed-actor-shadow-pipeline",
    });

    const light_position = Vec3{ .x = 20, .y = 32, .z = -24 };
    // Directional light = orthographic projection centered on the world origin.
    const light_view = Mat4.lookAtRh(light_position, .{}, .{ .y = 1 });
    const light_projection = Mat4.orthoOffCenterRh(-38, 38, -38, 38, 1, 100);
    game.render.light_view_projection = Mat4.mul(light_view, light_projection);
    game.render.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.045, .b = 0.055, .a = 1 } };
}

fn draw(position: b3.b3Pos, frame_time: f32, gameplay_active: bool) void {
    // Rebuild the character's instance record from its interpolated position.
    const fall = game.condition.fallAmount(game.condition_config);
    const instance = makeYawPitchedInstance(
        .{
            .x = position.x,
            .y = position.y - (character_half_extents.y - character_half_extents.z) * fall,
            .z = position.z,
        },
        character_half_extents,
        game.character.yaw,
        fall * std.math.pi * 0.5,
        rgb(0.20, 0.694, 1.0), // Oxocarbon blue: #33B1FF
    );
    sg.updateBuffer(game.render.character_instance, sg.asRange(&instance));
    const direction_instances = makeMapDirectionInstances(position, game.character.yaw);
    sg.updateBuffer(game.render.map_direction_instances, sg.asRange(&direction_instances));
    var save_instances: [map_save_capacity]Instance = undefined;
    for (level.current.save_targets[0..level.current.save_target_count], 0..) |target, index| {
        const selected = index == game.map.selected_save;
        save_instances[index] = makeScaledInstance(
            .{ .x = target.x, .y = level.floor_height + 0.18, .z = target.z },
            if (selected) .{ .x = 1.2, .y = 0.08, .z = 1.2 } else .{ .x = 0.75, .y = 0.06, .z = 0.75 },
            0,
            if (selected) rgb(1.0, 0.82, 0.22) else rgb(1.0, 0.49, 0.71),
        );
    }
    sg.updateBuffer(game.render.map_save_instances, sg.asRange(save_instances[0..level.current.save_target_count]));
    if (game.debug.draw_physics) updateCapsuleInstances(position);

    // Interpolate during gameplay, but use the authoritative pose while paused
    // so the clock's cycling alpha cannot replay the hunter's last movement.
    const hunter_render = if ((game.map.active and game.map.hunter_paused) or game.menu.kind != .none or game.inventory_ui.active or game.condition.hunter_watch_timer > 0)
        game.hunter.position
    else
        hunter.interpolatedPosition(game.hunter, game.clock.alpha());
    const knocked_down = game.combat.hunterKnockedDown();
    const hunter_center = Vec3{ .x = hunter_render.x, .y = hunter_render.y, .z = hunter_render.z };
    const hunter_render_color = if (game.combat_visuals.hunter_hit_flash > 0)
        rgb(1.0, 0.78, 0.24)
    else if (knocked_down)
        rgb(0.32, 0.045, 0.05)
    else
        hunter_color;
    const hunter_instance = makeInstance(
        hunter_center,
        hunter_half_extents,
        game.hunter.yaw,
        hunter_render_color,
    );
    sg.updateBuffer(game.render.hunter_instance, sg.asRange(&hunter_instance));
    updateImpactInstances();
    updatePickupInstances();

    const player_sample: deformation.Sample = .{
        .position = .{ .x = position.x, .y = position.y, .z = position.z },
        .yaw = game.character.yaw,
        .height = character_half_extents.y * 2.0,
        .max_speed = game.character_config.run_speed,
        .aiming = game.input.aiming,
    };
    const hunter_sample: deformation.Sample = .{
        .position = .{ .x = hunter_render.x, .y = hunter_render.y, .z = hunter_render.z },
        .yaw = game.hunter.yaw,
        .height = hunter_half_extents.y * 2.0,
        .max_speed = game.hunter_config.far_speed,
    };
    const player_pose = if (gameplay_active and game.condition.canMove())
        game.player_deformation.update(game.deformation_config, player_sample, frame_time)
    else blk: {
        game.player_deformation.reset(player_sample);
        break :blk deformation.Pose{};
    };
    var hunter_pose = if (gameplay_active and !knocked_down)
        game.hunter_deformation.update(game.deformation_config, hunter_sample, frame_time)
    else blk: {
        game.hunter_deformation.reset(hunter_sample);
        break :blk deformation.Pose{};
    };
    const flinch = game.hunter_reaction.amount();
    hunter_pose.bend_x += game.hunter_reaction.side * flinch * 0.20;
    hunter_pose.bend_z += flinch * 0.12;
    hunter_pose.twist += game.hunter_reaction.side * flinch * 0.24;
    hunter_pose.foot_roll -= game.hunter_reaction.side * flinch * 0.035;
    const knockdown = hunterKnockdownAmount(game.combat.knockdown_timer, game.combat_config.knockdown_duration);
    const breath_phase = (game.combat_config.knockdown_duration - game.combat.knockdown_timer) * 2.0 * std.math.pi * 0.72;
    const breath = @sin(breath_phase) * knockdown;
    hunter_pose.bend_z += knockdown * 0.82 + breath * 0.035;
    hunter_pose.bend_x += breath * 0.018;
    hunter_pose.twist += breath * 0.025;
    hunter_pose.squash += knockdown * 0.055 + breath * 0.008;
    hunter_pose.foot_pitch += knockdown * 0.045;

    // Pass 1: render everything from the sun's viewpoint, depth-only, to the
    // shadow map. The character draws as a second single-instance call. The
    // roof is skipped in map mode so the interior is lit from above.
    const shadow_params: shd.ShadowVsParams = .{ .light_view_projection = game.render.light_view_projection };
    sg.beginPass(game.render.shadow_pass);
    sg.applyPipeline(game.render.shadow_pipeline);
    sg.applyUniforms(shd.UB_shadow_vs_params, sg.asRange(&shadow_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, game.render.level_instance_count, false);
    if (game.map.active) {
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
        drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    } else {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, false);
        sg.applyPipeline(game.render.actor_shadow_pipeline);
        var actor_shadow_params: shd.DeformedShadowVsParams = .{
            .light_view_projection = game.render.light_view_projection,
            .deformation = poseVector(player_pose),
            .lower_motion = footVector(player_pose),
            .action_motion = actionVector(),
        };
        sg.applyUniforms(shd.UB_deformed_shadow_vs_params, sg.asRange(&actor_shadow_params));
        drawDeformedActor(game.render.character_instance, false);
        actor_shadow_params.deformation = poseVector(hunter_pose);
        actor_shadow_params.lower_motion = footVector(hunter_pose);
        actor_shadow_params.action_motion = .{};
        sg.applyUniforms(shd.UB_deformed_shadow_vs_params, sg.asRange(&actor_shadow_params));
        drawDeformedActor(game.render.hunter_instance, false);
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
    if (!game.map.active) {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, true);
    }
    if (game.map.active) {
        const route_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        if (game.map.route_segment_count > 0) {
            drawInstances(game.render.route_instances, game.render.box_range, 0, game.map.route_segment_count, false);
        }
        drawInstances(game.render.map_save_instances, game.render.box_range, 0, level.current.save_target_count, false);
        if (game.render.map_item_instance_count > 0) {
            drawInstances(game.render.map_item_instances, game.render.box_range, 0, game.render.map_item_instance_count, false);
        }
        drawInstances(game.render.map_direction_instances, game.render.box_range, 0, map_direction_instance_count, false);

        // Map actors use flat instance colors while still writing depth.
        sg.applyPipeline(game.render.map_actor_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
        drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    } else {
        sg.applyPipeline(game.render.actor_display_pipeline);
        sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
        var actor_vs_params: shd.DeformedDisplayVsParams = .{
            .view_projection = game.camera.view_projection,
            .light_view_projection = game.render.light_view_projection,
            .deformation = poseVector(player_pose),
            .lower_motion = footVector(player_pose),
            .action_motion = actionVector(),
        };
        sg.applyUniforms(shd.UB_deformed_display_vs_params, sg.asRange(&actor_vs_params));
        drawDeformedActor(game.render.character_instance, true);
        actor_vs_params.deformation = poseVector(hunter_pose);
        actor_vs_params.lower_motion = footVector(hunter_pose);
        actor_vs_params.action_motion = .{};
        sg.applyUniforms(shd.UB_deformed_display_vs_params, sg.asRange(&actor_vs_params));
        drawDeformedActor(game.render.hunter_instance, true);
    }
    if (!game.map.active and game.render.pickup_instance_count > 0) {
        const pickup_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&pickup_params));
        drawInstances(game.render.pickup_instances, game.render.box_range, 0, game.render.pickup_instance_count, false);
    }
    if (!game.map.active and game.render.debris_instance_count > 0) {
        const debris_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&debris_params));
        drawInstances(game.render.debris_instances, game.render.box_range, 0, game.render.debris_instance_count, false);
    }
    if (!game.map.active and game.render.impact_instance_count > 0) {
        const impact_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&impact_params));
        drawInstances(game.render.impact_instances, game.render.capsule_sphere_range, 0, game.render.impact_instance_count, false);
    }
    sg.applyPipeline(game.render.debug_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    if (game.debug.draw_physics and !game.map.active) {
        drawInstances(game.render.capsule_instances, game.render.capsule_cylinder_range, 0, 1, true);
        drawInstances(game.render.capsule_instances, game.render.capsule_sphere_range, @sizeOf(Instance), 2, true);
    }
    drawReticle();
    drawInventoryRects();
    drawHudShapes();
    drawHud(position);
    sg.endPass();
    sg.commit();
}

fn updatePickupInstances() void {
    var instances: [world_item_count]Instance = undefined;
    var count: usize = 0;
    for (pickup_defs, 0..) |pickup, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.collected_pickups & bit != 0) continue;
        const color = switch (pickup.item.kind) {
            .ammo => rgb(0.15, 0.48, 1.0),
            .health => rgb(0.18, 0.82, 0.37),
            .empty => continue,
        };
        instances[count] = makeInstance(pickup.position, .{ .x = 0.18, .y = 0.18, .z = 0.18 }, 0, color);
        count += 1;
    }
    for (breakable_defs, 0..) |box, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.broken_boxes & bit != 0) continue;
        instances[count] = makeInstance(
            box.position,
            .{ .x = 0.42, .y = 0.42, .z = 0.42 },
            0,
            rgb(1.0, 0.42, 0.06),
        );
        count += 1;
    }
    if (count > 0) sg.updateBuffer(game.render.pickup_instances, sg.asRange(instances[0..count]));
    game.render.pickup_instance_count = count;

    var map_instances: [world_item_count]Instance = undefined;
    var map_count: usize = 0;
    for (pickup_defs, 0..) |pickup, index| {
        const collected_bit = @as(u32, 1) << @intCast(index);
        const discovered_bit = collected_bit;
        if (game.collected_pickups & collected_bit != 0 or !mapItemVisible(discovered_bit)) continue;
        const color = switch (pickup.item.kind) {
            .ammo => rgb(0.15, 0.48, 1.0),
            .health => rgb(0.18, 0.82, 0.37),
            .empty => continue,
        };
        map_instances[map_count] = makeInstance(
            .{ .x = pickup.position.x, .y = level.floor_height + 0.22, .z = pickup.position.z },
            .{ .x = 0.28, .y = 0.06, .z = 0.28 },
            0,
            color,
        );
        map_count += 1;
    }
    for (breakable_defs, 0..) |box, index| {
        const broken_bit = @as(u32, 1) << @intCast(index);
        const discovered_bit = @as(u32, 1) << @intCast(pickup_defs.len + index);
        if (game.broken_boxes & broken_bit != 0 or !mapItemVisible(discovered_bit)) continue;
        map_instances[map_count] = makeInstance(
            .{ .x = box.position.x, .y = level.floor_height + 0.22, .z = box.position.z },
            .{ .x = 0.28, .y = 0.06, .z = 0.28 },
            0,
            rgb(1.0, 0.42, 0.06),
        );
        map_count += 1;
    }
    if (map_count > 0) sg.updateBuffer(game.render.map_item_instances, sg.asRange(map_instances[0..map_count]));
    game.render.map_item_instance_count = map_count;

    var debris_instances: [debris_capacity]Instance = undefined;
    var debris_count: usize = 0;
    for (game.debris) |piece| {
        if (!piece.active) continue;
        debris_instances[debris_count] = makeYawPitchedInstance(
            piece.position,
            .{ .x = 0.11, .y = 0.07, .z = 0.09 },
            piece.yaw,
            piece.pitch,
            rgb(1.0, 0.38, 0.045),
        );
        debris_count += 1;
    }
    if (debris_count > 0) sg.updateBuffer(game.render.debris_instances, sg.asRange(debris_instances[0..debris_count]));
    game.render.debris_instance_count = debris_count;
}

fn updateImpactInstances() void {
    var instances: [impact_capacity]Instance = undefined;
    var count: usize = 0;
    for (game.combat_visuals.impacts) |impact| {
        if (impact.timer <= 0) continue;
        const life = impact.timer / impact_seconds;
        const radius = 0.004 + 0.008 * life;
        instances[count] = makeScaledInstance(
            impact.position,
            .{ .x = radius, .y = radius, .z = radius },
            0,
            rgb(1.0, 0.72, 0.18),
        );
        count += 1;
    }
    if (count > 0) sg.updateBuffer(game.render.impact_instances, sg.asRange(instances[0..count]));
    game.render.impact_instance_count = count;
}

fn drawReticle() void {
    if (game.map.active or game.menu.kind != .none or game.inventory_ui.active or game.camera.aim_alpha <= 0.01 or game.combat.reloading()) return;
    const scale = sapp.heightf() / 1080.0;
    const gap = (48.0 + (14.0 - 48.0) * game.combat.focus) * scale;
    const params: shd.ReticleFsParams = .{
        .resolution = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .color = .{ .x = 0.27, .y = 1.0, .z = 0.29, .w = 0.92 * game.camera.aim_alpha },
        .geometry = .{ .x = gap, .y = 26.0 * scale, .z = 3.0 * scale, .w = 3.0 * scale },
    };
    sg.applyPipeline(game.render.reticle_pipeline);
    sg.applyUniforms(shd.UB_reticle_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

fn drawUiRect(rect: ScreenRect, fill: Vec4, border: Vec4, border_width: f32) void {
    const params: shd.UiRectFsParams = .{
        .viewport = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .rect = .{ .x = rect.x, .y = rect.y, .z = rect.w, .w = rect.h },
        .fill_color = fill,
        .border_color = border,
        .style = .{ .x = border_width },
    };
    sg.applyPipeline(game.render.ui_rect_pipeline);
    sg.applyUniforms(shd.UB_ui_rect_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

fn drawHudCircle(center: math.Vec2, radius: f32, thickness: f32, color: Vec4, with_x: bool) void {
    const params: shd.HudCircleFsParams = .{
        .viewport = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .geometry = .{ .x = center.x, .y = center.y, .z = radius, .w = thickness },
        .color = color,
        .style = .{ .x = fbool(with_x) },
    };
    sg.applyPipeline(game.render.hud_circle_pipeline);
    sg.applyUniforms(shd.UB_hud_circle_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

fn interactionPromptCenter() math.Vec2 {
    return .{ .x = sapp.widthf() * 0.5 - 150, .y = sapp.heightf() * 0.79 };
}

fn mapHoverName() ?[]const u8 {
    if (!game.map.active) return null;
    const world = mapWorldAtScreen(game.map.cursor.x, game.map.cursor.y);
    for (pickup_defs, 0..) |pickup, index| {
        const item_bit = @as(u32, 1) << @intCast(index);
        if (!mapItemVisible(item_bit) or game.collected_pickups & item_bit != 0) continue;
        const dx = world.x - pickup.position.x;
        const dz = world.z - pickup.position.z;
        if (dx * dx + dz * dz <= 0.8 * 0.8) return pickup.name;
    }
    for (breakable_defs, 0..) |box, index| {
        const discovered_bit = @as(u32, 1) << @intCast(pickup_defs.len + index);
        const broken_bit = @as(u32, 1) << @intCast(index);
        if (!mapItemVisible(discovered_bit) or game.broken_boxes & broken_bit != 0) continue;
        const dx = world.x - box.position.x;
        const dz = world.z - box.position.z;
        if (dx * dx + dz * dz <= 0.9 * 0.9) return box.name;
    }
    for (level.current.save_fixtures[0..level.current.save_fixture_count]) |fixture| {
        const dx = world.x - fixture.x;
        const dz = world.z - fixture.z;
        if (dx * dx + dz * dz <= 1.0) return "Typewriter";
    }
    return null;
}

fn mapTooltipRect() ScreenRect {
    const width: f32 = 176;
    const height: f32 = 32;
    return .{
        .x = std.math.clamp(game.map.cursor.x + 20, 8, @max(8, sapp.widthf() - width - 8)),
        .y = std.math.clamp(game.map.cursor.y + 18, 8, @max(8, sapp.heightf() - height - 8)),
        .w = width,
        .h = height,
    };
}

fn drawHudShapes() void {
    if (game.map.active) {
        if (mapHoverName() != null) {
            drawUiRect(
                mapTooltipRect(),
                .{ .x = 0.035, .y = 0.042, .z = 0.048, .w = 0.94 },
                .{ .x = 0.74, .y = 0.76, .z = 0.77, .w = 1 },
                2,
            );
        }
        drawHudCircle(game.map.cursor, 11, 2, .{ .x = 1, .y = 1, .z = 1, .w = 0.95 }, false);
        return;
    }
    const target = game.interaction_target orelse return;
    const center = interactionPromptCenter();
    drawHudCircle(center, 15, 2.2, .{ .x = 1, .y = 1, .z = 1, .w = 0.98 }, true);
    const color = targetColor(target);
    drawUiRect(
        .{ .x = center.x + 27, .y = center.y - 10, .w = 20, .h = 20 },
        color,
        .{ .x = 0.9, .y = 0.9, .z = 0.88, .w = 1 },
        1.5,
    );
}

fn drawInventoryRects() void {
    if (!game.inventory_ui.active) return;
    drawUiRect(
        .{ .x = 0, .y = 0, .w = sapp.widthf(), .h = sapp.heightf() },
        .{ .x = 0.025, .y = 0.032, .z = 0.040, .w = 0.90 },
        .{},
        0,
    );
    const layout = inventoryLayout();
    const grid_width = layout.cell * @as(f32, @floatFromInt(inventory.columns)) + layout.gap * @as(f32, @floatFromInt(inventory.columns - 1));
    const grid_height = layout.cell * @as(f32, @floatFromInt(inventory.rows)) + layout.gap * @as(f32, @floatFromInt(inventory.rows - 1));
    drawUiRect(
        .{ .x = layout.left - 18, .y = layout.top - 18, .w = grid_width + 36, .h = grid_height + 36 },
        .{ .x = 0.08, .y = 0.09, .z = 0.10, .w = 0.98 },
        .{ .x = 0.34, .y = 0.36, .z = 0.37, .w = 1 },
        2,
    );
    for (0..inventory.cell_count) |cell| {
        const rect = inventoryCellRect(layout, cell);
        const selected = game.inventory_ui.moving_cell == cell or game.inventory_ui.popup_cell == cell;
        drawUiRect(
            rect,
            .{ .x = 0.12, .y = 0.13, .z = 0.14, .w = 1 },
            if (selected) .{ .x = 0.95, .y = 0.78, .z = 0.25, .w = 1 } else .{ .x = 0.30, .y = 0.32, .z = 0.33, .w = 1 },
            if (selected) 4 else 2,
        );
        const item = game.inventory.cells[cell];
        if (!item.occupied()) continue;
        const inset: f32 = 9;
        const item_color: Vec4 = switch (item.kind) {
            .ammo => .{ .x = 0.12, .y = 0.43, .z = 0.98, .w = 1 },
            .health => .{ .x = 0.12, .y = 0.76, .z = 0.30, .w = 1 },
            .empty => unreachable,
        };
        drawUiRect(
            .{ .x = rect.x + inset, .y = rect.y + inset, .w = rect.w - inset * 2, .h = rect.h - inset * 2 },
            item_color,
            .{ .x = item_color.x + 0.12, .y = item_color.y + 0.12, .z = @min(item_color.z + 0.12, 1), .w = 1 },
            2,
        );
    }
    if (game.inventory_ui.popup_cell) |cell| {
        const popup = inventoryPopupRect(cell);
        drawUiRect(popup, .{ .x = 0.07, .y = 0.08, .z = 0.09, .w = 1 }, .{ .x = 0.68, .y = 0.70, .z = 0.70, .w = 1 }, 2);
        drawUiRect(
            .{ .x = popup.x + 2, .y = popup.y + popup.h * 0.5 - 1, .w = popup.w - 4, .h = 2 },
            .{ .x = 0.32, .y = 0.34, .z = 0.35, .w = 1 },
            .{},
            0,
        );
    }
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
        sdtx.print("MAP (click save room, WASD pans, P hunter, M exits)", .{});
        sdtx.pos(1.0, 2.2);
        sdtx.print("HUNTER: {s} / {s}", .{
            if (game.map.hunter_paused) "PAUSED" else "MOVING",
            if (game.hunter_friendly) "FRIENDLY" else "HOSTILE",
        });
        sdtx.pos(1.0, 3.4);
        sdtx.print("TARGET SAVE: {d}", .{game.map.selected_save + 1});
        switch (game.map.route_status) {
            .arrived => {
                sdtx.pos(1.0, 4.6);
                sdtx.color3b(80, 250, 123);
                sdtx.print("SAVE ROOM REACHED", .{});
            },
            .no_path => {
                sdtx.pos(1.0, 4.6);
                sdtx.color3b(255, 85, 85);
                sdtx.print("NO SAFE ROUTE", .{});
            },
            else => {},
        }
        if (mapHoverName()) |name| {
            const tooltip = mapTooltipRect();
            sdtx.pos((tooltip.x + 10) / 8.0, (tooltip.y + 8) / 8.0);
            sdtx.color3b(245, 245, 240);
            sdtx.print("{s}", .{name});
        }
    } else {
        if (game.debug.draw_physics) {
            sdtx.pos(1.0, 1.0);
            sdtx.print("POS {d:.1} {d:.1} {d:.1}", .{ position.x, position.y, position.z });
        }
        if (game.hunter_friendly) {
            sdtx.pos(1.0, 2.2);
            sdtx.color3b(80, 250, 123);
            sdtx.print("HUNTER FRIENDLY (F toggles)", .{});
        }
        const ammo_x = @max(1.0, sapp.widthf() / 8.0 - 16.0);
        const ammo_y = @max(1.0, sapp.heightf() / 8.0 - 2.0);
        sdtx.pos(ammo_x, ammo_y);
        if (game.combat.magazine == 0) {
            sdtx.color3b(255, 76, 76);
        } else {
            sdtx.color3b(225, 235, 225);
        }
        sdtx.print("AMMO {d:>2} / {d:>3}", .{ game.combat.magazine, game.combat.reserve });
        sdtx.pos(ammo_x, ammo_y - 2.4);
        if (game.condition.health <= 35) {
            sdtx.color3b(255, 76, 76);
        } else {
            sdtx.color3b(80, 250, 123);
        }
        sdtx.print("HEALTH {d:>3}%", .{@as(u8, @intFromFloat(@round(game.condition.health)))});
        if (game.combat.reloading()) {
            sdtx.pos(ammo_x, ammo_y - 1.2);
            sdtx.color3b(80, 250, 123);
            sdtx.print("RELOADING", .{});
        }
        if (game.interaction_target) |target| {
            const center = interactionPromptCenter();
            sdtx.pos((center.x + 57) / 8.0, (center.y - 5) / 8.0);
            sdtx.color3b(248, 248, 244);
            sdtx.print("{s}", .{targetName(target)});
        }
    }
    switch (game.notice) {
        .caught => drawNotice("CAUGHT - RETURNED TO LAST SAVE", 255, 60, 60),
        .saved => drawNotice("GAME SAVED", 80, 250, 123),
        .deleted => drawNotice("SAVE DELETED", 255, 220, 120),
        .save_failed => drawNotice("SAVE FAILED", 255, 60, 60),
        .hunter_friendly => drawNotice("HUNTER FRIENDLY", 80, 250, 123),
        .hunter_hostile => drawNotice("HUNTER HOSTILE", 255, 85, 85),
        .ammo_found => drawNotice("HANDGUN AMMO ADDED", 70, 135, 255),
        .health_found => drawNotice("HEALING ITEM ADDED", 80, 250, 123),
        .inventory_full => drawNotice("INVENTORY FULL", 255, 220, 120),
        .healed => drawNotice("HEALTH RECOVERED", 80, 250, 123),
        .full_health => drawNotice("HEALTH IS ALREADY FULL", 255, 220, 120),
        .none => {},
    }
    if (game.inventory_ui.active) {
        drawInventoryText();
    } else if (game.menu.kind != .none) {
        drawSaveMenu();
    } else if (!game.map.active and nearSaveFixture()) {
        const prompt = "PRESS SPACE TO SAVE";
        sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(prompt.len)) / 2.0, sapp.heightf() / 8.0 - 2.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print(prompt, .{});
    }
    sdtx.draw();
}

fn drawInventoryText() void {
    const layout = inventoryLayout();
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 5.2);
    sdtx.color3b(230, 230, 225);
    sdtx.print("INVENTORY", .{});
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 3.8);
    sdtx.color3b(80, 250, 123);
    sdtx.print("CONDITION  {d}%", .{@as(u8, @intFromFloat(@round(game.condition.health)))});
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 2.4);
    sdtx.color3b(150, 155, 155);
    sdtx.print("CLICK ITEM, THEN DESTINATION    I / ESC CLOSE", .{});

    for (game.inventory.cells, 0..) |item, cell| {
        if (!item.occupied()) continue;
        const rect = inventoryCellRect(layout, cell);
        sdtx.pos((rect.x + 13) / 8.0, (rect.y + rect.h - 20) / 8.0);
        sdtx.color3b(255, 255, 255);
        switch (item.kind) {
            .ammo => sdtx.print("{d}", .{item.amount}),
            .health => sdtx.print("HEAL", .{}),
            .empty => {},
        }
    }
    if (game.inventory_ui.moving_cell != null) {
        sdtx.pos(layout.left / 8.0, (layout.top + layout.cell * 4 + layout.gap * 3 + 28) / 8.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print("SELECT A DESTINATION CELL", .{});
    }
    if (game.inventory_ui.popup_cell) |cell| {
        const popup = inventoryPopupRect(cell);
        sdtx.color3b(235, 235, 230);
        sdtx.pos((popup.x + 14) / 8.0, (popup.y + 13) / 8.0);
        sdtx.print("USE", .{});
        sdtx.pos((popup.x + 14) / 8.0, (popup.y + popup.h * 0.5 + 13) / 8.0);
        sdtx.print("MOVE", .{});
    }
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

fn poseVector(pose: deformation.Pose) Vec4 {
    return .{ .x = pose.bend_x, .y = pose.bend_z, .z = pose.twist, .w = pose.squash };
}

fn footVector(pose: deformation.Pose) Vec4 {
    return .{ .x = pose.foot_roll, .y = pose.foot_pitch, .z = pose.foot_twist, .w = pose.foot_splay };
}

fn actionVector() Vec4 {
    return .{ .x = kickAmount(), .y = game.pickup_action.amount() };
}

fn drawDeformedActor(instance_buffer: sg.Buffer, with_shadow_texture: bool) void {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = game.render.actor_vertex_buffer;
    bindings.vertex_buffers[1] = instance_buffer;
    bindings.index_buffer = game.render.actor_index_buffer;
    if (with_shadow_texture) {
        bindings.views[shd.VIEW_shadow_map] = game.render.shadow_view;
        bindings.samplers[shd.SMP_shadow_sampler] = game.render.shadow_sampler;
    }
    sg.applyBindings(bindings);
    sg.draw(0, deformed_box.index_count, 1);
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

// Full actor orientation used by the knockdown presentation: pitch happens in
// character-local space, then yaw keeps the fall aligned with the actor.
fn makeYawPitchedInstance(center: Vec3, half: Vec3, yaw: f32, pitch: f32, color: Vec4) Instance {
    const scale = Vec3.scale(half, 2);
    const cy = @cos(yaw);
    const sy = @sin(yaw);
    const cp = @cos(pitch);
    const sp = @sin(pitch);
    return .{
        .x = .{ .x = cy * scale.x, .y = sy * sp * scale.y, .z = sy * cp * scale.z, .w = center.x },
        .y = .{ .y = cp * scale.y, .z = -sp * scale.z, .w = center.y },
        .z = .{ .x = -sy * scale.x, .y = cy * sp * scale.y, .z = cy * cp * scale.z, .w = center.z },
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
    const half_h = mapHalfHeight(); // covers z +-19
    const center = game.map.pan;
    const eye = Vec3{ .x = center.x, .y = 80, .z = center.z };
    const at = Vec3{ .x = center.x, .y = 0, .z = center.z };
    const view = Mat4.lookAtRh(eye, at, .{ .x = 0, .y = 0, .z = -1 });
    const projection = Mat4.orthoOffCenterRh(-map_half_width, map_half_width, -half_h, half_h, 1, 200);
    return Mat4.mul(view, projection);
}

fn fbool(value: bool) f32 {
    return @floatFromInt(@intFromBool(value));
}

fn smoothstep(value: f32) f32 {
    const t = std.math.clamp(value, 0, 1);
    return t * t * (3.0 - 2.0 * t);
}

fn hunterKnockdownAmount(remaining: f32, duration: f32) f32 {
    if (remaining <= 0 or duration <= 0) return 0;
    const elapsed = @max(0, duration - remaining);
    const bend_in = smoothstep(elapsed / hunter_knockdown_enter_seconds);
    const stand_up = smoothstep(remaining / hunter_knockdown_exit_seconds);
    return @min(bend_in, stand_up);
}

fn mapItemVisible(discovery_bit: u32) bool {
    return game.debug.draw_physics or game.discovered_items & discovery_bit != 0;
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

test "keyboard quick turn chooses shortest backward direction" {
    const tolerance: f32 = 0.0001;
    try std.testing.expectApproxEqAbs(std.math.pi, keyboardQuickTurnDelta(false, false), tolerance);
    try std.testing.expectApproxEqAbs(std.math.pi * 0.75, keyboardQuickTurnDelta(true, false), tolerance);
    try std.testing.expectApproxEqAbs(-std.math.pi * 0.75, keyboardQuickTurnDelta(false, true), tolerance);
    // Opposing lateral keys cancel back to a straight 180-degree turn.
    try std.testing.expectApproxEqAbs(std.math.pi, keyboardQuickTurnDelta(true, true), tolerance);
}

test "hunter flinch stops briefly and eases back to neutral" {
    var reaction = HunterReaction{};
    reaction.begin(-1);
    try std.testing.expect(reaction.active());
    reaction.update(hunter_flinch_seconds * 0.18);
    try std.testing.expect(reaction.amount() > 0.99);
    reaction.update(hunter_flinch_seconds);
    try std.testing.expect(!reaction.active());
    try std.testing.expectEqual(@as(f32, 0), reaction.amount());
}

test "hunter knockdown eases into and out of the recovery bend" {
    const duration: f32 = 8;
    try std.testing.expectEqual(@as(f32, 0), hunterKnockdownAmount(duration, duration));
    const entering = hunterKnockdownAmount(duration - hunter_knockdown_enter_seconds * 0.5, duration);
    try std.testing.expect(entering > 0 and entering < 1);
    try std.testing.expectApproxEqAbs(@as(f32, 1), hunterKnockdownAmount(duration - hunter_knockdown_enter_seconds, duration), 0.0001);
    const recovering = hunterKnockdownAmount(hunter_knockdown_exit_seconds * 0.5, duration);
    try std.testing.expect(recovering > 0 and recovering < 1);
    try std.testing.expectEqual(@as(f32, 0), hunterKnockdownAmount(0, duration));
}

test "pickup action commits at contact and finishes after retracting" {
    var action = PickupAction{ .active = true, .target = 3 };
    var events = action.advance(action_contact_time - 0.01);
    try std.testing.expect(!events.collect);
    try std.testing.expect(action.amount() > 0);

    events = action.advance(0.02);
    try std.testing.expect(events.collect);
    try std.testing.expect(!events.finished);
    try std.testing.expectEqual(@as(usize, 3), action.target);

    events = action.advance(action_duration);
    try std.testing.expect(!events.collect);
    try std.testing.expect(events.finished);
    try std.testing.expect(!action.active);
    try std.testing.expectEqual(@as(f32, 0), action.amount());
}

test "authored world items occupy walkable player cells" {
    level.load();
    navmesh.buildLevel();
    for (pickup_defs, 0..) |pickup, index| {
        const cell = navmesh.player_nav.cellAt(pickup.position.x, pickup.position.z) orelse return error.TestUnexpectedResult;
        if (!navmesh.player_nav.isWalkable(cell)) std.debug.print("blocked pickup {d}: ({d}, {d})\n", .{ index, pickup.position.x, pickup.position.z });
        try std.testing.expect(navmesh.player_nav.isWalkable(cell));
        const reachable = navmesh.player_nav.isReachable(
            level.current.player_spawn.x,
            level.current.player_spawn.z,
            pickup.position.x,
            pickup.position.z,
        );
        if (!reachable) std.debug.print("unreachable pickup {d}: ({d}, {d})\n", .{ index, pickup.position.x, pickup.position.z });
        try std.testing.expect(reachable);
    }
}

test "breakable boxes can be approached from the reachable navmesh" {
    level.load();
    navmesh.buildLevel();
    try std.testing.expect(world_item_count <= 32);
    for (breakable_defs, 0..) |box, index| {
        const cell = navmesh.player_nav.nearestWalkable(box.position.x, box.position.z, 4) orelse return error.TestUnexpectedResult;
        const approach = navmesh.player_nav.worldAt(cell);
        const dx = approach.x - box.position.x;
        const dz = approach.z - box.position.z;
        const close_enough = dx * dx + dz * dz <= interaction_radius * interaction_radius;
        if (!close_enough) std.debug.print("unapproachable box {d}: ({d}, {d})\n", .{ index, box.position.x, box.position.z });
        try std.testing.expect(close_enough);
        try std.testing.expect(navmesh.player_nav.isReachable(
            level.current.player_spawn.x,
            level.current.player_spawn.z,
            approach.x,
            approach.z,
        ));
    }
}

test "hunter AI tests" {
    std.testing.refAllDecls(@import("hunter.zig"));
}

test "combat tests" {
    std.testing.refAllDecls(@import("combat.zig"));
}
