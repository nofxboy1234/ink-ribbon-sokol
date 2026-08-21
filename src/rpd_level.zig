//! Deterministic procedural single-floor level generation.
//!
//! The 52 x 38 metre footprint and the navigation grid never change. Rooms are
//! placed in a 4 x 3 regional grid, joined by a randomized connected graph and
//! carved together with two-tile-wide orthogonal corridors. Geometry, actor
//! spawns, save-room bounds and lights all live in one runtime `Level` value.

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

pub const Level = struct {
    seed: u64,
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

    // Structural validation independent of Box3D/navmesh. Generation also has
    // navmesh-level deterministic tests, including the two different agents.
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

    pub fn fingerprint(self: *const Level) u64 {
        var hash: u64 = 1469598103934665603;
        for (self.rooms[0..self.room_count]) |room| {
            const values = [_]u64{ room.min_col, room.min_row, room.cols, room.rows, room.neighbors };
            for (values) |value| {
                hash ^= value;
                hash *%= 1099511628211;
            }
        }
        for (self.edges[0..self.edge_count]) |edge| {
            hash ^= (@as(u64, edge.a) << 8) | edge.b;
            hash *%= 1099511628211;
        }
        hash ^= @as(u32, @bitCast(self.save_room_target.x));
        hash *%= 1099511628211;
        hash ^= @as(u32, @bitCast(self.save_room_target.z));
        return hash;
    }

    fn addBox(self: *Level, box: Box) void {
        std.debug.assert(self.box_count < max_boxes);
        self.boxes[self.box_count] = box;
        self.box_count += 1;
    }
};

pub var current: Level = undefined;

pub fn regenerate(seed: u64) void {
    current = generate(seed);
}

pub fn generate(seed: u64) Level {
    var result = Level{ .seed = seed };
    var random = Random.init(seed);
    placeRooms(&result, &random);
    connectRooms(&result, &random);
    carveRoomsAndCorridors(&result, &random);
    chooseObjectives(&result, &random);
    buildGeometry(&result, &random);
    deriveLights(&result);
    std.debug.assert(result.validate());
    return result;
}

const Random = struct {
    state: u64,

    fn init(seed: u64) Random {
        return .{ .state = if (seed == 0) 0x9e3779b97f4a7c15 else seed };
    }

    fn next(self: *Random) u64 {
        var x = self.state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.state = x;
        return x *% 2685821657736338717;
    }

    fn lessThan(self: *Random, limit: usize) usize {
        std.debug.assert(limit > 0);
        return @intCast(self.next() % limit);
    }

    fn range(self: *Random, min: usize, max_inclusive: usize) usize {
        return min + self.lessThan(max_inclusive - min + 1);
    }

    fn unit(self: *Random) f32 {
        return @as(f32, @floatFromInt(self.next() & 0x00ffffff)) / 16777216.0;
    }
};

fn placeRooms(result: *Level, random: *Random) void {
    // One room per region guarantees useful coverage without placement retries.
    const region_x = [_]usize{ 1, 7, 13, 19 };
    const region_z = [_]usize{ 1, 7, 13 };
    for (0..3) |regional_row| {
        for (0..4) |regional_col| {
            const width = random.range(3, 5);
            const height = random.range(3, 5);
            const x = region_x[regional_col] + random.lessThan(6 - width + 1);
            const z = region_z[regional_row] + random.lessThan(5 - height + 1);
            result.rooms[result.room_count] = .{
                .min_col = @intCast(x),
                .min_row = @intCast(z),
                .cols = @intCast(width),
                .rows = @intCast(height),
            };
            result.room_count += 1;
        }
    }
}

fn connectRooms(result: *Level, random: *Random) void {
    var candidates: [17]Edge = undefined;
    var count: usize = 0;
    for (0..3) |row| for (0..4) |col| {
        const index: u8 = @intCast(row * 4 + col);
        if (col + 1 < 4) {
            candidates[count] = .{ .a = index, .b = index + 1 };
            count += 1;
        }
        if (row + 1 < 3) {
            candidates[count] = .{ .a = index, .b = index + 4 };
            count += 1;
        }
    };
    var i = count;
    while (i > 1) {
        i -= 1;
        const other = random.lessThan(i + 1);
        const tmp = candidates[i];
        candidates[i] = candidates[other];
        candidates[other] = tmp;
    }

    var parent: [room_capacity]u8 = undefined;
    for (&parent, 0..) |*entry, index| entry.* = @intCast(index);
    for (candidates[0..count]) |edge| {
        const a_root = rootOf(&parent, edge.a);
        const b_root = rootOf(&parent, edge.b);
        if (a_root == b_root) continue;
        parent[b_root] = a_root;
        addEdge(result, edge);
    }
    // A few cycle edges make alternate routes without destroying the graph's
    // randomized spanning-tree character.
    for (candidates[0..count]) |edge| {
        if (hasEdge(result, edge) or random.lessThan(100) >= 28) continue;
        addEdge(result, edge);
    }
}

fn rootOf(parent: *[room_capacity]u8, start: u8) u8 {
    var node = start;
    while (parent[node] != node) node = parent[node];
    return node;
}

fn hasEdge(result: *const Level, edge: Edge) bool {
    return (result.rooms[edge.a].neighbors & (@as(u16, 1) << @intCast(edge.b))) != 0;
}

fn addEdge(result: *Level, edge: Edge) void {
    std.debug.assert(result.edge_count < edge_capacity);
    result.edges[result.edge_count] = edge;
    result.edge_count += 1;
    result.rooms[edge.a].neighbors |= @as(u16, 1) << @intCast(edge.b);
    result.rooms[edge.b].neighbors |= @as(u16, 1) << @intCast(edge.a);
}

