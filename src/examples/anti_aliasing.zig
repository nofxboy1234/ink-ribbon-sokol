const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sglue = @import("sokol").glue;
const slog = @import("sokol").log;

const shd = @import("generated/anti_aliasing_shader.zig");

const samples_msaa = 4;

const SceneVertex = extern struct { position: [2]f32 };

const DisplayVertex = extern struct {
    position: [2]f32,
    uv: [2]f32,
};

const scene_vertices = [_]SceneVertex{
    .{ .position = .{ -0.82, -0.055 } }, .{ .position = .{ 0.82, -0.055 } }, .{ .position = .{ -0.82, 0.055 } },
    .{ .position = .{ -0.82, 0.055 } },  .{ .position = .{ 0.82, -0.055 } }, .{ .position = .{ 0.82, 0.055 } },
};

const display_vertices = [_]DisplayVertex{
    .{ .position = .{ -1, -1 }, .uv = .{ 0, 0 } }, .{ .position = .{ 1, -1 }, .uv = .{ 1, 0 } }, .{ .position = .{ -1, 1 }, .uv = .{ 0, 1 } },
    .{ .position = .{ -1, 1 }, .uv = .{ 0, 1 } },  .{ .position = .{ 1, -1 }, .uv = .{ 1, 0 } }, .{ .position = .{ 1, 1 }, .uv = .{ 1, 1 } },
};

const state = struct {
    var use_msaa = true;

    var width: i32 = 0;
    var height: i32 = 0;

    var scene_bindings: sg.Bindings = .{};
    var display_bindings: sg.Bindings = .{};

    var single_pipeline: sg.Pipeline = .{};
    var msaa_pipeline: sg.Pipeline = .{};
    var display_pipeline: sg.Pipeline = .{};
    var sampler: sg.Sampler = .{};

    var single_color_image: sg.Image = .{};
    var single_color_view: sg.View = .{};
    var single_texture_view: sg.View = .{};

    var msaa_color_image: sg.Image = .{};
    var msaa_color_view: sg.View = .{};
    var resolve_image: sg.Image = .{};
    var resolve_view: sg.View = .{};
    var resolve_texture_view: sg.View = .{};
};

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.scene_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&scene_vertices), .label = "anti-aliasing scene vertices" });
    state.display_bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&display_vertices), .label = "anti-aliasing display quad" });

    state.sampler = sg.makeSampler(.{ .min_filter = .NEAREST, .mag_filter = .NEAREST, .label = "resolved scene sampler" });
    state.display_bindings.samplers[shd.SMP_scene_smp] = state.sampler;

    var scene_layout: sg.VertexLayoutState = .{};
    scene_layout.attrs[shd.ATTR_scene_position].format = .FLOAT2;
    const scene_shader = sg.makeShader(shd.sceneShaderDesc(sg.queryBackend()));
    state.single_pipeline = sg.makePipeline(.{
        .shader = scene_shader,
        .layout = scene_layout,

        .depth = .{ .pixel_format = .NONE },
        .sample_count = 1,
        .label = "single-sample scene pipeline",
    });
    state.msaa_pipeline = sg.makePipeline(.{
        .shader = scene_shader,
        .layout = scene_layout,
        .depth = .{ .pixel_format = .NONE },

        .sample_count = samples_msaa,
        .label = "4x-msaa scene pipeline",
    });

    var display_layout: sg.VertexLayoutState = .{};
    display_layout.attrs[shd.ATTR_display_position] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "position") };
    display_layout.attrs[shd.ATTR_display_texcoord0] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "uv") };
    state.display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = display_layout,

        .sample_count = 1,
        .label = "resolved-texture display pipeline",
    });
}

fn destroyTargets() void {
    if (state.width == 0) return;

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
    if (width == state.width and height == state.height) return;
    destroyTargets();

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

    state.msaa_color_image = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .sample_count = samples_msaa,
        .label = "4x-msaa color image",
    });
    state.msaa_color_view = sg.makeView(.{ .color_attachment = .{ .image = state.msaa_color_image }, .label = "4x-msaa color attachment" });

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
    const width = @max(sapp.width(), 1);
    const height = @max(sapp.height(), 1);
    recreateTargets(width, height);

    const scene_params = shd.SceneVsParams{ .transform = .{
        @cos(0.23),
        @sin(0.23),
        @as(f32, @floatFromInt(height)) / @as(f32, @floatFromInt(width)),
        0,
    } };

    const action = sg.PassAction{ .colors = init: {
        var colors: [8]sg.ColorAttachmentAction = @splat(.{});
        colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.04, .b = 0.055, .a = 1 } };
        break :init colors;
    } };

    var offscreen_pass = sg.Pass{ .action = action };
    if (state.use_msaa) {
        offscreen_pass.attachments.colors[0] = state.msaa_color_view;
        offscreen_pass.attachments.resolves[0] = state.resolve_view;
    } else {
        offscreen_pass.attachments.colors[0] = state.single_color_view;
    }
    sg.beginPass(offscreen_pass);
    sg.applyPipeline(if (state.use_msaa) state.msaa_pipeline else state.single_pipeline);
    sg.applyBindings(state.scene_bindings);
    sg.applyUniforms(shd.UB_scene_vs_params, sg.asRange(&scene_params));
    sg.draw(0, scene_vertices.len, 1);

    sg.endPass();

    state.display_bindings.views[shd.VIEW_scene_tex] = if (state.use_msaa) state.resolve_texture_view else state.single_texture_view;
    sg.beginPass(.{ .action = action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.display_pipeline);
    sg.applyBindings(state.display_bindings);
    sg.draw(0, display_vertices.len, 1);
    sg.endPass();

    sg.commit();
}

export fn cleanup() void {
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
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 900,
        .height = 600,

        .sample_count = 1,
        .window_title = "Anti-Aliasing — 1: off  2: 4x MSAA",
        .logger = .{ .func = slog.func },
    });
}
