const model_image = @import("model_image");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/depth_testing_shader.zig");

const near_plane: f32 = 0.1;
const far_plane: f32 = 20.0;

const Vertex = extern struct {
    position: [3]f32,
    uv: [2]f32,
};

const state = struct {
    var pass_action: sg.PassAction = .{};
    var depth_pipeline: sg.Pipeline = .{};
    var always_pipeline: sg.Pipeline = .{};
    var cube_bindings: sg.Bindings = .{};
    var floor_bindings: sg.Bindings = .{};
    var show_depth = false;
    var depth_always = false;
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

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.cube_bindings = makeBindings(&cube_vertices, &cube_indices, @embedFile("assets/depth_testing/marble.jpg"));
    state.floor_bindings = makeBindings(&floor_vertices, &floor_indices, @embedFile("assets/depth_testing/metal.png"));

    var pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.depthTestingShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS, .write_enabled = true },
    };
    pipeline_desc.layout.attrs[shd.ATTR_depth_testing_position].format = .FLOAT3;
    pipeline_desc.layout.attrs[shd.ATTR_depth_testing_texcoord0].format = .FLOAT2;
    state.depth_pipeline = sg.makePipeline(pipeline_desc);

    pipeline_desc.depth.compare = .ALWAYS;
    state.always_pipeline = sg.makePipeline(pipeline_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
    };

    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

fn makeBindings(vertices: []const Vertex, indices: []const u16, encoded_image: []const u8) sg.Bindings {
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
        .wrap_u = .REPEAT,
        .wrap_v = .REPEAT,
    });
    return bindings;
}

fn decodeTexture(encoded: []const u8) sg.View {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = model_image.model_image_decode_rgba(encoded.ptr, encoded.len, &width, &height);
    if (pixels == null) @panic("could not decode depth-testing texture");
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
    const projection = Mat4.persp(45, sapp.widthf() / sapp.heightf(), near_plane, far_plane);
    const view = Mat4.lookat(.{ .x = 0, .y = 1.2, .z = 5 }, .{ .x = 0, .y = 0, .z = -1 }, Vec3.up());
    const view_projection = Mat4.mul(projection, view);
    const fs_params = shd.FsParams{
        .depth_options = .{ if (state.show_depth) 1 else 0, near_plane, far_plane, 0 },
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(if (state.depth_always) state.always_pipeline else state.depth_pipeline);
    sg.applyUniforms(shd.UB_fs_params, sg.asRange(&fs_params));

    sg.applyBindings(state.cube_bindings);
    drawObject(view_projection, Mat4.translate(.{ .x = -1, .y = 0, .z = -1 }), cube_indices.len);
    drawObject(view_projection, Mat4.translate(.{ .x = 2, .y = 0, .z = 0 }), cube_indices.len);

    sg.applyBindings(state.floor_bindings);
    drawObject(view_projection, Mat4.identity(), floor_indices.len);
    sg.endPass();
    sg.commit();
}

fn drawObject(view_projection: Mat4, model: Mat4, element_count: u32) void {
    const params = shd.VsParams{ .mvp = Mat4.mul(view_projection, model) };
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&params));
    sg.draw(0, element_count, 1);
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    switch (event.key_code) {
        .Z => state.show_depth = !state.show_depth,
        .D => state.depth_always = !state.depth_always,
        else => {},
    }
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
        .window_title = "LearnOpenGL Depth Testing — Z: depth, D: comparison",
        .logger = .{ .func = slog.func },
    });
}