fn carveRoomsAndCorridors(result: *Level, random: *Random) void {
    for (result.rooms[0..result.room_count]) |room| {
        for (room.min_row..room.min_row + room.rows) |row| {
            for (room.min_col..room.min_col + room.cols) |col| setWalkable(result, col, row);
        }
    }
    for (result.edges[0..result.edge_count]) |edge| {
        const a = roomCenterTile(result.rooms[edge.a]);
        const b = roomCenterTile(result.rooms[edge.b]);
        if ((random.next() & 1) == 0) {
            carveHorizontal(result, a[0], b[0], a[1]);
            carveVertical(result, a[1], b[1], b[0]);
        } else {
            carveVertical(result, a[1], b[1], a[0]);
            carveHorizontal(result, a[0], b[0], b[1]);
        }
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

fn chooseObjectives(result: *Level, random: *Random) void {
    const corners = [_]usize{ 0, 3, 8, 11 };
    result.start_room = corners[random.lessThan(corners.len)];
    var farthest: [room_capacity]usize = undefined;
    var farthest_count: usize = 0;
    var maximum: usize = 0;
    for (0..result.room_count) |candidate| {
        const distance = result.graphDistance(result.start_room, candidate) orelse unreachable;
        if (distance > maximum) {
            maximum = distance;
            farthest_count = 0;
        }
        if (distance == maximum) {
            farthest[farthest_count] = candidate;
            farthest_count += 1;
        }
    }
    result.save_room = farthest[random.lessThan(farthest_count)];

    const start = result.rooms[result.start_room].center();
    const save = result.rooms[result.save_room];
    const save_center = save.center();
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

fn buildGeometry(result: *Level, random: *Random) void {
    result.addBox(slab(0, 0, 0, footprint_half_x, footprint_half_z));
    result.addBox(ceiling(0, floor_height, 0, footprint_half_x, footprint_half_z));
    buildHorizontalWalls(result);
    buildVerticalWalls(result);

    // Random compact furniture in every room. Room and corridor center lines are
    // kept clear, preserving robust capsule routes through all graph nodes.
    for (result.rooms[0..result.room_count], 0..) |room, room_index| {
        const furniture_count = 1 + random.lessThan(3);
        const center_tile = roomCenterTile(room);
        var made: usize = 0;
        var attempts: usize = 0;
        while (made < furniture_count and attempts < 16) : (attempts += 1) {
            const col = room.min_col + random.lessThan(room.cols);
            const row = room.min_row + random.lessThan(room.rows);
            const dc = @abs(@as(i32, @intCast(col)) - @as(i32, @intCast(center_tile[0])));
            const dr = @abs(@as(i32, @intCast(row)) - @as(i32, @intCast(center_tile[1])));
            // Preserve the full horizontal and vertical centre lanes used by
            // graph corridors, including enough side clearance for capsules.
            if (dc <= 1 or dr <= 1) continue;
            const center = tileCenter(col, row);
            const hx = 0.42 + random.unit() * 0.35;
            const hz = 0.42 + random.unit() * 0.35;
            const colors = [_]Vec4{ wood_color, crate_color, shelf_color, locker_color };
            result.addBox(solid(center.x, 0.55, center.z, hx, 0.55 + random.unit() * 0.45, hz, colors[random.lessThan(colors.len)]));
            made += 1;
        }
        if (made == 0) {
            // Small corner furniture is already inside the wall-clearance band,
            // so it adds visible/physical variation without narrowing a route.
            const corner = tileCenter(room.min_col, room.min_row);
            result.addBox(solid(corner.x, 0.55, corner.z, 0.4, 0.55, 0.4, crate_color));
        }
        _ = room_index;
    }

    // A visible save fixture sits away from the open target at room centre.
    const save = result.rooms[result.save_room];
    const save_center = save.center();
    const offset_x: f32 = if (save_center.x < 0) 1.8 else -1.8;
    result.addBox(visual(save_center.x + offset_x, 0.8, save_center.z, 1.1, 0.8, 0.65, oxocarbon_pink));
    result.addBox(visual(save_center.x + offset_x, 1.66, save_center.z, 0.28, 0.06, 0.18, typewriter_color));

    // Seal the complete room perimeter for the hunter. Physical walls still
    // define ordinary room boundaries; these four invisible boxes close every
    // possible generated opening and also occlude hunter sight rays.
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
            const z = -footprint_half_z + (@as(f32, @floatFromInt(start)) + @as(f32, @floatFromInt(length)) * 0.5) * tile_size;
            result.addBox(wallZ(x, 0, z, @as(f32, @floatFromInt(length)), wall_color));
        }
    }
}

fn deriveLights(result: *Level) void {
    // Always light start/save first, then spread the remaining fixtures across
    // the generated rooms. The shader has eight fixture slots.
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

test "same seed produces identical procedural level" {
    const a = generate(0x12345678);
    const b = generate(0x12345678);
    try std.testing.expectEqual(a.fingerprint(), b.fingerprint());
    try std.testing.expectEqual(a.box_count, b.box_count);
    try std.testing.expectEqual(a.save_room, b.save_room);
}

test "different seeds vary layouts" {
    const a = generate(1);
    const b = generate(2);
    try std.testing.expect(a.fingerprint() != b.fingerprint());
}

test "generated graph and protected distant room validate across seeds" {
    for (1..65) |seed| {
        const generated = generate(seed);
        try std.testing.expect(generated.validate());
        try std.testing.expect((generated.graphDistance(generated.start_room, generated.save_room) orelse 0) >= 3);
        try std.testing.expect(generated.player_spawn.x >= -footprint_half_x and generated.player_spawn.x <= footprint_half_x);
        try std.testing.expect(generated.player_spawn.z >= -footprint_half_z and generated.player_spawn.z <= footprint_half_z);
    }
}
