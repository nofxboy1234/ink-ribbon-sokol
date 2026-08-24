//! Minimal glTF blockout importer.
//!
//! Blender remains the level editor and exports `level/level.glb`.  The game
//! embeds that file, uses cgltf to read its scene graph, and treats every mesh
//! node as an oriented box derived from the POSITION accessor bounds.  This is
//! intentionally a blockout path: arbitrary production meshes can be added to
//! the renderer later without changing the collision-oriented authoring flow.

const std = @import("std");
const cgltf = @import("cgltf");

pub const max_boxes = 512;
pub const max_doors = 16;
pub const max_pickups = 24;
pub const max_breakables = 16;
pub const max_save_fixtures = 4;
pub const max_trigger_volumes = 4;
pub const max_lights = 8;

pub const Vec3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};

pub const Box = struct {
    center: Vec3,
    half_extents: Vec3,
    basis_x: Vec3 = .{ .x = 1 },
    basis_y: Vec3 = .{ .y = 1 },
    basis_z: Vec3 = .{ .z = 1 },
    is_roof: bool = false,
};

pub const DoorLock = enum { none, purple, pink, cyan };
pub const Door = struct {
    box: Box,
    lock: DoorLock,
};

pub const PickupKind = enum { ammo, health, key_purple, key_pink, key_cyan };
pub const Pickup = struct {
    position: Vec3,
    kind: PickupKind,
};

pub const Volume = struct {
    center: Vec3,
    half_extents: Vec3,
};

pub const Light = struct {
    position: Vec3,
    radius: f32,
};

pub const Scene = struct {
    boxes: [max_boxes]Box = undefined,
    box_count: usize = 0,
    player_spawn: ?Vec3 = null,
    player_yaw: f32 = std.math.pi,
    hunter_spawn: ?Vec3 = null,
    hunter_yaw: f32 = 0,
    doors: [max_doors]Door = undefined,
    door_count: usize = 0,
    pickups: [max_pickups]Pickup = undefined,
    pickup_count: usize = 0,
    breakables: [max_breakables]Box = undefined,
    breakable_count: usize = 0,
    save_fixtures: [max_save_fixtures]Vec3 = undefined,
    save_fixture_count: usize = 0,
    save_rooms: [max_trigger_volumes]Volume = undefined,
    save_room_count: usize = 0,
    endings: [max_trigger_volumes]Volume = undefined,
    ending_count: usize = 0,
    lights: [max_lights]Light = undefined,
    light_count: usize = 0,

    pub fn boxSlice(self: *const Scene) []const Box {
        return self.boxes[0..self.box_count];
    }
};

// The build graph exposes the file as an anonymous import so it can remain in
// the user-facing `level/` authoring directory rather than being copied under
// `src/` merely to satisfy Zig's package-path boundary.
const embedded_glb = @embedFile("level_glb");

