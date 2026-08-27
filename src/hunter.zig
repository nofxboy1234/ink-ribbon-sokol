//! Mr X style hunter: an unkillable red stalker that hunts the player.
//!
//! The AI mirrors how the Tyrant behaves in Resident Evil 2 Remake:
//! - He is always present in real space (no teleporting) and navigates the
//!   level like the player. His routes come from a baked navigation mesh
//!   searched with A* (the same approach the RE Engine uses for Mr X), so he
//!   walks through doorways and around furniture instead of cutting corners.
//! - He senses the player through two channels, like the real Mr X:
//!     * Vision: a frontal cone with a raycast for line of sight. Walls and
//!       furniture hide the player — ducking around a corner breaks the lock-on.
//!     * Hearing: running is loud enough to pinpoint through walls, so a sprint
//!       gives away the general area (with error) and he walks over to check.
//!   Walking quietly keeps him guessing.
//! - He moves much faster while far away and slows to a deliberate stride as
//!   he closes in; chasing is faster than walking but slower than sprinting, so
//!   the player can build distance by running — just like the real game.
//! - Once the player escapes his senses for long enough, he gives up and walks
//!   a random patrol route through the level, checking different rooms.
//! - If a path is blocked and he makes no progress toward his goal for a while,
//!   he abandons it: a stuck patrol re-rolls a new destination, and a stuck
//!   chase gives up and briefly searches the player's last known area.

const std = @import("std");
const b3 = @import("box3d");
const controller = @import("character_controller.zig");
const navmesh = @import("navmesh.zig");

// Procedural corridors can meander. Capacity matches the complete fixed nav
// grid, so reconstruction can never reject an otherwise valid simple route.
const path_capacity = navmesh.level_cols * navmesh.level_rows;

pub const Config = struct {
    capsule_half_segment: f32 = 1.0,
    capsule_radius: f32 = 0.5,
    // Mr X's signature gait: a fast stride far away that slows to a menacing
    // stomp as he gets close. Speeds are balanced against the player's originals
    // (walk 3.0 / run 5.0): chasing is faster than walking but slower than
    // sprinting, so the player can build distance by running.
    far_speed: f32 = 5.5,
    near_speed: f32 = 3.0,
    chase_speed: f32 = 4.4,
    close_radius: f32 = 3.5, // within this distance he slows from chase to near
    // Vision: a 120-degree frontal cone. Several rays from his eyes sample the
    // player's full height and width, so partial cover does not make the whole
    // player invisible. Every sample must be blocked to break line of sight.
    detect_radius: f32 = 22.0,
    vision_half_angle: f32 = 60.0 * std.math.pi / 180.0,
    vision_eye_offset: f32 = 0.75,
    player_visibility_half_height: f32 = 0.8,
    player_visibility_half_width: f32 = 0.25,
    // Hearing: a sprint is audible through walls within this radius. The
    // reported position carries error and only refreshes on a cadence, so sound
    // never gives a perfect track through a wall.
    hearing_radius: f32 = 14.0,
    run_speed_threshold: f32 = 4.0,
    hearing_interval: f32 = 1.5,
    hearing_error: f32 = 2.5,
    // He only gives up after give_up_time without any new perception.
    give_up_time: f32 = 4.0,
    // Physically touching the player puts him in punch range.
    contact_radius: f32 = 1.1,
    // Patrol wandering: new random destinations inside the level bounds.
    arrive_radius: f32 = 1.8,
    stuck_time: f32 = 5.0,
    patrol_distance_min: f32 = 10.0,
    patrol_distance_max: f32 = 34.0,
    // Progress of at least this many metres toward the goal counts as "not
    // stuck" and resets the stuck timer.
    progress_threshold: f32 = 0.1,
    // After a chase gets stuck on a blocked path, he gives up and searches the
    // last-known area for this long (deaf to new perceptions so a wall-blocked
    // lock-on can't instantly repeat).
    search_time: f32 = 3.0,
    search_radius_min: f32 = 3.0,
    search_radius_max: f32 = 8.0,
    level_center_x: f32 = 0,
    level_center_z: f32 = 0,
    level_half_x: f32 = 24.0,
    level_half_z: f32 = 17.0,
    turn_speed: f32 = 10.0,
    solve_iterations: u8 = 5,
    gravity: f32 = 15.0,
    ground_normal_y: f32 = 0.65,
    // Path following: how close to a waypoint before advancing, and how often
    // to re-route while chasing (relentlessly) vs. investigating/patrolling.
    waypoint_radius: f32 = 0.4,
    chase_repath_interval: f32 = 0.4,
    investigate_repath_interval: f32 = 0.6,
};

