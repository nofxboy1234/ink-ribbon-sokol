const std = @import("std");
const model_image = @import("model_image");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/stencil_testing_shader.zig");

const Vertex = extern struct {
    position: [3]f32,
    uv: [2]f32,
};

const cube_positions = [_]Vec3{
    .{ .x = -1.0, .y = 0.0, .z = -1.0 },
    .{ .x = 2.0, .y = 0.0, .z = 0.0 },
};

const camera_position = Vec3{ .x = 0, .y = 1.2, .z = 5 };
const camera_target = Vec3{ .x = 0, .y = 0, .z = -1 };
const field_of_view_degrees: f32 = 45.0;

const state = struct {
    var pass_action: sg.PassAction = .{};
    var scene_pipeline: sg.Pipeline = .{};
    var stencil_write_pipeline: sg.Pipeline = .{};
    var outline_pipeline: sg.Pipeline = .{};
    var cube_bindings: sg.Bindings = .{};
    var floor_bindings: sg.Bindings = .{};
    var selected_cube: ?usize = null;
};

const cube_vertices = [_]Vertex{
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } }, .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 1 } },   .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 0 } },  .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } }, .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },   .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },  .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } }, .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 1, 1 } },   .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 0, 0 } },  .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 0, 1 } },
};

const cube_indices = [_]u16{
    0,  1,  2,  0,  2,  3,  6,  5,  4,  7,  6,  4,  8,  9,  10, 8,  10, 11,
    14, 13, 12, 15, 14, 12, 16, 17, 18, 16, 18, 19, 22, 21, 20, 23, 22, 20,
};

const floor_vertices = [_]Vertex{
    .{ .position = .{ -5, -0.5, -5 }, .uv = .{ 0, 0 } }, .{ .position = .{ 5, -0.5, -5 }, .uv = .{ 2, 0 } },
    .{ .position = .{ 5, -0.5, 5 }, .uv = .{ 2, 2 } },   .{ .position = .{ -5, -0.5, 5 }, .uv = .{ 0, 2 } },
};
const floor_indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
    state.cube_bindings = makeBindings(&cube_vertices, &cube_indices, @embedFile("assets/depth_testing/marble.jpg"));
    state.floor_bindings = makeBindings(&floor_vertices, &floor_indices, @embedFile("assets/depth_testing/metal.png"));

    var desc = basePipelineDesc(sg.makeShader(shd.texturedShaderDesc(sg.queryBackend())));
    state.scene_pipeline = sg.makePipeline(desc);

    desc.stencil = .{
        .enabled = true,
        .front = .{ .compare = .ALWAYS, .pass_op = .REPLACE },
        .back = .{ .compare = .ALWAYS, .pass_op = .REPLACE },
        .read_mask = 0xFF,
        .write_mask = 0xFF,
        .ref = 1,
    };
    state.stencil_write_pipeline = sg.makePipeline(desc);

    desc.shader = sg.makeShader(shd.outlineShaderDesc(sg.queryBackend()));
    desc.depth = .{ .compare = .ALWAYS, .write_enabled = false };
    desc.stencil = .{
        .enabled = true,
        .front = .{ .compare = .NOT_EQUAL },
        .back = .{ .compare = .NOT_EQUAL },
        .read_mask = 0xFF,
        .write_mask = 0x00,
        .ref = 1,
    };
    state.outline_pipeline = sg.makePipeline(desc);

    state.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 } };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
    state.pass_action.stencil = .{ .load_action = .CLEAR, .clear_value = 0 };
}

fn basePipelineDesc(shader: sg.Shader) sg.PipelineDesc {
    var desc: sg.PipelineDesc = .{
        .shader = shader,
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS, .write_enabled = true },
    };
    desc.layout.attrs[shd.ATTR_textured_position].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_textured_texcoord0].format = .FLOAT2;
    return desc;
}

fn makeBindings(vertices: []const Vertex, indices: []const u16, encoded_image: []const u8) sg.Bindings {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertices) });
    bindings.index_buffer = sg.makeBuffer(.{ .usage = .{ .index_buffer = true }, .data = sg.asRange(indices) });
    bindings.views[shd.VIEW_tex] = decodeTexture(encoded_image);
    bindings.samplers[shd.SMP_smp] = sg.makeSampler(.{ .min_filter = .LINEAR, .mag_filter = .LINEAR, .wrap_u = .REPEAT, .wrap_v = .REPEAT });
    return bindings;
}

