//! Hand-authored first floor of the RPD, traced from `layout.png`.
//!
//! The walkable footprint follows the reference's west wing, main hall,
//! courtyards, east wing, and north-east stair block. Interior walls and doors
//! are authored separately so their proportions are not constrained to a room
//! generator. Stairs end at first-floor walls until upper floors are added.

const std = @import("std");
const math = @import("math.zig");
pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

pub const footprint_half_x: f32 = 26;
pub const footprint_half_z: f32 = 19;
pub const floor_height: f32 = 5.5;
pub const tile_size: f32 = 1;
pub const tile_cols = 52;
pub const tile_rows = 38;
pub const tile_count = tile_cols * tile_rows;
pub const room_capacity = 16;
pub const edge_capacity = 24;
pub const light_capacity = 8;
pub const max_boxes = 768;

const wall_half_height: f32 = 2.65;
const wall_half_width: f32 = 0.16;
const slab_half_height: f32 = 0.20;

pub const Box = struct {
    center: Vec3,
    half_extents: Vec3,
    color: Vec4,
    pitch: f32 = 0,
    visible: bool = true,
    collidable: bool = true,
    nav_block: bool = true,
    is_roof: bool = false,
    // Invisible save-room perimeter. The player and camera ignore this category.
    hunter_block: bool = false,
};

const RoomRect = struct { min_col: u8, min_row: u8, cols: u8, rows: u8 };
const FloorRect = struct { min_col: u8, min_row: u8, cols: u8, rows: u8 };

pub const Room = struct {
    min_col: u8,
    min_row: u8,
    cols: u8,
    rows: u8,
    neighbors: u16 = 0,

    pub fn center(self: Room) Vec3 {
        return .{
            .x = -footprint_half_x + (@as(f32, @floatFromInt(self.min_col)) + @as(f32, @floatFromInt(self.cols)) * 0.5) * tile_size,
            .z = -footprint_half_z + (@as(f32, @floatFromInt(self.min_row)) + @as(f32, @floatFromInt(self.rows)) * 0.5) * tile_size,
        };
    }
};

pub const Edge = struct { a: u8, b: u8 };

// These are lighting/patrol regions, not a generated room grid. Their positions
// follow the named spaces visible in the supplied first-floor plan.
const room_rects = [_]RoomRect{
    .{ .min_col = 22, .min_row = 27, .cols = 6, .rows = 6 }, //  0 entrance lobby
    .{ .min_col = 20, .min_row = 16, .cols = 10, .rows = 11 }, // 1 main hall
    .{ .min_col = 20, .min_row = 9, .cols = 10, .rows = 7 }, //  2 north main hall
    .{ .min_col = 14, .min_row = 8, .cols = 5, .rows = 8 }, //   3 west save room
    .{ .min_col = 2, .min_row = 6, .cols = 8, .rows = 7 }, //    4 north-west office
    .{ .min_col = 2, .min_row = 14, .cols = 8, .rows = 7 }, //   5 west operations
    .{ .min_col = 3, .min_row = 22, .cols = 8, .rows = 6 }, //   6 south-west office
    .{ .min_col = 11, .min_row = 20, .cols = 8, .rows = 9 }, //  7 west records
    .{ .min_col = 30, .min_row = 8, .cols = 7, .rows = 7 }, //   8 north-east office
    .{ .min_col = 30, .min_row = 15, .cols = 7, .rows = 7 }, //  9 east office
    .{ .min_col = 31, .min_row = 23, .cols = 10, .rows = 6 }, // 10 east records
    .{ .min_col = 43, .min_row = 15, .cols = 5, .rows = 7 }, // 11 east corridor
    .{ .min_col = 44, .min_row = 23, .cols = 7, .rows = 6 }, // 12 east hunter room
    .{ .min_col = 40, .min_row = 5, .cols = 7, .rows = 7 }, //  13 north-east hall
    .{ .min_col = 48, .min_row = 8, .cols = 4, .rows = 7 }, //  14 east stair hall
    .{ .min_col = 39, .min_row = 0, .cols = 3, .rows = 5 }, //  15 north stair room
};