pub const State = struct {
    previous_position: b3.b3Pos,
    position: b3.b3Pos,
    yaw: f32 = 0,
    // Where the hunter believes the player is; refreshed by vision or hearing.
    last_known: b3.b3Pos,
    // True while actively pursuing a player he has SEEN (he locks onto the
    // exact position and chases hard).
    acquired: bool = false,
    acquire_timer: f32 = 0,
    // True while walking toward a spot he only HEARD the player at. He doesn't
    // know the exact position and gives up after investigate_timer.
    investigating: bool = false,
    investigate_timer: f32 = 0,
    // Cadence for hearing reports so a sprint doesn't give a perfect track.
    hearing_timer: f32 = 0,
    // Current destination: the last known player position while chasing or
    // investigating, otherwise a patrol/search point.
    target: b3.b3Pos,
    // Time spent without making progress toward the current goal. When it
    // exceeds Config.stuck_time the hunter abandons the goal.
    stuck_timer: f32 = 0,
    // Distance to the goal at the previous check, used to detect progress.
    last_goal_distance: f32 = 0,
    // Remaining "search the last-known area" period after a chase gets stuck.
    disengage_timer: f32 = 0,
    // The A* route to the current goal, rebuilt as the goal moves.
    path: [path_capacity]b3.b3Pos = undefined,
    path_len: usize = 0,
    path_index: usize = 0,
    // The snapped goal cell the current path was built for.
    path_goal_cell: i64 = -1,
    repath_timer: f32 = 0,
    // True when the last A* attempt found no route; used to re-roll an
    // unreachable patrol/search destination instead of retrying it forever.
    last_path_failed: bool = false,
    // The player's position last tick, to measure their speed for hearing.
    previous_player_position: b3.b3Pos,
    // Phase of the patrolling gaze sweep, used to scan left and right so he
    // notices the player even when they approach from the side.
    scan_timer: f32 = 0,
    vertical_velocity: f32 = 0,
    grounded: bool = false,

    pub fn init(position: b3.b3Pos) State {
        return .{
            .previous_position = position,
            .position = position,
            .last_known = position,
            .target = position,
            .previous_player_position = position,
        };
    }
};

