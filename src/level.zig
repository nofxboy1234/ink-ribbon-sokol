//! Runtime level data imported exclusively from `level/level.glb`.
//!
//! Blender owns the scene layout. Each mesh node becomes an oriented Box3D
//! collision/render box and a required `PlayerSpawn` node defines the start
//! position, facing direction, and ground height. An optional `HunterSpawn`
//! node enables the hunter and defines his starting position.

const std = @import("std");
const math = @import("math.zig");
const blender_level = @import("blender_level.zig");
const inventory = @import("inventory.zig");

pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

pub const max_boxes = blender_level.max_boxes;
pub const light_capacity = blender_level.max_lights;

// Runtime metadata arrays remain empty until equivalent nodes are authored in
// Blender and added to the importer. They keep the reusable interaction and
// rendering systems independent from any hard-coded level layout.
pub const DoorAxis = enum { x, z };
pub const DoorLock = enum { none, purple, pink, cyan };
pub const DoorDef = struct {
    position: Vec3,
    axis: DoorAxis,
    lock: DoorLock = .none,
    width: f32,
    height: f32,
    half_thickness: f32,
};
pub const max_doors = blender_level.max_doors;

pub const PickupDef = struct {
    position: Vec3,
    item: inventory.Item,
};
pub const max_pickups = blender_level.max_pickups;

pub const BreakableDef = struct {
    position: Vec3,
    half_extent: f32,
};
pub const max_breakables = blender_level.max_breakables;

pub const WindowDef = struct {
    center: Vec3,
    half_extents: Vec3,
};
pub const max_windows = 1;
pub const window_count = 0;
pub const window_defs: [max_windows]WindowDef = .{.{ .center = .{}, .half_extents = .{} }};

pub fn windowSlice() []const WindowDef {
    return window_defs[0..window_count];
}

pub const Box = struct {
    center: Vec3,
    half_extents: Vec3,
    color: Vec4,
    basis_x: Vec3 = .{ .x = 1 },
    basis_y: Vec3 = .{ .y = 1 },
    basis_z: Vec3 = .{ .z = 1 },
    pitch: f32 = 0,
    visible: bool = true,
    collidable: bool = true,
    nav_block: bool = true,
    is_roof: bool = false,
    hunter_block: bool = false,
};

const SaveBounds = struct { min_x: f32, max_x: f32, min_z: f32, max_z: f32 };