pub fn load() !Scene {
    var options: cgltf.cgltf_options = .{};
    var data: [*c]cgltf.cgltf_data = null;
    if (cgltf.cgltf_parse(&options, embedded_glb.ptr, embedded_glb.len, &data) != cgltf.cgltf_result_success) {
        return error.InvalidGlb;
    }
    defer cgltf.cgltf_free(data);
    if (data == null or cgltf.cgltf_validate(data) != cgltf.cgltf_result_success) return error.InvalidGlb;

    var result = Scene{};
    for (data.*.nodes[0..data.*.nodes_count]) |*node| {
        const name = if (node.name != null) std.mem.span(node.name) else "";
        if (std.mem.eql(u8, name, "PlayerSpawn")) {
            if (result.player_spawn != null) return error.DuplicatePlayerSpawn;
            var matrix: [16]f32 = undefined;
            cgltf.cgltf_node_transform_world(node, &matrix);
            result.player_spawn = transformPoint(matrix, .{});
            // A zero-rotation Blender Empty faces the game's conventional -Z.
            // Rotating it around Blender Z is exported as a glTF Y rotation,
            // so its transformed local -Z axis provides the starting heading.
            const forward_x = -matrix[8];
            const forward_z = -matrix[10];
            if (forward_x * forward_x + forward_z * forward_z > 0.000001) {
                result.player_yaw = std.math.atan2(forward_x, forward_z);
            }
            continue;
        }
        if (std.mem.eql(u8, name, "HunterSpawn")) {
            if (result.hunter_spawn != null) return error.DuplicateHunterSpawn;
            var matrix: [16]f32 = undefined;
            cgltf.cgltf_node_transform_world(node, &matrix);
            result.hunter_spawn = transformPoint(matrix, .{});
            result.hunter_yaw = yawFromMatrix(matrix);
            continue;
        }
        // Blender-only scale guide. The authoring exporter excludes this, but
        // ignoring it here too prevents an accidental export from becoming a
        // large invisible collider in the playable level.
        if (std.mem.eql(u8, name, "PlayerPlaceHolder")) continue;
        if (std.mem.startsWith(u8, name, "Trigger_SaveRoom_")) {
            if (result.save_room_count == max_trigger_volumes) return error.TooManySaveRooms;
            result.save_rooms[result.save_room_count] = try volumeFromNode(node);
            result.save_room_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Trigger_Ending_")) {
            if (result.ending_count == max_trigger_volumes) return error.TooManyEndingAreas;
            result.endings[result.ending_count] = try volumeFromNode(node);
            result.ending_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Light_")) {
            if (result.light_count == max_lights) return error.TooManyLights;
            var matrix: [16]f32 = undefined;
            cgltf.cgltf_node_transform_world(node, &matrix);
            result.lights[result.light_count] = .{
                .position = transformPoint(matrix, .{}),
                .radius = length(.{ .x = matrix[0], .y = matrix[1], .z = matrix[2] }),
            };
            result.light_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Door_")) {
            if (node.mesh == null) return error.GameplayMarkerMeshMissing;
            if (result.door_count == max_doors) return error.TooManyDoors;
            result.doors[result.door_count] = .{
                .box = try boxFromNode(node),
                .lock = if (std.mem.startsWith(u8, name, "Door_Unlocked_"))
                    .none
                else if (std.mem.startsWith(u8, name, "Door_Locked_Purple_"))
                    .purple
                else if (std.mem.startsWith(u8, name, "Door_Locked_Pink_"))
                    .pink
                else if (std.mem.startsWith(u8, name, "Door_Locked_Cyan_"))
                    .cyan
                else
                    return error.InvalidDoorName,
            };
            result.door_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Pickup_")) {
            if (node.mesh == null) return error.GameplayMarkerMeshMissing;
            if (result.pickup_count == max_pickups) return error.TooManyPickups;
            const marker = try boxFromNode(node);
            result.pickups[result.pickup_count] = .{
                .position = marker.center,
                .kind = if (std.mem.startsWith(u8, name, "Pickup_Ammo_"))
                    .ammo
                else if (std.mem.startsWith(u8, name, "Pickup_Health_"))
                    .health
                else if (std.mem.startsWith(u8, name, "Pickup_Key_Purple_"))
                    .key_purple
                else if (std.mem.startsWith(u8, name, "Pickup_Key_Pink_"))
                    .key_pink
                else if (std.mem.startsWith(u8, name, "Pickup_Key_Cyan_"))
                    .key_cyan
                else
                    return error.InvalidPickupName,
            };
            result.pickup_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Breakable_ItemBox_")) {
            if (node.mesh == null) return error.GameplayMarkerMeshMissing;
            if (result.breakable_count == max_breakables) return error.TooManyBreakables;
            result.breakables[result.breakable_count] = try boxFromNode(node);
            result.breakable_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, name, "Interactible_Typewriter_")) {
            if (node.mesh == null) return error.GameplayMarkerMeshMissing;
            if (result.save_fixture_count == max_save_fixtures) return error.TooManySaveFixtures;
            const fixture_box = try boxFromNode(node);
            result.save_fixtures[result.save_fixture_count] = fixture_box.center;
            result.save_fixture_count += 1;
            if (result.box_count == max_boxes) return error.TooManyMeshNodes;
            result.boxes[result.box_count] = fixture_box;
            result.box_count += 1;
            continue;
        }
        if (node.mesh == null) continue;
        if (result.box_count == max_boxes) return error.TooManyMeshNodes;
        var box = try boxFromNode(node);
        box.is_roof = std.mem.startsWith(u8, name, "Roof_");
        result.boxes[result.box_count] = box;
        result.box_count += 1;
    }
    if (result.box_count == 0) return error.EmptyScene;
    if (result.player_spawn == null) return error.PlayerSpawnMissing;
    return result;
}

fn yawFromMatrix(matrix: [16]f32) f32 {
    const forward_x = -matrix[8];
    const forward_z = -matrix[10];
    if (forward_x * forward_x + forward_z * forward_z <= 0.000001) return 0;
    return std.math.atan2(forward_x, forward_z);
}