pub fn update(
    config: Config,
    state: *State,
    scratch: *controller.MoverScratch,
    world: b3.b3WorldId,
    player_position: b3.b3Pos,
    dt: f32,
) void {
    state.previous_position = state.position;

    const to_player = subPos(player_position, state.position);
    const player_distance = length(to_player);
    const player_speed = length(subPos(player_position, state.previous_player_position)) / dt;
    state.previous_player_position = player_position;

    // --- Senses: vision first, then hearing (Mr X's two channels) ---
    if (state.hearing_timer > 0) state.hearing_timer -= dt;
    if (state.investigate_timer > 0) state.investigate_timer -= dt;
    if (state.investigating and state.investigate_timer <= 0) state.investigating = false;
    state.scan_timer += dt;

    // After a blocked chase he is briefly deaf so a wall-blocked lock-on can't
    // instantly repeat.
    const sensing = state.disengage_timer <= 0;
    if (state.disengage_timer > 0) {
        state.disengage_timer -= dt;
        if (state.disengage_timer <= 0) state.acquire_timer = 0;
    }

    if (sensing) {
        // While chasing or investigating he stares at his target; while
        // patrolling he slowly sweeps his gaze left and right so a quiet player
        // walking up beside him is still noticed, like Mr X turning his head.
        const gaze_yaw = if (state.acquired or state.investigating)
            state.yaw
        else
            scanYaw(state.yaw, state.scan_timer);
        const seen = player_distance < config.detect_radius and
            inVisionCone(gaze_yaw, to_player, config.vision_half_angle) and
            playerVisible(config, world, state.position, player_position);
        if (seen) {
            // Fresh lock-on: start tracking progress toward this goal from
            // scratch (the previous patrol goal is irrelevant).
            if (!state.acquired) {
                state.stuck_timer = 0;
                state.last_goal_distance = std.math.floatMax(f32);
            }
            state.last_known = player_position;
            state.acquired = true;
            state.investigating = false;
            state.investigate_timer = 0;
            state.acquire_timer = 0;
        } else {
            const heard = player_speed > config.run_speed_threshold and
                player_distance < config.hearing_radius and
                state.hearing_timer <= 0;
            if (heard) {
                // A sprint pinpoints only the general area, with error.
                const error_x = randomRange(-config.hearing_error, config.hearing_error);
                const error_z = randomRange(-config.hearing_error, config.hearing_error);
                state.last_known = offset(player_position, .{ .x = error_x, .y = 0, .z = error_z });
                state.acquired = false;
                state.investigating = true;
                state.investigate_timer = config.search_time;
                state.hearing_timer = config.hearing_interval;
                state.stuck_timer = 0;
                state.last_goal_distance = std.math.floatMax(f32);
                state.acquire_timer = 0;
            } else {
                state.acquire_timer += dt;
                if (state.acquire_timer > config.give_up_time) state.acquired = false;
            }
        }
    }

    var chasing = state.acquired;
    var investigating = state.investigating;
    // Chasing and investigating both aim at the last perceived spot; patrol
    // heads for its own destination.
    var target: b3.b3Pos = if (chasing or investigating) state.last_known else state.target;

    var to_target = subPos(target, state.position);
    to_target.y = 0; // only horizontal progress matters on a flat level
    const target_distance = length(to_target);

    // Stuck detection: meaningful progress (closing in on the goal) resets the
    // timer, so only a genuinely blocked path accumulates it. Reaching a patrol
    // destination also resets it, but then a new destination is picked.
    if (target_distance < state.last_goal_distance - config.progress_threshold or target_distance < config.arrive_radius) {
        state.stuck_timer = 0;
    } else {
        state.stuck_timer += dt;
    }
    state.last_goal_distance = target_distance;

    if (state.stuck_timer > config.stuck_time) {
        // No progress for a long time: the route failed. Give up and start over.
        state.stuck_timer = 0;
        state.last_goal_distance = std.math.floatMax(f32);
        if (chasing) {
            // The path to the player's last known position is blocked. Give up
            // the chase and search the area for a moment instead.
            state.acquired = false;
            state.disengage_timer = config.search_time;
            state.target = searchPoint(config, state.last_known);
            chasing = false;
        } else {
            state.investigating = false;
            state.target = randomPatrolTarget(config, state.position);
        }
        // Route to the fresh destination right away, not on the next timer.
        state.repath_timer = 0;
        state.last_path_failed = false;
        target = state.target;
        investigating = state.investigating;
    } else if (!chasing and target_distance < config.arrive_radius) {
        if (investigating) {
            // Standing at the spot he heard the player: hold still and wait out
            // the search before returning to patrol.
            target = state.position;
        } else {
            state.target = randomPatrolTarget(config, state.position);
            // Route to the new destination right away so there is no pause (and
            // no blind straight-line walk) between patrol legs.
            state.repath_timer = 0;
            state.last_path_failed = false;
            target = state.target;
        }
    }

    var to_goal = subPos(target, state.position);
    to_goal.y = 0;
    const goal_distance = length(to_goal);

    var speed = config.far_speed;
    if (chasing) {
        speed = if (player_distance < config.close_radius) config.near_speed else config.chase_speed;
    } else if (investigating) {
        speed = config.near_speed; // the menacing walk toward a sound
    } else if (goal_distance < config.close_radius) {
        speed = config.near_speed;
    }

    // --- Route: recompute the A* path when the goal moves or it goes stale ---
    if (state.repath_timer > 0) state.repath_timer -= dt;
    const repath_interval = if (chasing) config.chase_repath_interval else config.investigate_repath_interval;

    if (state.path_len == 0) {
        // No route yet (first frame, or the previous goal was unreachable).
        // Retry on the timer instead of every tick, and re-roll an unreachable
        // patrol/search destination right away so we do not keep pathing to it.
        if (state.repath_timer <= 0) {
            if (state.last_path_failed and !chasing) {
                if (investigating) state.investigating = false;
                state.target = randomPatrolTarget(config, state.position);
                target = state.target;
            }
            state.repath_timer = repath_interval;
            const goal_cell = navmesh.level_nav.cellAt(target.x, target.z);
            state.path_goal_cell = if (goal_cell) |cell| @as(i64, @intCast(cell)) else -1;
            state.path_len = navmesh.level_nav.findPath(
                state.position.x,
                state.position.z,
                target.x,
                target.z,
                state.path[0..],
            );
            state.last_path_failed = state.path_len == 0;
            state.path_index = 0;
        }
    } else {
        // A route exists; re-route when it is exhausted, the goal moved to a
        // different cell (a moving player), or the refresh timer elapsed while
        // chasing a moving target. Patrol and investigate goals are fixed, so a
        // fresh route never goes stale and only needs rebuilding on arrival.
        const goal_cell = navmesh.level_nav.cellAt(target.x, target.z);
        const goal_cell_changed = (goal_cell != null) and (state.path_goal_cell >= 0) and
            (@as(i64, @intCast(goal_cell.?)) != state.path_goal_cell);
        if (state.path_index >= state.path_len or goal_cell_changed or (chasing and state.repath_timer <= 0)) {
            state.repath_timer = repath_interval;
            state.path_goal_cell = if (goal_cell) |cell| @as(i64, @intCast(cell)) else -1;
            state.path_len = navmesh.level_nav.findPath(
                state.position.x,
                state.position.z,
                target.x,
                target.z,
                state.path[0..],
            );
            state.last_path_failed = state.path_len == 0;
            state.path_index = 0;
        }
    }

    // --- Move along the route ---
    var move_delta: b3.b3Vec3 = .{};
    // Advance past every waypoint already within reach in this frame, then move
    // toward the next one. Stepping one waypoint per frame without moving would
    // freeze the hunter for a frame at each 0.5 m cell, which looks like a
    // stutter at slow patrol speeds.
    while (true) {
        if (state.path_len == 0 or state.path_index >= state.path_len) {
            // No route (unreachable, or the goal snapped to this cell): go straight.
            if (goal_distance > 0.0001) move_delta = scale(to_goal, speed * dt / goal_distance);
            break;
        }
        const waypoint = state.path[state.path_index];
        var to_waypoint = subPos(waypoint, state.position);
        to_waypoint.y = 0; // waypoints sit on the floor; progress is horizontal
        const waypoint_distance = length(to_waypoint);
        if (waypoint_distance < config.waypoint_radius) {
            state.path_index += 1;
        } else {
            move_delta = scale(to_waypoint, speed * dt / waypoint_distance);
            break;
        }
    }
    applyGravity(config, state, &move_delta, dt);

    const capsule = localCapsule(config);
    controller.moveCapsule(scratch, world, &state.position, &capsule, move_delta, controller.hunterFilter(), config.solve_iterations);
    refreshGrounding(config, state, scratch, world, &capsule);

    // Face the direction of travel, turning gradually like a heavy stalker.
    if (move_delta.x * move_delta.x + move_delta.z * move_delta.z > 0.0001) {
        const target_yaw = std.math.atan2(move_delta.x, move_delta.z);
        state.yaw = approachAngle(state.yaw, target_yaw, config.turn_speed * dt);
    }
}

