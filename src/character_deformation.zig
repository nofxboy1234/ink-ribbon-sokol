//! Procedural secondary motion for the cuboid actors.
//!
//! Gameplay owns the rigid capsule pose. This module samples that pose at
//! render cadence and produces a small bend/twist/squash pose for the GPU.
//! The spring state deliberately trails acceleration and turns, which gives
//! the tall box the weighted, flexible motion seen on RE2R's Tofu character.

const std = @import("std");
const math = @import("math.zig");

const Vec3 = math.Vec3;

pub const Config = struct {
    max_bend: f32 = 0.32,
    max_twist: f32 = 0.40,
    max_squash: f32 = 0.05,
    gait_bend: f32 = 0.14,
    gait_twist: f32 = 0.08,
    movement_lean: f32 = 0.10,
    acceleration_lag: f32 = 0.12,
    turn_lag: f32 = 0.045,
    idle_bend: f32 = 0.025,
    idle_hz: f32 = 0.7,
    spring_hz: f32 = 3.5,
    damping: f32 = 0.55,
    aim_scale: f32 = 0.25,
    aim_max_bend: f32 = 0.06,
    aim_max_twist: f32 = 0.10,
    aim_max_squash: f32 = 0.015,
    aim_spring_hz: f32 = 6.0,
    aim_damping: f32 = 0.90,
    acceleration_reference: f32 = 24.0,
};

pub const Sample = struct {
    position: Vec3,
    yaw: f32,
    height: f32,
    max_speed: f32,
    aiming: bool = false,
};

pub const Pose = extern struct {
    bend_x: f32 = 0,
    bend_z: f32 = 0,
    twist: f32 = 0,
    squash: f32 = 0,
};

const Spring = struct {
    value: f32 = 0,
    velocity: f32 = 0,

    // Stable implicit damped spring. Unlike a naive Euler spring, this remains
    // well behaved through an occasional long render frame.
    fn update(self: *Spring, target: f32, frequency: f32, damping: f32, dt: f32) void {
        const omega = 2.0 * std.math.pi * frequency;
        const f = 1.0 + 2.0 * dt * damping * omega;
        const oo = omega * omega;
        const hoo = dt * oo;
        const hhoo = dt * hoo;
        const inverse = 1.0 / (f + hhoo);
        const old_value = self.value;
        self.value = (f * old_value + dt * self.velocity + hhoo * target) * inverse;
        self.velocity = (self.velocity + hoo * (target - old_value)) * inverse;
    }
};