// Broad floor masses traced from the outer silhouette. Boundary walls are
// derived from this union, preserving the long west/east wings and narrow joins.
const floor_rects = [_]FloorRect{
    .{ .min_col = 1, .min_row = 5, .cols = 17, .rows = 14 },
    .{ .min_col = 1, .min_row = 18, .cols = 19, .rows = 11 },
    .{ .min_col = 17, .min_row = 5, .cols = 3, .rows = 17 },
    .{ .min_col = 20, .min_row = 9, .cols = 10, .rows = 23 },
    .{ .min_col = 22, .min_row = 31, .cols = 6, .rows = 2 },
    .{ .min_col = 29, .min_row = 7, .cols = 14, .rows = 22 },
    .{ .min_col = 42, .min_row = 14, .cols = 6, .rows = 15 },
    .{ .min_col = 47, .min_row = 7, .cols = 5, .rows = 22 },
    .{ .min_col = 39, .min_row = 0, .cols = 3, .rows = 7 },
    .{ .min_col = 40, .min_row = 4, .cols = 12, .rows = 4 },
    .{ .min_col = 37, .min_row = 5, .cols = 5, .rows = 7 },
};

const room_edges = [_]Edge{
    .{ .a = 0, .b = 1 },   .{ .a = 1, .b = 2 },   .{ .a = 2, .b = 3 },
    .{ .a = 3, .b = 4 },   .{ .a = 4, .b = 5 },   .{ .a = 5, .b = 6 },
    .{ .a = 6, .b = 7 },   .{ .a = 7, .b = 1 },   .{ .a = 2, .b = 8 },
    .{ .a = 8, .b = 9 },   .{ .a = 9, .b = 10 },  .{ .a = 10, .b = 11 },
    .{ .a = 11, .b = 12 }, .{ .a = 11, .b = 13 }, .{ .a = 13, .b = 14 },
    .{ .a = 14, .b = 15 }, .{ .a = 1, .b = 9 },
};

const start_room_index: usize = 0;
const save_room_index: usize = 1;

const Wall = struct {
    horizontal: bool,
    fixed: f32,
    from: f32,
    to: f32,
};