// Reactions, punches and knockdowns stop the AI's horizontal steering, but
// they must not suspend gravity. This keeps an unsupported hunter subject to
// the same fall as the player even while an animation is holding him still.
pub fn updateIdlePhysics(
    config: Config,
    state: *State,
    scratch: *controller.MoverScratch,
    world: b3.b3WorldId,
    dt: f32,
) void {
    state.previous_position = state.position;
    var move_delta = b3.b3Vec3{};
    applyGravity(config, state, &move_delta, dt);
    const capsule = localCapsule(config);
    controller.moveCapsule(scratch, world, &state.position, &capsule, move_delta, controller.hunterFilter(), config.solve_iterations);
    refreshGrounding(config, state, scratch, world, &capsule);
}

fn applyGravity(config: Config, state: *State, move_delta: *b3.b3Vec3, dt: f32) void {
    if (state.grounded) {
        state.vertical_velocity = 0;
    } else {
        state.vertical_velocity -= config.gravity * dt;
    }
    move_delta.y = state.vertical_velocity * dt;
}

fn refreshGrounding(
    config: Config,
    state: *State,
    scratch: *controller.MoverScratch,
    world: b3.b3WorldId,
    capsule: *const b3.b3Capsule,
) void {
    state.grounded = controller.capsuleGrounded(scratch, world, state.position, capsule, controller.hunterFilter(), config.ground_normal_y);
    if (state.grounded and state.vertical_velocity < 0) state.vertical_velocity = 0;
}