pub const Level = struct {
    boxes: [max_boxes]Box = undefined,
    box_count: usize = 0,
    player_spawn: Vec3 = .{},
    player_spawn_yaw: f32 = std.math.pi,
    hunter_spawn: Vec3 = .{},
    hunter_spawn_yaw: f32 = 0,
    hunter_enabled: bool = false,
    doors: [max_doors]DoorDef = undefined,
    door_count: usize = 0,
    pickups: [max_pickups]PickupDef = undefined,
    pickup_count: usize = 0,
    breakables: [max_breakables]BreakableDef = undefined,
    breakable_count: usize = 0,
    ending_areas: [blender_level.max_trigger_volumes]SaveBounds = undefined,
    ending_area_count: usize = 0,
    save_room_target: Vec3 = .{},
    save_fixtures: [2]Vec3 = @splat(.{}),
    save_fixture_count: usize = 0,
    save_targets: [2]Vec3 = @splat(.{}),
    save_target_count: usize = 0,
    save_bounds: [2]SaveBounds = @splat(.{ .min_x = 0, .max_x = 0, .min_z = 0, .max_z = 0 }),
    lights: [light_capacity]Vec4 = @splat(.{}),
    light_count: usize = 0,
    ground_y: f32 = 0,
    walk_min_x: f32 = 0,
    walk_max_x: f32 = 0,
    walk_min_z: f32 = 0,
    walk_max_z: f32 = 0,

    pub fn boxSlice(self: *const Level) []const Box {
        return self.boxes[0..self.box_count];
    }

    pub fn doorSlice(self: *const Level) []const DoorDef {
        return self.doors[0..self.door_count];
    }

    pub fn pickupSlice(self: *const Level) []const PickupDef {
        return self.pickups[0..self.pickup_count];
    }

    pub fn breakableSlice(self: *const Level) []const BreakableDef {
        return self.breakables[0..self.breakable_count];
    }

    pub fn isInEndingArea(self: *const Level, x: f32, z: f32) bool {
        for (self.ending_areas[0..self.ending_area_count]) |bounds| {
            if (x > bounds.min_x and x < bounds.max_x and z > bounds.min_z and z < bounds.max_z) return true;
        }
        return false;
    }

    pub fn isInSaveRoom(self: *const Level, x: f32, z: f32) bool {
        for (0..self.save_target_count) |index| {
            if (self.isInSaveRoomIndex(index, x, z)) return true;
        }
        return false;
    }

    pub fn isInSaveRoomIndex(self: *const Level, index: usize, x: f32, z: f32) bool {
        if (index >= self.save_target_count) return false;
        const bounds = self.save_bounds[index];
        return x > bounds.min_x and x < bounds.max_x and z > bounds.min_z and z < bounds.max_z;
    }

    pub fn saveRoomAt(self: *const Level, x: f32, z: f32) ?usize {
        for (0..self.save_target_count) |index| {
            if (self.isInSaveRoomIndex(index, x, z)) return index;
        }
        return null;
    }

    // True when a door sits on the perimeter of a save room and is therefore
    // the room's entrance. Save rooms are sealed against the hunter at these
    // doorways with hunter-only barriers, so the hunter can never enter.
    pub fn isSaveRoomDoor(self: *const Level, door: DoorDef) bool {
        const margin: f32 = 0.75;
        for (0..self.save_target_count) |index| {
            const bounds = self.save_bounds[index];
            const within_x = door.position.x >= bounds.min_x - margin and door.position.x <= bounds.max_x + margin;
            const within_z = door.position.z >= bounds.min_z - margin and door.position.z <= bounds.max_z + margin;
            const near_min_x = @abs(door.position.x - bounds.min_x) <= margin;
            const near_max_x = @abs(door.position.x - bounds.max_x) <= margin;
            const near_min_z = @abs(door.position.z - bounds.min_z) <= margin;
            const near_max_z = @abs(door.position.z - bounds.max_z) <= margin;
            // On a vertical boundary, centred along the wall's length. This
            // ignores corridors shared with other rooms because the door must
            // hug the save room's own edge.
            if ((near_min_x or near_max_x) and within_z) return true;
            if ((near_min_z or near_max_z) and within_x) return true;
        }
        return false;
    }

    pub fn validate(self: *const Level) bool {
        return self.box_count > 0 and self.box_count <= max_boxes and
            self.walk_min_x < self.walk_max_x and self.walk_min_z < self.walk_max_z and
            self.player_spawn.x >= self.walk_min_x and self.player_spawn.x <= self.walk_max_x and
            self.player_spawn.z >= self.walk_min_z and self.player_spawn.z <= self.walk_max_z;
    }

    fn addBox(self: *Level, box: Box) void {
        std.debug.assert(self.box_count < max_boxes);
        self.boxes[self.box_count] = box;
        self.box_count += 1;
    }
};

pub var current: Level = undefined;

pub fn loadDefault() void {
    current = build() catch |err| std.debug.panic("failed to import level/level.glb: {s}", .{@errorName(err)});
}

// Items, doors, save fixtures, and hunter encounters will be enabled once
// their metadata is authored in Blender rather than hard-coded in Zig.
pub fn hasGameplayMetadata() bool {
    return current.door_count > 0 or current.pickup_count > 0 or current.breakable_count > 0 or current.save_fixture_count > 0;
}

pub fn hunterEnabled() bool {
    return current.hunter_enabled;
}

pub fn insideWalkBounds(x: f32, z: f32) bool {
    return x >= current.walk_min_x and x <= current.walk_max_x and
        z >= current.walk_min_z and z <= current.walk_max_z;
}

pub fn supportsWalk(x: f32, z: f32) bool {
    for (current.boxSlice()) |box| {
        if (!box.collidable or box.nav_block) continue;
        const top = box.center.y + projectedHalfExtent(box, .y);
        if (@abs(top - current.ground_y) > 0.08) continue;
        if (@abs(x - box.center.x) <= projectedHalfExtent(box, .x) + 0.01 and
            @abs(z - box.center.z) <= projectedHalfExtent(box, .z) + 0.01)
        {
            return true;
        }
    }
    return false;
}