// Door gaps are deliberately encoded as separate wall runs. This mirrors the
// reference much more closely than carving centre-to-centre corridors.
const interior_walls = [_]Wall{
    // West wing: offices wrapped around a long central corridor.
    .{ .horizontal = true, .fixed = -12.1, .from = -23.5, .to = -20.5 },
    .{ .horizontal = true, .fixed = -12.1, .from = -18.9, .to = -16.2 },
    .{ .horizontal = true, .fixed = -5.5, .from = -23.5, .to = -20.1 },
    .{ .horizontal = true, .fixed = -5.5, .from = -18.5, .to = -16.5 },
    .{ .horizontal = true, .fixed = -1.1, .from = -24.0, .to = -20.3 },
    .{ .horizontal = true, .fixed = -1.1, .from = -18.7, .to = -14.0 },
    .{ .horizontal = true, .fixed = 2.2, .from = -23.0, .to = -18.2 },
    .{ .horizontal = true, .fixed = 2.2, .from = -16.6, .to = -12.6 },
    .{ .horizontal = true, .fixed = 5.4, .from = -22.8, .to = -18.4 },
    .{ .horizontal = true, .fixed = 5.4, .from = -16.8, .to = -12.0 },
    .{ .horizontal = true, .fixed = 8.0, .from = -15.8, .to = -12.2 },
    .{ .horizontal = false, .fixed = -23.5, .from = -12.1, .to = -6.9 },
    .{ .horizontal = false, .fixed = -20.4, .from = -13.8, .to = -8.2 },
    .{ .horizontal = false, .fixed = -18.3, .from = -5.5, .to = -3.8 },
    .{ .horizontal = false, .fixed = -18.3, .from = -2.2, .to = 2.2 },
    .{ .horizontal = false, .fixed = -18.7, .from = 2.2, .to = 7.5 },
    .{ .horizontal = false, .fixed = -16.2, .from = -13.8, .to = -8.3 },
    .{ .horizontal = false, .fixed = -16.2, .from = -6.7, .to = -1.1 },
    .{ .horizontal = false, .fixed = -14.0, .from = -5.5, .to = -2.9 },
    .{ .horizontal = false, .fixed = -12.6, .from = -1.1, .to = 5.4 },
    .{ .horizontal = false, .fixed = -11.0, .from = 5.4, .to = 9.7 },
    .{ .horizontal = false, .fixed = -8.2, .from = -13.8, .to = -10.5 },
    .{ .horizontal = false, .fixed = -8.2, .from = -9.0, .to = -3.0 },

    // West typewriter room, in the upper-right corner of the west wing.
    .{ .horizontal = true, .fixed = -10.5, .from = -12.0, .to = -8.2 },
    .{ .horizontal = true, .fixed = -3.0, .from = -12.0, .to = -8.2 },
    .{ .horizontal = false, .fixed = -12.0, .from = -10.5, .to = -8.7 },
    .{ .horizontal = false, .fixed = -12.0, .from = -7.3, .to = -3.0 },

    // Main hall side rooms and the north cross-corridor.
    .{ .horizontal = true, .fixed = -9.2, .from = -5.8, .to = -2.2 },
    .{ .horizontal = true, .fixed = -9.2, .from = -0.6, .to = 3.0 },
    .{ .horizontal = true, .fixed = -3.5, .from = 3.2, .to = 7.2 },
    // Large office island in the central-east hall.
    .{ .horizontal = true, .fixed = -9.2, .from = 9.3, .to = 14.8 },
    .{ .horizontal = true, .fixed = -0.2, .from = 9.3, .to = 11.8 },
    .{ .horizontal = true, .fixed = -0.2, .from = 13.2, .to = 14.8 },
    .{ .horizontal = true, .fixed = -5.5, .from = 9.3, .to = 12.0 },
    .{ .horizontal = true, .fixed = 2.0, .from = 5.8, .to = 8.7 },
    .{ .horizontal = true, .fixed = 2.0, .from = 10.3, .to = 16.8 },
    .{ .horizontal = true, .fixed = 5.2, .from = 6.0, .to = 9.6 },
    .{ .horizontal = true, .fixed = 5.2, .from = 11.2, .to = 16.8 },
    .{ .horizontal = false, .fixed = 4.0, .from = -9.2, .to = -5.8 },
    .{ .horizontal = false, .fixed = 4.0, .from = -2.8, .to = 2.0 },
    .{ .horizontal = false, .fixed = 6.0, .from = 2.0, .to = 8.8 },
    .{ .horizontal = false, .fixed = 9.2, .from = 5.2, .to = 8.8 },
    .{ .horizontal = false, .fixed = 9.3, .from = -9.2, .to = -0.2 },
    .{ .horizontal = false, .fixed = 12.0, .from = -5.5, .to = -0.2 },
    .{ .horizontal = false, .fixed = 14.8, .from = -9.2, .to = -0.2 },
    .{ .horizontal = false, .fixed = 16.8, .from = -12.0, .to = -8.1 },
    .{ .horizontal = false, .fixed = 16.8, .from = -6.5, .to = -4.0 },
    .{ .horizontal = false, .fixed = 16.8, .from = -1.4, .to = 2.0 },

    // East spine and the stacked rooms shown along the right edge.
    .{ .horizontal = true, .fixed = -11.0, .from = 17.0, .to = 21.4 },
    .{ .horizontal = true, .fixed = -11.0, .from = 23.0, .to = 25.8 },
    .{ .horizontal = true, .fixed = -7.0, .from = 17.0, .to = 20.0 },
    .{ .horizontal = true, .fixed = -7.0, .from = 21.6, .to = 25.8 },
    .{ .horizontal = true, .fixed = -3.5, .from = 17.0, .to = 19.2 },
    .{ .horizontal = true, .fixed = -3.5, .from = 22.6, .to = 25.8 },
    .{ .horizontal = true, .fixed = 0.0, .from = 17.0, .to = 20.0 },
    .{ .horizontal = true, .fixed = 0.0, .from = 22.6, .to = 25.8 },
    .{ .horizontal = true, .fixed = 3.2, .from = 18.6, .to = 21.8 },
    .{ .horizontal = true, .fixed = 3.2, .from = 23.4, .to = 25.8 },
    .{ .horizontal = false, .fixed = 20.8, .from = -7.0, .to = -4.5 },
    .{ .horizontal = false, .fixed = 20.8, .from = -1.8, .to = 0.0 },
    .{ .horizontal = false, .fixed = 18.6, .from = 0.0, .to = 5.3 },
    .{ .horizontal = false, .fixed = 18.6, .from = 6.9, .to = 9.8 },
    .{ .horizontal = false, .fixed = 22.0, .from = -14.8, .to = -12.4 },
    .{ .horizontal = false, .fixed = 22.0, .from = -10.8, .to = -7.0 },
    .{ .horizontal = false, .fixed = 22.0, .from = 0.0, .to = 3.2 },

    // North-east upper corridor and stair block.
    .{ .horizontal = true, .fixed = -16.8, .from = 13.0, .to = 16.0 },
    .{ .horizontal = true, .fixed = -14.8, .from = 13.0, .to = 16.0 },
    .{ .horizontal = true, .fixed = -12.0, .from = 17.0, .to = 21.2 },
    .{ .horizontal = true, .fixed = -12.0, .from = 22.8, .to = 25.8 },
    .{ .horizontal = false, .fixed = 16.0, .from = -18.8, .to = -15.7 },
    .{ .horizontal = false, .fixed = 16.0, .from = -14.1, .to = -12.0 },
};

