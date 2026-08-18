//! Data-oriented RPD blockout based on the four stacked MapGenie floor plans.
//!
//! Dimensions are authored in metres on one shared grid. Thin boxes form floor
//! slabs and walls; gaps between wall segments are intentional doorways. The
//! four floors deliberately have different footprints, matching the reference.

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
    steps: usize = 16,
};

pub const floor_height: f32 = 5.5;
const wall_half_height: f32 = 2.65;
const wall_half_width: f32 = 0.16;
const slab_half_height: f32 = 0.20;

const floor_color = rgba(0.18, 0.21, 0.23, 1);
const wall_color = rgba(0.43, 0.44, 0.46, 1);
const hall_color = rgba(0.51, 0.50, 0.48, 1);
const roof_color = rgba(0.13, 0.14, 0.15, 1);
const stair_color = rgba(0.42, 0.37, 0.31, 1);

pub const boxes = [_]Box{
    // ---------------------------------------------------------------------
    // 1F — broad full station, projecting entrance and east-side annex.
    // ---------------------------------------------------------------------
    slab(-18, 0, 0, 9, 18), // west offices and records wing
    slab(-7, 0, 0, 2, 18), // west circulation spine
    slab(0, 0, 2, 7, 18), // Main Hall and entrance
    slab(7, 0, 0, 2, 18), // east circulation spine
    slab(17.5, 0, 0, 8.5, 18), // east office/press wing
    slab(22, 0, -22, 4, 4), // watchman's/boiler projection

    // Exterior outline. The south wall has the wide Main Hall entrance.
    wallZ(-27, 0, 0, 18, wall_color),
    wallZ(26, 0, 1, 17, wall_color),
    wallX(-18, 0, -18, 9, wall_color),
    wallX(-2, 0, -18, 7, wall_color),
    wallX(15.5, 0, -18, 10.5, wall_color),
    wallZ(18, 0, -22, 4, wall_color),
    wallZ(26, 0, -22, 4, wall_color),
    wallX(22, 0, -26, 4, wall_color),
    wallX(-17, 0, 18, 10, wall_color),
    wallX(-6, 0, 18, 1, wall_color),
    wallX(6, 0, 18, 1, wall_color),
    wallX(17, 0, 18, 9, wall_color),
    wallZ(-7, 0, 19, 1, hall_color),
    wallZ(7, 0, 19, 1, hall_color),
    wallX(-5, 0, 20, 2, hall_color),
    wallX(5, 0, 20, 2, hall_color),

    // Main Hall enclosure. Split runs reproduce the map's west/east doors.
    wallZ(-9, 0, -15, 3, hall_color),
    wallZ(-9, 0, -7.5, 2.5, hall_color),
    wallZ(-9, 0, 0.5, 3.5, hall_color),
    wallZ(-9, 0, 10.5, 4.5, hall_color),
    wallZ(9, 0, -15, 3, hall_color),
    wallZ(9, 0, -7.5, 2.5, hall_color),
    wallZ(9, 0, 0.5, 3.5, hall_color),
    wallZ(9, 0, 10.5, 4.5, hall_color),
    // Reception/security desks around the central entrance sightline.
    visual(-4.8, 0.65, 8.5, 2.2, 0.65, 0.45, rgba(0.37, 0.26, 0.17, 1)),
    visual(4.8, 0.65, 8.5, 2.2, 0.65, 0.45, rgba(0.37, 0.26, 0.17, 1)),
    visual(0, 0.85, -1, 3.2, 0.85, 1.2, rgba(0.34, 0.31, 0.27, 1)),

    // West: Reception, West Office, Records, Safety Deposit, Operations,
    // Darkroom and the enclosed north-west stair tower.
    wallZ(-12, 0, 13, 5, wall_color),
    wallZ(-12, 0, 2, 4, wall_color),
    wallZ(-12, 0, -11.5, 6.5, wall_color),
    wallX(-19.5, 0, 9, 7.5, wall_color),
    wallX(-19.5, 0, 1, 7.5, wall_color),
    wallX(-19.5, 0, -8, 7.5, wall_color),
    wallZ(-20, 0, 13.5, 4.5, wall_color),
    wallZ(-20, 0, 4.5, 3.5, wall_color),
    wallZ(-20, 0, -13, 5, wall_color),
    wallX(-23.5, 0, 6, 3.5, wall_color),
    wallX(-23.5, 0, -3, 3.5, wall_color),
    solid(-17.5, 0.65, 5, 3.8, 0.65, 0.7, rgba(0.39, 0.27, 0.18, 1)),
    solid(-23, 1.0, -12, 0.7, 1.0, 3.3, rgba(0.24, 0.35, 0.42, 1)),

    // East: East Office, Press Room, bathroom/interrogation side, Watchman's
    // Room and the narrow exterior fire-escape stair strip.
    wallZ(12, 0, 13, 5, wall_color),
    wallZ(12, 0, 2.5, 3.5, wall_color),
    wallZ(12, 0, -12, 6, wall_color),
    wallX(18.5, 0, 9, 6.5, wall_color),
    wallX(18.5, 0, 0, 6.5, wall_color),
    wallX(18.5, 0, -9, 6.5, wall_color),
    wallZ(21, 0, 13.5, 4.5, wall_color),
    wallZ(21, 0, 3, 4, wall_color),
    wallZ(21, 0, -11.5, 6.5, wall_color),
    wallX(23.5, 0, 5, 2.5, wall_color),
    wallX(22, 0, -18, 4, wall_color),
    solid(17.5, 0.65, 11.5, 3.6, 0.65, 0.75, rgba(0.37, 0.28, 0.18, 1)),

    // ---------------------------------------------------------------------
    // 2F — U-shaped gallery around the double-height Main Hall.
    // ---------------------------------------------------------------------
    // Split around the west stair shaft (x=-23, z=-5..7).
    slab(-26, floor_height, 0, 1, 18),
    slab(-15, floor_height, 0, 6, 18),
    slab(-23, floor_height, 12.5, 2, 5.5),
    slab(-23, floor_height, -11.5, 2, 6.5),
    // Split the gallery rails around both grand-stair flights.
    slab(-7, floor_height, 11.5, 2, 6.5),
    slab(-7, floor_height, -13, 2, 5),
    slab(7, floor_height, 11.5, 2, 6.5),
    slab(7, floor_height, -13, 2, 5),
    // Split around the east fire stair (x=23, z=-15..-4).
    slab(13.8, floor_height, 0, 4.8, 18),
    slab(25.2, floor_height, 0, 0.8, 18),
    slab(23, floor_height, 7, 1.4, 11),
    slab(23, floor_height, -16.5, 1.4, 1.5),
    slab(0, floor_height, -14, 7, 4), // north bridge/Lounge
    slab(0, floor_height, 16, 7, 2), // south gallery/entrance overlook
    // One continuous strip prevents seams between the independently blocked
    // north bridge and room-wing slabs. The reference map shows this corridor
    // as an uninterrupted east-west route.
    slab(-0.5, floor_height, -12, 26.5, 4),

    // Main Hall gallery edges follow the long central void shown on 2F.
    // Leave a broad north opening around z=-12. The previous rail reached to
    // z=-10 and formed a tight stagger with the outer wall that could trap the
    // capsule between two collision planes.
    wallZ(-5, floor_height, 3, 9, hall_color),
    wallZ(5, floor_height, 3, 9, hall_color),
    wallX(0, floor_height, -10, 5, hall_color),
    wallX(-3.5, floor_height, 12, 1.5, hall_color),
    wallX(3.5, floor_height, 12, 1.5, hall_color),
    wallZ(-9, floor_height, -17.5, 0.5, wall_color),
    wallZ(-9, floor_height, -7, 3, wall_color),
    wallZ(-9, floor_height, 4, 6, wall_color),
    wallZ(-9, floor_height, 15.5, 2.5, wall_color),
    wallZ(9, floor_height, -17.5, 0.5, wall_color),
    wallZ(9, floor_height, -7, 3, wall_color),
    wallZ(9, floor_height, 4, 6, wall_color),
    wallZ(9, floor_height, 15.5, 2.5, wall_color),

    // West 2F: Library fills the south-west block; Linen/Lounge, Shower and
    // STARS form the narrower northern chain from the reference map.
    wallX(-18, floor_height, 10, 9, wall_color),
    wallX(-18, floor_height, 0, 9, wall_color),
    // Split around the west stair shaft. The previous full run crossed the
    // landing and prevented approaching the upper ramp from its lower end.
    wallX(-26, floor_height, -8, 1, wall_color),
    wallX(-13.5, floor_height, -8, 4.5, wall_color),
    wallZ(-14, floor_height, 14, 4, wall_color),
    wallZ(-14, floor_height, 4, 4, wall_color),
    // Broad south doorway prevents the capsule catching on the partition end
    // while turning from the north gallery into the west stair tower.
    wallZ(-19, floor_height, -14, 4, wall_color),
    // Split around the west stair flight at x=-23. A single wall here crossed
    // the ramp at z=-13 and made the otherwise valid 2F -> 3F route impassable.
    wallX(-25.75, floor_height, -13, 1.25, wall_color),
    wallX(-20.25, floor_height, -13, 1.25, wall_color),
    // Library shelves are visual scale cues but remain collidable cover.
    solid(-21, floor_height + 1, 5, 0.55, 1, 3.5, rgba(0.29, 0.25, 0.20, 1)),
    solid(-17.5, floor_height + 1, 5, 0.55, 1, 3.5, rgba(0.29, 0.25, 0.20, 1)),

    // East 2F: Waiting Room/Art Room and Chief's Office/Private Collection.
    wallX(17.5, floor_height, 9, 8.5, wall_color),
    wallX(17.5, floor_height, 0, 8.5, wall_color),
    wallX(17.5, floor_height, -9, 8.5, wall_color),
    wallZ(14, floor_height, 13.5, 4.5, wall_color),
    wallZ(14, floor_height, 4, 3, wall_color),
    wallZ(20, floor_height, -13, 5, wall_color),
    wallX(23, floor_height, -13, 3, wall_color),
    solid(18, floor_height + 0.7, -4, 3.4, 0.7, 0.7, rgba(0.31, 0.25, 0.19, 1)),

    // ---------------------------------------------------------------------
    // 3F — much smaller west Clock Tower/storage loop and east roof wing.
    // ---------------------------------------------------------------------
    // The 3F west footprint is split around the upper west-stair flight.
    slab(-26, 2 * floor_height, -3, 1, 15),
    slab(-15, 2 * floor_height, -3, 6, 15),
    slab(-23, 2 * floor_height, 3.5, 2, 8.5),
    slab(-23, 2 * floor_height, -16.5, 2, 1.5),
    slab(-8, 2 * floor_height, -10, 1, 6),
    // Open Main Hall balcony. It joins the west stair route to the narrow
    // bridge while leaving the three-storey atrium below unobstructed.
    slab(-4, 2 * floor_height, -13, 5, 3),
    slab(2, 2 * floor_height, -13, 1, 3),
    slab(8, 2 * floor_height, -7, 3, 9),
    slab(17, 2 * floor_height, -8, 6, 8),

    // West Storage outer loop and Clock Tower inner chamber.
    wallZ(-25, 2 * floor_height, -2, 14, wall_color),
    wallX(-17, 2 * floor_height, -18, 8, wall_color),
    wallX(-17, 2 * floor_height, 12, 8, wall_color),
    wallZ(-9, 2 * floor_height, 6, 6, wall_color),
    // Door-sized break from West Storage onto the Main Hall balcony.
    wallZ(-9, 2 * floor_height, -8.5, 2.5, wall_color),
    wallZ(-9, 2 * floor_height, -17, 1, wall_color),
    wallX(-17, 2 * floor_height, 5, 6, wall_color),
    wallX(-17, 2 * floor_height, -6, 6, wall_color),
    wallZ(-21, 2 * floor_height, 8, 3, wall_color),
    wallZ(-21, 2 * floor_height, -11, 5, wall_color),
    wallZ(-13, 2 * floor_height, 8.5, 3.5, hall_color),
    wallZ(-13, 2 * floor_height, -1, 4, hall_color),
    wallX(-17, 2 * floor_height, -5, 4, hall_color),
    // Clock machinery blockout.
    solid(-17, 2 * floor_height + 1.2, 0, 3.2, 1.2, 1.1, rgba(0.34, 0.25, 0.15, 1)),

    // A waist-high rail keeps the balcony edge open to the Main Hall view.
    railX(-4, 2 * floor_height, -10, 5, hall_color),

    // Narrow bridge and east storage/roof access wing.
    wallX(-4, 2 * floor_height, -16, 5, wall_color),
    wallX(5, 2 * floor_height, -10, 4, wall_color),
    wallZ(5, 2 * floor_height, -6, 4, wall_color),
    wallZ(11, 2 * floor_height, -7, 5, wall_color),
    wallZ(23, 2 * floor_height, -8, 8, wall_color),
    wallX(17, 2 * floor_height, -16, 6, wall_color),
    wallX(17, 2 * floor_height, 0, 6, wall_color),
    wallX(17, 2 * floor_height, -7, 6, wall_color),

    // 3F roof pieces close lower wings while leaving the Clock Tower stair
    // shaft open to its small 4F platform.
    // Roof pieces leave x=-17, z=-2..8 open for the 4F stair shaft.
    ceiling(-22, 3 * floor_height, 6, 3, 6),
    ceiling(-13, 3 * floor_height, 6, 2, 6),
    ceiling(-17, 3 * floor_height, 10, 2, 2),
    ceiling(-18, 3 * floor_height, -11, 7, 5),
    ceiling(-10, 3 * floor_height, -10, 1, 6),
    ceiling(3, 3 * floor_height, -11, 5, 5),
    ceiling(17, 3 * floor_height, -8, 6, 8),

    // ---------------------------------------------------------------------
    // 4F — the small upper Clock Tower machinery platform only.
    // ---------------------------------------------------------------------
    // Side strips and a north landing leave the incoming ramp unobstructed.
    slab(-19.65, 3 * floor_height, 0, 1.35, 3),
    slab(-14.35, 3 * floor_height, 0, 1.35, 3),
    slab(-17, 3 * floor_height, -2.5, 1.3, 0.5),
    wallZ(-21, 3 * floor_height, 0, 3, wall_color),
    wallZ(-13, 3 * floor_height, 0, 3, wall_color),
    wallX(-17, 3 * floor_height, -3, 4, wall_color),
    wallX(-19, 3 * floor_height, 3, 2, wall_color),
    wallX(-14, 3 * floor_height, 3, 1, wall_color),
    ceiling(-17, 4 * floor_height, 0, 4, 3),
};

