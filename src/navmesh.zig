//! Grid navigation mesh with A* pathfinding, the same approach the RE Engine
//! uses for Mr X in Resident Evil 2 Remake: a walkability map baked from the
//! level's collision geometry, searched with A*, returning a route the
//! character's own movement walks waypoint by waypoint.
//!
//! The level is a set of axis-aligned boxes, so a uniform grid is an exact
//! navmesh proxy. Every cell whose footprint (grown by the agent's capsule
//! radius) touches a collidable, above-floor box is marked blocked; the floor
//! slab and roof never block, and non-collidable decor is ignored. Paths are
//! 8-connected with corner-cut prevention so routes stay clean through doors.

const std = @import("std");
const b3 = @import("box3d");
const level = @import("level.zig");

// Level footprint and resolution. x in [-26, 26] -> 104 cells, z in [-19, 19]
// -> 76 cells at 0.5 m.
pub const level_cols = 104;
pub const level_rows = 76;

// How many cells around the start/goal A* will snap to when the exact cell is
// blocked (e.g. a patrol point inside a wall) or outside the grid.
const snap_ring: usize = 10;

pub const BuildOptions = struct {
    radius: f32,
    include_hunter_block: bool = true,
};

pub const HunterInfluence = struct {
    x: f32,
    z: f32,
    hard_radius: f32,
    danger_radius: f32,
    danger_penalty: f32,
};

