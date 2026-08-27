const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const shd = @import("generated/advanced_data_shader.zig");

const Vertex = extern struct {
    position: [2]f32,
    color: [3]f32,
};

const PlanarData = extern struct {
    positions: [3][2]f32,
    colors: [3][3]f32,
};

const state = struct {
    var interleaved_bindings: sg.Bindings = .{};
    var planar_bindings: sg.Bindings = .{};
    var dynamic_bindings: sg.Bindings = .{};
    var interleaved_pipeline: sg.Pipeline = .{};
    var planar_pipeline: sg.Pipeline = .{};
    var time: f32 = 0.0;
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    const interleaved = [_]Vertex{
        .{ .position = .{ -0.90, -0.35 }, .color = .{ 1.00, 0.25, 0.20 } },
        .{ .position = .{ -0.40, -0.35 }, .color = .{ 0.20, 1.00, 0.35 } },
        .{ .position = .{ -0.65, 0.45 }, .color = .{ 0.25, 0.45, 1.00 } },
    };
    state.interleaved_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&interleaved),
        .label = "interleaved vertices",
    });

    const planar = PlanarData{
        .positions = .{
            .{ -0.25, -0.35 }, .{ 0.25, -0.35 }, .{ 0.00, 0.45 },
        },
        .colors = .{
            .{ 1.00, 0.80, 0.15 }, .{ 0.15, 0.85, 1.00 }, .{ 0.85, 0.20, 1.00 },
        },
    };
    const planar_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&planar),
        .label = "grouped attribute arrays",
    });
    state.planar_bindings.vertex_buffers[0] = planar_buffer;
    state.planar_bindings.vertex_buffers[1] = planar_buffer;
    state.planar_bindings.vertex_buffer_offsets[1] = @offsetOf(PlanarData, "colors");

    state.dynamic_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .size = @sizeOf([3]Vertex),
        .usage = .{ .vertex_buffer = true, .stream_update = true },
        .label = "streamed vertices",
    });

    const shader = sg.makeShader(shd.advancedDataShaderDesc(sg.queryBackend()));
    state.interleaved_pipeline = sg.makePipeline(.{
        .shader = shader,
        .layout = interleavedLayout(),
        .label = "interleaved pipeline",
    });
    state.planar_pipeline = sg.makePipeline(.{
        .shader = shader,
        .layout = planarLayout(),
        .label = "grouped pipeline",
    });
}

fn interleavedLayout() sg.VertexLayoutState {
    var layout = sg.VertexLayoutState{};
    layout.buffers[0].stride = @sizeOf(Vertex);
    layout.attrs[shd.ATTR_advanced_data_position] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(Vertex, "position"),
    };
    layout.attrs[shd.ATTR_advanced_data_color0] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(Vertex, "color"),
    };
    return layout;
}

fn planarLayout() sg.VertexLayoutState {
    var layout = sg.VertexLayoutState{};
    layout.buffers[0].stride = @sizeOf([2]f32);
    layout.buffers[1].stride = @sizeOf([3]f32);
    layout.attrs[shd.ATTR_advanced_data_position] = .{
        .buffer_index = 0,
        .format = .FLOAT2,
    };
    layout.attrs[shd.ATTR_advanced_data_color0] = .{
        .buffer_index = 1,
        .format = .FLOAT3,
    };
    return layout;
}

export fn frame() void {
    state.time += @floatCast(sapp.frameDuration());
    const wave = 0.10 * @sin(state.time * 2.5);
    const streamed = [_]Vertex{
        .{ .position = .{ 0.40, -0.35 + wave }, .color = .{ 1.00, 0.35, 0.25 } },
        .{ .position = .{ 0.90, -0.35 + wave }, .color = .{ 0.25, 1.00, 0.40 } },
        .{ .position = .{ 0.65, 0.45 + wave }, .color = .{ 0.30, 0.50, 1.00 } },
    };

    sg.updateBuffer(state.dynamic_bindings.vertex_buffers[0], sg.asRange(&streamed));

    var pass_action = sg.PassAction{};
    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.07, .g = 0.08, .b = 0.11, .a = 1.0 },
    };
    sg.beginPass(.{
        .action = pass_action,
        .swapchain = sglue.swapchain(),
    });

    sg.applyPipeline(state.interleaved_pipeline);
    sg.applyBindings(state.interleaved_bindings);
    sg.draw(0, 3, 1);

    sg.applyPipeline(state.planar_pipeline);
    sg.applyBindings(state.planar_bindings);
    sg.draw(0, 3, 1);

    sg.applyPipeline(state.interleaved_pipeline);
    sg.applyBindings(state.dynamic_bindings);
    sg.draw(0, 3, 1);

    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 900,
        .height = 500,
        .sample_count = 1,
        .depth_format = .NONE,
        .icon = .{ .sokol_default = true },
        .window_title = "Advanced Data: interleaved | grouped | streamed",
        .logger = .{ .func = slog.func },
    });
}
