//! Runtime level data imported exclusively from `level/level.glb`.
//!
//! Blender owns the scene layout. Each mesh node becomes an oriented Box3D
//! collision/render box and a required `PlayerSpawn` node defines the start
//! position, facing direction, and ground height. An optional `HunterSpawn`
//! node enables the hunter and defines his starting position.

const std = @import("std");
const math = @import("math.zig");
const blender_level = @import("blender_level.zig");

pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

pub const max_boxes = blender_level.max_boxes;
pub const light_capacity = 8;

// Runtime metadata arrays remain empty until equivalent nodes are authored in
// Blender and added to the importer. They keep the reusable interaction and
// rendering systems independent from any hard-coded level layout.
pub const DoorAxis = enum { x, z };
pub const DoorLock = enum { none, purple, pink, cyan };
pub const DoorDef = struct {
    position: Vec3,
    axis: DoorAxis,
    gap_half_width: f32,
    clear_half_width: f32 = 1,
    lock: DoorLock = .none,
};
pub const max_doors = 1;
pub const door_count = 0;
pub const door_defs: [max_doors]DoorDef = .{.{ .position = .{}, .axis = .x, .gap_half_width = 0 }};
pub const door_width: f32 = 1.48;
pub const door_height: f32 = 3.15;
pub const door_half_thickness: f32 = 0.07;

pub const WindowDef = struct {
    center: Vec3,
    half_extents: Vec3,
};
pub const max_windows = 1;
pub const window_count = 0;
pub const window_defs: [max_windows]WindowDef = .{.{ .center = .{}, .half_extents = .{} }};

pub fn doorSlice() []const DoorDef {
    return door_defs[0..door_count];
}

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
    hunter_enabled: bool = false,
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
    return false;
}

pub fn hunterEnabled() bool {
    return current.hunter_enabled;
}

pub fn insideWalkBounds(x: f32, z: f32) bool {
    return x >= current.walk_min_x and x <= current.walk_max_x and
        z >= current.walk_min_z and z <= current.walk_max_z;
}

fn build() !Level {
    const imported = try blender_level.load();
    var result = Level{};
    result.player_spawn = fromImported(imported.player_spawn orelse return error.PlayerSpawnMissing);
    result.player_spawn_yaw = imported.player_yaw;
    result.ground_y = result.player_spawn.y;
    if (imported.hunter_spawn) |spawn| {
        result.hunter_spawn = fromImported(spawn);
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

    // These neutral defaults support reusable systems without placing any
    // old level content into the fresh Blender scene.
    result.save_room_target = result.player_spawn;
    result.save_targets[0] = result.player_spawn;
    result.save_target_count = 1;
    result.save_bounds[0] = .{
        .min_x = result.walk_min_x,
        .max_x = result.walk_max_x,
        .min_z = result.walk_min_z,
        .max_z = result.walk_max_z,
    };
    result.lights[0] = .{
        .x = (result.walk_min_x + result.walk_max_x) * 0.5,
        .y = result.ground_y + 6,
        .z = (result.walk_min_z + result.walk_max_z) * 0.5,
        .w = @max(result.walk_max_x - result.walk_min_x, result.walk_max_z - result.walk_min_z),
    };
    result.light_count = 1;
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