pub fn Grid(comptime cols: comptime_int, comptime rows: comptime_int) type {
    return struct {
        const Self = @This();
        pub const N = cols * rows;

        pub const cell_size: f32 = 0.5;
        pub const min_x: f32 = -26.0;
        pub const max_x: f32 = 26.0;
        pub const min_z: f32 = -19.0;
        pub const max_z: f32 = 19.0;

        const OpenEntry = struct { cell: usize, f: f32 };

        // Walkability map (baked once from the level geometry).
        blocked: [N]bool = @splat(false),

        // A* scratch, owned by the grid so findPath needs no allocation.
        open: [N]OpenEntry = undefined,
        open_count: usize = 0,
        // Heap position of each cell currently in the open set, or -1.
        open_index: [N]i32 = @splat(-1),
        g_cost: [N]f32 = undefined,
        came_from: [N]i32 = @splat(-1),
        closed: [N]bool = @splat(false),
        // Connected-component id per walkable cell, so an unreachable goal can
        // be rejected instantly instead of by a full search.
        component: [N]i32 = @splat(-1),
        components_valid: bool = false,

        pub fn colOf(self: *Self, x: f32) ?i32 {
            _ = self;
            const col: i32 = @intFromFloat(@floor((x - min_x) / cell_size));
            if (col < 0 or col >= cols) return null;
            return col;
        }

        pub fn rowOf(self: *Self, z: f32) ?i32 {
            _ = self;
            const row: i32 = @intFromFloat(@floor((z - min_z) / cell_size));
            if (row < 0 or row >= rows) return null;
            return row;
        }

        pub fn cellAt(self: *Self, x: f32, z: f32) ?usize {
            const col = self.colOf(x) orelse return null;
            const row = self.rowOf(z) orelse return null;
            return @intCast(@as(i32, row) * cols + col);
        }

        pub fn worldX(self: *Self, col: usize) f32 {
            _ = self;
            return min_x + (@as(f32, @floatFromInt(col)) + 0.5) * cell_size;
        }

        pub fn worldZ(self: *Self, row: usize) f32 {
            _ = self;
            return min_z + (@as(f32, @floatFromInt(row)) + 0.5) * cell_size;
        }

        pub fn worldAt(self: *Self, cell: usize) b3.b3Pos {
            return .{ .x = self.worldX(cell % cols), .y = 0, .z = self.worldZ(cell / cols) };
        }

        pub fn isWalkable(self: *Self, cell: usize) bool {
            return !self.blocked[cell];
        }

        // Mark every cell whose expanded footprint overlaps a blocking box.
        // Only collidable, non-roof boxes whose top rises above the walk
        // surface block navigation; the floor slab and roof are ignored.
        pub fn buildFromBoxes(self: *Self, boxes: []const level.Box, radius: f32) void {
            self.buildFromBoxesWithOptions(boxes, .{ .radius = radius });
        }

        pub fn buildFromBoxesWithOptions(self: *Self, boxes: []const level.Box, options: BuildOptions) void {
            self.components_valid = false;
            @memset(self.blocked[0..], false);
            for (0..N) |cell| {
                const cx = self.worldX(cell % cols);
                const cz = self.worldZ(cell / cols);
                const half = cell_size * 0.5 + options.radius;
                for (boxes) |box| {
                    if (!box.collidable or box.is_roof) continue;
                    if (!options.include_hunter_block and box.hunter_block) continue;
                    if (box.center.y + box.half_extents.y <= 0.05) continue;
                    if (aabbXZ(cx, cz, half, box)) {
                        self.blocked[cell] = true;
                        break;
                    }
                }
            }
        }

        // Tag every walkable cell with its connected component. A* connectivity
        // (cardinal moves always allowed, diagonals only with both orthogonals
        // open) is exactly 4-connectivity, so two cells are A* reachable from
        // each other iff they share a component.
        pub fn computeComponents(self: *Self) void {
            @setRuntimeSafety(false);
            @memset(self.component[0..], -1);
            var next_id: i32 = 0;
            for (0..N) |start| {
                if (self.blocked[start] or self.component[start] >= 0) continue;
                var head: usize = 0;
                var tail: usize = 0;
                self.open[tail].cell = start;
                tail += 1;
                self.component[start] = next_id;
                while (head < tail) {
                    const cell = self.open[head].cell;
                    head += 1;
                    const col: i32 = @intCast(cell % cols);
                    const row: i32 = @intCast(cell / cols);
                    const nbrs = [_][2]i32{
                        .{ col - 1, row },
                        .{ col + 1, row },
                        .{ col, row - 1 },
                        .{ col, row + 1 },
                    };
                    for (nbrs) |nb| {
                        if (nb[0] < 0 or nb[0] >= cols or nb[1] < 0 or nb[1] >= rows) continue;
                        const ncell: usize = @intCast(@as(i32, nb[1]) * cols + nb[0]);
                        if (self.blocked[ncell] or self.component[ncell] >= 0) continue;
                        self.component[ncell] = next_id;
                        self.open[tail].cell = ncell;
                        tail += 1;
                    }
                }
                next_id += 1;
            }
            self.components_valid = true;
        }

        // The nearest walkable cell to (x, z), scanning outward in square rings.
        pub fn nearestWalkable(self: *Self, x: f32, z: f32, max_ring: usize) ?usize {
            return self.nearestWalkableInner(x, z, max_ring, null);
        }

        // The same snapped start cell used by an influenced path query. Map
        // rendering uses this to avoid drawing an unchecked connector from a
        // conservatively blocked player cell into the returned route.
        pub fn nearestWalkableWithInfluence(self: *Self, x: f32, z: f32, influence: HunterInfluence) ?usize {
            return self.nearestWalkableInner(x, z, snap_ring, influence);
        }

        fn nearestWalkableInner(self: *Self, x: f32, z: f32, max_ring: usize, influence: ?HunterInfluence) ?usize {
            @setRuntimeSafety(false);
            const cx = std.math.clamp(x, min_x, max_x);
            const cz = std.math.clamp(z, min_z, max_z);
            var start_col: i32 = @intFromFloat(@floor((cx - min_x) / cell_size));
            var start_row: i32 = @intFromFloat(@floor((cz - min_z) / cell_size));
            // Clamp the cell, not the world coordinate, so a point on the outer
            // edge still snaps to the innermost cell.
            start_col = std.math.clamp(start_col, 0, cols - 1);
            start_row = std.math.clamp(start_row, 0, rows - 1);
            var ring: usize = 0;
            while (ring <= max_ring) : (ring += 1) {
                const r: i32 = @intCast(ring);
                var d: i32 = -r;
                while (d <= r) : (d += 1) {
                    const candidates = [_][2]i32{
                        .{ start_col + d, start_row - r },
                        .{ start_col + d, start_row + r },
                        .{ start_col - r, start_row + d },
                        .{ start_col + r, start_row + d },
                    };
                    for (candidates) |pair| {
                        if (pair[0] < 0 or pair[0] >= cols or pair[1] < 0 or pair[1] >= rows) continue;
                        const cell: usize = @intCast(@as(i32, pair[1]) * cols + pair[0]);
                        if (!self.blocked[cell] and !self.isHardBlocked(cell, influence)) return cell;
                    }
                }
            }
            return null;
        }

        // A* from the nearest walkable cell to (start_x, start_z) to the
        // nearest walkable cell to (goal_x, goal_z). Writes cell-center
        // waypoints (start cell excluded, goal included) into `out` and returns
        // the count; 0 when unreachable or both ends snap to the same cell.
        pub fn findPath(self: *Self, start_x: f32, start_z: f32, goal_x: f32, goal_z: f32, out: []b3.b3Pos) usize {
            return self.findPathInner(start_x, start_z, goal_x, goal_z, out, null);
        }

        // A* with one circular hunter influence. The hard radius excludes every
        // cell whose square footprint touches it. The nonnegative danger cost
        // is added to base edge costs and falls linearly to zero at the danger
        // radius, leaving the octile heuristic admissible.
        pub fn findPathWithInfluence(self: *Self, start_x: f32, start_z: f32, goal_x: f32, goal_z: f32, out: []b3.b3Pos, influence: HunterInfluence) usize {
            return self.findPathInner(start_x, start_z, goal_x, goal_z, out, influence);
        }

        fn findPathInner(self: *Self, start_x: f32, start_z: f32, goal_x: f32, goal_z: f32, out: []b3.b3Pos, influence: ?HunterInfluence) usize {
            @setRuntimeSafety(false);
            const start = self.nearestWalkableInner(start_x, start_z, snap_ring, influence) orelse return 0;
            const goal = self.nearestWalkableInner(goal_x, goal_z, snap_ring, influence) orelse return 0;
            if (start == goal) return 0;
            if (!self.components_valid) self.computeComponents();
            // Unreachable goal: reject it without searching.
            if (self.component[start] != self.component[goal]) return 0;

            @memset(self.g_cost[0..], std.math.floatMax(f32));
            @memset(self.came_from[0..], -1);
            @memset(self.open_index[0..], -1);
            @memset(self.closed[0..], false);
            self.open_count = 0;

            self.g_cost[start] = 0;
            self.heapPush(start, self.heuristic(start, goal));

            while (self.open_count > 0) {
                const current = self.heapPop();
                if (self.closed[current]) continue;
                self.closed[current] = true;
                if (current == goal) return self.reconstruct(start, goal, out);

                const cur_col: i32 = @intCast(current % cols);
                const cur_row: i32 = @intCast(current / cols);
                var dc: i32 = -1;
                while (dc <= 1) : (dc += 1) {
                    var dr: i32 = -1;
                    while (dr <= 1) : (dr += 1) {
                        if (dc == 0 and dr == 0) continue;
                        const nc = cur_col + dc;
                        const nr = cur_row + dr;
                        if (nc < 0 or nc >= cols or nr < 0 or nr >= rows) continue;
                        const neighbor: usize = @intCast(@as(i32, nr) * cols + nc);
                        if (self.blocked[neighbor] or self.isHardBlocked(neighbor, influence) or self.closed[neighbor]) continue;
                        // Corner-cut prevention: a diagonal step needs both
                        // orthogonal neighbours open under both baked and
                        // dynamic blocking so paths don't clip walls or danger.
                        if (dc != 0 and dr != 0) {
                            const beside_col: usize = @intCast(cur_col + dc);
                            const beside_row: usize = @intCast(cur_row + dr);
                            const this_row: usize = @intCast(cur_row);
                            const horizontal = this_row * cols + beside_col;
                            const vertical = beside_row * cols + @as(usize, @intCast(cur_col));
                            if (self.blocked[horizontal] or self.isHardBlocked(horizontal, influence) or
                                self.blocked[vertical] or self.isHardBlocked(vertical, influence)) continue;
                        }
                        const step_cost: f32 = if (dc != 0 and dr != 0) 1.41421356 else 1.0;
                        const tentative = self.g_cost[current] + step_cost + self.dangerCost(neighbor, influence);
                        if (tentative >= self.g_cost[neighbor]) continue;
                        self.g_cost[neighbor] = tentative;
                        self.came_from[neighbor] = @intCast(current);
                        const f = tentative + self.heuristic(neighbor, goal);
                        if (self.open_index[neighbor] < 0) {
                            self.heapPush(neighbor, f);
                        } else {
                            self.heapDecreaseKey(neighbor, f);
                        }
                    }
                }
            }
            return 0;
        }

        fn isHardBlocked(self: *Self, cell: usize, influence: ?HunterInfluence) bool {
            const hunter = influence orelse return false;
            if (hunter.hard_radius <= 0) return false;
            return self.distanceSquaredToCell(cell, hunter.x, hunter.z) <= hunter.hard_radius * hunter.hard_radius;
        }

        fn dangerCost(self: *Self, cell: usize, influence: ?HunterInfluence) f32 {
            const hunter = influence orelse return 0;
            if (hunter.danger_radius <= 0 or hunter.danger_penalty <= 0) return 0;
            const distance = @sqrt(self.distanceSquaredToCell(cell, hunter.x, hunter.z));
            if (distance >= hunter.danger_radius) return 0;
            return hunter.danger_penalty * (1.0 - distance / hunter.danger_radius);
        }

        fn distanceSquaredToCell(self: *Self, cell: usize, x: f32, z: f32) f32 {
            const half = cell_size * 0.5;
            const dx = @max(@abs(x - self.worldX(cell % cols)) - half, 0);
            const dz = @max(@abs(z - self.worldZ(cell / cols)) - half, 0);
            return dx * dx + dz * dz;
        }

        fn reconstruct(self: *Self, start: usize, goal: usize, out: []b3.b3Pos) usize {
            @setRuntimeSafety(false);
            var steps: usize = 0;
            {
                var cell = goal;
                while (cell != start) : (cell = @intCast(self.came_from[cell])) {
                    steps += 1;
                }
            }
            if (steps > out.len) return 0;
            var index = steps;
            var cell = goal;
            while (cell != start) : (cell = @intCast(self.came_from[cell])) {
                index -= 1;
                out[index] = self.worldAt(cell);
            }
            return steps;
        }

        // Exact octile distance between two cells: a consistent heuristic, so
        // A* expands each cell at most once.
        fn heuristic(self: *Self, a: usize, b: usize) f32 {
            _ = self;
            const dc: f32 = @floatFromInt(@abs(@as(i32, @intCast(a % cols)) - @as(i32, @intCast(b % cols))));
            const dr: f32 = @floatFromInt(@abs(@as(i32, @intCast(a / cols)) - @as(i32, @intCast(b / cols))));
            const d = @max(dc, dr);
            const s = @min(dc, dr);
            return s * 1.41421356 + (d - s);
        }

        fn heapPush(self: *Self, cell: usize, f: f32) void {
            @setRuntimeSafety(false);
            self.open[self.open_count] = .{ .cell = cell, .f = f };
            self.open_index[cell] = @intCast(self.open_count);
            self.open_count += 1;
            var i = self.open_count - 1;
            while (i > 0) {
                const parent = (i - 1) / 2;
                if (self.open[parent].f <= self.open[i].f) break;
                self.swapOpen(parent, i);
                i = parent;
            }
        }

        fn heapDecreaseKey(self: *Self, cell: usize, f: f32) void {
            @setRuntimeSafety(false);
            var i: usize = @intCast(self.open_index[cell]);
            self.open[i].f = f;
            while (i > 0) {
                const parent = (i - 1) / 2;
                if (self.open[parent].f <= self.open[i].f) break;
                self.swapOpen(parent, i);
                i = parent;
            }
        }

        fn heapPop(self: *Self) usize {
            @setRuntimeSafety(false);
            const result = self.open[0].cell;
            self.open_index[result] = -1;
            self.open_count -= 1;
            if (self.open_count > 0) {
                self.open[0] = self.open[self.open_count];
                self.open_index[self.open[0].cell] = 0;
                var i: usize = 0;
                while (true) {
                    const left = i * 2 + 1;
                    const right = left + 1;
                    if (left >= self.open_count) break;
                    var smallest = left;
                    if (right < self.open_count and self.open[right].f < self.open[left].f) smallest = right;
                    if (self.open[smallest].f >= self.open[i].f) break;
                    self.swapOpen(smallest, i);
                    i = smallest;
                }
            }
            return result;
        }

        fn swapOpen(self: *Self, a: usize, b: usize) void {
            @setRuntimeSafety(false);
            const tmp = self.open[a];
            self.open[a] = self.open[b];
            self.open[b] = tmp;
            self.open_index[self.open[a].cell] = @intCast(a);
            self.open_index[self.open[b].cell] = @intCast(b);
        }
    };
}

