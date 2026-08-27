const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/advanced_glsl_shader.zig");

const state = struct {
    var cube_bindings: sg.Bindings = .{};
    var marker_bindings: sg.Bindings = .{};
    var cube_pipeline: sg.Pipeline = .{};
    var marker_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var split_enabled: bool = false;
};

const cube_positions = [_]f32{
    -0.5, -0.5, -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, -0.5, 0.5,  -0.5,
    -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  0.5,  0.5,  -0.5, 0.5,  0.5,
    -0.5, -0.5, -0.5, -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, -0.5, 0.5,
    0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  0.5,  0.5,  -0.5, 0.5,
    -0.5, -0.5, -0.5, -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  -0.5, -0.5,
    -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  0.5,  0.5,  0.5,  0.5,  0.5,  -0.5,
};

const cube_indices = [_]u16{
    0,  1,  2,  0,  2,  3,
    6,  5,  4,  7,  6,  4,
    8,  9,  10, 8,  10, 11,
    14, 13, 12, 15, 14, 12,
    16, 17, 18, 16, 18, 19,
    22, 21, 20, 23, 22, 20,
};

const marker_positions = [_][2]f32{
    .{ -0.38, 0.82 }, .{ -0.32, 0.82 }, .{ -0.35, 0.92 },
    .{ -0.22, 0.82 }, .{ -0.16, 0.82 }, .{ -0.19, 0.92 },
    .{ -0.06, 0.82 }, .{ 0.00, 0.82 },  .{ -0.03, 0.92 },
    .{ 0.10, 0.82 },  .{ 0.16, 0.82 },  .{ 0.13, 0.92 },
    .{ 0.26, 0.82 },  .{ 0.32, 0.82 },  .{ 0.29, 0.92 },
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.cube_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&cube_positions),
        .label = "advanced-glsl cube vertices",
    });
    state.cube_bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&cube_indices),
        .label = "advanced-glsl cube indices",
    });
    state.marker_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&marker_positions),
        .label = "advanced-glsl marker positions",
    });

    state.cube_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.cubesShaderDesc(sg.queryBackend())),
        .layout = layout: {
            var value = sg.VertexLayoutState{};
            value.attrs[shd.ATTR_cubes_position].format = .FLOAT3;
            break :layout value;
        },
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },

        .cull_mode = .NONE,
        .label = "advanced-glsl cubes",
    });
    state.marker_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.markersShaderDesc(sg.queryBackend())),
        .layout = layout: {
            var value = sg.VertexLayoutState{};
            value.attrs[shd.ATTR_markers_position].format = .FLOAT2;
            break :layout value;
        },
        .label = "advanced-glsl vertex-index markers",
    });

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.055, .g = 0.06, .b = 0.08, .a = 1.0 },
    };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

export fn frame() void {
    const projection = Mat4.persp(45.0, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view = Mat4.lookat(.{ .x = 0.0, .y = 0.0, .z = 8.0 }, Vec3.zero(), Vec3.up());
    const view_projection = Mat4.mul(projection, view);

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.cube_pipeline);
    sg.applyBindings(state.cube_bindings);

    drawCube(view_projection, .{ .x = -1.15, .y = 0.9, .z = 0.0 }, .{ 1.0, 0.15, 0.12, 1.0 });
    drawCube(view_projection, .{ .x = 1.15, .y = 0.9, .z = 0.0 }, .{ 0.15, 0.85, 0.22, 1.0 });
    drawCube(view_projection, .{ .x = -1.15, .y = -0.9, .z = 0.0 }, .{ 0.15, 0.35, 1.0, 1.0 });
    drawCube(view_projection, .{ .x = 1.15, .y = -0.9, .z = 0.0 }, .{ 1.0, 0.82, 0.12, 1.0 });

    sg.applyPipeline(state.marker_pipeline);
    sg.applyBindings(state.marker_bindings);
    sg.draw(0, marker_positions.len, 1);

    sg.endPass();
    sg.commit();
}

fn drawCube(view_projection: Mat4, position: Vec3, color: [4]f32) void {
    const vertex = shd.CubeVsParams{
        .mvp = Mat4.mul(view_projection, Mat4.translate(position)),
    };
    const fragment = shd.CubeFsParams{
        .color = color,
        .viewport_size = .{ sapp.widthf(), sapp.heightf() },
        .split_enabled = if (state.split_enabled) 1.0 else 0.0,
    };
    sg.applyUniforms(shd.UB_cube_vs_params, sg.asRange(&vertex));
    sg.applyUniforms(shd.UB_cube_fs_params, sg.asRange(&fragment));
    sg.draw(0, cube_indices.len, 1);
}

export fn input(event: ?*const sapp.Event) void {
    const ev = event orelse return;
    if (ev.type == .KEY_DOWN and !ev.key_repeat and ev.key_code == .F) {
        state.split_enabled = !state.split_enabled;
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
        .icon = .{ .sokol_default = true },
        .window_title = "Advanced GLSL — F: toggle gl_FragCoord split",
        .logger = .{ .func = slog.func },
    });
}