fn build() !Level {
    const imported = try blender_level.load();
    var result = Level{};
    result.player_spawn = fromImported(imported.player_spawn orelse return error.PlayerSpawnMissing);
    result.player_spawn_yaw = imported.player_yaw;
    result.ground_y = result.player_spawn.y;
    if (imported.hunter_spawn) |spawn| {
        result.hunter_spawn = fromImported(spawn);
        result.hunter_spawn_yaw = imported.hunter_yaw;
        result.hunter_enabled = true;
    } else {
        result.hunter_spawn = result.player_spawn;
    }
    result.walk_min_x = std.math.inf(f32);
    result.walk_max_x = -std.math.inf(f32);
    result.walk_min_z = std.math.inf(f32);
    result.walk_max_z = -std.math.inf(f32);

    for (imported.boxSlice()) |box| {
        var converted = Box{
            .center = fromImported(box.center),
            .half_extents = fromImported(box.half_extents),
            .basis_x = fromImported(box.basis_x),
            .basis_y = fromImported(box.basis_y),
            .basis_z = fromImported(box.basis_z),
            .color = geometry_color,
            .is_roof = box.is_roof,
        };

        // Geometry whose top is at the spawn's ground plane supports walking;
        // geometry extending above that plane is an obstacle for navigation.
        // This avoids guessing which arbitrarily named mesh is the floor.
        converted.nav_block = converted.center.y + projectedHalfExtent(converted, .y) > result.ground_y + 0.05;
        result.addBox(converted);

        const half_x = projectedHalfExtent(converted, .x);
        const half_z = projectedHalfExtent(converted, .z);
        result.walk_min_x = @min(result.walk_min_x, converted.center.x - half_x);
        result.walk_max_x = @max(result.walk_max_x, converted.center.x + half_x);
        result.walk_min_z = @min(result.walk_min_z, converted.center.z - half_z);
        result.walk_max_z = @max(result.walk_max_z, converted.center.z + half_z);
    }

    for (imported.doors[0..imported.door_count]) |door| {
        const box = door.box;
        const width = box.half_extents.x * 2.0;
        const height = box.half_extents.y * 2.0;
        const thickness = box.half_extents.z;
        if (width <= 0.5 or height <= 1.0 or thickness <= 0.01) return error.InvalidDoorDimensions;
        result.doors[result.door_count] = .{
            .position = fromImported(box.center),
            .axis = if (@abs(box.basis_x.x) >= @abs(box.basis_x.z)) .x else .z,
            .lock = switch (door.lock) {
                .none => .none,
                .purple => .purple,
                .pink => .pink,
                .cyan => .cyan,
            },
            .width = width,
            .height = height,
            .half_thickness = thickness,
        };
        result.door_count += 1;
    }

    for (imported.pickups[0..imported.pickup_count]) |pickup| {
        result.pickups[result.pickup_count] = .{
            .position = fromImported(pickup.position),
            .item = switch (pickup.kind) {
                .ammo => .{ .kind = .ammo, .amount = 12 },
                .health => .{ .kind = .health, .amount = 1 },
                .key_purple => .{ .kind = .key_purple, .amount = 1 },
                .key_pink => .{ .kind = .key_pink, .amount = 1 },
                .key_cyan => .{ .kind = .key_cyan, .amount = 1 },
            },
        };
        result.pickup_count += 1;
    }

    for (imported.breakables[0..imported.breakable_count]) |box| {
        result.breakables[result.breakable_count] = .{
            .position = fromImported(box.center),
            .half_extent = @max(box.half_extents.x, @max(box.half_extents.y, box.half_extents.z)),
        };
        result.breakable_count += 1;
    }

    for (imported.save_fixtures[0..imported.save_fixture_count]) |fixture| {
        if (result.save_fixture_count == result.save_fixtures.len) return error.TooManySaveFixtures;
        result.save_fixtures[result.save_fixture_count] = fromImported(fixture);
        result.save_fixture_count += 1;
    }

    for (imported.save_rooms[0..imported.save_room_count]) |room| {
        if (result.save_target_count == result.save_bounds.len) return error.TooManySaveRooms;
        const center = fromImported(room.center);
        const half = fromImported(room.half_extents);
        result.save_bounds[result.save_target_count] = .{
            .min_x = center.x - half.x,
            .max_x = center.x + half.x,
            .min_z = center.z - half.z,
            .max_z = center.z + half.z,
        };
        // GLB node order is not the authoring order, so a fixture can never
        // be paired with its room by index alone. Match each room to the
        // typewriter fixture contained in its bounds; fall back to the room
        // center when no fixture sits inside it.
        var target = center;
        for (imported.save_fixtures[0..imported.save_fixture_count]) |fixture| {
            const position = fromImported(fixture);
            if (position.x >= center.x - half.x and position.x <= center.x + half.x and
                position.z >= center.z - half.z and position.z <= center.z + half.z)
            {
                target = position;
                break;
            }
        }
        result.save_targets[result.save_target_count] = target;
        result.save_target_count += 1;
    }

    for (imported.endings[0..imported.ending_count]) |ending| {
        const center = fromImported(ending.center);
        const half = fromImported(ending.half_extents);
        result.ending_areas[result.ending_area_count] = .{
            .min_x = center.x - half.x,
            .max_x = center.x + half.x,
            .min_z = center.z - half.z,
            .max_z = center.z + half.z,
        };
        result.ending_area_count += 1;
    }

    for (imported.lights[0..imported.light_count]) |light| {
        if (result.light_count == light_capacity) break;
        const position = fromImported(light.position);
        result.lights[result.light_count] = .{ .x = position.x, .y = position.y, .z = position.z, .w = light.radius };
        result.light_count += 1;
    }

    // Save rooms are sanctuary: the hunter must not be able to enter them.
    // Drop an invisible, hunter-only barrier across each save room's doorway
    // so the hunter's navmesh cells, capsule, and line of sight are all blocked
    // while the player walks straight through (the player's query mask excludes
    // the hunter_block category and the player navmesh skips these boxes).
    for (result.doorSlice()) |door| {
        if (!result.isSaveRoomDoor(door)) continue;
        // At least as tall as the hunter's 3.0 m capsule (a doorway is authored
        // >= 3.1 m), so the barrier always spans the full opening.
        const height = @max(door.height, 3.1);
        const half_thickness: f32 = 0.5;
        const half = if (door.axis == .x)
            Vec3{ .x = door.width * 0.5, .y = height * 0.5, .z = half_thickness }
        else
            Vec3{ .x = half_thickness, .y = height * 0.5, .z = door.width * 0.5 };
        result.addBox(.{
            .center = .{ .x = door.position.x, .y = result.ground_y + height * 0.5, .z = door.position.z },
            .half_extents = half,
            .color = geometry_color,
            .visible = false,
            .collidable = true,
            .nav_block = true,
            .hunter_block = true,
        });
    }

    // These neutral defaults support reusable systems without placing any
    // old level content into the fresh Blender scene.
    result.save_room_target = if (result.save_target_count > 0) result.save_targets[0] else result.player_spawn;
    if (result.save_target_count == 0) {
        result.save_targets[0] = result.player_spawn;
        result.save_target_count = 1;
        result.save_bounds[0] = .{
            .min_x = result.walk_min_x,
            .max_x = result.walk_max_x,
            .min_z = result.walk_min_z,
            .max_z = result.walk_max_z,
        };
    }
    if (result.light_count == 0) {
        result.lights[0] = .{
            .x = (result.walk_min_x + result.walk_max_x) * 0.5,
            .y = result.ground_y + 6,
            .z = (result.walk_min_z + result.walk_max_z) * 0.5,
            .w = @max(result.walk_max_x - result.walk_min_x, result.walk_max_z - result.walk_min_z),
        };
        result.light_count = 1;
    }
    if (!result.validate()) return error.InvalidImportedLevel;
    return result;
}

fn fromImported(value: blender_level.Vec3) Vec3 {
    return .{ .x = value.x, .y = value.y, .z = value.z };
}

const ProjectionAxis = enum { x, y, z };

pub fn projectedHalfExtent(box: Box, axis: ProjectionAxis) f32 {
    return switch (axis) {
        .x => @abs(box.basis_x.x) * box.half_extents.x + @abs(box.basis_y.x) * box.half_extents.y + @abs(box.basis_z.x) * box.half_extents.z,
        .y => @abs(box.basis_x.y) * box.half_extents.x + @abs(box.basis_y.y) * box.half_extents.y + @abs(box.basis_z.y) * box.half_extents.z,
        .z => @abs(box.basis_x.z) * box.half_extents.x + @abs(box.basis_y.z) * box.half_extents.y + @abs(box.basis_z.z) * box.half_extents.z,
    };
}

const geometry_color = Vec4{ .x = 0.43, .y = 0.44, .z = 0.46, .w = 1 };
