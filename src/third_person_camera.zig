const std = @import("std");
const b3 = @import("box3d");
const math = @import("math.zig");
const controller = @import("character_controller.zig");

const Vec3 = math.Vec3;
const Mat4 = math.Mat4;

pub const camera_query_category: u64 = 1 << 2;

pub const Config = struct {
    pivot_height: f32 = 1.35,
    distance: f32 = 3.4,
    shoulder_offset: f32 = 0.65,
    pitch_min: f32 = -0.65,
    pitch_max: f32 = 0.75,
    sensitivity: f32 = 0.0025,
    cast_radius: f32 = 0.18,
    wall_margin: f32 = 0.08,
    follow_rate: f32 = 18.0,
    recovery_rate: f32 = 8.0,
};

pub const State = struct {
    yaw: f32 = std.math.pi,
    pitch: f32 = 0.15,
    pivot: Vec3 = .{},
    eye: Vec3 = .{},
    view_projection: Mat4 = Mat4.identity(),
    basis: controller.Basis = .{},
    initialized: bool = false,
};

pub fn update(
    config: Config,
    state: *State,
    target: b3.b3Pos,
    mouse_delta: math.Vec2,
    world: b3.b3WorldId,
    frame_dt: f32,
    aspect: f32,
) void {
    state.yaw -= mouse_delta.x * config.sensitivity;
    state.pitch = std.math.clamp(
        state.pitch + mouse_delta.y * config.sensitivity,
        config.pitch_min,
        config.pitch_max,
    );

    const target_pivot: Vec3 = .{ .x = target.x, .y = target.y + config.pivot_height, .z = target.z };
    const follow_alpha = exponentialAlpha(config.follow_rate, frame_dt);
    if (!state.initialized) {
        state.pivot = target_pivot;
        state.initialized = true;
    } else {
        state.pivot = lerp(state.pivot, target_pivot, follow_alpha);
    }

    const forward: Vec3 = .{ .x = @sin(state.yaw), .y = 0, .z = @cos(state.yaw) };
    // In this right-handed Y-up world, screen-right is forward cross up.
    const right: Vec3 = .{ .x = -forward.z, .y = 0, .z = forward.x };
    state.basis = .{
        .forward = .{ .x = forward.x, .y = 0, .z = forward.z },
        .right = .{ .x = right.x, .y = 0, .z = right.z },
    };

    const cos_pitch = @cos(state.pitch);
    const back: Vec3 = .{
        .x = -@sin(state.yaw) * cos_pitch,
        .y = @sin(state.pitch),
        .z = -@cos(state.yaw) * cos_pitch,
    };
    const desired_eye = Vec3.add(
        Vec3.add(state.pivot, Vec3.scale(right, config.shoulder_offset)),
        Vec3.scale(back, config.distance),
    );
    const safe_eye = collideCamera(config, world, state.pivot, desired_eye);
    const rate = if (distanceSquared(state.pivot, safe_eye) < distanceSquared(state.pivot, state.eye))
        config.follow_rate
    else
        config.recovery_rate;
    state.eye = if (state.eye.x == 0 and state.eye.y == 0 and state.eye.z == 0)
        safe_eye
    else
        lerp(state.eye, safe_eye, exponentialAlpha(rate, frame_dt));

    const view = Mat4.lookAtRh(state.eye, state.pivot, .{ .y = 1 });
    const projection = Mat4.perspectiveFovRh(math.degreesToRadians(58), aspect, 0.08, 100);
    state.view_projection = Mat4.mul(view, projection);
}

fn collideCamera(config: Config, world: b3.b3WorldId, pivot: Vec3, desired: Vec3) Vec3 {
    var context = CastContext{};
    var point = b3.b3Vec3{};
    var proxy: b3.b3ShapeProxy = .{ .points = &point, .count = 1, .radius = config.cast_radius };
    const translation: b3.b3Vec3 = .{ .x = desired.x - pivot.x, .y = desired.y - pivot.y, .z = desired.z - pivot.z };
    var filter = b3.b3DefaultQueryFilter();
    filter.categoryBits = camera_query_category;
    filter.maskBits = controller.level_category;
    _ = b3.b3World_CastShape(
        world,
        .{ .x = pivot.x, .y = pivot.y, .z = pivot.z },
        &proxy,
        translation,
        filter,
        castResult,
        &context,
    );
    const length = @sqrt(translation.x * translation.x + translation.y * translation.y + translation.z * translation.z);
    const margin_fraction = if (length > 0) config.wall_margin / length else 0;
    const fraction = @max(0, context.fraction - margin_fraction);
    return .{
        .x = pivot.x + translation.x * fraction,
        .y = pivot.y + translation.y * fraction,
        .z = pivot.z + translation.z * fraction,
    };
}

const CastContext = struct { fraction: f32 = 1 };

fn castResult(_: b3.b3ShapeId, _: b3.b3Pos, _: b3.b3Vec3, fraction: f32, _: u64, _: c_int, _: c_int, raw: ?*anyopaque) callconv(.c) f32 {
    const context: *CastContext = @ptrCast(@alignCast(raw.?));
    if (fraction < context.fraction) context.fraction = fraction;
    return context.fraction;
}

fn exponentialAlpha(rate: f32, dt: f32) f32 {
    return 1.0 - @exp(-rate * dt);
}

fn lerp(a: Vec3, b: Vec3, alpha: f32) Vec3 {
    return .{
        .x = a.x + (b.x - a.x) * alpha,
        .y = a.y + (b.y - a.y) * alpha,
        .z = a.z + (b.z - a.z) * alpha,
    };
}

fn distanceSquared(a: Vec3, b: Vec3) f32 {
    const d = Vec3.sub(a, b);
    return Vec3.dot(d, d);
}

test "exponential smoothing is frame-rate independent" {
    const one_step = 1.0 - exponentialAlpha(8, 1.0 / 30.0);
    const two_steps = std.math.pow(f32, 1.0 - exponentialAlpha(8, 1.0 / 60.0), 2);
    try std.testing.expectApproxEqAbs(one_step, two_steps, 0.00001);
}