const Prop = struct { x: f32, z: f32, hx: f32, hy: f32, hz: f32, color: Vec4 };
const props = [_]Prop{
    // West offices and records: desks, archive shelves, and lockers.
    .{ .x = -21.7, .z = -9.0, .hx = 1.5, .hy = 0.55, .hz = 0.55, .color = wood_color },
    .{ .x = -17.2, .z = -10.0, .hx = 0.40, .hy = 1.05, .hz = 1.20, .color = locker_color },
    .{ .x = -21.2, .z = -3.4, .hx = 1.1, .hy = 0.55, .hz = 0.65, .color = wood_color },
    .{ .x = -15.4, .z = -1.9, .hx = 1.2, .hy = 0.85, .hz = 0.38, .color = shelf_color },
    .{ .x = -21.2, .z = 4.0, .hx = 0.42, .hy = 1.05, .hz = 1.25, .color = locker_color },
    .{ .x = -15.1, .z = 6.7, .hx = 1.4, .hy = 0.55, .hz = 0.55, .color = wood_color },
    .{ .x = -8.9, .z = 7.5, .hx = 0.45, .hy = 1.0, .hz = 1.4, .color = locker_color },
    .{ .x = -10.0, .z = -5.0, .hx = 0.55, .hy = 0.65, .hz = 0.55, .color = crate_color },

    // Main hall furniture leaves broad lanes around both sides.
    .{ .x = -4.2, .z = -0.8, .hx = 0.55, .hy = 0.65, .hz = 1.35, .color = wood_color },
    .{ .x = 2.2, .z = -0.8, .hx = 0.55, .hy = 0.65, .hz = 1.35, .color = wood_color },
    .{ .x = -4.5, .z = 8.0, .hx = 1.1, .hy = 0.50, .hz = 0.45, .color = wood_color },
    .{ .x = 2.4, .z = 8.1, .hx = 0.40, .hy = 1.0, .hz = 0.75, .color = locker_color },

    // East offices and the hunter's starting room.
    .{ .x = 6.8, .z = -7.0, .hx = 1.3, .hy = 0.55, .hz = 0.60, .color = wood_color },
    .{ .x = 10.8, .z = -1.2, .hx = 0.38, .hy = 1.0, .hz = 1.35, .color = locker_color },
    .{ .x = 13.7, .z = 3.6, .hx = 1.25, .hy = 0.55, .hz = 0.55, .color = wood_color },
    .{ .x = 15.2, .z = 7.2, .hx = 0.40, .hy = 1.0, .hz = 1.15, .color = shelf_color },
    .{ .x = 21.0, .z = 5.1, .hx = 0.45, .hy = 1.05, .hz = 1.15, .color = locker_color },
    .{ .x = 23.8, .z = 7.6, .hx = 1.0, .hy = 0.60, .hz = 0.65, .color = crate_color },
    .{ .x = 24.2, .z = -5.2, .hx = 0.42, .hy = 1.0, .hz = 1.0, .color = locker_color },
};

