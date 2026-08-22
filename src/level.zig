//! Hand-authored single-floor level.
//!
//! The 52 x 38 metre footprint and the navigation grid never change. The
//! layout keeps the regional style of the old generator: twelve rooms arranged
//! in a 4 x 3 grid, joined by an explicitly chosen connected graph and carved
//! together with two-tile-wide orthogonal corridors. Geometry, actor spawns,
//! save-room bounds and lights all live in one runtime `Level` value.

const std = @import("std");
const math = @import("math.zig");
pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

pub const footprint_half_x: f32 = 26;
pub const footprint_half_z: f32 = 19;
pub const floor_height: f32 = 5.5;
pub const tile_size: f32 = 2;
pub const tile_cols = 26;
pub const tile_rows = 19;
pub const tile_count = tile_cols * tile_rows;
pub const room_capacity = 12;
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
    is_roof: bool = false,
    // Invisible save-room perimeter. The player and camera ignore this category.
    hunter_block: bool = false,
};

const RoomRect = struct { min_col: u8, min_row: u8, cols: u8, rows: u8 };

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

// One room per region of the 4 x 3 grid, placed by hand. Row-major indices:
// 0 is the north-west corner and 11 the south-east corner (the save room).
const room_rects = [_]RoomRect{
    .{ .min_col = 1, .min_row = 1, .cols = 5, .rows = 3 }, //  0 north-west start
    .{ .min_col = 8, .min_row = 2, .cols = 4, .rows = 4 }, //  1 north hall
    .{ .min_col = 14, .min_row = 1, .cols = 3, .rows = 5 }, // 2 north corridor room
    .{ .min_col = 19, .min_row = 3, .cols = 4, .rows = 3 }, // 3 north-east
    .{ .min_col = 2, .min_row = 7, .cols = 3, .rows = 4 }, //  4 west wing
    .{ .min_col = 9, .min_row = 8, .cols = 5, .rows = 4 }, //  5 central atrium
    .{ .min_col = 16, .min_row = 7, .cols = 4, .rows = 3 }, // 6 east gallery
    .{ .min_col = 20, .min_row = 10, .cols = 4, .rows = 4 }, // 7 south-east stairwell
    .{ .min_col = 1, .min_row = 13, .cols = 4, .rows = 4 }, // 8 south-west storage
    .{ .min_col = 7, .min_row = 14, .cols = 5, .rows = 3 }, // 9 south corridor room
    .{ .min_col = 15, .min_row = 13, .cols = 3, .rows = 4 }, // 10 south passage
    .{ .min_col = 20, .min_row = 14, .cols = 4, .rows = 4 }, // 11 south-east save room
};

// A spanning tree plus five cycle edges: plenty of loops for chases without
// losing the tree's long dead-end character.
const room_edges = [_]Edge{
    .{ .a = 0, .b = 1 },
    .{ .a = 1, .b = 2 },
    .{ .a = 2, .b = 3 },
    .{ .a = 1, .b = 5 },
    .{ .a = 4, .b = 5 },
    .{ .a = 5, .b = 6 },
    .{ .a = 6, .b = 7 },
    .{ .a = 6, .b = 10 },
    .{ .a = 4, .b = 8 },
    .{ .a = 8, .b = 9 },
    .{ .a = 10, .b = 11 },
    .{ .a = 0, .b = 4 },
    .{ .a = 2, .b = 6 },
    .{ .a = 5, .b = 9 },
    .{ .a = 9, .b = 10 },
    .{ .a = 7, .b = 11 },
};

const start_room_index: usize = 0;
const save_room_index: usize = 11;

