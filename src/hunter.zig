//! Mr X style hunter: an unkillable red stalker that hunts the player.
//!
//! The AI mirrors how the Tyrant behaves in Resident Evil 2 Remake:
//! - He is always present in real space (no teleporting) and navigates the
//!   level like the player, blocked by walls and furniture.
//! - He moves much faster while far away and slows to a deliberate stride as
//!   he closes in.
//! - He tracks the player's last known position and goes straight for the kill
//!   when he perceives them (line-of-sight radius here standing in for vision
//!   and hearing).
//! - Once the player escapes his senses for long enough, he gives up and walks
//!   a random patrol route through the level, checking different rooms.

const std = @import("std");
const b3 = @import("box3d");
const controller = @import("character_controller.zig");

pub const Config = struct {
    capsule_half_segment: f32 = 1.0,
    capsule_radius: f32 = 0.5,
    // Mr X's signature gait: a fast stride far away that slows to a menacing
    // stomp as he gets close. Speeds are balanced against the player's originals
    // (walk 3.0 / run 5.0): chasing is faster than walking but slower than
    // sprinting, so the player can build distance by running — just like the
    // real game.
    far_speed: f32 = 5.5,
    near_speed: f32 = 3.0,
    chase_speed: f32 = 4.4,
    close_radius: f32 = 3.5, // within this distance he slows from chase to near
    // Senses: he perceives the player inside detect_radius and only gives up
    // after give_up_time without any new perception.
    detect_radius: f32 = 22.0,
    give_up_time: f32 = 4.0,
    // Physically touching the player ends the game.
    contact_radius: f32 = 1.1,
    // Patrol wandering: new random destinations inside the level bounds.
    arrive_radius: f32 = 1.8,
    stuck_time: f32 = 5.0,
    patrol_distance_min: f32 = 10.0,
    patrol_distance_max: f32 = 34.0,
    level_half_x: f32 = 24.0,
    level_half_z: f32 = 17.0,
    turn_speed: f32 = 10.0,
    solve_iterations: u8 = 5,
};

pub const State = struct {
    previous_position: b3.b3Pos,
    position: b3.b3Pos,
    yaw: f32 = 0,
    // Where the hunter believes the player is; refreshed by its senses.
    last_known: b3.b3Pos,
    // True while actively pursuing the player instead of patrolling.
    acquired: bool = false,
    acquire_timer: f32 = 0,
    // Current patrol destination (used while not acquired).
    target: b3.b3Pos,
    arrive_timer: f32 = 0,

    pub fn init(position: b3.b3Pos) State {
        return .{
            .previous_position = position,
            .position = position,
            .last_known = position,
            .target = position,
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

    // Sense the player. Within detect_radius the hunter knows exactly where the
    // player is; outside it he only remembers the last known position, and
    // eventually loses interest and returns to patrolling.
    if (player_distance < config.detect_radius) {
        state.last_known = player_position;
        state.acquired = true;
        state.acquire_timer = 0;
    } else {
        state.acquire_timer += dt;
        if (state.acquire_timer > config.give_up_time) state.acquired = false;
    }

    var target = state.last_known;
    const chasing = state.acquired;
    if (!chasing) {
        // Patrolling: walk to a random destination and pick a new one once it
        // is reached (or once we've been stuck on it for long enough that the
        // destination is clearly unreachable).
        const to_target = subPos(state.target, state.position);
        const arrived = length(to_target) < config.arrive_radius;
        state.arrive_timer += dt;
        if (arrived or state.arrive_timer > config.stuck_time) {
            state.arrive_timer = 0;
            state.target = randomPatrolTarget(config, state.position);
        }
        target = state.target;
    }

    const to_target = subPos(target, state.position);
    const target_distance = length(to_target);

    var speed = config.far_speed;
    if (chasing) {
        speed = if (player_distance < config.close_radius) config.near_speed else config.chase_speed;
    } else if (target_distance < config.close_radius) {
        speed = config.near_speed;
    }

    const move_delta = if (target_distance > 0.0001)
        scale(to_target, speed * dt / target_distance)
    else
        b3.b3Vec3{};

    const capsule = localCapsule(config);
    controller.moveCapsule(scratch, world, &state.position, &capsule, move_delta, controller.hunterFilter(), config.solve_iterations);

    // Face the direction of travel, turning gradually like a heavy stalker.
    if (lengthSquared(move_delta) > 0.0001) {
        const target_yaw = std.math.atan2(to_target.x, to_target.z);
        state.yaw = approachAngle(state.yaw, target_yaw, config.turn_speed * dt);
    }
}

pub fn interpolatedPosition(state: State, alpha: f32) b3.b3Pos {
    return .{
        .x = state.previous_position.x + (state.position.x - state.previous_position.x) * alpha,
        .y = state.previous_position.y + (state.position.y - state.previous_position.y) * alpha,
        .z = state.previous_position.z + (state.position.z - state.previous_position.z) * alpha,
    };
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

fn randomPatrolTarget(config: Config, origin: b3.b3Pos) b3.b3Pos {
    const angle = randomRange(0, 2.0 * std.math.pi);
    const distance = randomRange(config.patrol_distance_min, config.patrol_distance_max);
    return .{
        .x = std.math.clamp(origin.x + @cos(angle) * distance, -config.level_half_x, config.level_half_x),
        .y = origin.y,
        .z = std.math.clamp(origin.z + @sin(angle) * distance, -config.level_half_z, config.level_half_z),
    };
}

fn approachAngle(value: f32, target: f32, amount: f32) f32 {
    var delta = @mod(target - value + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    delta = std.math.clamp(delta, -amount, amount);
    return value + delta;
}

fn add(a: b3.b3Vec3, b: b3.b3Vec3) b3.b3Vec3 {
    return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

fn scale(v: b3.b3Vec3, s: f32) b3.b3Vec3 {
    return .{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

fn lengthSquared(v: b3.b3Vec3) f32 {
    return v.x * v.x + v.y * v.y + v.z * v.z;
}

fn length(v: b3.b3Vec3) f32 {
    return @sqrt(lengthSquared(v));
}

fn offset(p: b3.b3Pos, v: b3.b3Vec3) b3.b3Pos {
    return .{ .x = p.x + v.x, .y = p.y + v.y, .z = p.z + v.z };
}

fn subPos(a: b3.b3Pos, b: b3.b3Pos) b3.b3Vec3 {
    return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

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

test "angle approach takes the shortest path" {
    const result = approachAngle(3.0, -3.0, 0.1);
    try std.testing.expect(result > 3.0);
}