pub const staircases = [_]Staircase{
    // Main Hall's matching grand flights, 1F -> 2F.
    .{ .lower_center = .{ .x = -6.5, .z = 5 }, .width = 3.2, .run = 13, .rise = floor_height, .direction_z = -1, .steps = 18 },
    .{ .lower_center = .{ .x = 6.5, .z = 5 }, .width = 3.2, .run = 13, .rise = floor_height, .direction_z = -1, .steps = 18 },
    // Enclosed north-west stair tower links all primary floors.
    .{ .lower_center = .{ .x = -23, .z = 7 }, .width = 3.6, .run = 12, .rise = floor_height, .direction_z = -1 },
    .{ .lower_center = .{ .x = -23, .y = floor_height, .z = -8 }, .width = 3.6, .run = 10, .rise = floor_height, .direction_z = -1 },
    // East fire stair, 1F -> 2F.
    .{ .lower_center = .{ .x = 23, .z = -15 }, .width = 2.8, .run = 11, .rise = floor_height, .direction_z = 1 },
    // Clock Tower machinery stair, 3F -> the small 4F platform.
    .{ .lower_center = .{ .x = -17, .y = 2 * floor_height, .z = 8 }, .width = 2.6, .run = 10, .rise = floor_height, .direction_z = -1 },
};