pub const State = struct {
    initialized: bool = false,
    last_position: Vec3 = .{},
    last_velocity: Vec3 = .{},
    last_yaw: f32 = 0,
    gait_phase: f32 = 0,
    idle_time: f32 = 0,
    bend_x: Spring = .{},
    bend_z: Spring = .{},
    twist: Spring = .{},
    squash: Spring = .{},

    pub fn reset(self: *State, sample: Sample) void {
        self.* = .{
            .initialized = true,
            .last_position = sample.position,
            .last_yaw = sample.yaw,
        };
    }

    pub fn update(self: *State, config: Config, sample: Sample, frame_dt: f32) Pose {
        const dt = std.math.clamp(frame_dt, 0.0001, 0.1);
        if (!self.initialized) self.reset(sample);

        const displacement = Vec3.sub(sample.position, self.last_position);
        const distance = horizontalLength(displacement);
        const velocity = Vec3.scale(displacement, 1.0 / dt);
        const acceleration = Vec3.scale(Vec3.sub(velocity, self.last_velocity), 1.0 / dt);
        const yaw_rate = shortestAngle(sample.yaw - self.last_yaw) / dt;

        const c = @cos(sample.yaw);
        const s = @sin(sample.yaw);
        const local_velocity_x = velocity.x * c - velocity.z * s;
        const local_velocity_z = velocity.x * s + velocity.z * c;
        const local_acceleration_x = acceleration.x * c - acceleration.z * s;
        const local_acceleration_z = acceleration.x * s + acceleration.z * c;
        const speed = horizontalLength(velocity);
        const activity = std.math.clamp(speed / @max(sample.max_speed, 0.001), 0.0, 1.0);

        const stride_length = @max(sample.height * 0.5, 0.1);
        self.gait_phase = @mod(self.gait_phase + distance * 2.0 * std.math.pi / stride_length, 2.0 * std.math.pi);
        self.idle_time += dt;
        const gait = @sin(self.gait_phase);
        const gait_double = @sin(self.gait_phase * 2.0);
        const idle = @sin(self.idle_time * 2.0 * std.math.pi * config.idle_hz) * config.idle_bend;
        const dynamic_scale: f32 = if (sample.aiming) config.aim_scale else 1.0;
        const damping = if (sample.aiming) config.aim_damping else config.damping;
        const spring_hz = if (sample.aiming) config.aim_spring_hz else config.spring_hz;

        const speed_reference = @max(sample.max_speed, 0.001);
        const velocity_x = std.math.clamp(local_velocity_x / speed_reference, -1.0, 1.0);
        const velocity_z = std.math.clamp(local_velocity_z / speed_reference, -1.0, 1.0);
        const acceleration_x = std.math.clamp(local_acceleration_x / config.acceleration_reference, -1.0, 1.0);
        const acceleration_z = std.math.clamp(local_acceleration_z / config.acceleration_reference, -1.0, 1.0);

        var target_x = dynamic_scale * (idle + gait * config.gait_bend * activity +
            velocity_x * config.movement_lean -
            acceleration_x * config.acceleration_lag);
        var target_z = dynamic_scale * (gait_double * config.gait_bend * 0.32 * activity +
            velocity_z * config.movement_lean -
            acceleration_z * config.acceleration_lag);
        clampVectorLength(&target_x, &target_z, config.max_bend);
        const target_twist = std.math.clamp(
            dynamic_scale * (-yaw_rate * config.turn_lag + gait * config.gait_twist * activity),
            -config.max_twist,
            config.max_twist,
        );
        const target_squash = std.math.clamp(
            dynamic_scale * gait_double * config.max_squash * activity,
            -config.max_squash,
            config.max_squash,
        );

        self.bend_x.update(target_x, spring_hz, damping, dt);
        self.bend_z.update(target_z, spring_hz, damping, dt);
        self.twist.update(target_twist, spring_hz, damping, dt);
        self.squash.update(target_squash, spring_hz, damping, dt);

        self.last_position = sample.position;
        self.last_velocity = velocity;
        self.last_yaw = sample.yaw;
        var result = self.pose(config);
        if (sample.aiming) {
            clampVectorLength(&result.bend_x, &result.bend_z, config.aim_max_bend);
            result.twist = std.math.clamp(result.twist, -config.aim_max_twist, config.aim_max_twist);
            result.squash = std.math.clamp(result.squash, -config.aim_max_squash, config.aim_max_squash);
        }
        return result;
    }

    pub fn pose(self: State, config: Config) Pose {
        var bend_x = self.bend_x.value;
        var bend_z = self.bend_z.value;
        clampVectorLength(&bend_x, &bend_z, config.max_bend);
        return .{
            .bend_x = bend_x,
            .bend_z = bend_z,
            .twist = std.math.clamp(self.twist.value, -config.max_twist, config.max_twist),
            .squash = std.math.clamp(self.squash.value, -config.max_squash, config.max_squash),
        };
    }
};