// True when the XZ square around (cx, cz) overlaps the box's XZ footprint.
fn aabbXZ(cx: f32, cz: f32, half: f32, box: level.Box) bool {
    return @abs(cx - box.center.x) <= box.half_extents.x + half and
        @abs(cz - box.center.z) <= box.half_extents.z + half;
}

// Shared fixed-size grids, rebuilt whenever the runtime level changes.
pub var level_nav: Grid(level_cols, level_rows) = .{};
pub var player_nav: Grid(level_cols, level_rows) = .{};

pub fn buildLevel() void {
    const boxes = level.current.boxSlice();
    level_nav.buildFromBoxes(boxes, 0.5);
    player_nav.buildFromBoxesWithOptions(boxes, .{
        .radius = 0.35,
        .include_hunter_block = false,
    });
}

// Full agent-level validation used before a generated layout becomes live.
// The player must reach the target while the hunter must remain in a different
// component behind the hunter-only save-room perimeter.
pub fn validateLevel() bool {
    const target = level.current.save_room_target;
    if (!level.current.validate() or !level.current.isInSaveRoom(target.x, target.z)) return false;
    var path: [level_cols * level_rows]b3.b3Pos = undefined;
    if (player_nav.findPath(
        level.current.player_spawn.x,
        level.current.player_spawn.z,
        target.x,
        target.z,
        path[0..],
    ) == 0) return false;
    return level_nav.findPath(
        level.current.hunter_spawn.x,
        level.current.hunter_spawn.z,
        target.x,
        target.z,
        path[0..],
    ) == 0;
}

