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
const shd = @import("generated/cubemaps_shader.zig");

const CubeVertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
};

const state = struct {
    var pass_action: sg.PassAction = .{};
    var object_pipeline: sg.Pipeline = .{};
    var skybox_pipeline: sg.Pipeline = .{};
    var object_bindings: sg.Bindings = .{};
    var skybox_bindings: sg.Bindings = .{};
    var mode: u8 = 1;
    var paused = false;
    var rotation_x: f32 = -12;
    var rotation_y: f32 = 25;
};

const cube_vertices = [_]CubeVertex{
    .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ 0, 0, -1 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 0, 0, -1 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 0, 0, -1 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ 0, 0, -1 } },

    .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ 0, 0, 1 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 0, 0, 1 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 0, 0, 1 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ 0, 0, 1 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ -1, 0, 0 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ -1, 0, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ -1, 0, 0 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ -1, 0, 0 } },

    .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 1, 0, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 1, 0, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 1, 0, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 1, 0, 0 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ 0, -1, 0 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ 0, -1, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 0, -1, 0 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 0, -1, 0 } },

    .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ 0, 1, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ 0, 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 0, 1, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 0, 1, 0 } },
};

const cube_indices = [_]u16{
    0,  2,  1,  0,  3,  2,
    4,  5,  6,  4,  6,  7,
    8,  10, 9,  8,  11, 10,
    12, 13, 14, 12, 14, 15,
    16, 18, 17, 16, 19, 18,
    20, 21, 22, 20, 22, 23,
};

const skybox_vertices = [_][3]f32{
    .{ -1, 1, -1 },  .{ -1, -1, -1 }, .{ 1, -1, -1 },
    .{ 1, -1, -1 },  .{ 1, 1, -1 },   .{ -1, 1, -1 },
    .{ -1, -1, 1 },  .{ -1, -1, -1 }, .{ -1, 1, -1 },
    .{ -1, 1, -1 },  .{ -1, 1, 1 },   .{ -1, -1, 1 },
    .{ 1, -1, -1 },  .{ 1, -1, 1 },   .{ 1, 1, 1 },
    .{ 1, 1, 1 },    .{ 1, 1, -1 },   .{ 1, -1, -1 },
    .{ -1, -1, 1 },  .{ -1, 1, 1 },   .{ 1, 1, 1 },
    .{ 1, 1, 1 },    .{ 1, -1, 1 },   .{ -1, -1, 1 },
    .{ -1, 1, -1 },  .{ 1, 1, -1 },   .{ 1, 1, 1 },
    .{ 1, 1, 1 },    .{ -1, 1, 1 },   .{ -1, 1, -1 },
    .{ -1, -1, -1 }, .{ -1, -1, 1 },  .{ 1, -1, -1 },
    .{ 1, -1, -1 },  .{ -1, -1, 1 },  .{ 1, -1, 1 },
};

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    const cubemap_image = makeCubemap();
    const cubemap_view = sg.makeView(.{ .texture = .{ .image = cubemap_image } });
    const cubemap_sampler = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
        .wrap_w = .CLAMP_TO_EDGE,
    });

    state.object_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&cube_vertices) });
    state.object_bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&cube_indices),
    });
    state.object_bindings.views[shd.VIEW_environment_tex] = cubemap_view;
    state.object_bindings.samplers[shd.SMP_environment_smp] = cubemap_sampler;

    var object_pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.objectShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .face_winding = .CCW,
        .depth = .{ .compare = .LESS, .write_enabled = true },
    };
    object_pipeline_desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
    object_pipeline_desc.layout.attrs[shd.ATTR_object_normal].format = .FLOAT3;
    state.object_pipeline = sg.makePipeline(object_pipeline_desc);

    state.skybox_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&skybox_vertices) });
    state.skybox_bindings.views[shd.VIEW_environment_tex] = cubemap_view;
    state.skybox_bindings.samplers[shd.SMP_environment_smp] = cubemap_sampler;

    var skybox_pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.skyboxShaderDesc(sg.queryBackend())),

        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = false },

        .cull_mode = .NONE,
    };
    skybox_pipeline_desc.layout.attrs[shd.ATTR_skybox_position].format = .FLOAT3;
    state.skybox_pipeline = sg.makePipeline(skybox_pipeline_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.03, .g = 0.04, .b = 0.06, .a = 1 },
    };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