pub const tread_count = count: {
    var result: usize = 0;
    for (staircases) |item| result += item.steps;
    break :count result;
};

pub fn collisionRamp(item: Staircase) Box {
    return .{
        .center = .{ .x = item.lower_center.x, .y = item.lower_center.y + item.rise * 0.5 - 0.10, .z = item.lower_center.z + item.direction_z * item.run * 0.5 },
        .half_extents = .{ .x = item.width * 0.5, .y = 0.10, .z = @sqrt(item.run * item.run + item.rise * item.rise) * 0.5 },
        .color = stair_color,
        .pitch = -item.direction_z * std.math.atan(item.rise / item.run),
        .visible = false,
    };
}

pub fn tread(item: Staircase, index: usize) Box {
    const step_count: f32 = @floatFromInt(item.steps);
    const fraction = @as(f32, @floatFromInt(index + 1)) / step_count;
    return .{
        .center = .{ .x = item.lower_center.x, .y = item.lower_center.y + item.rise * fraction - 0.08, .z = item.lower_center.z + item.direction_z * item.run * (fraction - 0.5 / step_count) },
        .half_extents = .{ .x = item.width * 0.5, .y = 0.08, .z = item.run / step_count * 0.5 },
        .color = stair_color,
        .collidable = false,
    };
}