fn decodeTexture(encoded: []const u8) sg.View {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = model_image.model_image_decode_rgba(encoded.ptr, encoded.len, &width, &height);
    if (pixels == null) @panic("could not decode stencil-testing texture");
    defer model_image.model_image_free(pixels);
    var data: sg.ImageData = .{};
    data.mip_levels[0] = .{ .ptr = pixels, .size = @intCast(width * height * 4) };
    return sg.makeView(.{ .texture = .{ .image = sg.makeImage(.{ .width = width, .height = height, .pixel_format = .RGBA8, .data = data }) } });
}

export fn frame() void {
    const projection = Mat4.persp(field_of_view_degrees, sapp.widthf() / sapp.heightf(), 0.1, 20.0);
    const view = Mat4.lookat(camera_position, camera_target, Vec3.up());
    const view_projection = Mat4.mul(projection, view);

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.scene_pipeline);
    sg.applyBindings(state.floor_bindings);
    drawObject(view_projection, Mat4.identity(), floor_indices.len);

    for (cube_positions, 0..) |position, index| {
        sg.applyPipeline(if (state.selected_cube == index) state.stencil_write_pipeline else state.scene_pipeline);

        sg.applyBindings(state.cube_bindings);
        drawObject(view_projection, Mat4.translate(position), cube_indices.len);
    }

    if (state.selected_cube) |index| {
        sg.applyPipeline(state.outline_pipeline);
        sg.applyBindings(state.cube_bindings);
        const model = Mat4.mul(Mat4.translate(cube_positions[index]), uniformScale(1.1));
        drawObject(view_projection, model, cube_indices.len);
    }

    sg.endPass();
    sg.commit();
}

fn uniformScale(amount: f32) Mat4 {
    var result = Mat4.identity();
    result.m[0][0] = amount;
    result.m[1][1] = amount;
    result.m[2][2] = amount;
    return result;
}

fn drawObject(view_projection: Mat4, model: Mat4, element_count: u32) void {
    const params = shd.VsParams{ .mvp = Mat4.mul(view_projection, model) };
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&params));
    sg.draw(0, element_count, 1);
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type == .MOUSE_DOWN and event.mouse_button == .LEFT) {
        state.selected_cube = pickCube(event.mouse_x, event.mouse_y);
    }
}

fn pickCube(mouse_x: f32, mouse_y: f32) ?usize {
    const forward = Vec3.norm(Vec3.sub(camera_target, camera_position));
    const right = Vec3.norm(Vec3.cross(forward, Vec3.up()));
    const up = Vec3.cross(right, forward);
    const ndc_x = 2.0 * mouse_x / sapp.widthf() - 1.0;
    const ndc_y = 1.0 - 2.0 * mouse_y / sapp.heightf();

    const half_width = @tan(field_of_view_degrees * std.math.pi / 360.0);
    const aspect = sapp.widthf() / sapp.heightf();
    const ray_direction = Vec3.norm(Vec3.add(forward, Vec3.add(
        Vec3.mul(right, ndc_x * half_width),
        Vec3.mul(up, ndc_y * half_width / aspect),
    )));

    var closest_distance = std.math.inf(f32);
    var closest: ?usize = null;
    for (cube_positions, 0..) |center, index| {
        if (rayBoxDistance(camera_position, ray_direction, center)) |distance| {
            if (distance < closest_distance) {
                closest_distance = distance;
                closest = index;
            }
        }
    }
    return closest;
}

fn rayBoxDistance(origin: Vec3, direction: Vec3, center: Vec3) ?f32 {
    var near: f32 = 0.0;
    var far = std.math.inf(f32);
    const origins = [_]f32{ origin.x, origin.y, origin.z };
    const directions = [_]f32{ direction.x, direction.y, direction.z };
    const centers = [_]f32{ center.x, center.y, center.z };
    for (origins, directions, centers) |axis_origin, axis_direction, axis_center| {
        const minimum = axis_center - 0.5;
        const maximum = axis_center + 0.5;
        if (@abs(axis_direction) < 0.000001) {
            if (axis_origin < minimum or axis_origin > maximum) return null;
        } else {
            var t0 = (minimum - axis_origin) / axis_direction;
            var t1 = (maximum - axis_origin) / axis_direction;
            if (t0 > t1) std.mem.swap(f32, &t0, &t1);
            near = @max(near, t0);
            far = @min(far, t1);
            if (far < near) return null;
        }
    }
    return near;
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 800,
        .height = 600,

        .depth_format = .DEPTH_STENCIL,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "LearnOpenGL Stencil Testing — click a cube",
        .logger = .{ .func = slog.func },
    });
}
