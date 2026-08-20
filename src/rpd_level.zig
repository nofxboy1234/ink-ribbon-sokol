//! Data-oriented RPD-style blockout: one floor, one shared grid.
//!
//! Dimensions are authored in metres on one shared grid. Thin boxes form floor
//! slabs, walls and the roof; gaps between wall segments are intentional
//! doorways. A closed ring of corridors loops around the central hall and the
//! surrounding rooms reconnect through several doorways, so a player can get
//! lost and find their way back by multiple routes.

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
    // Roof boxes are hidden in the top-down map view.
    is_roof: bool = false,
    // Blocks the hunter only: the player and camera pass through these, but
    // they still block the hunter's navmesh cells and line of sight.
    hunter_block: bool = false,
};

// Roof height in metres (one floor of the former stacked plan).
pub const floor_height: f32 = 5.5;
const wall_half_height: f32 = 2.65;
const wall_half_width: f32 = 0.16;
const slab_half_height: f32 = 0.20;

const floor_color = rgba(0.18, 0.21, 0.23, 1);
const wall_color = rgba(0.43, 0.44, 0.46, 1);
const hall_color = rgba(0.51, 0.50, 0.48, 1);
const roof_color = rgba(0.13, 0.14, 0.15, 1);
const wood_color = rgba(0.42, 0.37, 0.31, 1);
const darkwood_color = rgba(0.30, 0.24, 0.18, 1);
const crate_color = rgba(0.55, 0.47, 0.33, 1);
const shelf_color = rgba(0.33, 0.30, 0.27, 1);
const locker_color = rgba(0.47, 0.51, 0.53, 1);
const rack_color = rgba(0.36, 0.38, 0.40, 1);
const plant_color = rgba(0.25, 0.45, 0.30, 1);
const oxocarbon_pink = rgba(1.0, 0.49, 0.71, 1);
const typewriter_color = rgba(0.06, 0.06, 0.07, 1);

// ---------------------------------------------------------------------------
// Layout summary (building spans x in [-26, 26], z in [-19, 19]):
//
//   Outer shell of four walls. Inside it a 4m-wide ring of corridors loops
//   around the central Main Hall (x/z in [-9, 9]). Door gaps in the ring lead
//   into eight rooms beyond it (four edge rooms and four corner rooms), and
//   the corner rooms also link to their neighbours, so several routes loop
//   back on themselves. Solid boxes are furniture (tables, cupboards, crates).
// ---------------------------------------------------------------------------