pub fn interpolatedPosition(state: State, alpha: f32) b3.b3Pos {
    return .{
        .x = state.previous_position.x + (state.position.x - state.previous_position.x) * alpha,
        .y = state.previous_position.y + (state.position.y - state.previous_position.y) * alpha,
        .z = state.previous_position.z + (state.position.z - state.previous_position.z) * alpha,
    };
}

// A slow left-right sweep of the gaze while patrolling: over one cycle the
// heading wanders to the left extreme, back through center, to the right, and
// home again, so the hunter regularly glances to both sides of his path.
fn scanYaw(heading: f32, t: f32) f32 {
    const period: f32 = 6.0; // seconds for a full left-right-left cycle
    const amplitude: f32 = 60.0 * std.math.pi / 180.0;
    const u = @mod(t, period) / period; // 0..1 across one cycle
    const sweep = if (u < 0.5) 4.0 * u - 1.0 else 3.0 - 4.0 * u;
    return heading + sweep * amplitude;
}

// True when the direction to the player lies inside the frontal vision cone
// centered on the hunter's facing direction.
fn inVisionCone(facing_yaw: f32, to_player: b3.b3Vec3, half_angle: f32) bool {
    const distance_sq = lengthSquared(to_player);
    if (distance_sq <= 0.0001) return true;
    const facing_x = @sin(facing_yaw);
    const facing_z = @cos(facing_yaw);
    const dot = (to_player.x * facing_x + to_player.z * facing_z) / @sqrt(distance_sq);
    return dot >= @cos(half_angle);
}

// The player is visible while any sampled part of their body can be seen. The
// lateral samples catch shoulders protruding around narrow cover; the vertical
// samples keep waist-high furniture from hiding an exposed head and torso.
fn playerVisible(config: Config, world: b3.b3WorldId, hunter_center: b3.b3Pos, player_center: b3.b3Pos) bool {
    const eye = offset(hunter_center, .{ .y = config.vision_eye_offset });
    var horizontal = subPos(player_center, hunter_center);
    horizontal.y = 0;
    const horizontal_length = length(horizontal);
    const side = if (horizontal_length > 0.0001)
        b3.b3Vec3{ .x = -horizontal.z / horizontal_length, .z = horizontal.x / horizontal_length }
    else
        b3.b3Vec3{ .x = 1 };
    const half_height = config.player_visibility_half_height;
    const half_width = config.player_visibility_half_width;
    const targets = [_]b3.b3Pos{
        offset(player_center, .{ .y = half_height }),
        offset(player_center, .{ .x = side.x * half_width, .y = half_height * 0.45, .z = side.z * half_width }),
        offset(player_center, .{ .x = -side.x * half_width, .y = half_height * 0.45, .z = -side.z * half_width }),
        player_center,
        offset(player_center, .{ .x = side.x * half_width, .y = -half_height * 0.45, .z = side.z * half_width }),
        offset(player_center, .{ .x = -side.x * half_width, .y = -half_height * 0.45, .z = -side.z * half_width }),
        offset(player_center, .{ .y = -half_height }),
    };
    for (targets) |target| {
        if (clearSightRay(world, eye, target)) return true;
    }
    return false;
}