const SaveBounds = struct { min_x: f32, max_x: f32, min_z: f32, max_z: f32 };

pub const Level = struct {
    boxes: [max_boxes]Box = undefined,
    box_count: usize = 0,
    rooms: [room_capacity]Room = undefined,
    room_count: usize = 0,
    edges: [edge_capacity]Edge = undefined,
    edge_count: usize = 0,
    walkable: [tile_count]bool = @splat(false),
    start_room: usize = 0,
    save_room: usize = 0,
    player_spawn: Vec3 = .{},
    hunter_spawn: Vec3 = .{},
    save_room_target: Vec3 = .{},
    save_fixtures: [2]Vec3 = @splat(.{}),
    save_fixture_count: usize = 0,
    save_bounds: [2]SaveBounds = @splat(.{ .min_x = 0, .max_x = 0, .min_z = 0, .max_z = 0 }),
    // Retained for the map/game API; these describe the primary main-hall save.
    save_min_x: f32 = 0,
    save_max_x: f32 = 0,
    save_min_z: f32 = 0,
    save_max_z: f32 = 0,
    lights: [light_capacity]Vec4 = @splat(.{}),
    light_count: usize = 0,

    pub fn boxSlice(self: *const Level) []const Box {
        return self.boxes[0..self.box_count];
    }

    pub fn isInSaveRoom(self: *const Level, x: f32, z: f32) bool {
        for (self.save_bounds) |bounds| {
            if (x > bounds.min_x and x < bounds.max_x and z > bounds.min_z and z < bounds.max_z) return true;
        }
        return false;
    }

    pub fn graphDistance(self: *const Level, from: usize, to: usize) ?usize {
        var distance: [room_capacity]i16 = @splat(-1);
        var queue: [room_capacity]usize = undefined;
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = from;
        distance[from] = 0;
        while (head < tail) {
            const room = queue[head];
            head += 1;
            if (room == to) return @intCast(distance[room]);
            for (0..self.room_count) |next| {
                if ((self.rooms[room].neighbors & (@as(u16, 1) << @intCast(next))) == 0 or distance[next] >= 0) continue;
                distance[next] = distance[room] + 1;
                queue[tail] = next;
                tail += 1;
            }
        }
        return null;
    }

    pub fn validate(self: *const Level) bool {
        if (self.room_count != room_capacity or self.box_count == 0 or self.box_count > max_boxes) return false;
        if (self.graphDistance(self.start_room, self.save_room) == null) return false;
        if (!self.isInSaveRoom(self.save_room_target.x, self.save_room_target.z)) return false;
        if (self.isInSaveRoom(self.hunter_spawn.x, self.hunter_spawn.z)) return false;
        const spawn_col = worldTile(self.player_spawn.x, footprint_half_x, tile_cols) orelse return false;
        const spawn_row = worldTile(self.player_spawn.z, footprint_half_z, tile_rows) orelse return false;
        if (!self.walkable[spawn_row * tile_cols + spawn_col]) return false;
        var barriers: usize = 0;
        for (self.boxSlice()) |box| barriers += @intFromBool(box.hunter_block);
        return barriers == 2 and self.save_fixture_count == 2;
    }

    fn addBox(self: *Level, box: Box) void {
        std.debug.assert(self.box_count < max_boxes);
        self.boxes[self.box_count] = box;
        self.box_count += 1;
    }
};

pub var current: Level = undefined;

pub fn load() void {
    current = build();
}

fn build() Level {
    var result = Level{};
    placeRooms(&result);
    connectRooms(&result);
    carveFootprint(&result);
    chooseObjectives(&result);
    buildGeometry(&result);
    deriveLights(&result);
    std.debug.assert(result.validate());
    return result;
}

fn placeRooms(result: *Level) void {
    for (room_rects) |rect| {
        result.rooms[result.room_count] = .{
            .min_col = rect.min_col,
            .min_row = rect.min_row,
            .cols = rect.cols,
            .rows = rect.rows,
        };
        result.room_count += 1;
    }
}

