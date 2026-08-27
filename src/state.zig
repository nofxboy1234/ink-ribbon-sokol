//! Shared scene state and declarations for the character mover.
//!
//! All subsystems render to and mutate the same runtime state. This module
//! owns the record (types + constants + the `game` value) so the orchestrator,
//! renderer, and UI can depend on it without importing one another. Systems
//! receive `*GameState` by dependency injection and never read a hidden global.

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
const camera = @import("third_person_camera.zig");
const game_audio = @import("game_audio.zig");
const navmesh = @import("navmesh.zig");

const sg = sokol.gfx;
const sshape = sokol.shape;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

/// Boolean -> 0.0/1.0, used to weight short-lived presentation factors.
pub fn fbool(value: bool) f32 {
    return @floatFromInt(@intFromBool(value));
}

/// Smoothstep easing, clamped to [0, 1].
pub fn smoothstep(value: f32) f32 {
    const t = std.math.clamp(value, 0, 1);
    return t * t * (3.0 - 2.0 * t);
}

/// Pack a colour into an opaque Vec4 (alpha = 1).
pub fn rgb(r: f32, g: f32, b: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = 1 };
}

/// Pixel-space layout of the grid inventory, used by both the UI logic and the
/// drawing code.
pub const InventoryLayout = struct {
    left: f32,
    top: f32,
    cell: f32,
    gap: f32,
};

/// Axis-aligned screen rectangle.
pub const ScreenRect = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,

    pub fn contains(self: ScreenRect, x: f32, y: f32) bool {
        return x >= self.x and y >= self.y and x <= self.x + self.w and y <= self.y + self.h;
    }
};

// Physics advances in fixed 1/60 s ticks; the clock accumulates real frame
// time and releases ticks at that rate, so simulation speed is frame-rate
// independent. max_* bounds how much backlog a slow frame may process.
pub const fixed_dt: f64 = 1.0 / 60.0;
pub const max_frame_dt: f64 = 0.1;
pub const max_ticks_per_frame = 6;
pub const shadow_map_size = 2048;
// Half the character box's size along each axis (full size = 2x this).
pub const character_half_extents = Vec3{ .x = 0.32, .y = 0.9, .z = 0.22 };

// The hunter is a larger, red Tyrant-style box.
pub const hunter_half_extents = Vec3{ .x = 0.45, .y = 1.25, .z = 0.30 };
pub const hunter_color = Vec4{ .x = 0.92, .y = 0.12, .z = 0.14, .w = 1 };

// Capsule centre heights match each actor's capsule geometry, so they sit on
// the floor at the room-derived spawn points.
pub const player_spawn_y: f32 = 0.9;
pub const hunter_spawn_y: f32 = 1.5;
pub const save_interaction_radius: f32 = 2.0;

// How long a HUD notice (catch / save result) stays on screen.
pub const notice_seconds: f32 = 3;
pub const impact_capacity = 32;
pub const impact_seconds: f32 = 0.35;
pub const hunter_hit_flash_seconds: f32 = 0.09;
pub const hunter_flinch_seconds: f32 = 0.32;
pub const hunter_knockdown_enter_seconds: f32 = 0.75;
pub const hunter_knockdown_exit_seconds: f32 = 1.15;
pub const shot_recoil_radians: f32 = 0.008;

// Transient centered HUD messages.
pub const HudNotice = enum {
    none,
    caught,
    saved,
    save_failed,
    deleted,
    hunter_friendly,
    hunter_hostile,
    ammo_found,
    health_found,
    key_found,
    inventory_full,
    healed,
    full_health,
    door_locked,
    door_unlocked,
};

// Top-down map view tuning.
pub const map_pan_speed: f32 = 25.0; // metres/second the map pans with WASD
pub const map_margin: f32 = 2.0;
pub const map_route_capacity = navmesh.level_cols * navmesh.level_rows;
pub const map_route_width: f32 = 0.16;
pub const map_route_height: f32 = 0.04;
pub const map_route_danger_radius: f32 = 6.0;
pub const map_route_danger_penalty: f32 = 4.0;
pub const map_direction_color = rgb(0.741, 0.576, 0.976); // Dracula purple #BD93F9
pub const map_direction_instance_count = 3;
pub const map_save_capacity = 2;