// Level geometry, save-room barriers, and doors occlude vision. Actor proxy
// shapes are excluded by the mask, so the ray reaches the sampled body point.
fn clearSightRay(world: b3.b3WorldId, from: b3.b3Pos, to: b3.b3Pos) bool {
    var filter = b3.b3DefaultQueryFilter();
    filter.maskBits = controller.level_category | controller.hunter_block_category | controller.door_category;
    const ray = b3.b3World_CastRayClosest(world, from, subPos(to, from), filter);
    return !ray.hit;
}

// Deterministic pseudo-random generator for spawns and patrol routes.
var random_state: u32 = 0x12345678;

pub fn seedRandom(seed: u32) void {
    random_state = if (seed == 0) 0x12345678 else seed;
}

pub fn randomRange(min: f32, max: f32) f32 {
    random_state ^= random_state << 13;
    random_state ^= random_state >> 17;
    random_state ^= random_state << 5;
    const unit = @as(f32, @floatFromInt(random_state & 0x00FFFFFF)) / 16777216.0;
    return min + (max - min) * unit;
}

fn localCapsule(config: Config) b3.b3Capsule {
    return .{
        .center1 = .{ .x = 0, .y = -config.capsule_half_segment, .z = 0 },
        .center2 = .{ .x = 0, .y = config.capsule_half_segment, .z = 0 },
        .radius = config.capsule_radius,
    };
}

pub fn randomPatrolTarget(config: Config, origin: b3.b3Pos) b3.b3Pos {
    const angle = randomRange(0, 2.0 * std.math.pi);
    const distance = randomRange(config.patrol_distance_min, config.patrol_distance_max);
    return .{
        .x = std.math.clamp(origin.x + @cos(angle) * distance, config.level_center_x - config.level_half_x, config.level_center_x + config.level_half_x),
        .y = origin.y,
        .z = std.math.clamp(origin.z + @sin(angle) * distance, config.level_center_z - config.level_half_z, config.level_center_z + config.level_half_z),
    };
}

// A point near the player's last known position, used while searching the area
// after a chase gets stuck.
fn searchPoint(config: Config, around: b3.b3Pos) b3.b3Pos {
    const angle = randomRange(0, 2.0 * std.math.pi);
    const distance = randomRange(config.search_radius_min, config.search_radius_max);
    return .{
        .x = std.math.clamp(around.x + @cos(angle) * distance, config.level_center_x - config.level_half_x, config.level_center_x + config.level_half_x),
        .y = around.y,
        .z = std.math.clamp(around.z + @sin(angle) * distance, config.level_center_z - config.level_half_z, config.level_center_z + config.level_half_z),
    };
}

fn approachAngle(value: f32, target: f32, amount: f32) f32 {
    var delta = @mod(target - value + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    delta = std.math.clamp(delta, -amount, amount);
    return value + delta;
}

const add = controller.add;
const scale = controller.scale;
const length = controller.length;
const lengthSquared = controller.lengthSquared;
const offset = controller.offset;
const subPos = controller.subPos;

test "random range stays within bounds" {
    seedRandom(123);
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const value = randomRange(-3.0, 7.0);
        try std.testing.expect(value >= -3.0 and value < 7.0);
    }
}

test "patrol target is clamped to the level" {
    const config: Config = .{};
    const origin = b3.b3Pos{ .x = 23.5, .y = 1.5, .z = 16.5 };
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const target = randomPatrolTarget(config, origin);
        try std.testing.expect(@abs(target.x) <= config.level_half_x);
        try std.testing.expect(@abs(target.z) <= config.level_half_z);
        try std.testing.expectEqual(origin.y, target.y);
    }
}

