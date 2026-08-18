//------------------------------------------------------------------------------
// LearnOpenGL: Advanced OpenGL / Framebuffers
//
// This scene performs two render passes:
//   1. Draw two textured cubes and a floor into an offscreen texture.
//   2. Draw that texture over one full-screen quad, optionally filtering it.
//
// Scene controls:
//   1 - normal framebuffer texture
//   2 - inverted colours
//   3 - grayscale
//   4 - sharpen kernel
//   5 - blur kernel
//   6 - edge-detection kernel
//------------------------------------------------------------------------------
const model_image = @import("model_image");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/framebuffers_shader.zig");

const SceneVertex = extern struct {
    position: [3]f32,
    uv: [2]f32,
};

const ScreenVertex = extern struct {
    position: [2]f32,
    uv: [2]f32,
};

const Effect = enum(u8) {
    normal,
    invert,
    grayscale,
    sharpen,
    blur,
    edges,
};

const state = struct {
    var offscreen_pass: sg.Pass = .{};
    var offscreen_action: sg.PassAction = .{};
    var display_action: sg.PassAction = .{};

    var scene_pipeline: sg.Pipeline = .{};
    var screen_pipeline: sg.Pipeline = .{};
    var cube_bindings: sg.Bindings = .{};
    var floor_bindings: sg.Bindings = .{};
    var screen_bindings: sg.Bindings = .{};

    // One image can have more than one view. The colour image has an
    // attachment view for pass 1 and a texture view for pass 2.
    var color_image: sg.Image = .{};
    var depth_image: sg.Image = .{};
    var color_attachment_view: sg.View = .{};
    var depth_attachment_view: sg.View = .{};
    var color_texture_view: sg.View = .{};
    var target_width: i32 = 0;
    var target_height: i32 = 0;

    var effect: Effect = .normal;
};

const cube_vertices = [_]SceneVertex{
    // Back and front.
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 0, 1 } },
    // Left and right.
    .{ .position = .{ -0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .uv = .{ 1, 1 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .uv = .{ 0, 1 } },
    // Bottom and top.
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

const floor_vertices = [_]SceneVertex{
    .{ .position = .{ -5, -0.5, -5 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 5, -0.5, -5 }, .uv = .{ 2, 0 } },
    .{ .position = .{ 5, -0.5, 5 }, .uv = .{ 2, 2 } },
    .{ .position = .{ -5, -0.5, 5 }, .uv = .{ 0, 2 } },
};

const floor_indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

// Two triangles cover normalized device coordinates from -1 to +1. No camera
// or matrix is needed because these positions are already in clip space.
const screen_vertices = [_]ScreenVertex{
    .{ .position = .{ -1, -1 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 1, -1 }, .uv = .{ 1, 0 } },
    .{ .position = .{ 1, 1 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -1, -1 }, .uv = .{ 0, 0 } },
    .{ .position = .{ 1, 1 }, .uv = .{ 1, 1 } },
    .{ .position = .{ -1, 1 }, .uv = .{ 0, 1 } },
};

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.cube_bindings = makeSceneBindings(
        &cube_vertices,
        &cube_indices,
        @embedFile("assets/depth_testing/marble.jpg"),
    );
    state.floor_bindings = makeSceneBindings(
        &floor_vertices,
        &floor_indices,
        @embedFile("assets/depth_testing/metal.png"),
    );

    var scene_pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.sceneShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        // The offscreen target is deliberately single-sampled. These formats
        // must match the images attached to its pass.
        .sample_count = 1,
        .depth = .{
            .pixel_format = .DEPTH,
            .compare = .LESS,
            .write_enabled = true,
        },
    };
    scene_pipeline_desc.colors[0].pixel_format = .RGBA8;
    scene_pipeline_desc.layout.attrs[shd.ATTR_scene_position].format = .FLOAT3;
    scene_pipeline_desc.layout.attrs[shd.ATTR_scene_texcoord0].format = .FLOAT2;
    state.scene_pipeline = sg.makePipeline(scene_pipeline_desc);

    var screen_pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.screenShaderDesc(sg.queryBackend())),
    };
    screen_pipeline_desc.layout.attrs[shd.ATTR_screen_position].format = .FLOAT2;
    screen_pipeline_desc.layout.attrs[shd.ATTR_screen_texcoord0].format = .FLOAT2;
    state.screen_pipeline = sg.makePipeline(screen_pipeline_desc);
    state.screen_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&screen_vertices) });
    state.screen_bindings.samplers[shd.SMP_scene_smp] = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    state.offscreen_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
    };
    state.offscreen_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
    state.display_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
    };

    recreateOffscreenTargets(@max(sapp.width(), 1), @max(sapp.height(), 1));
}