pub const PickupDef = struct {
    position: Vec3,
    item: inventory.Item,
    name: []const u8 = "",
};

pub const max_pickups = level.max_pickups;

pub const BreakableDef = struct {
    position: Vec3,
    name: []const u8 = "Wooden Item Box",
    half_extent: f32 = 0.42,
};

pub const max_breakables = level.max_breakables;
pub const world_render_capacity: usize = max_pickups + max_breakables + level.max_doors;
pub const window_render_capacity: usize = @max(level.window_count, 1);
pub const interaction_radius: f32 = 2.0;
pub const door_interaction_radius: f32 = 1.0;
pub const door_limit_radians: f32 = 95.0 * std.math.pi / 180.0;
pub const door_spring_hertz: f32 = 0.65;
pub const door_spring_damping: f32 = 0.8;
pub const door_density: f32 = 1.5;
pub const door_angular_damping: f32 = 0.25;
pub const door_push_impulse: f32 = 3.0;
pub const door_walk_push_strength: f32 = 10.0;
pub const door_run_push_strength: f32 = 16.0;
pub const door_physics_edge_clearance: f32 = 0.05;
pub const door_physics_vertical_clearance: f32 = 0.025;
pub const door_ai_push_cooldown_seconds: f32 = 0.55;
pub const physics_substeps: c_int = 4;
pub const debris_capacity: usize = max_breakables * 8;
pub const debris_seconds: f32 = 4.0;
pub const action_duration: f32 = 0.68;
pub const action_contact_time: f32 = 0.30;
pub const hunter_punch_duration: f32 = 0.58;
pub const hunter_punch_extend_fraction: f32 = 0.18;
pub const hunter_punch_hold_fraction: f32 = 0.16;
pub const box_item_chance: f32 = 0.60;
pub const box_health_share: f32 = 0.25;
pub const box_ammo_amount: u16 = 20;
pub const breakable_half_extent: f32 = 0.42;
pub const audio_buffer_frames = 1024;
pub const audio_channel_count = 2;

pub const InteractionKind = enum { pickup, breakable, box_drop, door };
pub const InteractionTarget = struct {
    kind: InteractionKind,
    index: usize,
};

pub const KickState = struct {
    active: bool = false,
    timer: f32 = 0,
    target: usize = 0,
    broke_box: bool = false,
};

