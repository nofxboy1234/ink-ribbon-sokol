const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sglue = @import("sokol").glue;
const slog = @import("sokol").log;
// `sokol-shdc` generated this Zig interface from anti_aliasing.glsl. It gives
// us type-safe shader descriptions, uniform structs, and binding-slot numbers.
const shd = @import("generated/anti_aliasing_shader.zig");

// 4x MSAA tests triangle coverage at four places inside every pixel.
const samples_msaa = 4;

// Pass 1 only needs positions: it draws the green test shape.
const SceneVertex = extern struct { position: [2]f32 };
// Pass 2 also needs UV coordinates so its full-screen quad can read the image
// produced by pass 1.
const DisplayVertex = extern struct {
    position: [2]f32,
    uv: [2]f32,
};

// Two triangles form one long rectangle around the origin. The shader rotates
// it slightly so its edges cross pixel rows—the situation where aliasing is
// easiest to see.
const scene_vertices = [_]SceneVertex{
    .{ .position = .{ -0.82, -0.055 } }, .{ .position = .{ 0.82, -0.055 } }, .{ .position = .{ -0.82, 0.055 } },
    .{ .position = .{ -0.82, 0.055 } },  .{ .position = .{ 0.82, -0.055 } }, .{ .position = .{ 0.82, 0.055 } },
};

const display_vertices = [_]DisplayVertex{
    .{ .position = .{ -1, -1 }, .uv = .{ 0, 0 } }, .{ .position = .{ 1, -1 }, .uv = .{ 1, 0 } }, .{ .position = .{ -1, 1 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -1, 1 }, .uv = .{ 0, 1 } },  .{ .position = .{ 1, -1 }, .uv = .{ 1, 0 } }, .{ .position = .{ 1, 1 }, .uv = .{ 1, 1 } },
};

// Mental model for the whole frame:
//
//   draw green shape offscreen -> optional MSAA resolve -> draw image to window
//
// Sokol resources are handles stored here so they survive between callbacks.
const state = struct {
    // Key 1 makes this false; key 2 makes it true.
    var use_msaa = true;
    // Offscreen images must match the window size, so remember their size.
    var width: i32 = 0;
    var height: i32 = 0;

    // Bindings connect buffers/textures/samplers to a shader for a draw.
    var scene_bindings: sg.Bindings = .{};
    var display_bindings: sg.Bindings = .{};

    // A pipeline describes how the GPU interprets vertices and rasterizes them.
    // The scene needs separate pipelines because sample count is pipeline state.
    var single_pipeline: sg.Pipeline = .{};
    var msaa_pipeline: sg.Pipeline = .{};
    var display_pipeline: sg.Pipeline = .{};
    var sampler: sg.Sampler = .{};

    // Mode 1 writes straight into an ordinary one-sample image.
    var single_color_image: sg.Image = .{};
    var single_color_view: sg.View = .{};
    var single_texture_view: sg.View = .{};

    // Mode 2 writes into a four-sample image, then combines those samples into
    // the ordinary resolve image. A view is a particular way to use an image.
    var msaa_color_image: sg.Image = .{};
    var msaa_color_view: sg.View = .{};
    var resolve_image: sg.Image = .{};
    var resolve_view: sg.View = .{};
    var resolve_texture_view: sg.View = .{};
};

export fn init() void {
    // Start sokol-gfx and connect it to the graphics context made by sokol-app.
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    // Upload both pieces of static geometry once. Pass 1 uses the rectangle;
    // pass 2 uses the screen-sized quad.
    state.scene_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&scene_vertices), .label = "anti-aliasing scene vertices" });
    state.display_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&display_vertices), .label = "anti-aliasing display quad" });
    // NEAREST avoids adding texture-filter smoothing to the comparison. We want
    // the visible difference to come from MSAA coverage alone.
    state.sampler = sg.makeSampler(.{ .min_filter = .NEAREST, .mag_filter = .NEAREST, .label = "resolved scene sampler" });
    state.display_bindings.samplers[shd.SMP_scene_smp] = state.sampler;

    // Tell Sokol that each pass-1 vertex begins with two 32-bit floats.
    var scene_layout: sg.VertexLayoutState = .{};
    scene_layout.attrs[shd.ATTR_scene_position].format = .FLOAT2;
    const scene_shader = sg.makeShader(shd.sceneShaderDesc(sg.queryBackend()));
    state.single_pipeline = sg.makePipeline(.{
        .shader = scene_shader,
        .layout = scene_layout,
        // This flat 2D demonstration has no overlapping depth to test, so the
        // pipeline explicitly matches the pass's lack of a depth attachment.
        .depth = .{ .pixel_format = .NONE },
        .sample_count = 1,
        .label = "single-sample scene pipeline",
    });
    state.msaa_pipeline = sg.makePipeline(.{
        .shader = scene_shader,
        .layout = scene_layout,
        .depth = .{ .pixel_format = .NONE },
        // Pipeline and color-attachment sample counts must agree.
        .sample_count = samples_msaa,
        .label = "4x-msaa scene pipeline",
    });

    // The display vertex buffer interleaves position and UV in each record.
    var display_layout: sg.VertexLayoutState = .{};
    display_layout.attrs[shd.ATTR_display_position] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "position") };
    display_layout.attrs[shd.ATTR_display_texcoord0] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "uv") };
    state.display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = display_layout,
        // The resolved texture and final window are ordinary one-sample images.
        .sample_count = 1,
        .label = "resolved-texture display pipeline",
    });
}

