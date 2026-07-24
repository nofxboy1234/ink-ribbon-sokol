const std = @import("std");

pub const Vec2 = extern struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
};

pub const Vec3 = extern struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn scale(v: Vec3, s: f32) Vec3 {
        return .{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
    }

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn normalized(v: Vec3) Vec3 {
        const len = @sqrt(dot(v, v));
        return if (len > 0.0) scale(v, 1.0 / len) else .{};
    }
};

pub const Vec4 = extern struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,
    w: f32 = 0.0,
};

/// Row-major matrices with row-vector multiplication, matching vecmath.h from
/// sokol-samples. The shader compiler emits the corresponding transpositions.
pub const Mat4 = extern struct {
    m: [4][4]f32 = @splat(@splat(0.0)),

    pub fn identity() Mat4 {
        return .{ .m = .{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } };
    }

    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var result: Mat4 = .{};
        inline for (0..4) |row| {
            inline for (0..4) |column| {
                inline for (0..4) |k| {
                    result.m[row][column] += a.m[row][k] * b.m[k][column];
                }
            }
        }
        return result;
    }

    pub fn transpose(matrix: Mat4) Mat4 {
        var result: Mat4 = .{};
        inline for (0..4) |row| {
            inline for (0..4) |column| {
                result.m[row][column] = matrix.m[column][row];
            }
        }
        return result;
    }

    pub fn translation(v: Vec3) Mat4 {
        var result = identity();
        result.m[3][0] = v.x;
        result.m[3][1] = v.y;
        result.m[3][2] = v.z;
        return result;
    }

    pub fn fromQuaternion(x: f32, y: f32, z: f32, w: f32) Mat4 {
        const xx = x * x;
        const yy = y * y;
        const zz = z * z;
        const xy = x * y;
        const xz = x * z;
        const yz = y * z;
        const wx = w * x;
        const wy = w * y;
        const wz = w * z;
        return .{ .m = .{
            .{ 1.0 - 2.0 * (yy + zz), 2.0 * (xy + wz), 2.0 * (xz - wy), 0.0 },
            .{ 2.0 * (xy - wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz + wx), 0.0 },
            .{ 2.0 * (xz + wy), 2.0 * (yz - wx), 1.0 - 2.0 * (xx + yy), 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } };
    }

    pub fn lookAtRh(eye: Vec3, at: Vec3, up: Vec3) Mat4 {
        const z_axis = Vec3.normalized(Vec3.sub(eye, at));
        const x_axis = Vec3.normalized(Vec3.cross(up, z_axis));
        const y_axis = Vec3.cross(z_axis, x_axis);
        return .{ .m = .{
            .{ x_axis.x, y_axis.x, z_axis.x, 0.0 },
            .{ x_axis.y, y_axis.y, z_axis.y, 0.0 },
            .{ x_axis.z, y_axis.z, z_axis.z, 0.0 },
            .{ -Vec3.dot(x_axis, eye), -Vec3.dot(y_axis, eye), -Vec3.dot(z_axis, eye), 1.0 },
        } };
    }

    pub fn perspectiveFovRh(fov_y: f32, aspect: f32, near: f32, far: f32) Mat4 {
        const y_scale = 1.0 / @tan(fov_y * 0.5);
        const x_scale = y_scale / aspect;
        return .{ .m = .{
            .{ x_scale, 0.0, 0.0, 0.0 },
            .{ 0.0, y_scale, 0.0, 0.0 },
            .{ 0.0, 0.0, far / (near - far), -1.0 },
            .{ 0.0, 0.0, near * far / (near - far), 0.0 },
        } };
    }

    pub fn orthoOffCenterRh(
        left: f32,
        right: f32,
        bottom: f32,
        top: f32,
        near: f32,
        far: f32,
    ) Mat4 {
        return .{ .m = .{
            .{ 2.0 / (right - left), 0.0, 0.0, 0.0 },
            .{ 0.0, 2.0 / (top - bottom), 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0 / (near - far), 0.0 },
            .{
                (left + right) / (left - right),
                (top + bottom) / (bottom - top),
                near / (near - far),
                1.0,
            },
        } };
    }
};

pub fn degreesToRadians(degrees: f32) f32 {
    return degrees * std.math.pi / 180.0;
}

test "matrix multiplication and transpose" {
    const translated = Mat4.translation(.{ .x = 1.0, .y = 2.0, .z = 3.0 });
    const result = Mat4.mul(Mat4.identity(), translated);
    try std.testing.expectEqual(@as(f32, 2.0), result.m[3][1]);
    try std.testing.expectEqual(@as(f32, 1.0), Mat4.transpose(result).m[0][3]);
}