test "grid marks walls and furniture but clears open floor" {
    level.load();
    const generated = &level.current;
    var grid: Grid(level_cols, level_rows) = .{};
    grid.buildFromBoxes(generated.boxSlice(), 0.5);

    const spawn = grid.cellAt(generated.hunter_spawn.x, generated.hunter_spawn.z) orelse return error.TestUnexpectedResult;
    try std.testing.expect(grid.isWalkable(spawn));

    const wall = generated.boxes[2];
    const wall_cell = grid.cellAt(wall.center.x, wall.center.z) orelse return error.TestUnexpectedResult;
    try std.testing.expect(!grid.isWalkable(wall_cell));
}

test "navmesh routes across rooms through doorways" {
    level.load();
    const generated = &level.current;
    var grid: Grid(level_cols, level_rows) = .{};
    grid.buildFromBoxesWithOptions(generated.boxSlice(), .{ .radius = 0.35, .include_hunter_block = false });

    var path: [level_cols * level_rows]b3.b3Pos = undefined;
    const len = grid.findPath(
        generated.player_spawn.x,
        generated.player_spawn.z,
        generated.save_room_target.x,
        generated.save_room_target.z,
        path[0..],
    );
    try std.testing.expect(len > 1);
    for (path[0..len]) |waypoint| {
        const cell = grid.cellAt(waypoint.x, waypoint.z) orelse return error.TestUnexpectedResult;
        try std.testing.expect(grid.isWalkable(cell));
    }
}