// Hand-placed furniture: (room, tile offset from the room's minimum corner,
// half extents, colour). Every piece sits off the centre lanes the corridors
// follow and away from doorway mouths, so capsule routes stay intact.
const Furniture = struct { room: usize, dc: u8, dr: u8, hx: f32, hy: f32, hz: f32, color: Vec4 };
const furniture = [_]Furniture{
    .{ .room = 0, .dc = 0, .dr = 0, .hx = 0.50, .hy = 0.60, .hz = 0.50, .color = crate_color },
    .{ .room = 0, .dc = 4, .dr = 2, .hx = 0.70, .hy = 0.55, .hz = 0.45, .color = wood_color },
    .{ .room = 1, .dc = 0, .dr = 0, .hx = 0.40, .hy = 0.95, .hz = 0.50, .color = locker_color },
    .{ .room = 1, .dc = 3, .dr = 3, .hx = 0.60, .hy = 0.70, .hz = 0.60, .color = crate_color },
    .{ .room = 2, .dc = 0, .dr = 0, .hx = 0.35, .hy = 1.00, .hz = 0.70, .color = shelf_color },
    .{ .room = 2, .dc = 2, .dr = 4, .hx = 0.55, .hy = 0.65, .hz = 0.45, .color = wood_color },
    .{ .room = 3, .dc = 0, .dr = 0, .hx = 0.45, .hy = 0.75, .hz = 0.45, .color = crate_color },
    .{ .room = 3, .dc = 3, .dr = 2, .hx = 0.65, .hy = 0.55, .hz = 0.50, .color = shelf_color },
    .{ .room = 4, .dc = 0, .dr = 0, .hx = 0.50, .hy = 0.85, .hz = 0.40, .color = locker_color },
    .{ .room = 4, .dc = 2, .dr = 3, .hx = 0.55, .hy = 0.60, .hz = 0.55, .color = crate_color },
    .{ .room = 5, .dc = 0, .dr = 0, .hx = 0.70, .hy = 0.55, .hz = 0.70, .color = wood_color },
    .{ .room = 5, .dc = 4, .dr = 0, .hx = 0.40, .hy = 0.95, .hz = 0.45, .color = locker_color },
    .{ .room = 5, .dc = 4, .dr = 3, .hx = 0.60, .hy = 0.80, .hz = 0.60, .color = crate_color },
    .{ .room = 6, .dc = 0, .dr = 0, .hx = 0.45, .hy = 0.90, .hz = 0.35, .color = shelf_color },
    .{ .room = 6, .dc = 3, .dr = 2, .hx = 0.55, .hy = 0.65, .hz = 0.55, .color = wood_color },
    .{ .room = 7, .dc = 0, .dr = 0, .hx = 0.50, .hy = 0.70, .hz = 0.50, .color = crate_color },
    .{ .room = 7, .dc = 1, .dr = 3, .hx = 0.65, .hy = 0.55, .hz = 0.45, .color = wood_color },
    .{ .room = 7, .dc = 3, .dr = 3, .hx = 0.40, .hy = 0.95, .hz = 0.40, .color = locker_color },
    .{ .room = 8, .dc = 0, .dr = 0, .hx = 0.55, .hy = 0.60, .hz = 0.55, .color = crate_color },
    .{ .room = 8, .dc = 3, .dr = 3, .hx = 0.70, .hy = 0.55, .hz = 0.40, .color = shelf_color },
    .{ .room = 9, .dc = 0, .dr = 0, .hx = 0.45, .hy = 0.80, .hz = 0.50, .color = wood_color },
    .{ .room = 9, .dc = 4, .dr = 2, .hx = 0.55, .hy = 0.65, .hz = 0.55, .color = crate_color },
    .{ .room = 10, .dc = 0, .dr = 0, .hx = 0.35, .hy = 1.00, .hz = 0.60, .color = locker_color },
    .{ .room = 10, .dc = 2, .dr = 3, .hx = 0.50, .hy = 0.70, .hz = 0.50, .color = wood_color },
    .{ .room = 11, .dc = 0, .dr = 0, .hx = 0.50, .hy = 0.60, .hz = 0.50, .color = crate_color },
};

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
        return x > self.save_min_x and x < self.save_max_x and z > self.save_min_z and z < self.save_max_z;
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

    // Structural validation independent of Box3D/navmesh. Navmesh-level checks
    // cover the two different agents before the level goes live.
    pub fn validate(self: *const Level) bool {
        if (self.room_count != room_capacity or self.box_count == 0 or self.box_count > max_boxes) return false;
        const distance = self.graphDistance(self.start_room, self.save_room) orelse return false;
        if (distance < 3 or !self.isInSaveRoom(self.save_room_target.x, self.save_room_target.z)) return false;
        if (self.isInSaveRoom(self.hunter_spawn.x, self.hunter_spawn.z)) return false;
        const target_col = worldTile(self.save_room_target.x, footprint_half_x, tile_cols) orelse return false;
        const target_row = worldTile(self.save_room_target.z, footprint_half_z, tile_rows) orelse return false;
        if (!self.walkable[target_row * tile_cols + target_col]) return false;
        var barriers: usize = 0;
        for (self.boxSlice()) |box| barriers += @intFromBool(box.hunter_block);
        return barriers == 4;
    }

    fn addBox(self: *Level, box: Box) void {
        std.debug.assert(self.box_count < max_boxes);
        self.boxes[self.box_count] = box;
        self.box_count += 1;
    }
};