pub const PickupAction = struct {
    const Events = struct {
        collect: bool = false,
        finished: bool = false,
    };

    active: bool = false,
    timer: f32 = 0,
    target: InteractionTarget = .{ .kind = .pickup, .index = 0 },
    committed: bool = false,

    pub fn advance(self: *PickupAction, dt: f32) Events {
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

    pub fn amount(self: PickupAction) f32 {
        if (!self.active) return 0;
        return @sin(std.math.pi * std.math.clamp(self.timer / action_duration, 0, 1));
    }
};

pub const Debris = struct {
    active: bool = false,
    position: Vec3 = .{},
    velocity: Vec3 = .{},
    yaw: f32 = 0,
    pitch: f32 = 0,
    angular_velocity: f32 = 0,
    timer: f32 = 0,
};

pub const Instance = extern struct {
    // One GPU instance record: 3 transform axes (xyz) + origin (w), then color.
    // Matches the vec4 attributes declared in character.glsl (inst_x/y/z/color).
    x: Vec4,
    y: Vec4,
    z: Vec4,
    color: Vec4,
};

pub const Clock = struct {
    accumulator: f64 = 0,

    // Add this frame's duration, clamped so a single slow frame can't flood
    // the physics backlog.
    pub fn addFrame(self: *Clock, frame_time: f64) void {
        self.accumulator += @min(frame_time, max_frame_dt);
    }

    // Pop one fixed tick whenever a full tick's worth of time has accrued.
    pub fn consumeTick(self: *Clock) bool {
        if (self.accumulator < fixed_dt) return false;
        self.accumulator -= fixed_dt;
        return true;
    }

    // Fraction of the way toward the next tick — used to interpolate the
    // character's render position between two physics states.
    pub fn alpha(self: Clock) f32 {
        return @floatCast(self.accumulator / fixed_dt);
    }
};

pub const InputState = struct {
    forward: bool = false,
    back: bool = false,
    left: bool = false,
    right: bool = false,
    run: bool = false,
    aiming: bool = false,
    firing: bool = false,
    reload_queued: bool = false,
    mouse_delta: math.Vec2 = .{},

    pub fn moving(self: InputState) bool {
        return self.forward or self.back or self.left or self.right;
    }

    // Turn held keys into a movement intent. x is strafe (right-left),
    // y is forward-back (positive = toward where the camera looks).
    pub fn characterInput(self: *InputState) controller.Input {
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

pub const Impact = struct {
    position: Vec3 = .{},
    timer: f32 = 0,
};

pub const CombatVisuals = struct {
    impacts: [impact_capacity]Impact = @splat(.{}),
    next_impact: usize = 0,
    hunter_hit_flash: f32 = 0,
};

pub const HunterReaction = struct {
    elapsed: f32 = 0,
    duration: f32 = 0,
    side: f32 = 1,

    pub fn begin(self: *HunterReaction, side: f32) void {
        self.elapsed = 0;
        self.duration = hunter_flinch_seconds;
        self.side = if (side < 0) -1 else 1;
    }

    pub fn update(self: *HunterReaction, dt: f32) void {
        if (!self.active()) return;
        self.elapsed = @min(self.duration, self.elapsed + dt);
    }

    pub fn active(self: HunterReaction) bool {
        return self.elapsed < self.duration;
    }

    pub fn amount(self: HunterReaction) f32 {
        if (!self.active() or self.duration <= 0) return 0;
        const t = std.math.clamp(self.elapsed / self.duration, 0, 1);
        // A fast recoil followed by a longer ease back to the neutral pose.
        if (t < 0.18) return smoothstep(t / 0.18);
        return 1.0 - smoothstep((t - 0.18) / 0.82);
    }
};

pub const HunterPunchAction = struct {
    active: bool = false,
    elapsed: f32 = 0,

    pub fn begin(self: *HunterPunchAction) void {
        self.* = .{ .active = true };
    }

    pub fn update(self: *HunterPunchAction, dt: f32) void {
        if (!self.active) return;
        self.elapsed = @min(hunter_punch_duration, self.elapsed + dt);
        if (self.elapsed >= hunter_punch_duration) self.active = false;
    }

    pub fn amount(self: HunterPunchAction) f32 {
        if (!self.active) return 0;
        const t = std.math.clamp(self.elapsed / hunter_punch_duration, 0, 1);
        if (t < hunter_punch_extend_fraction) return smoothstep(t / hunter_punch_extend_fraction);
        const retract_start = hunter_punch_extend_fraction + hunter_punch_hold_fraction;
        if (t < retract_start) return 1;
        return 1.0 - smoothstep((t - retract_start) / (1.0 - retract_start));
    }
};

pub const DebugState = struct {
    draw_physics: bool = false,
};

pub const MapRouteStatus = enum { none, found, arrived, no_path };

// Typewriter save/load windows. While open they freeze the round exactly like
// map mode does; navigation is keyboard-only.
pub const MenuKind = enum { none, save, load, pause, results };
pub const MenuState = struct {
    kind: MenuKind = .none,
    slot: usize = 0,
    load_returns_to_pause: bool = false,
};

pub const RunStats = struct {
    elapsed_active_seconds: f64 = 0,
    damage_events: u32 = 0,
    deaths: u32 = 0,
};

pub const InventoryUi = struct {
    active: bool = false,
    moving_cell: ?usize = null,
    popup_cell: ?usize = null,
};

// Top-down map overlay state. The route is rebuilt from the current actor poses
// whenever the map opens, then remains fixed while the player is paused.
pub const MapState = struct {
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
pub const QuickTurn = struct {
    active: bool = false,
    timer: f32 = 0,
    duration: f32 = 0.35 / 1.5,
    character_start: f32 = 0,
    character_target: f32 = 0,
    camera_start: f32 = 0,
    camera_target: f32 = 0,
};

pub const RenderState = struct {
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
    window_instances: sg.Buffer = .{},
    debris_instances: sg.Buffer = .{},
    route_instances: sg.Buffer = .{},
    capsule_instances: sg.Buffer = .{},
    level_instance_count: usize = 0,
    roof_instance_count: usize = 0,
    display_pipeline: sg.Pipeline = .{},
    actor_display_pipeline: sg.Pipeline = .{},
    route_pipeline: sg.Pipeline = .{},
    window_pipeline: sg.Pipeline = .{},
    map_item_pipeline: sg.Pipeline = .{},
    map_actor_pipeline: sg.Pipeline = .{},
    debug_pipeline: sg.Pipeline = .{},
    reticle_pipeline: sg.Pipeline = .{},
    ui_rect_pipeline: sg.Pipeline = .{},
    hud_circle_pipeline: sg.Pipeline = .{},
    post_pipeline: sg.Pipeline = .{},
    post_bindings: sg.Bindings = .{},
    scene_pass: sg.Pass = .{},
    scene_color_image: sg.Image = .{},
    scene_depth_image: sg.Image = .{},
    scene_resolve_image: sg.Image = .{},
    scene_color_view: sg.View = .{},
    scene_depth_view: sg.View = .{},
    scene_resolve_view: sg.View = .{},
    scene_texture_view: sg.View = .{},
    scene_sampler: sg.Sampler = .{},
    scene_target_width: i32 = 0,
    scene_target_height: i32 = 0,
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
    window_instance_count: usize = 0,
    debris_instance_count: usize = 0,
};

pub const GameState = struct {
    world: b3.b3WorldId = b3.b3_nullWorldId,
    breakable_bodies: [max_breakables]b3.b3BodyId = @splat(b3.b3_nullBodyId),
    door_bodies: [level.max_doors]b3.b3BodyId = @splat(b3.b3_nullBodyId),
    door_anchor_bodies: [level.max_doors]b3.b3BodyId = @splat(b3.b3_nullBodyId),
    door_joints: [level.max_doors]b3.b3JointId = @splat(b3.b3_nullJointId),
    player_proxy_body: b3.b3BodyId = b3.b3_nullBodyId,
    hunter_proxy_body: b3.b3BodyId = b3.b3_nullBodyId,
    clock: Clock = .{},
    input: InputState = .{},
    debug: DebugState = .{},
    map: MapState = .{},
    menu: MenuState = .{},
    inventory_ui: InventoryUi = .{},
    run_stats: RunStats = .{},
    inventory: inventory.State = .{},
    // Authored world-item layout, rebuilt from the level when it is loaded.
    pickup_count: usize = 0,
    pickup_defs: [max_pickups]PickupDef = undefined,
    breakable_count: usize = 0,
    breakable_defs: [max_breakables]BreakableDef = undefined,
    collected_pickups: u32 = 0,
    discovered_items: u32 = 0,
    broken_boxes: u32 = 0,
    box_drops_present: u32 = 0,
    box_drops_health: u32 = 0,
    collected_box_drops: u32 = 0,
    unlocked_doors: u32 = 0,
    door_previous_angle: [level.max_doors]f32 = @splat(0),
    door_current_angle: [level.max_doors]f32 = @splat(0),
    door_hinge_sign: [level.max_doors]f32 = @splat(-1),
    door_ai_push_cooldown: [level.max_doors]f32 = @splat(0),
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
    hunter_punch: HunterPunchAction = .{},
    condition_config: player_condition.Config = .{},
    condition: player_condition.State = .{},
    deformation_config: deformation.Config = .{},
    player_deformation: deformation.State = .{},
    hunter_deformation: deformation.State = .{},
    hunter_friendly: bool = false,
    // Debug hold (F4): freezes just the hunter's simulation while the player
    // keeps moving, so route and door behaviour can be tested uninterrupted.
    hunter_hold: bool = false,
    audio: game_audio.System = .{},
    audio_buffer: [audio_buffer_frames * audio_channel_count]f32 = @splat(0),
    player_step_distance: f32 = 0,
    hunter_step_distance: f32 = 0,
    // Current transient HUD message and its remaining seconds.
    notice: HudNotice = .none,
    notice_timer: f32 = 0,
    quick_turn: QuickTurn = .{},
    mover_scratch: controller.MoverScratch = .{},
    camera_config: camera.Config = .{},
    camera: camera.State = .{},
    render: RenderState = .{},
};

pub var game: GameState = .{};

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