fn connectRooms(result: *Level) void {
    for (room_edges) |edge| {
        result.edges[result.edge_count] = edge;
        result.edge_count += 1;
        result.rooms[edge.a].neighbors |= @as(u16, 1) << @intCast(edge.b);
        result.rooms[edge.b].neighbors |= @as(u16, 1) << @intCast(edge.a);
    }
}

fn carveFootprint(result: *Level) void {
    for (floor_rects) |rect| {
        for (rect.min_row..rect.min_row + rect.rows) |row| {
            for (rect.min_col..rect.min_col + rect.cols) |col| {
                result.walkable[row * tile_cols + col] = true;
            }
        }
    }
}

fn chooseObjectives(result: *Level) void {
    result.start_room = start_room_index;
    result.save_room = save_room_index;
    // South end of the central entrance lobby, facing into the main hall.
    result.player_spawn = .{ .x = 0, .z = 10.5 };
    // The large room at the south-east end of the eastern spine.
    result.hunter_spawn = .{ .x = 23.8, .z = -1.8 };

    // Main hall typewriter enclosure and west-wing typewriter room.
    result.save_bounds[0] = .{ .min_x = -3.7, .max_x = 1.7, .min_z = 2.0, .max_z = 5.7 };
    result.save_bounds[1] = .{ .min_x = -11.8, .max_x = -8.35, .min_z = -10.3, .max_z = -3.2 };
    result.save_min_x = result.save_bounds[0].min_x;
    result.save_max_x = result.save_bounds[0].max_x;
    result.save_min_z = result.save_bounds[0].min_z;
    result.save_max_z = result.save_bounds[0].max_z;
    result.save_room_target = .{ .x = -0.5, .z = 4.2 };
}

fn buildGeometry(result: *Level) void {
    buildSurfaces(result);
    buildHorizontalBoundaries(result);
    buildVerticalBoundaries(result);

    for (interior_walls) |wall| {
        const middle = (wall.from + wall.to) * 0.5;
        const half = (wall.to - wall.from) * 0.5;
        if (wall.horizontal) {
            result.addBox(wallX(middle, 0, wall.fixed, half, wall_color));
        } else {
            result.addBox(wallZ(wall.fixed, 0, middle, half, wall_color));
        }
    }

    // Narrow shafts/courtyards visible as black holes in the source plan.
    result.addBox(solid(-18.0, 0.65, -4.5, 0.55, 0.65, 1.0, void_color));
    result.addBox(solid(3.55, 0.65, 3.0, 0.45, 0.65, 5.8, void_color));
    result.addBox(solid(17.8, 0.65, -5.1, 2.8, 0.65, 1.0, void_color));
    result.addBox(solid(19.8, 0.65, 1.5, 1.2, 0.65, 0.75, void_color));

    for (props) |item| {
        result.addBox(solid(item.x, item.hy, item.z, item.hx, item.hy, item.hz, item.color));
    }

    // Main-hall save enclosure: a shallow U with one player-sized opening.
    result.addBox(wallX(-1.0, 0, 2.0, 2.7, wall_color));
    result.addBox(wallZ(-3.7, 0, 3.85, 1.85, wall_color));
    result.addBox(wallZ(1.7, 0, 3.85, 1.85, wall_color));
    result.addBox(wallX(-2.95, 0, 5.7, 0.75, wall_color));
    result.addBox(wallX(0.95, 0, 5.7, 0.75, wall_color));
    result.addBox(hunterDoorX(-1.0, 5.7, 1.2));
    addTypewriter(result, -2.3, 3.3);

    // West save room has one doorway in its west wall.
    result.addBox(hunterDoorZ(-12.0, -8.0, 0.7));
    addTypewriter(result, -9.5, -7.7);

    // First-floor-only stair treatment. Each ramp rises into an existing solid
    // wall, making the unfinished upper-floor exits explicit dead ends.
    addRamp(result, -9.7, -12.1, 1.25, 1.65, -0.20);
    addRamp(result, -4.1, -5.9, 1.15, 1.85, -0.20);
    addRamp(result, 2.2, -5.9, 1.15, 1.85, -0.20);
    addRamp(result, 14.5, -15.8, 1.15, 1.45, -0.22);
    addRamp(result, 20.0, -9.5, 1.05, 1.55, -0.22);
    addRamp(result, 24.0, 6.1, 1.05, 1.50, 0.22);
}