fn makeSceneBindings(
    vertices: []const SceneVertex,
    indices: []const u16,
    encoded_image: []const u8,
) sg.Bindings {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertices) });
    bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(indices),
    });
    bindings.views[shd.VIEW_object_tex] = decodeTexture(encoded_image);
    bindings.samplers[shd.SMP_object_smp] = sg.makeSampler(.{
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
    if (pixels == null) @panic("could not decode framebuffer lesson texture");
    defer model_image.model_image_free(pixels);

    var image_data: sg.ImageData = .{};
    image_data.mip_levels[0] = .{
        .ptr = pixels,
        .size = @intCast(width * height * 4),
    };
    const image = sg.makeImage(.{
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .data = image_data,
    });
    return sg.makeView(.{ .texture = .{ .image = image } });
}

// Recreate screen-sized attachments after a window or browser-canvas resize.
// The attachment and texture views refer to the same colour image but describe
// two different ways that image will be used by the GPU.
fn recreateOffscreenTargets(width: i32, height: i32) void {
    if (width == state.target_width and height == state.target_height) return;

    if (state.target_width != 0) {
        sg.destroyView(state.color_attachment_view);
        sg.destroyView(state.depth_attachment_view);
        sg.destroyView(state.color_texture_view);
        sg.destroyImage(state.color_image);
        sg.destroyImage(state.depth_image);
    }

    state.color_image = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .sample_count = 1,
    });
    state.depth_image = sg.makeImage(.{
        .usage = .{ .depth_stencil_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .DEPTH,
        .sample_count = 1,
    });
    state.color_attachment_view = sg.makeView(.{
        .color_attachment = .{ .image = state.color_image },
    });
    state.depth_attachment_view = sg.makeView(.{
        .depth_stencil_attachment = .{ .image = state.depth_image },
    });
    state.color_texture_view = sg.makeView(.{
        .texture = .{ .image = state.color_image },
    });

    state.offscreen_pass.attachments.colors[0] = state.color_attachment_view;
    state.offscreen_pass.attachments.depth_stencil = state.depth_attachment_view;
    state.screen_bindings.views[shd.VIEW_scene_tex] = state.color_texture_view;
    state.target_width = width;
    state.target_height = height;
}

export fn frame() void {
    const width = @max(sapp.width(), 1);
    const height = @max(sapp.height(), 1);
    recreateOffscreenTargets(width, height);

    const projection = Mat4.persp(45, @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height)), 0.1, 20.0);
    const view = Mat4.lookat(.{ .x = 0, .y = 1.2, .z = 5 }, .{ .x = 0, .y = 0, .z = -1 }, Vec3.up());
    const view_projection = Mat4.mul(projection, view);

    // Pass 1: the scene is rendered offscreen. Nothing from this pass is shown
    // by the window directly; its colour fragments are stored in color_image.
    state.offscreen_pass.action = state.offscreen_action;
    sg.beginPass(state.offscreen_pass);
    sg.applyPipeline(state.scene_pipeline);

    sg.applyBindings(state.cube_bindings);
    drawSceneObject(view_projection, Mat4.translate(.{ .x = -1, .y = 0, .z = -1 }), cube_indices.len);
    drawSceneObject(view_projection, Mat4.translate(.{ .x = 2, .y = 0, .z = 0 }), cube_indices.len);

    sg.applyBindings(state.floor_bindings);
    drawSceneObject(view_projection, Mat4.identity(), floor_indices.len);
    sg.endPass();

    // Pass 2: return to the window's swapchain and cover it with one quad. Its
    // fragment shader reads the completed colour image from pass 1.
    const screen_params = shd.ScreenFsParams{
        .post_options = .{
            @floatFromInt(@backingInt(state.effect)),
            1.0 / @as(f32, @floatFromInt(width)),
            1.0 / @as(f32, @floatFromInt(height)),
            0,
        },
    };
    sg.beginPass(.{ .action = state.display_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.screen_pipeline);
    sg.applyBindings(state.screen_bindings);
    sg.applyUniforms(shd.UB_screen_fs_params, sg.asRange(&screen_params));
    sg.draw(0, screen_vertices.len, 1);
    sg.endPass();

    sg.commit();
}

fn drawSceneObject(view_projection: Mat4, model: Mat4, element_count: u32) void {
    const params = shd.SceneVsParams{ .mvp = Mat4.mul(view_projection, model) };
    sg.applyUniforms(shd.UB_scene_vs_params, sg.asRange(&params));
    sg.draw(0, element_count, 1);
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    state.effect = switch (event.key_code) {
        ._1 => .normal,
        ._2 => .invert,
        ._3 => .grayscale,
        ._4 => .sharpen,
        ._5 => .blur,
        ._6 => .edges,
        else => state.effect,
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
        .window_title = "LearnOpenGL Framebuffers — 1-6 post-processing effects",
        .logger = .{ .func = slog.func },
    });
}