fn destroyTargets() void {
    // Before the first allocation there is nothing to destroy.
    if (state.width == 0) return;
    // Views refer to images, so release the views before their parent images.
    sg.destroyView(state.single_color_view);
    sg.destroyView(state.single_texture_view);
    sg.destroyView(state.msaa_color_view);
    sg.destroyView(state.resolve_view);
    sg.destroyView(state.resolve_texture_view);
    sg.destroyImage(state.single_color_image);
    sg.destroyImage(state.msaa_color_image);
    sg.destroyImage(state.resolve_image);
}

fn recreateTargets(width: i32, height: i32) void {
    // Avoid reallocating GPU images on every frame; only do it after a resize.
    if (width == state.width and height == state.height) return;
    destroyTargets();

    // Mode 1 mental model:
    //
    //   rectangle -> one color value per pixel -> display shader
    //
    // The two views below refer to the same image. One lets a render pass write
    // into it; the other lets the following pass sample from it as a texture.
    state.single_color_image = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .sample_count = 1,
        .label = "single-sample color image",
    });
    state.single_color_view = sg.makeView(.{ .color_attachment = .{ .image = state.single_color_image }, .label = "single-sample color attachment" });
    state.single_texture_view = sg.makeView(.{ .texture = .{ .image = state.single_color_image }, .label = "single-sample texture" });

    // Mode 2 starts with multisample storage:
    //
    //   one screen pixel -> four coverage/color sample slots
    //
    // This image is temporary working storage and is not sampled directly.
    state.msaa_color_image = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .sample_count = samples_msaa,
        .label = "4x-msaa color image",
    });
    state.msaa_color_view = sg.makeView(.{ .color_attachment = .{ .image = state.msaa_color_image }, .label = "4x-msaa color attachment" });

    // A multisampled image cannot be used here like an ordinary texture. At the
    // end of the pass, Sokol *resolves* its four samples into one final value:
    //
    //   four stored samples -> combine/average coverage -> one resolved pixel
    state.resolve_image = sg.makeImage(.{
        .usage = .{ .resolve_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .sample_count = 1,
        .label = "resolved color image",
    });
    state.resolve_view = sg.makeView(.{ .resolve_attachment = .{ .image = state.resolve_image }, .label = "resolve attachment" });
    state.resolve_texture_view = sg.makeView(.{ .texture = .{ .image = state.resolve_image }, .label = "resolved texture" });

    state.width = width;
    state.height = height;
}

export fn frame() void {
    // Clamp to one because a minimized window may briefly report zero size,
    // while GPU images must have non-zero dimensions.
    const width = @max(sapp.width(), 1);
    const height = @max(sapp.height(), 1);
    recreateTargets(width, height);

    // Calculate the rotation once on the CPU. The vertex shader uses the same
    // cosine and sine for all six rectangle vertices. height/width compensates
    // for the window aspect ratio so the shape does not stretch horizontally.
    const scene_params = shd.SceneVsParams{ .transform = .{
        @cos(0.23),
        @sin(0.23),
        @as(f32, @floatFromInt(height)) / @as(f32, @floatFromInt(width)),
        0,
    } };
    // A pass action says what should already be in an attachment when a pass
    // begins. CLEAR fills color attachment 0 with the dark background.
    const action = sg.PassAction{ .colors = init: {
        var colors: [8]sg.ColorAttachmentAction = @splat(.{});
        colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.04, .b = 0.055, .a = 1 } };
        break :init colors;
    } };

    // PASS 1: render the green shape into an offscreen color attachment.
    var offscreen_pass = sg.Pass{ .action = action };
    if (state.use_msaa) {
        // Render into the four-sample image. The resolve view names the
        // one-sample destination that receives the combined result.
        offscreen_pass.attachments.colors[0] = state.msaa_color_view;
        offscreen_pass.attachments.resolves[0] = state.resolve_view;
    } else {
        // No MSAA and no resolve: render directly into the sampleable image.
        offscreen_pass.attachments.colors[0] = state.single_color_view;
    }
    sg.beginPass(offscreen_pass);
    sg.applyPipeline(if (state.use_msaa) state.msaa_pipeline else state.single_pipeline);
    sg.applyBindings(state.scene_bindings);
    sg.applyUniforms(shd.UB_scene_vs_params, sg.asRange(&scene_params));
    sg.draw(0, scene_vertices.len, 1); // six vertices, one rectangle instance
    // In mode 2 this boundary also performs the MSAA resolve. Pass 2 can then
    // safely read the resulting ordinary texture.
    sg.endPass();

    // PASS 2: choose the completed one-sample image and paste it over the
    // swapchain (the image that will ultimately appear in the window).
    state.display_bindings.views[shd.VIEW_scene_tex] = if (state.use_msaa) state.resolve_texture_view else state.single_texture_view;
    sg.beginPass(.{ .action = action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.display_pipeline);
    sg.applyBindings(state.display_bindings);
    sg.draw(0, display_vertices.len, 1);
    sg.endPass();
    // Submit the completed frame for presentation.
    sg.commit();
}

export fn cleanup() void {
    // Release our resize-dependent resources before shutting down sokol-gfx.
    destroyTargets();
    sg.shutdown();
}

export fn input(event_ptr: [*c]const sapp.Event) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    switch (event.key_code) {
        ._1 => state.use_msaa = false,
        ._2 => state.use_msaa = true,
        else => {},
    }
}

pub fn main() void {
    // sokol-app owns the event loop and calls init(), frame(), input(), and
    // cleanup() at the appropriate times.
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 900,
        .height = 600,
        // Keep the final window single-sampled so both teaching modes use the
        // same display pass. Mode 2 performs its 4x resolve before this point.
        .sample_count = 1,
        .window_title = "Anti-Aliasing — 1: off  2: 4x MSAA",
        .logger = .{ .func = slog.func },
    });
}