pub const boxes = [_]Box{
    // ---------------------------------------------------------------------
    // Floor and roof spanning the whole footprint.
    // ---------------------------------------------------------------------
    slab(0, 0, 0, 26, 19),
    ceiling(0, floor_height, 0, 26, 19),

    // ---------------------------------------------------------------------
    // Outer shell.
    // ---------------------------------------------------------------------
    wallZ(-26, 0, 0, 19, wall_color), // west
    wallZ(26, 0, 0, 19, wall_color), // east
    wallX(0, 0, -19, 26, wall_color), // north
    wallX(0, 0, 19, 26, wall_color), // south

    // ---------------------------------------------------------------------
    // Main Hall enclosure (inner ring). Gaps in each side are the hall doors.
    // ---------------------------------------------------------------------
    wallZ(-9, 0, -5.5, 3.5, hall_color),
    wallZ(-9, 0, 5.5, 3.5, hall_color),
    wallZ(9, 0, -5.5, 3.5, hall_color),
    wallZ(9, 0, 5.5, 3.5, hall_color),
    wallX(-5.5, 0, -9, 3.5, hall_color),
    wallX(5.5, 0, -9, 3.5, hall_color),
    wallX(-5.5, 0, 9, 3.5, hall_color),
    wallX(5.5, 0, 9, 3.5, hall_color),

    // ---------------------------------------------------------------------
    // Ring corridor walls. North ring at z=-13, south ring at z=13, west ring
    // at x=-13, east ring at x=13. Gaps are doorways into the rooms beyond.
    // ---------------------------------------------------------------------
    wallX(-22, 0, -13, 4, wall_color), // z=-13, x -26..-18 (NW corner room)
    wallX(-13.75, 0, -13, 1.25, wall_color), // x -15..-12.5
    wallX(-8.75, 0, -13, 0.75, wall_color), // x -9.5..-8
    wallX(0, 0, -13, 5, wall_color), // x -5..5
    wallX(8.75, 0, -13, 0.75, wall_color), // x 8..9.5
    wallX(13.75, 0, -13, 1.25, wall_color), // x 12.5..15
    wallX(22, 0, -13, 4, wall_color), // x 18..26 (NE corner room)

    wallX(-22, 0, 13, 4, wall_color), // z=13, x -26..-18 (SW corner room)
    wallX(-13.75, 0, 13, 1.25, wall_color),
    wallX(-8.75, 0, 13, 0.75, wall_color),
    wallX(0, 0, 13, 5, wall_color),
    wallX(8.75, 0, 13, 0.75, wall_color),
    wallX(13.75, 0, 13, 1.25, wall_color),
    wallX(22, 0, 13, 4, wall_color), // x 18..26 (SE corner room)

    wallZ(-13, 0, -11.5, 1.5, wall_color), // x=-13, z -13..-10
    wallZ(-13, 0, -4.25, 2.75, wall_color), // z -7..-1.5
    wallZ(-13, 0, 4.25, 2.75, wall_color), // z 1.5..7
    wallZ(-13, 0, 11.5, 1.5, wall_color), // z 10..13

    wallZ(13, 0, -11.5, 1.5, wall_color), // x=13, z -13..-10
    wallZ(13, 0, -4.25, 2.75, wall_color),
    wallZ(13, 0, 4.25, 2.75, wall_color),
    wallZ(13, 0, 11.5, 1.5, wall_color), // z 10..13

    // ---------------------------------------------------------------------
    // West rooms: W1 storage, W2 office, W3 records (partitions at z=-4, z=4).
    // ---------------------------------------------------------------------
    wallX(-22.5, 0, -4, 3.5, wall_color), // z=-4, x -26..-19
    wallX(-14.5, 0, -4, 1.5, wall_color), // x -16..-13 (door x -19..-16)
    wallX(-22.5, 0, 4, 3.5, wall_color), // z=4, x -26..-19
    wallX(-14.5, 0, 4, 1.5, wall_color), // x -16..-13 (door x -19..-16)

    // East rooms: E1, E2 office, E3 conference.
    wallX(14.5, 0, -4, 1.5, wall_color), // z=-4, x 13..16 (door x 16..19)
    wallX(22.5, 0, -4, 3.5, wall_color), // x 19..26
    wallX(14.5, 0, 4, 1.5, wall_color), // z=4, x 13..16 (door x 16..19)
    wallX(22.5, 0, 4, 3.5, wall_color), // x 19..26

    // ---------------------------------------------------------------------
    // North rooms: NW2 lab and NE2 evidence (partition at x=0), plus the two
    // corner rooms beyond them, which also link into the west/east rooms.
    // ---------------------------------------------------------------------
    wallZ(0, 0, -18.25, 0.75, wall_color), // x=0, z -19..-17.5
    wallZ(0, 0, -14, 1, wall_color), // z -15..-13 (door z -17.5..-15)

    wallZ(-13, 0, -18, 1, wall_color), // x=-13, z -19..-17 (NW corner room)
    wallZ(-13, 0, -13.5, 0.5, wall_color), // z -14..-13 (door z -17..-14)

    wallZ(13, 0, -18, 1, wall_color), // x=13, z -19..-17 (NE corner room)
    wallZ(13, 0, -13.5, 0.5, wall_color), // z -14..-13 (door z -17..-14)

    // ---------------------------------------------------------------------
    // South rooms: SW2 locker room and SE2 interview, plus the two corner
    // rooms beyond them.
    // ---------------------------------------------------------------------
    wallZ(0, 0, 14, 1, wall_color), // x=0, z 13..15 (door z 15..17.5)
    wallZ(0, 0, 18.25, 0.75, wall_color), // z 17.5..19

    wallZ(-13, 0, 13.5, 0.5, wall_color), // x=-13, z 13..14 (SW corner room)
    wallZ(-13, 0, 18, 1, wall_color), // z 17..19 (door z 14..17)

    wallZ(13, 0, 13.5, 0.5, wall_color), // x=13, z 13..14 (SE corner room)
    wallZ(13, 0, 18, 1, wall_color), // z 17..19 (door z 14..17)

    // ---------------------------------------------------------------------
    // Main Hall furniture (desk and plant are non-collidable decor).
    // ---------------------------------------------------------------------
    visual(0, 0.9, 5.5, 3, 0.9, 1, darkwood_color), // reception desk
    visual(0, 1.0, -4, 0.35, 1.0, 0.35, plant_color), // pot plant
    solid(-4, 0.75, 0, 1.8, 0.75, 0.8, wood_color), // hall table
    solid(4, 0.75, 0, 1.8, 0.75, 0.8, wood_color), // hall table

    // ---------------------------------------------------------------------
    // West furniture.
    // ---------------------------------------------------------------------
    solid(-25, 1.0, -8.5, 0.5, 1.0, 3.5, darkwood_color), // W1 cupboards
    solid(-25, 1.0, -5.5, 0.5, 1.0, 1.5, darkwood_color),
    solid(-20, 0.6, -11, 1, 0.6, 1, crate_color), // W1 crates
    solid(-18, 0.6, -11, 1, 0.6, 1, crate_color),
    solid(-17.5, 0.85, 0, 2.5, 0.85, 1.1, oxocarbon_pink), // W2 landmark desk
    solid(-23, 0.75, -2, 2.2, 0.75, 0.9, wood_color), // W2 table
    solid(-24.5, 1.1, 2, 0.5, 1.1, 1.6, darkwood_color), // W2 cupboard
    solid(-18, 1.2, 6, 0.5, 1.2, 2.5, shelf_color), // W3 shelves
    solid(-18, 1.2, 10, 0.5, 1.2, 2, shelf_color),
    solid(-22, 0.75, 8.5, 2, 0.75, 1, wood_color), // W3 table

    // ---------------------------------------------------------------------
    // W2 save room: a typewriter on the pink landmark desk, and invisible
    // hunter-block barriers sealing all three doorways (z=-4, z=4, and the
    // corridor gap at x=-13) so the hunter cannot enter or see inside.
    // ---------------------------------------------------------------------
    visual(-17.5, 1.76, 0, 0.28, 0.06, 0.18, typewriter_color), // W2 typewriter
    hunterDoorX(-17.5, -4, 1.5), // seal W2 north doorway
    hunterDoorX(-17.5, 4, 1.5), // seal W2 south doorway
    hunterDoorZ(-13, 0, 1.5), // seal W2 east doorway into the corridor

    // ---------------------------------------------------------------------
    // East furniture.
    // ---------------------------------------------------------------------
    solid(20, 0.75, -8, 2.4, 0.75, 1.2, wood_color), // E1 table
    solid(24.5, 1.0, -6, 0.5, 1.0, 2.5, darkwood_color), // E1 cupboard
    solid(18, 0.75, -1, 2, 0.75, 1, wood_color), // E2 tables
    solid(23, 0.75, 1, 2, 0.75, 1, wood_color),
    solid(20, 0.75, 8, 4, 0.75, 1.4, wood_color), // E3 conference table
    solid(24.5, 1.1, 5, 0.5, 1.1, 1.8, darkwood_color), // E3 cupboard

    // ---------------------------------------------------------------------
    // North furniture.
    // ---------------------------------------------------------------------
    solid(-8, 0.75, -16, 2.4, 0.75, 1, wood_color), // NW2 work table
    solid(-3.5, 1.0, -18, 2.5, 1.0, 0.5, darkwood_color), // NW2 cupboard
    solid(5, 1.1, -17.5, 2, 1.1, 0.5, shelf_color), // NE2 shelves
    solid(9, 0.75, -15, 2, 0.75, 1, wood_color), // NE2 table
    solid(-20, 0.5, -17, 1, 0.5, 1, crate_color), // NW corner crates
    solid(-17.5, 0.5, -16, 1, 0.5, 1, crate_color),
    solid(-23, 0.8, -15.5, 1.2, 0.8, 1.2, crate_color),
    solid(18, 1.0, -16.5, 3, 1.0, 0.5, rack_color), // NE corner racks
    solid(23, 1.0, -16.5, 1.8, 1.0, 0.5, rack_color),

    // ---------------------------------------------------------------------
    // South furniture.
    // ---------------------------------------------------------------------
    solid(-8, 1.1, 14, 2.6, 1.1, 0.5, locker_color), // SW2 lockers
    solid(-4.5, 1.1, 14, 1.3, 1.1, 0.5, locker_color),
    solid(6, 0.75, 17, 2.4, 0.75, 1, wood_color), // SE2 table
    solid(-20, 0.75, 15, 3, 0.75, 1, wood_color), // SW corner work table
    solid(17, 1.2, 15, 0.5, 1.2, 2.6, shelf_color), // SE corner shelves
    solid(23, 1.2, 15, 0.5, 1.2, 2.6, shelf_color),
};