fn makeCubemap() sg.Image {
    const encoded_faces = [_][]const u8{
        @embedFile("assets/cubemaps/right.jpg"),
        @embedFile("assets/cubemaps/left.jpg"),
        @embedFile("assets/cubemaps/top.jpg"),
        @embedFile("assets/cubemaps/bottom.jpg"),
        @embedFile("assets/cubemaps/front.jpg"),
        @embedFile("assets/cubemaps/back.jpg"),
    };

    var width: c_int = 0;
    var height: c_int = 0;
    var packed_pixels: []u8 = &.{};

    for (encoded_faces, 0..) |encoded, face_index| {
        var face_width: c_int = 0;
        var face_height: c_int = 0;
        const pixels = model_image.model_image_decode_rgba(
            encoded.ptr,
            encoded.len,
            &face_width,
            &face_height,
        );
        if (pixels == null) @panic("could not decode cubemap face");
        defer model_image.model_image_free(pixels);

        if (face_index == 0) {
            width = face_width;
            height = face_height;
            const face_size: usize = @intCast(width * height * 4);
            packed_pixels = std.heap.c_allocator.alloc(u8, face_size * encoded_faces.len) catch
                @panic("could not allocate packed cubemap pixels");
        } else if (face_width != width or face_height != height) {
            @panic("all cubemap faces must have identical dimensions");
        }

        const face_size: usize = @intCast(width * height * 4);
        const offset = face_index * face_size;
        const source: [*]const u8 = @ptrCast(pixels);
        @memcpy(packed_pixels[offset .. offset + face_size], source[0..face_size]);
    }
    defer std.heap.c_allocator.free(packed_pixels);

    var image_data: sg.ImageData = .{};
    image_data.mip_levels[0] = sg.asRange(packed_pixels);
    return sg.makeImage(.{
        .type = .CUBE,
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .data = image_data,
    });
}

export fn frame() void {
    if (!state.paused) {
        const frame_scale: f32 = @floatCast(sapp.frameDuration() * 60.0);
        state.rotation_x += 0.12 * frame_scale;
        state.rotation_y += 0.28 * frame_scale;
    }

    const camera_position = Vec3{ .x = 0, .y = 0, .z = 3 };
    const projection = Mat4.persp(45, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view = Mat4.lookat(camera_position, Vec3.zero(), Vec3.up());

    const rotate_x = Mat4.rotate(state.rotation_x, .{ .x = 1, .y = 0, .z = 0 });
    const rotate_y = Mat4.rotate(state.rotation_y, .{ .x = 0, .y = 1, .z = 0 });
    const model = Mat4.mul(rotate_y, rotate_x);
    const object_params = shd.ObjectVsParams{
        .mvp = Mat4.mul(Mat4.mul(projection, view), model),
        .model = model,
    };
    const material_params = shd.ObjectFsParams{
        .camera_and_mode = .{
            camera_position.x,
            camera_position.y,
            camera_position.z,
            @floatFromInt(state.mode),
        },
    };

    var skybox_view = view;
    skybox_view.m[3][0] = 0;
    skybox_view.m[3][1] = 0;
    skybox_view.m[3][2] = 0;
    const skybox_params = shd.SkyboxVsParams{
        .view_projection = Mat4.mul(projection, skybox_view),
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.object_pipeline);
    sg.applyBindings(state.object_bindings);
    sg.applyUniforms(shd.UB_object_vs_params, sg.asRange(&object_params));
    sg.applyUniforms(shd.UB_object_fs_params, sg.asRange(&material_params));
    sg.draw(0, cube_indices.len, 1);

    sg.applyPipeline(state.skybox_pipeline);
    sg.applyBindings(state.skybox_bindings);
    sg.applyUniforms(shd.UB_skybox_vs_params, sg.asRange(&skybox_params));
    sg.draw(0, skybox_vertices.len, 1);

    sg.endPass();
    sg.commit();
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    switch (event.key_code) {
        ._1 => state.mode = 0,
        ._2 => state.mode = 1,
        ._3 => state.mode = 2,
        .SPACE => state.paused = !state.paused,
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
        .window_title = "LearnOpenGL Cubemaps — 1: ordinary, 2: reflection, 3: refraction",
        .logger = .{ .func = slog.func },
    });
}
