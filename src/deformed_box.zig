const std = @import("std");
const math = @import("math.zig");

pub const height_segments = 16;
pub const vertex_count = 4 * (height_segments + 1) * 2 + 8;
pub const index_count = 4 * height_segments * 6 + 12;

pub const Vertex = extern struct {
    position: math.Vec3,
    normal: math.Vec3,
};

pub const Mesh = struct {
    vertices: [vertex_count]Vertex,
    indices: [index_count]u16,
};

pub fn build() Mesh {
    var mesh: Mesh = undefined;
    var vertex_cursor: usize = 0;
    var index_cursor: usize = 0;

    addSide(&mesh, &vertex_cursor, &index_cursor, .{ .x = 0.5, .z = -0.5 }, .{ .x = 0.5, .z = 0.5 }, .{ .x = 1 });
    addSide(&mesh, &vertex_cursor, &index_cursor, .{ .x = -0.5, .z = 0.5 }, .{ .x = -0.5, .z = -0.5 }, .{ .x = -1 });
    addSide(&mesh, &vertex_cursor, &index_cursor, .{ .x = 0.5, .z = 0.5 }, .{ .x = -0.5, .z = 0.5 }, .{ .z = 1 });
    addSide(&mesh, &vertex_cursor, &index_cursor, .{ .x = -0.5, .z = -0.5 }, .{ .x = 0.5, .z = -0.5 }, .{ .z = -1 });

    addCap(&mesh, &vertex_cursor, &index_cursor, 0.5, .{ .y = 1 }, .{
        .{ .x = -0.5, .z = 0.5 },
        .{ .x = 0.5, .z = 0.5 },
        .{ .x = 0.5, .z = -0.5 },
        .{ .x = -0.5, .z = -0.5 },
    });
    addCap(&mesh, &vertex_cursor, &index_cursor, -0.5, .{ .y = -1 }, .{
        .{ .x = -0.5, .z = -0.5 },
        .{ .x = 0.5, .z = -0.5 },
        .{ .x = 0.5, .z = 0.5 },
        .{ .x = -0.5, .z = 0.5 },
    });

    std.debug.assert(vertex_cursor == vertex_count);
    std.debug.assert(index_cursor == index_count);
    return mesh;
}

fn addSide(
    mesh: *Mesh,
    vertex_cursor: *usize,
    index_cursor: *usize,
    a: math.Vec3,
    b: math.Vec3,
    normal: math.Vec3,
) void {
    const base = vertex_cursor.*;
    for (0..height_segments + 1) |ring| {
        const y = -0.5 + @as(f32, @floatFromInt(ring)) / @as(f32, @floatFromInt(height_segments));
        mesh.vertices[vertex_cursor.*] = .{ .position = .{ .x = a.x, .y = y, .z = a.z }, .normal = normal };
        vertex_cursor.* += 1;
        mesh.vertices[vertex_cursor.*] = .{ .position = .{ .x = b.x, .y = y, .z = b.z }, .normal = normal };
        vertex_cursor.* += 1;
    }
    for (0..height_segments) |segment| {
        const lower_a: u16 = @intCast(base + segment * 2);
        const lower_b = lower_a + 1;
        const upper_a = lower_a + 2;
        const upper_b = lower_a + 3;
        const quad = [_]u16{ lower_a, upper_a, upper_b, lower_a, upper_b, lower_b };
        @memcpy(mesh.indices[index_cursor.* .. index_cursor.* + quad.len], &quad);
        index_cursor.* += quad.len;
    }
}

fn addCap(
    mesh: *Mesh,
    vertex_cursor: *usize,
    index_cursor: *usize,
    y: f32,
    normal: math.Vec3,
    corners: [4]math.Vec3,
) void {
    const base: u16 = @intCast(vertex_cursor.*);
    for (corners) |corner| {
        mesh.vertices[vertex_cursor.*] = .{
            .position = .{ .x = corner.x, .y = y, .z = corner.z },
            .normal = normal,
        };
        vertex_cursor.* += 1;
    }
    const cap = [_]u16{ base, base + 1, base + 2, base, base + 2, base + 3 };
    @memcpy(mesh.indices[index_cursor.* .. index_cursor.* + cap.len], &cap);
    index_cursor.* += cap.len;
}

test "subdivided box has valid closed geometry" {
    const mesh = build();
    try std.testing.expectEqual(@as(usize, 144), mesh.vertices.len);
    try std.testing.expectEqual(@as(usize, 396), mesh.indices.len);
    for (mesh.indices) |index| try std.testing.expect(index < mesh.vertices.len);
    for (0..mesh.indices.len / 3) |triangle| {
        const a = mesh.vertices[mesh.indices[triangle * 3]].position;
        const b = mesh.vertices[mesh.indices[triangle * 3 + 1]].position;
        const c = mesh.vertices[mesh.indices[triangle * 3 + 2]].position;
        const edge_ab = math.Vec3.sub(b, a);
        const edge_ac = math.Vec3.sub(c, a);
        const geometric_normal = math.Vec3.cross(edge_ab, edge_ac);
        const authored_normal = mesh.vertices[mesh.indices[triangle * 3]].normal;
        try std.testing.expect(math.Vec3.dot(geometric_normal, authored_normal) > 0);
    }
    var bottom_count: usize = 0;
    var top_count: usize = 0;
    for (mesh.vertices) |vertex| {
        if (vertex.position.y == -0.5) bottom_count += 1;
        if (vertex.position.y == 0.5) top_count += 1;
    }

    try std.testing.expectEqual(@as(usize, 12), bottom_count);
    try std.testing.expectEqual(@as(usize, 12), top_count);
}
