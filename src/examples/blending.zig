const model_image = @import("model_image");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/blending_shader.zig");

const Vertex = extern struct {
    position: [3]f32,
    uv: [2]f32,
};

const LessonMode = enum {
    cutout_grass,
    unsorted_windows,
    sorted_windows,
};

const camera_position = Vec3{ .x = 0, .y = 0, .z = 3 };
const camera_target = Vec3{ .x = 0, .y = 0, .z = 2 };

const transparent_positions = [_]Vec3{
    .{ .x = -1.5, .y = 0.0, .z = -0.48 },
    .{ .x = 1.5, .y = 0.0, .z = 0.51 },
    .{ .x = 0.0, .y = 0.0, .z = 0.7 },
    .{ .x = -0.3, .y = 0.0, .z = -2.3 },
    .{ .x = 0.5, .y = 0.0, .z = -0.6 },
};

const state = struct {
    var pass_action: sg.PassAction = .{};
    var opaque_pipeline: sg.Pipeline = .{};
    var cutout_pipeline: sg.Pipeline = .{};
    var blended_pipeline: sg.Pipeline = .{};
    var cube_bindings: sg.Bindings = .{};
    var floor_bindings: sg.Bindings = .{};
    var grass_bindings: sg.Bindings = .{};
    var window_bindings: sg.Bindings = .{};
    var mode: LessonMode = .sorted_windows;
};

const cube_vertices = [_]Vertex{
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 0, 1 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 0, 1 } },
};

const cube_indices = [_]u16{
    0,  1,  2,  0,  2,  3,  6,  5,  4,  7,  6,  4,
    8,  9,  10, 8,  10, 11, 14, 13, 12, 15, 14, 12,
    16, 17, 18, 16, 18, 19, 22, 21, 20, 23, 22, 20,
};

const floor_vertices = [_]Vertex{
    .{ .position = .{ -5, -0.5, -5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 5, -0.5, -5 }, .uv = .{ 2, 0 } },
    .{ .position = .{ 5, -0.5, 5 }, .uv = .{ 2, 2 } },
    .{ .position = .{ -5, -0.5, 5 }, .uv = .{ 0, 2 } },
};
const floor_indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

const transparent_vertices = [_]Vertex{
    .{ .position = .{ 0.0, 0.5, 0.0 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.0, -0.5, 0.0 }, .uv = .{ 0, 1 } },
    .{ .position = .{ 1.0, -0.5, 0.0 }, .uv = .{ 1, 1 } },
    .{ .position = .{ 1.0, 0.5, 0.0 }, .uv = .{ 1, 0 } },
};
const transparent_indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.cube_bindings = makeBindings(&cube_vertices, &cube_indices, @embedFile("assets/depth_testing/marble.jpg"), .REPEAT);
    state.floor_bindings = makeBindings(&floor_vertices, &floor_indices, @embedFile("assets/depth_testing/metal.png"), .REPEAT);

    state.grass_bindings = makeBindings(&transparent_vertices, &transparent_indices, @embedFile("assets/blending/grass.png"), .CLAMP_TO_EDGE);
    state.window_bindings = makeBindings(&transparent_vertices, &transparent_indices, @embedFile("assets/blending/window.png"), .CLAMP_TO_EDGE);

    const sampled_shader = sg.makeShader(shd.sampledShaderDesc(sg.queryBackend()));
    var pipeline_desc = basePipelineDesc(sampled_shader);
    state.opaque_pipeline = sg.makePipeline(pipeline_desc);

    pipeline_desc.shader = sg.makeShader(shd.cutoutShaderDesc(sg.queryBackend()));
    state.cutout_pipeline = sg.makePipeline(pipeline_desc);

    pipeline_desc.shader = sampled_shader;
    pipeline_desc.colors[0].blend = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
        .op_rgb = .ADD,
        .src_factor_alpha = .SRC_ALPHA,
        .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
        .op_alpha = .ADD,
    };
    state.blended_pipeline = sg.makePipeline(pipeline_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
    };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

fn basePipelineDesc(shader: sg.Shader) sg.PipelineDesc {
    var desc: sg.PipelineDesc = .{
        .shader = shader,
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS, .write_enabled = true },
    };

    desc.layout.attrs[shd.ATTR_sampled_position].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_sampled_texcoord0].format = .FLOAT2;
    return desc;
}