test "authored level keeps save reachable for player and excluded from hunter" {
    var path: [level_cols * level_rows]b3.b3Pos = undefined;
    level.load();
    const generated = &level.current;
    var hunter_grid: Grid(level_cols, level_rows) = .{};
    var player_grid: Grid(level_cols, level_rows) = .{};
    hunter_grid.buildFromBoxes(generated.boxSlice(), 0.5);
    player_grid.buildFromBoxesWithOptions(generated.boxSlice(), .{
        .radius = 0.35,
        .include_hunter_block = false,
    });

    const target = generated.save_room_target;
    try std.testing.expect(generated.isInSaveRoom(target.x, target.z));
    try std.testing.expectEqual(@as(usize, 0), hunter_grid.findPath(
        generated.hunter_spawn.x,
        generated.hunter_spawn.z,
        target.x,
        target.z,
        path[0..],
    ));
    const player_path_len = player_grid.findPath(
        generated.player_spawn.x,
        generated.player_spawn.z,
        target.x,
        target.z,
        path[0..],
    );
    try std.testing.expect(player_path_len > 0);
}

test "buildFromBoxes clears blocked state when rebuilt" {
    var grid: Grid(4, 4) = .{};
    grid.blocked[0] = true;
    grid.buildFromBoxes(&.{}, 0.5);
    for (grid.blocked) |blocked| try std.testing.expect(!blocked);
}