// Tile the exact footprint into non-overlapping rectangular floor and roof
// pieces. The old full-footprint slabs made exterior voids look like playable
// floor in map view and left a roof hanging outside the building silhouette.
fn buildSurfaces(result: *Level) void {
    var consumed: [tile_count]bool = @splat(false);
    for (0..tile_rows) |row| {
        for (0..tile_cols) |col| {
            const start = row * tile_cols + col;
            if (!result.walkable[start] or consumed[start]) continue;

            var width: usize = 1;
            while (col + width < tile_cols) : (width += 1) {
                const cell = row * tile_cols + col + width;
                if (!result.walkable[cell] or consumed[cell]) break;
            }

            var height: usize = 1;
            height_loop: while (row + height < tile_rows) : (height += 1) {
                for (col..col + width) |next_col| {
                    const cell = (row + height) * tile_cols + next_col;
                    if (!result.walkable[cell] or consumed[cell]) break :height_loop;
                }
            }

            for (row..row + height) |used_row| {
                for (col..col + width) |used_col| consumed[used_row * tile_cols + used_col] = true;
            }

            const x = -footprint_half_x + (@as(f32, @floatFromInt(col)) + @as(f32, @floatFromInt(width)) * 0.5) * tile_size;
            const z = -footprint_half_z + (@as(f32, @floatFromInt(row)) + @as(f32, @floatFromInt(height)) * 0.5) * tile_size;
            const hx = @as(f32, @floatFromInt(width)) * tile_size * 0.5;
            const hz = @as(f32, @floatFromInt(height)) * tile_size * 0.5;
            result.addBox(slab(x, 0, z, hx, hz));
            result.addBox(ceiling(x, floor_height, z, hx, hz));
        }
    }
}

fn addTypewriter(result: *Level, x: f32, z: f32) void {
    result.save_fixtures[result.save_fixture_count] = .{ .x = x, .z = z };
    result.save_fixture_count += 1;
    result.addBox(solid(x, 0.55, z, 1.0, 0.55, 0.62, oxocarbon_pink));
    result.addBox(visual(x, 1.16, z, 0.28, 0.06, 0.18, typewriter_color));
}

fn addRamp(result: *Level, x: f32, z: f32, hx: f32, hz: f32, pitch: f32) void {
    var box = solid(x, 0.38, z, hx, 0.12, hz, stair_color);
    box.pitch = pitch;
    box.nav_block = false;
    result.addBox(box);
}

fn boundaryHorizontal(result: *const Level, col: usize, boundary_row: usize) bool {
    const north = boundary_row > 0 and result.walkable[(boundary_row - 1) * tile_cols + col];
    const south = boundary_row < tile_rows and result.walkable[boundary_row * tile_cols + col];
    return north != south;
}

fn boundaryVertical(result: *const Level, boundary_col: usize, row: usize) bool {
    const west = boundary_col > 0 and result.walkable[row * tile_cols + boundary_col - 1];
    const east = boundary_col < tile_cols and result.walkable[row * tile_cols + boundary_col];
    return west != east;
}

fn buildHorizontalBoundaries(result: *Level) void {
    for (0..tile_rows + 1) |boundary_row| {
        var col: usize = 0;
        while (col < tile_cols) {
            if (!boundaryHorizontal(result, col, boundary_row)) {
                col += 1;
                continue;
            }
            const start = col;
            while (col < tile_cols and boundaryHorizontal(result, col, boundary_row)) col += 1;
            const length = col - start;
            const x = -footprint_half_x + @as(f32, @floatFromInt(start)) + @as(f32, @floatFromInt(length)) * 0.5;
            const z = -footprint_half_z + @as(f32, @floatFromInt(boundary_row));
            result.addBox(wallX(x, 0, z, @as(f32, @floatFromInt(length)) * 0.5, wall_color));
        }
    }
}

