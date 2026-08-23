const std = @import("std");
const b3 = @import("box3d");
const math = @import("math.zig");
const controller = @import("character_controller.zig");

const Vec3 = math.Vec3;
const Mat4 = math.Mat4;

pub const camera_query_category: u64 = 1 << 2;

pub const Config = struct {
    pivot_height: f32 = 1.35,
    hip_distance: f32 = 3.4,
    aim_distance: f32 = 2.25,
    hip_shoulder_offset: f32 = 0.65,
    aim_shoulder_offset: f32 = 0.78,
    hip_fov_degrees: f32 = 58,
    aim_fov_degrees: f32 = 50,
    aim_transition_rate: f32 = 12,
    pitch_min: f32 = -0.65,
    pitch_max: f32 = 0.75,
    sensitivity: f32 = 0.0025,
    cast_radius: f32 = 0.18,
    wall_margin: f32 = 0.08,
    follow_rate: f32 = 18.0,
    recovery_rate: f32 = 8.0,
    orbit_rate: f32 = 30.0,
};

pub const State = struct {
    yaw: f32 = std.math.pi,
    pitch: f32 = 0.15,
    visual_yaw: f32 = std.math.pi,
    visual_pitch: f32 = 0.15,
    pivot: Vec3 = .{},
    eye: Vec3 = .{},
    view_projection: Mat4 = Mat4.identity(),
    basis: controller.Basis = .{},
    forward: Vec3 = .{ .z = -1 },
    aim_alpha: f32 = 0,
    recoil_pitch: f32 = 0,
    boom_fraction: f32 = 1,
    initialized: bool = false,
};

pub fn update(
    config: Config,
    state: *State,
    target: b3.b3Pos,
    mouse_delta: math.Vec2,
    aiming: bool,
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

    const aim_target: f32 = if (aiming) 1.0 else 0.0;
    state.aim_alpha += (aim_target - state.aim_alpha) * exponentialAlpha(config.aim_transition_rate, frame_dt);
    state.recoil_pitch *= @exp(-10.0 * frame_dt);
    if (@abs(state.recoil_pitch) < 0.00001) state.recoil_pitch = 0;
    const target_pivot: Vec3 = .{ .x = target.x, .y = target.y + config.pivot_height, .z = target.z };
    const follow_alpha = exponentialAlpha(config.follow_rate, frame_dt);
    if (!state.initialized) {
        state.pivot = target_pivot;
        state.visual_yaw = state.yaw;
        state.visual_pitch = state.pitch;
    } else {
        state.pivot = lerp(state.pivot, target_pivot, follow_alpha);
        state.visual_yaw = lerpAngle(state.visual_yaw, state.yaw, exponentialAlpha(config.orbit_rate, frame_dt));
        state.visual_pitch = lerpScalar(state.visual_pitch, state.pitch, exponentialAlpha(config.orbit_rate, frame_dt));
    }

    const forward: Vec3 = .{ .x = @sin(state.visual_yaw), .y = 0, .z = @cos(state.visual_yaw) };
    // In this right-handed Y-up world, screen-right is forward cross up.
    const right: Vec3 = .{ .x = -forward.z, .y = 0, .z = forward.x };
    state.basis = .{
        .forward = .{ .x = forward.x, .y = 0, .z = forward.z },
        .right = .{ .x = right.x, .y = 0, .z = right.z },
    };

    const rendered_pitch = std.math.clamp(state.visual_pitch + state.recoil_pitch, config.pitch_min, config.pitch_max);
    const cos_pitch = @cos(rendered_pitch);
    state.forward = .{
        .x = @sin(state.visual_yaw) * cos_pitch,
        .y = -@sin(rendered_pitch),
        .z = @cos(state.visual_yaw) * cos_pitch,
    };
    const distance = lerpScalar(config.hip_distance, config.aim_distance, state.aim_alpha);
    const shoulder_offset = lerpScalar(config.hip_shoulder_offset, config.aim_shoulder_offset, state.aim_alpha);
    const desired_eye = Vec3.add(
        Vec3.add(state.pivot, Vec3.scale(right, shoulder_offset)),
        Vec3.scale(state.forward, -distance),
    );
    const safe_fraction = collideCameraFraction(config, world, state.pivot, desired_eye);
    if (!state.initialized) state.boom_fraction = safe_fraction;
    const rate = if (safe_fraction < state.boom_fraction)
        config.follow_rate
    else
        config.recovery_rate;
    state.boom_fraction = lerpScalar(state.boom_fraction, safe_fraction, exponentialAlpha(rate, frame_dt));
    state.eye = Vec3.add(state.pivot, Vec3.scale(Vec3.sub(desired_eye, state.pivot), state.boom_fraction));
    state.initialized = true;

    const view = Mat4.lookAtRh(state.eye, Vec3.add(state.eye, state.forward), .{ .y = 1 });
    const fov = lerpScalar(config.hip_fov_degrees, config.aim_fov_degrees, state.aim_alpha);
    const projection = Mat4.perspectiveFovRh(math.degreesToRadians(fov), aspect, 0.08, 100);
    state.view_projection = Mat4.mul(view, projection);
}

pub fn addRecoil(state: *State, amount: f32) void {
    state.recoil_pitch = @max(-0.12, state.recoil_pitch - amount);
}

fn collideCameraFraction(config: Config, world: b3.b3WorldId, pivot: Vec3, desired: Vec3) f32 {
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
    return @max(0, context.fraction - margin_fraction);
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

fn lerpScalar(a: f32, b: f32, alpha: f32) f32 {
    return a + (b - a) * alpha;
}

fn lerpAngle(value: f32, target: f32, alpha: f32) f32 {
    const delta = @mod(target - value + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    return value + delta * alpha;
}

test "exponential smoothing is frame-rate independent" {
    const one_step = 1.0 - exponentialAlpha(8, 1.0 / 30.0);
    const two_steps = std.math.pow(f32, 1.0 - exponentialAlpha(8, 1.0 / 60.0), 2);
    try std.testing.expectApproxEqAbs(one_step, two_steps, 0.00001);
}

test "visual yaw smoothing follows the shortest arc" {
    const result = lerpAngle(3.0, -3.0, 0.5);
    try std.testing.expect(result > 3.0);
}
