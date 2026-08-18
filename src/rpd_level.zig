//! Data-oriented RPD station blockout.
//!
//! Geometry stays deliberately coarse. Rendering and collision flags are
//! independent so stairs can render as steps but collide as smooth ramps.

const std = @import("std");
const math = @import("math.zig");
pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

pub const Box = struct {
    center: Vec3,
    half_extents: Vec3,
    color: Vec4,
    pitch: f32 = 0,
    visible: bool = true,
    collidable: bool = true,
};

pub const Staircase = struct {
    lower_center: Vec3,
    width: f32,
    run: f32,
    rise: f32,
    direction_z: f32,
    steps: usize = 12,
};

const floor = rgba(0.20, 0.23, 0.25, 1);
const wall = rgba(0.46, 0.47, 0.49, 1);
const inner = rgba(0.52, 0.52, 0.54, 1);
const stair_color = rgba(0.43, 0.39, 0.34, 1);
const height_scale: f32 = 1.4;
const horizontal_scale: f32 = 1.25;

// Floors are split around the Main Hall atrium and stair openings. A complete
// slab at either upper storey would silently block the collision ramps.
pub const boxes = [_]Box{
    // 1F: entrance/Main Hall and the west/east office wings.
    box(0, -0.25, 0, 22, 0.25, 20, floor),
    box(-22, 5, 0, 0.2, 5, 20, wall),
    box(22, 5, 0, 0.2, 5, 20, wall),
    box(0, 5, -20, 22, 5, 0.2, wall),
    box(-12, 1.75, 20, 10, 1.75, 0.2, wall),
    box(12, 1.75, 20, 10, 1.75, 0.2, wall),
    // Main Hall boundary and its aligned doorway gaps.
    box(-7, 1.5, -17.5, 0.15, 1.5, 2.5, inner),
    box(-7, 1.5, -9.5, 0.15, 1.5, 3.5, inner),
    box(-7, 1.5, 1, 0.15, 1.5, 5, inner),
    box(-7, 1.5, 12.5, 0.15, 1.5, 5.5, inner),
    box(7, 1.5, -17.5, 0.15, 1.5, 2.5, inner),
    box(7, 1.5, -9.5, 0.15, 1.5, 3.5, inner),
    box(7, 1.5, 1, 0.15, 1.5, 5, inner),
    box(7, 1.5, 12.5, 0.15, 1.5, 5.5, inner),
    // Narrow corridors and room-facing walls.
    box(-9, 1.5, -17.5, 0.15, 1.5, 2.5, wall),
    box(-9, 1.5, -9.5, 0.15, 1.5, 3.5, wall),
    box(-9, 1.5, 1, 0.15, 1.5, 5, wall),
    box(-9, 1.5, 12.5, 0.15, 1.5, 5.5, wall),
    box(9, 1.5, -17.5, 0.15, 1.5, 2.5, wall),
    box(9, 1.5, -9.5, 0.15, 1.5, 3.5, wall),
    box(9, 1.5, 1, 0.15, 1.5, 5, wall),
    box(9, 1.5, 12.5, 0.15, 1.5, 5.5, wall),
    // Reception, West Office, Safety Deposit and Operations/Dark Room.
    box(-15.5, 1.5, 8, 6.5, 1.5, 0.15, wall),
    box(-15.5, 1.5, -2, 6.5, 1.5, 0.15, wall),
    box(-15.5, 1.5, -11, 6.5, 1.5, 0.15, wall),
    // East Office, Press Room, Watchman's Room and break-room wing.
    box(15.5, 1.5, 8, 6.5, 1.5, 0.15, wall),
    box(15.5, 1.5, -2, 6.5, 1.5, 0.15, wall),
    box(15.5, 1.5, -11, 6.5, 1.5, 0.15, wall),

    // 2F: Main Hall balcony, Library/Lounge and STARS west; Waiting/Art and
    // Chief's Office/Private Collection east.
    // West and east wing slabs are divided around their stairwell shafts.
    box(-12.5, 3.8, 0, 5.5, 0.2, 20, floor),
    box(-21, 3.8, 0, 1, 0.2, 20, floor),
    box(-19, 3.8, 13.5, 1.4, 0.2, 6.5, floor),
    box(-19, 3.8, -12, 1.4, 0.2, 8, floor),
    box(12.5, 3.8, 0, 5.5, 0.2, 20, floor),
    box(21, 3.8, 0, 1, 0.2, 20, floor),
    box(19, 3.8, 6.5, 1.4, 0.2, 13.5, floor),
    box(19, 3.8, -19, 1.4, 0.2, 1, floor),
    box(0, 3.8, 10, 7, 0.2, 10, floor),
    box(-5, 3.8, -17, 2, 0.2, 3, floor),
    box(5, 3.8, -17, 2, 0.2, 3, floor),
    box(0, 3.8, -7, 7, 0.2, 3, floor),
    box(-7, 5.3, -8.5, 0.15, 1.5, 8.5, inner),
    box(7, 5.3, -8.5, 0.15, 1.5, 8.5, inner),
    box(-7, 5.3, 11, 0.15, 1.5, 9, inner),
    box(7, 5.3, 11, 0.15, 1.5, 9, inner),
    box(-15.5, 5.3, 8, 6.5, 1.5, 0.15, wall),
    box(-15.5, 5.3, -3, 6.5, 1.5, 0.15, wall),
    box(-15.5, 5.3, -12, 6.5, 1.5, 0.15, wall),
    box(-13, 5.3, 2.5, 0.15, 1.5, 5.5, wall),
    box(15.5, 5.3, 8, 6.5, 1.5, 0.15, wall),
    box(15.5, 5.3, -3, 6.5, 1.5, 0.15, wall),
    box(15.5, 5.3, -12, 6.5, 1.5, 0.15, wall),
    box(14, 5.3, 2.5, 0.15, 1.5, 5.5, wall),

    // 3F: upper Main Hall route, West/East Storage and Clock Tower.
    box(-12.5, 7.8, -7, 5.5, 0.2, 13, floor),
    box(-21, 7.8, -7, 1, 0.2, 13, floor),
    box(-19, 7.8, 1, 1.4, 0.2, 5, floor),
    box(-19, 7.8, -17.5, 1.4, 0.2, 2.5, floor),
    box(14.5, 7.8, -7, 7.5, 0.2, 13, floor),
    box(0, 7.8, -16.5, 7, 0.2, 3.5, floor),
    box(-5, 7.8, 1.5, 2, 0.2, 5.5, floor),
    box(5, 7.8, 1.5, 2, 0.2, 5.5, floor),
    box(-7, 9.3, -7, 0.15, 1.5, 13, inner),
    box(7, 9.3, -7, 0.15, 1.5, 13, inner),
    box(-15.5, 9.3, -8, 6.5, 1.5, 0.15, wall),
    box(-15.5, 9.3, -15, 6.5, 1.5, 0.15, wall),
    box(-13, 9.3, -15.5, 0.15, 1.5, 4.5, wall),
    box(15.5, 9.3, -5, 6.5, 1.5, 0.15, wall),
    box(15.5, 9.3, -14, 6.5, 1.5, 0.15, wall),
    box(-17, 9.3, -11.5, 0.15, 1.5, 3.5, inner),
    box(-17.5, 8.8, -17, 2.2, 0.8, 1, rgba(0.35, 0.27, 0.16, 1)),

    // Closed roof. The underside is visible from inside and receives the same
    // warm room lighting as the walls. It also prevents camera escape.
    box(0, 11.25, 0, 22, 0.25, 20, rgba(0.16, 0.17, 0.18, 1)),

    // Scale cues and furniture.
    box(-15, 0.55, 3, 3, 0.55, 0.7, rgba(0.43, 0.28, 0.17, 1)),
    box(-16, 0.9, -7, 0.7, 0.9, 3, rgba(0.25, 0.38, 0.47, 1)),
    box(15, 0.55, 12, 2.6, 0.55, 0.8, rgba(0.40, 0.31, 0.19, 1)),
    box(-16, 4.55, 2, 3, 0.55, 0.8, rgba(0.32, 0.25, 0.16, 1)),
};