fn slab(x: f32, y: f32, z: f32, hx: f32, hz: f32) Box {
    return solid(x, y - slab_half_height, z, hx, slab_half_height, hz, floor_color);
}

fn ceiling(x: f32, y: f32, z: f32, hx: f32, hz: f32) Box {
    return solid(x, y, z, hx, slab_half_height, hz, roof_color);
}

fn wallX(x: f32, y: f32, z: f32, hx: f32, color: Vec4) Box {
    return solid(x, y + wall_half_height, z, hx, wall_half_height, wall_half_width, color);
}

fn wallZ(x: f32, y: f32, z: f32, hz: f32, color: Vec4) Box {
    return solid(x, y + wall_half_height, z, wall_half_width, wall_half_height, hz, color);
}

fn railX(x: f32, y: f32, z: f32, hx: f32, color: Vec4) Box {
    const rail_half_height = 0.55;
    return solid(x, y + rail_half_height, z, hx, rail_half_height, wall_half_width, color);
}

fn visual(x: f32, y: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4) Box {
    var result = solid(x, y, z, hx, hy, hz, color);
    result.collidable = false;
    return result;
}

fn solid(x: f32, y: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4) Box {
    return .{ .center = .{ .x = x, .y = y, .z = z }, .half_extents = .{ .x = hx, .y = hy, .z = hz }, .color = color };
}

fn rgba(r: f32, g: f32, b: f32, a: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = a };
}