pub var current: Level = undefined;

// Rebuild the authored level into the runtime slot.
pub fn load() void {
    current = build();
}

fn build() Level {
    var result = Level{};
    placeRooms(&result);
    connectRooms(&result);
    carveRoomsAndCorridors(&result);
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
    for (room_edges) |edge| addEdge(result, edge);
}

fn addEdge(result: *Level, edge: Edge) void {
    std.debug.assert(result.edge_count < edge_capacity);
    result.edges[result.edge_count] = edge;
    result.edge_count += 1;
    result.rooms[edge.a].neighbors |= @as(u16, 1) << @intCast(edge.b);
    result.rooms[edge.b].neighbors |= @as(u16, 1) << @intCast(edge.a);
}

fn carveRoomsAndCorridors(result: *Level) void {
    for (result.rooms[0..result.room_count]) |room| {
        for (room.min_row..room.min_row + room.rows) |row| {
            for (room.min_col..room.min_col + room.cols) |col| setWalkable(result, col, row);
        }
    }
    for (result.edges[0..result.edge_count]) |edge| {
        const a = roomCenterTile(result.rooms[edge.a]);
        const b = roomCenterTile(result.rooms[edge.b]);
        // Fixed L-shape orientation: run horizontally first, then vertically.
        carveHorizontal(result, a[0], b[0], a[1]);
        carveVertical(result, a[1], b[1], b[0]);
    }
}

fn roomCenterTile(room: Room) [2]usize {
    return .{ room.min_col + room.cols / 2, room.min_row + room.rows / 2 };
}

fn carveHorizontal(result: *Level, from: usize, to: usize, row: usize) void {
    const low = @min(from, to);
    const high = @max(from, to);
    for (low..high + 1) |col| {
        setWalkable(result, col, row);
        setWalkable(result, col, if (row + 1 < tile_rows - 1) row + 1 else row - 1);
    }
}

fn carveVertical(result: *Level, from: usize, to: usize, col: usize) void {
    const low = @min(from, to);
    const high = @max(from, to);
    for (low..high + 1) |row| {
        setWalkable(result, col, row);
        setWalkable(result, if (col + 1 < tile_cols - 1) col + 1 else col - 1, row);
    }
}

fn setWalkable(result: *Level, col: usize, row: usize) void {
    if (col < tile_cols and row < tile_rows) result.walkable[row * tile_cols + col] = true;
}

fn chooseObjectives(result: *Level) void {
    const start = result.rooms[start_room_index].center();
    const save = result.rooms[save_room_index];
    const save_center = save.center();
    result.start_room = start_room_index;
    result.save_room = save_room_index;
    result.player_spawn = start;
    result.save_room_target = save_center;
    result.save_min_x = -footprint_half_x + @as(f32, @floatFromInt(save.min_col)) * tile_size + 0.25;
    result.save_max_x = result.save_min_x + @as(f32, @floatFromInt(save.cols)) * tile_size - 0.5;
    result.save_min_z = -footprint_half_z + @as(f32, @floatFromInt(save.min_row)) * tile_size + 0.25;
    result.save_max_z = result.save_min_z + @as(f32, @floatFromInt(save.rows)) * tile_size - 0.5;

    // Hunter starts in the room with greatest Euclidean separation from the
    // player, excluding the protected room.
    var best_distance: f32 = -1;
    for (0..result.room_count) |index| {
        if (index == result.start_room or index == result.save_room) continue;
        const center = result.rooms[index].center();
        const dx = center.x - start.x;
        const dz = center.z - start.z;
        const distance = dx * dx + dz * dz;
        if (distance > best_distance) {
            best_distance = distance;
            result.hunter_spawn = center;
        }
    }
}