fn volumeFromNode(node: *const cgltf.cgltf_node) !Volume {
    var matrix: [16]f32 = undefined;
    cgltf.cgltf_node_transform_world(node, &matrix);
    const half_extents = Vec3{
        .x = length(.{ .x = matrix[0], .y = matrix[1], .z = matrix[2] }),
        .y = length(.{ .x = matrix[4], .y = matrix[5], .z = matrix[6] }),
        .z = length(.{ .x = matrix[8], .y = matrix[9], .z = matrix[10] }),
    };
    if (half_extents.x <= 0.000001 or half_extents.y <= 0.000001 or half_extents.z <= 0.000001) return error.ZeroScale;
    return .{ .center = transformPoint(matrix, .{}), .half_extents = half_extents };
}

fn boxFromNode(node: *const cgltf.cgltf_node) !Box {
    var minimum = Vec3{ .x = std.math.inf(f32), .y = std.math.inf(f32), .z = std.math.inf(f32) };
    var maximum = Vec3{ .x = -std.math.inf(f32), .y = -std.math.inf(f32), .z = -std.math.inf(f32) };
    var found_position = false;

    for (node.mesh.*.primitives[0..node.mesh.*.primitives_count]) |primitive| {
        for (primitive.attributes[0..primitive.attributes_count]) |attribute| {
            if (attribute.type != cgltf.cgltf_attribute_type_position or attribute.data == null) continue;
            const accessor = attribute.data.*;
            if (accessor.has_min == 0 or accessor.has_max == 0) return error.PositionBoundsMissing;
            minimum.x = @min(minimum.x, accessor.min[0]);
            minimum.y = @min(minimum.y, accessor.min[1]);
            minimum.z = @min(minimum.z, accessor.min[2]);
            maximum.x = @max(maximum.x, accessor.max[0]);
            maximum.y = @max(maximum.y, accessor.max[1]);
            maximum.z = @max(maximum.z, accessor.max[2]);
            found_position = true;
        }
    }
    if (!found_position) return error.PositionAccessorMissing;

    var matrix: [16]f32 = undefined;
    cgltf.cgltf_node_transform_world(node, &matrix);
    var basis_x = Vec3{ .x = matrix[0], .y = matrix[1], .z = matrix[2] };
    var basis_y = Vec3{ .x = matrix[4], .y = matrix[5], .z = matrix[6] };
    var basis_z = Vec3{ .x = matrix[8], .y = matrix[9], .z = matrix[10] };
    const scale_x = length(basis_x);
    const scale_y = length(basis_y);
    const scale_z = length(basis_z);
    if (scale_x <= 0.000001 or scale_y <= 0.000001 or scale_z <= 0.000001) return error.ZeroScale;
    basis_x = scale(basis_x, 1.0 / scale_x);
    basis_y = scale(basis_y, 1.0 / scale_y);
    basis_z = scale(basis_z, 1.0 / scale_z);
    // Reflections cannot be represented by Box3D's rotation quaternion.  The
    // Blender workflow applies scale before export, so reject a negative-scale
    // node rather than silently producing mismatched visuals and collision.
    if (dot(cross(basis_x, basis_y), basis_z) < 0.999) return error.UnsupportedTransform;

    const local_center = Vec3{
        .x = (minimum.x + maximum.x) * 0.5,
        .y = (minimum.y + maximum.y) * 0.5,
        .z = (minimum.z + maximum.z) * 0.5,
    };
    const world_center = transformPoint(matrix, local_center);
    return .{
        .center = world_center,
        .half_extents = .{
            .x = (maximum.x - minimum.x) * 0.5 * scale_x,
            .y = (maximum.y - minimum.y) * 0.5 * scale_y,
            .z = (maximum.z - minimum.z) * 0.5 * scale_z,
        },
        .basis_x = basis_x,
        .basis_y = basis_y,
        .basis_z = basis_z,
    };
}

fn transformPoint(matrix: [16]f32, point: Vec3) Vec3 {
    return .{
        .x = matrix[0] * point.x + matrix[4] * point.y + matrix[8] * point.z + matrix[12],
        .y = matrix[1] * point.x + matrix[5] * point.y + matrix[9] * point.z + matrix[13],
        .z = matrix[2] * point.x + matrix[6] * point.y + matrix[10] * point.z + matrix[14],
    };
}

fn scale(value: Vec3, amount: f32) Vec3 {
    return .{ .x = value.x * amount, .y = value.y * amount, .z = value.z * amount };
}

fn dot(a: Vec3, b: Vec3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

fn cross(a: Vec3, b: Vec3) Vec3 {
    return .{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

fn length(value: Vec3) f32 {
    return @sqrt(dot(value, value));
}