fn slab(x: f32, y: f32, z: f32, hx: f32, hz: f32) Box {
    return solid(x, y - slab_half_height, z, hx, slab_half_height, hz, floor_color);
}

fn ceiling(x: f32, y: f32, z: f32, hx: f32, hz: f32) Box {
    var result = solid(x, y, z, hx, slab_half_height, hz, roof_color);
    result.is_roof = true;
    return result;
}

fn wallX(x: f32, y: f32, z: f32, hx: f32, color: Vec4) Box {
    return solid(x, y + wall_half_height, z, hx, wall_half_height, wall_half_width, color);
}

fn wallZ(x: f32, y: f32, z: f32, hz: f32, color: Vec4) Box {
    return solid(x, y + wall_half_height, z, wall_half_width, wall_half_height, hz, color);
}

fn visual(x: f32, y: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4) Box {
    var result = solid(x, y, z, hx, hy, hz, color);
    result.collidable = false;
    return result;
}

// Invisible barrier in a doorway that only the hunter collides with (and
// that blocks his navmesh cells and view). The player walks straight through.
fn hunterDoorX(x: f32, z: f32, hx: f32) Box {
    var result = wallX(x, 0, z, hx, wall_color);
    result.visible = false;
    result.hunter_block = true;
    return result;
}

fn hunterDoorZ(x: f32, z: f32, hz: f32) Box {
    var result = wallZ(x, 0, z, hz, wall_color);
    result.visible = false;
    result.hunter_block = true;
    return result;
}

fn solid(x: f32, y: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4) Box {
    return .{ .center = .{ .x = x, .y = y, .z = z }, .half_extents = .{ .x = hx, .y = hy, .z = hz }, .color = color };
}

fn rgba(r: f32, g: f32, b: f32, a: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = a };
}