test "hard hunter influence forces a footprint-safe detour" {
    var grid: Grid(12, 12) = .{};
    const start = grid.worldAt(6 * 12 + 1);
    const goal = grid.worldAt(6 * 12 + 10);
    const hunter = grid.worldAt(6 * 12 + 6);
    const influence: HunterInfluence = .{
        .x = hunter.x,
        .z = hunter.z,
        .hard_radius = 0.3,
        .danger_radius = 0,
        .danger_penalty = 0,
    };

    var direct: [64]b3.b3Pos = undefined;
    var detour: [64]b3.b3Pos = undefined;
    const direct_len = grid.findPath(start.x, start.z, goal.x, goal.z, direct[0..]);
    const detour_len = grid.findPathWithInfluence(start.x, start.z, goal.x, goal.z, detour[0..], influence);
    try std.testing.expect(direct_len > 0 and detour_len > 0);
    var left_direct_row = false;
    for (detour[0..detour_len]) |waypoint| {
        left_direct_row = left_direct_row or waypoint.z != start.z;
        const cell = grid.cellAt(waypoint.x, waypoint.z) orelse return error.TestUnexpectedResult;
        try std.testing.expect(!grid.isHardBlocked(cell, influence));
    }
    try std.testing.expect(left_direct_row);
}

test "soft hunter danger chooses a more distant route" {
    var grid: Grid(12, 12) = .{};
    const start = grid.worldAt(6 * 12 + 1);
    const goal = grid.worldAt(6 * 12 + 10);
    const hunter = grid.worldAt(6 * 12 + 6);
    const influence: HunterInfluence = .{
        .x = hunter.x,
        .z = hunter.z,
        .hard_radius = 0,
        .danger_radius = 2.0,
        .danger_penalty = 8.0,
    };

    var direct: [64]b3.b3Pos = undefined;
    var safer: [64]b3.b3Pos = undefined;
    const direct_len = grid.findPath(start.x, start.z, goal.x, goal.z, direct[0..]);
    const safer_len = grid.findPathWithInfluence(start.x, start.z, goal.x, goal.z, safer[0..], influence);
    try std.testing.expect(direct_len > 0 and safer_len > 0);

    var direct_nearest = std.math.floatMax(f32);
    for (direct[0..direct_len]) |waypoint| {
        direct_nearest = @min(direct_nearest, std.math.hypot(waypoint.x - hunter.x, waypoint.z - hunter.z));
    }
    var safer_nearest = std.math.floatMax(f32);
    for (safer[0..safer_len]) |waypoint| {
        safer_nearest = @min(safer_nearest, std.math.hypot(waypoint.x - hunter.x, waypoint.z - hunter.z));
    }
    try std.testing.expect(safer_nearest > direct_nearest);
}

test "dynamic hard blocker prevents diagonal corner cutting" {
    var grid: Grid(10, 10) = .{};
    const start_cell = 4 * 10 + 4;
    const goal_cell = 5 * 10 + 5;
    const start = grid.worldAt(start_cell);
    const goal = grid.worldAt(goal_cell);
    const right = grid.worldAt(4 * 10 + 5);
    const influence: HunterInfluence = .{
        .x = right.x + 0.24,
        .z = right.z - 0.24,
        .hard_radius = 0.05,
        .danger_radius = 0,
        .danger_penalty = 0,
    };

    try std.testing.expect(grid.isHardBlocked(4 * 10 + 5, influence));
    try std.testing.expect(!grid.isHardBlocked(start_cell, influence));
    try std.testing.expect(!grid.isHardBlocked(goal_cell, influence));

    var path: [32]b3.b3Pos = undefined;
    try std.testing.expectEqual(@as(usize, 1), grid.findPath(start.x, start.z, goal.x, goal.z, path[0..]));
    const len = grid.findPathWithInfluence(start.x, start.z, goal.x, goal.z, path[0..], influence);
    try std.testing.expect(len > 1);
}