pub const staircases = [_]Staircase{
    // Paired grand-stair flights from the Main Hall to 2F.
    .{ .lower_center = .{ .x = -3.8, .z = -4 }, .width = 3.2, .run = 11.5, .rise = 5.5, .direction_z = -1, .steps = 16 },
    .{ .lower_center = .{ .x = 3.8, .z = -4 }, .width = 3.2, .run = 11.5, .rise = 5.5, .direction_z = -1, .steps = 16 },
    // West stairwell links 1F, 2F and 3F.
    .{ .lower_center = .{ .x = -19, .z = 7 }, .width = 2.8, .run = 11, .rise = 5.5, .direction_z = -1, .steps = 15 },
    .{ .lower_center = .{ .x = -19, .y = 5.5, .z = -4 }, .width = 2.8, .run = 11, .rise = 5.5, .direction_z = -1, .steps = 15 },
    // East stair/fire-escape route from 1F to 2F.
    .{ .lower_center = .{ .x = 19, .z = -18 }, .width = 2.8, .run = 11, .rise = 5.5, .direction_z = 1, .steps = 15 },
};

pub const tread_count = count: {
    var result: usize = 0;
    for (staircases) |item| result += item.steps;
    break :count result;
};

pub fn collisionRamp(item: Staircase) Box {
    const scaled_run = item.run * horizontal_scale;
    return .{
        .center = .{ .x = item.lower_center.x * horizontal_scale, .y = item.lower_center.y + item.rise * 0.5 - 0.10, .z = (item.lower_center.z + item.direction_z * item.run * 0.5) * horizontal_scale },
        .half_extents = .{ .x = item.width * horizontal_scale * 0.5, .y = 0.10, .z = @sqrt(scaled_run * scaled_run + item.rise * item.rise) * 0.5 },
        .color = stair_color,
        .pitch = -item.direction_z * std.math.atan(item.rise / scaled_run),
        .visible = false,
    };
}

pub fn tread(item: Staircase, index: usize) Box {
    const step_count: f32 = @floatFromInt(item.steps);
    const fraction = @as(f32, @floatFromInt(index + 1)) / step_count;
    return .{
        .center = .{ .x = item.lower_center.x * horizontal_scale, .y = item.lower_center.y + item.rise * fraction - 0.08, .z = (item.lower_center.z + item.direction_z * item.run * (fraction - 0.5 / step_count)) * horizontal_scale },
        .half_extents = .{ .x = item.width * horizontal_scale * 0.5, .y = 0.08, .z = item.run * horizontal_scale / step_count * 0.5 },
        .color = stair_color,
        .collidable = false,
    };
}

fn box(x: f32, y: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4) Box {
    return .{ .center = .{ .x = x * horizontal_scale, .y = y * height_scale, .z = z * horizontal_scale }, .half_extents = .{ .x = hx * horizontal_scale, .y = hy * height_scale, .z = hz * horizontal_scale }, .color = color };
}

fn rgba(r: f32, g: f32, b: f32, a: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = a };
}