fn shortestAngle(delta: f32) f32 {
    return @mod(delta + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
}

fn horizontalLength(value: Vec3) f32 {
    return @sqrt(value.x * value.x + value.z * value.z);
}

fn clampVectorLength(x: *f32, y: *f32, maximum: f32) void {
    const length_squared = x.* * x.* + y.* * y.*;
    if (length_squared <= maximum * maximum or length_squared == 0) return;
    const scale = maximum / @sqrt(length_squared);
    x.* *= scale;
    y.* *= scale;
}

fn sampleAt(x: f32, z: f32, yaw: f32, aiming: bool) Sample {
    return .{
        .position = .{ .x = x, .y = 0.9, .z = z },
        .yaw = yaw,
        .height = 1.8,
        .max_speed = 5.0,
        .aiming = aiming,
    };
}

test "wrapped yaw does not create a false full turn" {
    var state: State = .{};
    state.reset(sampleAt(0, 0, std.math.pi - 0.01, false));
    const pose = state.update(.{}, sampleAt(0, 0, -std.math.pi + 0.01, false), 1.0 / 60.0);
    try std.testing.expect(@abs(pose.twist) < 0.05);
}

test "aiming suppresses movement deformation" {
    const config: Config = .{};
    var free: State = .{};
    var aimed: State = .{};
    free.reset(sampleAt(0, 0, 0, false));
    aimed.reset(sampleAt(0, 0, 0, true));
    var z: f32 = 0;
    var free_pose: Pose = .{};
    var aimed_pose: Pose = .{};
    for (0..30) |_| {
        z += 5.0 / 60.0;
        free_pose = free.update(config, sampleAt(0, z, 0, false), 1.0 / 60.0);
        aimed_pose = aimed.update(config, sampleAt(0, z, 0, true), 1.0 / 60.0);
    }
    try std.testing.expect(@abs(aimed_pose.bend_z) < @abs(free_pose.bend_z));
    try std.testing.expect(@sqrt(aimed_pose.bend_x * aimed_pose.bend_x + aimed_pose.bend_z * aimed_pose.bend_z) <= config.aim_max_bend);
    try std.testing.expect(@abs(aimed_pose.twist) <= config.aim_max_twist);
}

test "entering aim immediately caps a carried locomotion bend" {
    const config: Config = .{};
    var state: State = .{};
    state.reset(sampleAt(0, 0, 0, false));
    var z: f32 = 0;
    for (0..20) |_| {
        z += 5.0 / 60.0;
        _ = state.update(config, sampleAt(0, z, 0, false), 1.0 / 60.0);
    }
    const aimed = state.update(config, sampleAt(0, z, 0, true), 1.0 / 60.0);
    try std.testing.expect(@sqrt(aimed.bend_x * aimed.bend_x + aimed.bend_z * aimed.bend_z) <= config.aim_max_bend);
    try std.testing.expect(@abs(aimed.twist) <= config.aim_max_twist);
    try std.testing.expect(@abs(aimed.squash) <= config.aim_max_squash);
}

test "deformation is bounded during a rapid turn" {
    const config: Config = .{};
    var state: State = .{};
    state.reset(sampleAt(0, 0, 0, false));
    var pose: Pose = .{};
    for (0..20) |index| {
        const yaw = std.math.pi * @as(f32, @floatFromInt(index + 1)) / 20.0;
        pose = state.update(config, sampleAt(0, 0, yaw, false), 1.0 / 60.0);
    }
    try std.testing.expect(@abs(pose.twist) <= config.max_twist);
    try std.testing.expect(@sqrt(pose.bend_x * pose.bend_x + pose.bend_z * pose.bend_z) <= config.max_bend);
}

test "render-rate chunks converge to the same walking pose" {
    const config: Config = .{};
    var coarse: State = .{};
    var fine: State = .{};
    coarse.reset(sampleAt(0, 0, 0, false));
    fine.reset(sampleAt(0, 0, 0, false));
    var coarse_pose: Pose = .{};
    var fine_pose: Pose = .{};
    for (0..30) |index| {
        const z = 3.0 * @as(f32, @floatFromInt(index + 1)) / 30.0;
        coarse_pose = coarse.update(config, sampleAt(0, z, 0, false), 1.0 / 30.0);
    }
    for (0..120) |index| {
        const z = 3.0 * @as(f32, @floatFromInt(index + 1)) / 120.0;
        fine_pose = fine.update(config, sampleAt(0, z, 0, false), 1.0 / 120.0);
    }
    try std.testing.expectApproxEqAbs(coarse_pose.bend_x, fine_pose.bend_x, 0.015);
    try std.testing.expectApproxEqAbs(coarse_pose.bend_z, fine_pose.bend_z, 0.015);
    try std.testing.expectApproxEqAbs(coarse_pose.twist, fine_pose.twist, 0.015);
    try std.testing.expectApproxEqAbs(coarse_pose.squash, fine_pose.squash, 0.015);
}
