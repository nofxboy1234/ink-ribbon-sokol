//! LearnOpenGL Instancing mapped to sokol_gfx.

const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const shd = @import("generated/instancing_shader.zig");

const Vertex = extern struct {
    position: [2]f32,
    color: [3]f32,
};

const Instance = extern struct {
    offset: [2]f32,
    color: [3]f32,
    scale: f32,
};

const instance_count = 100;

const state = struct {
    var bindings: sg.Bindings = .{};
    var index_pipeline: sg.Pipeline = .{};
    var buffer_pipeline: sg.Pipeline = .{};
    var use_instance_buffer = false;
};

const quad = [_]Vertex{
    .{ .position = .{ -0.055, 0.055 }, .color = .{ 1, 0, 0 } },
    .{ .position = .{ 0.055, -0.055 }, .color = .{ 0, 1, 0 } },
    .{ .position = .{ -0.055, -0.055 }, .color = .{ 0, 0, 1 } },
    .{ .position = .{ -0.055, 0.055 }, .color = .{ 1, 0, 0 } },
    .{ .position = .{ 0.055, -0.055 }, .color = .{ 0, 1, 0 } },
    .{ .position = .{ 0.055, 0.055 }, .color = .{ 0, 1, 1 } },
};

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&quad),
        .label = "one shared quad",
    });

    var instances: [instance_count]Instance = undefined;
    for (0..10) |row| {
        for (0..10) |column| {
            const i = row * 10 + column;
            const t: f32 = @floatFromInt(i);
            instances[i] = .{
                .offset = .{
                    -0.9 + @as(f32, @floatFromInt(column)) * 0.2,
                    -0.9 + @as(f32, @floatFromInt(row)) * 0.2,
                },
                .color = .{
                    0.35 + @as(f32, @floatFromInt(column)) * 0.065,
                    0.35 + @as(f32, @floatFromInt(row)) * 0.065,
                    1.0 - t * 0.004,
                },
                .scale = 0.35 + 0.65 * ((t + 1.0) / instance_count),
            };
        }
    }
    state.bindings.vertex_buffers[1] = sg.makeBuffer(.{
        .data = sg.asRange(&instances),
        .label = "100 per-instance records",
    });

    state.index_pipeline = makeIndexPipeline();
    state.buffer_pipeline = makeBufferPipeline();
}

fn baseLayout(position_attr: u32, color_attr: u32) sg.VertexLayoutState {
    var layout = sg.VertexLayoutState{};
    layout.buffers[0].stride = @sizeOf(Vertex);
    layout.attrs[position_attr] = .{ .format = .FLOAT2, .offset = @offsetOf(Vertex, "position") };
    layout.attrs[color_attr] = .{ .format = .FLOAT3, .offset = @offsetOf(Vertex, "color") };
    return layout;
}

fn makeIndexPipeline() sg.Pipeline {
    return sg.makePipeline(.{
        .shader = sg.makeShader(shd.indexGridShaderDesc(sg.queryBackend())),
        .layout = baseLayout(shd.ATTR_index_grid_position, shd.ATTR_index_grid_color0),
        .sample_count = 4,
        .label = "instance-index grid",
    });
}

fn makeBufferPipeline() sg.Pipeline {
    var layout = baseLayout(shd.ATTR_buffer_grid_position, shd.ATTR_buffer_grid_color0);
    // Buffer 0 advances for every quad corner. Buffer 1 advances only when the
    // GPU starts the next copy of the quad.
    layout.buffers[1] = .{ .stride = @sizeOf(Instance), .step_func = .PER_INSTANCE };
    layout.attrs[shd.ATTR_buffer_grid_instance_offset] = .{
        .buffer_index = 1,
        .offset = @offsetOf(Instance, "offset"),
        .format = .FLOAT2,
    };
    layout.attrs[shd.ATTR_buffer_grid_instance_color] = .{
        .buffer_index = 1,
        .offset = @offsetOf(Instance, "color"),
        .format = .FLOAT3,
    };
    layout.attrs[shd.ATTR_buffer_grid_instance_scale] = .{
        .buffer_index = 1,
        .offset = @offsetOf(Instance, "scale"),
        .format = .FLOAT,
    };
    return sg.makePipeline(.{
        .shader = sg.makeShader(shd.bufferGridShaderDesc(sg.queryBackend())),
        .layout = layout,
        .sample_count = 4,
        .label = "per-instance-buffer grid",
    });
}

export fn frame() void {
    var action = sg.PassAction{};
    action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.055, .g = 0.06, .b = 0.08, .a = 1 },
    };
    sg.beginPass(.{ .action = action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(if (state.use_instance_buffer) state.buffer_pipeline else state.index_pipeline);
    sg.applyBindings(state.bindings);
    // Six mesh vertices are reused for 100 instances in one draw command.
    sg.draw(0, quad.len, instance_count);
    sg.endPass();
    sg.commit();
}

export fn input(event: ?*const sapp.Event) void {
    const ev = event orelse return;
    if (ev.type != .KEY_DOWN or ev.key_repeat) return;
    switch (ev.key_code) {
        ._1 => state.use_instance_buffer = false,
        ._2 => state.use_instance_buffer = true,
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
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .depth_format = .NONE,
        .icon = .{ .sokol_default = true },
        .window_title = "Instancing — 1: instance index  2: instance buffer",
        .logger = .{ .func = slog.func },
    });
}
