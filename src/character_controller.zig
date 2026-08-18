const std = @import("std");
const b3 = @import("box3d");

pub const Vec2 = struct { x: f32 = 0, y: f32 = 0 };

pub const Basis = struct {
    forward: b3.b3Vec3 = .{ .x = 0, .y = 0, .z = -1 },
    right: b3.b3Vec3 = .{ .x = 1, .y = 0, .z = 0 },
};

pub const Input = struct {
    move: Vec2 = .{},
    run: bool = false,
};

pub const Config = struct {
    walk_speed: f32 = 3.0,
    run_speed: f32 = 5.0,
    acceleration: f32 = 24.0,
    friction: f32 = 12.0,
    gravity: f32 = 15.0,
    turn_speed: f32 = 12.0,
    ground_normal_y: f32 = 0.65,
    capsule_half_segment: f32 = 0.55,
    capsule_radius: f32 = 0.35,
    solve_iterations: u8 = 5,
};

pub const State = struct {
    previous_position: b3.b3Pos,
    position: b3.b3Pos,
    velocity: b3.b3Vec3 = .{},
    yaw: f32 = 0,
    grounded: bool = false,

    pub fn init(position: b3.b3Pos) State {
        return .{ .previous_position = position, .position = position };
    }
};

pub const plane_capacity = 16;

// Query callbacks write into this fixed scratch buffer. Keeping transient planes
// out of State makes the hot character data compact and avoids frame allocations.
pub const MoverScratch = struct {
    planes: [plane_capacity]b3.b3CollisionPlane = @splat(.{}),
    count: usize = 0,
};

pub const player_query_category: u64 = 1 << 1;
pub const level_category: u64 = 1 << 0;

pub fn update(
    config: Config,
    state: *State,
    scratch: *MoverScratch,
    world: b3.b3WorldId,
    input: Input,
    basis: Basis,
    dt: f32,
) void {
    state.previous_position = state.position;

    const move = normalizedInput(input.move);
    const wish = add(scale(basis.forward, move.y), scale(basis.right, move.x));
    const wish_speed = if (input.run) config.run_speed else config.walk_speed;
    const target = scale(wish, wish_speed);

    state.velocity.x = approach(state.velocity.x, target.x, horizontalRate(config, move, dt));
    state.velocity.z = approach(state.velocity.z, target.z, horizontalRate(config, move, dt));
    // Contact planes support the capsule while grounded. Applying gravity here
    // would be clipped along a ramp and continuously create downhill motion.
    if (state.grounded) {
        state.velocity.y = 0;
    } else {
        state.velocity.y -= config.gravity * dt;
    }

    if (lengthSquared(wish) > 0.0001) {
        const target_yaw = std.math.atan2(wish.x, wish.z);
        state.yaw = approachAngle(state.yaw, target_yaw, config.turn_speed * dt);
    }

    const capsule = localCapsule(config);
    const desired_position = offset(state.position, scale(state.velocity, dt));
    var iterations: u8 = 0;
    while (iterations < config.solve_iterations) : (iterations += 1) {
        collectPlanes(scratch, world, state.position, &capsule);
        const target_delta = subPos(desired_position, state.position);
        const solved = b3.b3SolvePlanes(target_delta, &scratch.planes, @intCast(scratch.count));
        const fraction = b3.b3World_CastMover(
            world,
            state.position,
            &capsule,
            solved.delta,
            moverFilter(),
            null,
            null,
        );
        const delta = scale(solved.delta, fraction);
        state.position = offset(state.position, delta);
        if (lengthSquared(delta) < 0.000001) break;
    }

    // Refresh planes at the final pose: these are the contacts used for both
    // grounding and velocity clipping during the next tick.
    collectPlanes(scratch, world, state.position, &capsule);
    state.grounded = false;
    for (scratch.planes[0..scratch.count]) |plane| {
        if (plane.plane.normal.y >= config.ground_normal_y) state.grounded = true;
    }
    state.velocity = b3.b3ClipVector(state.velocity, &scratch.planes, @intCast(scratch.count));
}

pub fn interpolatedPosition(state: State, alpha: f32) b3.b3Pos {
    return .{
        .x = state.previous_position.x + (state.position.x - state.previous_position.x) * alpha,
        .y = state.previous_position.y + (state.position.y - state.previous_position.y) * alpha,
        .z = state.previous_position.z + (state.position.z - state.previous_position.z) * alpha,
    };
}

fn localCapsule(config: Config) b3.b3Capsule {
    return .{
        .center1 = .{ .x = 0, .y = -config.capsule_half_segment, .z = 0 },
        .center2 = .{ .x = 0, .y = config.capsule_half_segment, .z = 0 },
        .radius = config.capsule_radius,
    };
}

fn collectPlanes(scratch: *MoverScratch, world: b3.b3WorldId, origin: b3.b3Pos, capsule: *const b3.b3Capsule) void {
    scratch.count = 0;
    b3.b3World_CollideMover(world, origin, capsule, moverFilter(), collectPlane, scratch);
}

fn collectPlane(_: b3.b3ShapeId, results: [*c]const b3.b3PlaneResult, count: c_int, context: ?*anyopaque) callconv(.c) bool {
    const scratch: *MoverScratch = @ptrCast(@alignCast(context.?));
    var i: usize = 0;
    const result_count: usize = @intCast(count);
    while (i < result_count and scratch.count < plane_capacity) : (i += 1) {
        scratch.planes[scratch.count] = .{
            .plane = results[i].plane,
            .pushLimit = std.math.floatMax(f32),
            .push = 0,
            .clipVelocity = true,
        };
        scratch.count += 1;
    }
    return scratch.count < plane_capacity;
}

fn moverFilter() b3.b3QueryFilter {
    var filter = b3.b3DefaultQueryFilter();
    filter.categoryBits = player_query_category;
    filter.maskBits = level_category;
    return filter;
}

fn normalizedInput(value: Vec2) Vec2 {
    const len_sq = value.x * value.x + value.y * value.y;
    if (len_sq <= 1.0) return value;
    const inv_len = 1.0 / @sqrt(len_sq);
    return .{ .x = value.x * inv_len, .y = value.y * inv_len };
}

fn horizontalRate(config: Config, move: Vec2, dt: f32) f32 {
    const moving = move.x != 0 or move.y != 0;
    return (if (moving) config.acceleration else config.friction) * dt;
}

fn approach(value: f32, target: f32, amount: f32) f32 {
    if (value < target) return @min(value + amount, target);
    return @max(value - amount, target);
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

fn offset(p: b3.b3Pos, v: b3.b3Vec3) b3.b3Pos {
    return .{ .x = p.x + v.x, .y = p.y + v.y, .z = p.z + v.z };
}

fn subPos(a: b3.b3Pos, b: b3.b3Pos) b3.b3Vec3 {
    return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

test "diagonal input is normalized" {
    const value = normalizedInput(.{ .x = 1, .y = 1 });
    try std.testing.expectApproxEqAbs(@as(f32, 1), value.x * value.x + value.y * value.y, 0.0001);
}

test "angle approach takes the shortest path" {
    const result = approachAngle(3.0, -3.0, 0.1);
    try std.testing.expect(result > 3.0);
}