fn makeBindings(
    vertices: []const Vertex,
    indices: []const u16,
    encoded_image: []const u8,
    wrap: sg.Wrap,
) sg.Bindings {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertices) });
    bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(indices),
    });
    bindings.views[shd.VIEW_tex] = decodeTexture(encoded_image);
    bindings.samplers[shd.SMP_smp] = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = wrap,
        .wrap_v = wrap,
    });
    return bindings;
}

fn decodeTexture(encoded: []const u8) sg.View {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = model_image.model_image_decode_rgba(encoded.ptr, encoded.len, &width, &height);
    if (pixels == null) @panic("could not decode blending texture");
    defer model_image.model_image_free(pixels);

    var image_data: sg.ImageData = .{};
    image_data.mip_levels[0] = .{
        .ptr = pixels,
        .size = @intCast(width * height * 4),
    };
    return sg.makeView(.{ .texture = .{ .image = sg.makeImage(.{
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .data = image_data,
    }) } });
}

export fn frame() void {
    const projection = Mat4.persp(45, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view = Mat4.lookat(camera_position, camera_target, Vec3.up());
    const view_projection = Mat4.mul(projection, view);

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.opaque_pipeline);
    sg.applyBindings(state.cube_bindings);
    drawObject(view_projection, Mat4.translate(.{ .x = -1, .y = 0, .z = -1 }), cube_indices.len);
    drawObject(view_projection, Mat4.translate(.{ .x = 2, .y = 0, .z = 0 }), cube_indices.len);

    sg.applyBindings(state.floor_bindings);
    drawObject(view_projection, Mat4.identity(), floor_indices.len);

    switch (state.mode) {
        .cutout_grass => {
            sg.applyPipeline(state.cutout_pipeline);
            sg.applyBindings(state.grass_bindings);
            drawTransparentObjects(view_projection, &transparent_positions);
        },
        .unsorted_windows => {
            sg.applyPipeline(state.blended_pipeline);
            sg.applyBindings(state.window_bindings);
            drawTransparentObjects(view_projection, &transparent_positions);
        },
        .sorted_windows => {
            const positions = sortBackToFront(transparent_positions);
            sg.applyPipeline(state.blended_pipeline);
            sg.applyBindings(state.window_bindings);
            drawTransparentObjects(view_projection, &positions);
        },
    }

    sg.endPass();
    sg.commit();
}

fn drawTransparentObjects(view_projection: Mat4, positions: []const Vec3) void {
    for (positions) |position| {
        drawObject(view_projection, Mat4.translate(position), transparent_indices.len);
    }
}

fn drawObject(view_projection: Mat4, model: Mat4, element_count: u32) void {
    const params = shd.VsParams{ .mvp = Mat4.mul(view_projection, model) };
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&params));
    sg.draw(0, element_count, 1);
}

fn distanceSquared(position: Vec3) f32 {
    const from_camera = Vec3.sub(position, camera_position);
    return Vec3.dot(from_camera, from_camera);
}

fn sortBackToFront(positions: [transparent_positions.len]Vec3) [transparent_positions.len]Vec3 {
    var result = positions;
    var index: usize = 1;
    while (index < result.len) : (index += 1) {
        const current = result[index];
        const current_distance = distanceSquared(current);
        var insertion_index = index;
        while (insertion_index > 0 and distanceSquared(result[insertion_index - 1]) < current_distance) : (insertion_index -= 1) {
            result[insertion_index] = result[insertion_index - 1];
        }
        result[insertion_index] = current;
    }
    return result;
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    state.mode = switch (event.key_code) {
        ._1 => .cutout_grass,
        ._2 => .unsorted_windows,
        ._3 => .sorted_windows,
        else => state.mode,
    };
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
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "LearnOpenGL Blending — 1: cutout, 2: unsorted, 3: sorted",
        .logger = .{ .func = slog.func },
    });
}

test "transparent objects are sorted from farthest to nearest" {
    const positions = sortBackToFront(transparent_positions);
    for (positions[0 .. positions.len - 1], positions[1..]) |farther, nearer| {
        if (distanceSquared(farther) < distanceSquared(nearer)) {
            return error.NotBackToFront;
        }
    }
}