fn buildVerticalBoundaries(result: *Level) void {
    for (0..tile_cols + 1) |boundary_col| {
        var row: usize = 0;
        while (row < tile_rows) {
            if (!boundaryVertical(result, boundary_col, row)) {
                row += 1;
                continue;
            }
            const start = row;
            while (row < tile_rows and boundaryVertical(result, boundary_col, row)) row += 1;
            const length = row - start;
            const x = -footprint_half_x + @as(f32, @floatFromInt(boundary_col));
            const z = -footprint_half_z + @as(f32, @floatFromInt(start)) + @as(f32, @floatFromInt(length)) * 0.5;
            result.addBox(wallZ(x, 0, z, @as(f32, @floatFromInt(length)) * 0.5, wall_color));
        }
    }
}

fn deriveLights(result: *Level) void {
    const fixtures = [_]Vec4{
        .{ .x = -1.0, .y = 4.1, .z = 5.0, .w = 9.0 },
        .{ .x = -1.0, .y = 4.1, .z = -5.0, .w = 9.0 },
        .{ .x = -10.0, .y = 4.1, .z = -7.0, .w = 8.0 },
        .{ .x = -21.0, .y = 4.1, .z = -8.0, .w = 9.0 },
        .{ .x = -18.0, .y = 4.1, .z = 5.0, .w = 9.0 },
        .{ .x = 9.0, .y = 4.1, .z = -6.0, .w = 9.0 },
        .{ .x = 13.0, .y = 4.1, .z = 5.0, .w = 9.0 },
        .{ .x = 23.0, .y = 4.1, .z = 4.0, .w = 9.0 },
    };
    for (fixtures) |fixture| {
        result.lights[result.light_count] = fixture;
        result.light_count += 1;
    }
}

fn worldTile(value: f32, half_extent: f32, count: usize) ?usize {
    const tile: i32 = @intFromFloat(@floor((value + half_extent) / tile_size));
    if (tile < 0 or tile >= count) return null;
    return @intCast(tile);
}

const floor_color = rgba(0.18, 0.21, 0.23, 1);
const wall_color = rgba(0.43, 0.44, 0.46, 1);
const roof_color = rgba(0.13, 0.14, 0.15, 1);
const wood_color = rgba(0.42, 0.37, 0.31, 1);
const crate_color = rgba(0.55, 0.47, 0.33, 1);
const shelf_color = rgba(0.33, 0.30, 0.27, 1);
const locker_color = rgba(0.47, 0.51, 0.53, 1);
const stair_color = rgba(0.36, 0.38, 0.40, 1);
const void_color = rgba(0.035, 0.04, 0.045, 1);
const oxocarbon_pink = rgba(1.0, 0.49, 0.71, 1);
const typewriter_color = rgba(0.06, 0.06, 0.07, 1);

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

test "RPD first floor validates structurally" {
    load();
    try std.testing.expect(current.validate());
    try std.testing.expectEqual(room_capacity, current.room_count);
    try std.testing.expectEqual(@as(usize, 17), current.edge_count);
    try std.testing.expectEqual(@as(usize, 2), current.save_fixture_count);
}

test "player starts in south entrance and hunter starts east" {
    load();
    try std.testing.expect(current.player_spawn.z > 8.0);
    try std.testing.expect(@abs(current.player_spawn.x) < 1.0);
    try std.testing.expect(current.hunter_spawn.x > 18.0);
}

test "both save locations have hunter barriers" {
    load();
    var barriers: usize = 0;
    for (current.boxSlice()) |box| barriers += @intFromBool(box.hunter_block);
    try std.testing.expectEqual(@as(usize, 2), barriers);
    try std.testing.expect(current.isInSaveRoom(-1.0, 4.1));
    try std.testing.expect(current.isInSaveRoom(-9.5, -7.7));
}

test "six stair ramps are pitched and terminate on first floor" {
    load();
    var ramps: usize = 0;
    for (current.boxSlice()) |box| ramps += @intFromBool(box.pitch != 0);
    try std.testing.expectEqual(@as(usize, 6), ramps);
}