fn buildGeometry(result: *Level) void {
    result.addBox(slab(0, 0, 0, footprint_half_x, footprint_half_z));
    result.addBox(ceiling(0, floor_height, 0, footprint_half_x, footprint_half_z));
    buildHorizontalWalls(result);
    buildVerticalWalls(result);

    // Hand-placed furniture, kept clear of the centre lanes used by corridors.
    for (furniture) |item| {
        const room = room_rects[item.room];
        std.debug.assert(item.dc < room.cols and item.dr < room.rows);
        const center = tileCenter(room.min_col + item.dc, room.min_row + item.dr);
        result.addBox(solid(center.x, item.hy, center.z, item.hx, item.hy, item.hz, item.color));
    }

    // A visible save fixture sits away from the open target at room centre.
    const save = result.rooms[result.save_room];
    const save_center = save.center();
    const offset_x: f32 = if (save_center.x < 0) 1.8 else -1.8;
    result.addBox(visual(save_center.x + offset_x, 0.8, save_center.z, 1.1, 0.8, 0.65, oxocarbon_pink));
    result.addBox(visual(save_center.x + offset_x, 1.66, save_center.z, 0.28, 0.06, 0.18, typewriter_color));

    // Seal the complete room perimeter for the hunter. Physical walls still
    // define ordinary room boundaries; these four invisible boxes close every
    // opening and also occlude hunter sight rays.
    const min_x = -footprint_half_x + @as(f32, @floatFromInt(save.min_col)) * tile_size;
    const max_x = min_x + @as(f32, @floatFromInt(save.cols)) * tile_size;
    const min_z = -footprint_half_z + @as(f32, @floatFromInt(save.min_row)) * tile_size;
    const max_z = min_z + @as(f32, @floatFromInt(save.rows)) * tile_size;
    result.addBox(hunterDoorX((min_x + max_x) * 0.5, min_z, (max_x - min_x) * 0.5));
    result.addBox(hunterDoorX((min_x + max_x) * 0.5, max_z, (max_x - min_x) * 0.5));
    result.addBox(hunterDoorZ(min_x, (min_z + max_z) * 0.5, (max_z - min_z) * 0.5));
    result.addBox(hunterDoorZ(max_x, (min_z + max_z) * 0.5, (max_z - min_z) * 0.5));
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

fn buildHorizontalWalls(result: *Level) void {
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
            const x = -footprint_half_x + (@as(f32, @floatFromInt(start)) + @as(f32, @floatFromInt(length)) * 0.5) * tile_size;
            const z = -footprint_half_z + @as(f32, @floatFromInt(boundary_row)) * tile_size;
            result.addBox(wallX(x, 0, z, @as(f32, @floatFromInt(length)), wall_color));
        }
    }
}

fn buildVerticalWalls(result: *Level) void {
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
            const x = -footprint_half_x + @as(f32, @floatFromInt(boundary_col)) * tile_size;
            const z = -footprint_half_z + @as(f32, @floatFromInt(start)) + @as(f32, @floatFromInt(length)) * 0.5 * tile_size;
            result.addBox(wallZ(x, 0, z, @as(f32, @floatFromInt(length)), wall_color));
        }
    }
}

fn deriveLights(result: *Level) void {
    // Always light start/save first, then spread the remaining fixtures across
    // the other rooms. The shader has eight fixture slots.
    const first = [_]usize{ result.start_room, result.save_room };
    for (first) |index| addRoomLight(result, index);
    for (0..result.room_count) |index| {
        if (result.light_count == light_capacity) break;
        if (index == result.start_room or index == result.save_room) continue;
        addRoomLight(result, index);
    }
}

fn addRoomLight(result: *Level, index: usize) void {
    const room = result.rooms[index];
    const center = room.center();
    const radius = @max(@as(f32, @floatFromInt(room.cols)), @as(f32, @floatFromInt(room.rows))) * tile_size * 0.9;
    result.lights[result.light_count] = .{ .x = center.x, .y = 4.1, .z = center.z, .w = @max(radius, 7) };
    result.light_count += 1;
}

fn tileCenter(col: usize, row: usize) Vec3 {
    return .{
        .x = -footprint_half_x + (@as(f32, @floatFromInt(col)) + 0.5) * tile_size,
        .z = -footprint_half_z + (@as(f32, @floatFromInt(row)) + 0.5) * tile_size,
    };
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

test "authored level validates structurally" {
    load();
    try std.testing.expect(current.validate());
    try std.testing.expect((current.graphDistance(current.start_room, current.save_room) orelse 0) >= 3);
    try std.testing.expect(current.player_spawn.x >= -footprint_half_x and current.player_spawn.x <= footprint_half_x);
    try std.testing.expect(current.player_spawn.z >= -footprint_half_z and current.player_spawn.z <= footprint_half_z);
    try std.testing.expectEqual(room_capacity, current.room_count);
    try std.testing.expectEqual(@as(usize, 16), current.edge_count);
}