test "search point stays near the last known location" {
    const config: Config = .{};
    const around = b3.b3Pos{ .x = 3, .y = 1.5, .z = 4 };
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const point = searchPoint(config, around);
        try std.testing.expect(@abs(point.x) <= config.level_half_x);
        try std.testing.expect(@abs(point.z) <= config.level_half_z);
        try std.testing.expectEqual(around.y, point.y);
    }
}

test "angle approach takes the shortest path" {
    const result = approachAngle(3.0, -3.0, 0.1);
    try std.testing.expect(result > 3.0);
}

test "unsupported hunter falls even while AI movement is idle" {
    var world_def = b3.b3DefaultWorldDef();
    const world = b3.b3CreateWorld(&world_def);
    defer b3.b3DestroyWorld(world);

    const config: Config = .{};
    var state = State.init(.{ .y = 1.5 });
    var scratch = controller.MoverScratch{};
    updateIdlePhysics(config, &state, &scratch, world, 0.1);

    try std.testing.expect(!state.grounded);
    try std.testing.expect(state.position.y < 1.5);
    try std.testing.expect(state.vertical_velocity < 0);
}

test "vision cone is frontal" {
    const half = 60.0 * std.math.pi / 180.0;
    try std.testing.expect(inVisionCone(0, .{ .x = 0, .y = 0, .z = 5 }, half)); // dead ahead
    try std.testing.expect(inVisionCone(0, .{ .x = 3, .y = 0, .z = 5 }, half)); // inside the cone
    try std.testing.expect(!inVisionCone(0, .{ .x = 0, .y = 0, .z = -5 }, half)); // behind
    try std.testing.expect(!inVisionCone(0, .{ .x = 5, .y = 0, .z = -1 }, half)); // behind the shoulder
    try std.testing.expect(inVisionCone(std.math.pi, .{ .x = 0, .y = 0, .z = -5 }, half)); // facing -Z
}

test "patrol gaze sweep glances to both sides" {
    // At phase times during one cycle the gaze should reach far left, center,
    // and far right relative to the heading.
    const amp = 60.0 * std.math.pi / 180.0;
    const sweep_at = comptime blk: {
        break :blk .{
            scanYaw(0, 0.0), // start: left extreme
            scanYaw(0, 1.5), // center
            scanYaw(0, 3.0), // right extreme
            scanYaw(0, 4.5), // center again
            scanYaw(0, 6.0), // back at left
        };
    };
    try std.testing.expectApproxEqAbs(@as(f32, -amp), sweep_at[0], 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, 0), sweep_at[1], 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, amp), sweep_at[2], 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, 0), sweep_at[3], 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, -amp), sweep_at[4], 1e-4);
}

test "vision sees partial cover and loses a fully hidden player" {
    var world_def = b3.b3DefaultWorldDef();
    const world = b3.b3CreateWorld(&world_def);
    defer b3.b3DestroyWorld(world);

    const config: Config = .{};
    const hunter_center = b3.b3Pos{ .x = 0, .y = 1.5, .z = 5 };
    const player_center = b3.b3Pos{ .x = 0, .y = 0.9, .z = -5 };

    // A waist-high level-category box leaves the player's upper body visible.
    var body_def = b3.b3DefaultBodyDef();
    body_def.position = .{ .x = 0, .y = 0.5, .z = 0 };
    const low_body = b3.b3CreateBody(world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    shape_def.filter.categoryBits = controller.level_category;
    var low_hull = b3.b3MakeBoxHull(2.0, 0.5, 0.2);
    _ = b3.b3CreateHullShape(low_body, &shape_def, &low_hull.base);
    try std.testing.expect(playerVisible(config, world, hunter_center, player_center));

    // Extending the same cover above every sample fully hides the player.
    b3.b3DestroyBody(low_body);
    body_def.position = .{ .x = 0, .y = 1.5, .z = 0 };
    const tall_body = b3.b3CreateBody(world, &body_def);
    var tall_hull = b3.b3MakeBoxHull(2.0, 1.5, 0.2);
    _ = b3.b3CreateHullShape(tall_body, &shape_def, &tall_hull.base);
    try std.testing.expect(!playerVisible(config, world, hunter_center, player_center));
}