test "dynamic hard blocker reports no route through a sealed corridor" {
    var grid: Grid(12, 12) = .{};
    @memset(grid.blocked[0..], true);
    for (0..12) |col| grid.blocked[6 * 12 + col] = false;

    const start = grid.worldAt(6 * 12 + 1);
    const goal = grid.worldAt(6 * 12 + 10);
    const hunter = grid.worldAt(6 * 12 + 6);
    var path: [32]b3.b3Pos = undefined;
    const len = grid.findPathWithInfluence(start.x, start.z, goal.x, goal.z, path[0..], .{
        .x = hunter.x,
        .z = hunter.z,
        .hard_radius = 0.1,
        .danger_radius = 2.0,
        .danger_penalty = 4.0,
    });
    try std.testing.expectEqual(@as(usize, 0), len);
}

test "default findPath matches a zero influence query" {
    var grid: Grid(8, 8) = .{};
    const start = grid.worldAt(0);
    const goal = grid.worldAt(8 * 8 - 1);
    const zero: HunterInfluence = .{
        .x = 0,
        .z = 0,
        .hard_radius = 0,
        .danger_radius = 0,
        .danger_penalty = 0,
    };
    var default_path: [32]b3.b3Pos = undefined;
    var influenced_path: [32]b3.b3Pos = undefined;
    const default_len = grid.findPath(start.x, start.z, goal.x, goal.z, default_path[0..]);
    const influenced_len = grid.findPathWithInfluence(start.x, start.z, goal.x, goal.z, influenced_path[0..], zero);
    try std.testing.expectEqual(default_len, influenced_len);
    for (default_path[0..default_len], influenced_path[0..influenced_len]) |expected, actual| {
        try std.testing.expectEqual(expected.x, actual.x);
        try std.testing.expectEqual(expected.z, actual.z);
    }
}

test "navmesh returns no path through a sealed wall" {
    var grid: Grid(12, 12) = .{};
    var row: usize = 0;
    while (row < 12) : (row += 1) grid.blocked[row * 12 + 6] = true;

    var path: [64]b3.b3Pos = undefined;
    const start = grid.worldAt(0);
    const goal = grid.worldAt(12 * 12 - 1);
    try std.testing.expectEqual(@as(usize, 0), grid.findPath(start.x, start.z, goal.x, goal.z, path[0..]));
}

test "navmesh routes through a door gap" {
    var grid: Grid(12, 12) = .{};
    var row: usize = 0;
    while (row < 12) : (row += 1) {
        if (row == 5 or row == 6) continue; // two-cell door
        grid.blocked[row * 12 + 6] = true;
    }

    var path: [64]b3.b3Pos = undefined;
    const start = grid.worldAt(0);
    const goal = grid.worldAt(12 * 12 - 1);
    const len = grid.findPath(start.x, start.z, goal.x, goal.z, path[0..]);
    try std.testing.expect(len > 1);
    for (path[0..len]) |waypoint| {
        const cell = grid.cellAt(waypoint.x, waypoint.z) orelse return error.TestUnexpectedResult;
        try std.testing.expect(grid.isWalkable(cell));
    }
}

test "nearest walkable snaps a blocked goal out of the wall" {
    level.load();
    const generated = &level.current;
    var grid: Grid(level_cols, level_rows) = .{};
    grid.buildFromBoxes(generated.boxSlice(), 0.5);

    // Inside the south wall itself; snap to the nearest open cell just north.
    const cell = grid.nearestWalkable(0, 19.0, 10) orelse return error.TestUnexpectedResult;
    try std.testing.expect(grid.isWalkable(cell));
}
