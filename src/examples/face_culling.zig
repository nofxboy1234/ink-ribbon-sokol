const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/face_culling_shader.zig");

const Vertex = extern struct {
    position: [3]f32,
    color: [3]f32,
};

const LessonMode = enum {
    none,
    back_ccw,
    front_ccw,
    back_cw,
    both,
};

const state = struct {
    var pass_action: sg.PassAction = .{};
    var no_culling_pipeline: sg.Pipeline = .{};
    var back_ccw_pipeline: sg.Pipeline = .{};
    var front_ccw_pipeline: sg.Pipeline = .{};
    var back_cw_pipeline: sg.Pipeline = .{};
    var bindings: sg.Bindings = .{};
    var mode: LessonMode = .back_ccw;
    var camera_inside = false;
    var paused = false;
    var rotation_x: f32 = -18;
    var rotation_y: f32 = 30;
};

const cube_vertices = [_]Vertex{
    .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.55, 0.12, 0.12 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 0.55, 0.12, 0.12 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.55, 0.12, 0.12 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.55, 0.12, 0.12 } },

    .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.95, 0.32, 0.12 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 0.95, 0.32, 0.12 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.95, 0.32, 0.12 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.95, 0.32, 0.12 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.16, 0.72, 0.32 } },
    .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.16, 0.72, 0.32 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.16, 0.72, 0.32 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.16, 0.72, 0.32 } },

    .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 0.14, 0.42, 0.92 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.14, 0.42, 0.92 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.14, 0.42, 0.92 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 0.14, 0.42, 0.92 } },

    .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.60, 0.20, 0.80 } },
    .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.60, 0.20, 0.80 } },
    .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 0.60, 0.20, 0.80 } },
    .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 0.60, 0.20, 0.80 } },

    .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.95, 0.78, 0.16 } },
    .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.95, 0.78, 0.16 } },
    .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.95, 0.78, 0.16 } },
    .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.95, 0.78, 0.16 } },
};

const cube_indices = [_]u16{
    0,  2,  1,  0,  3,  2,
    4,  5,  6,  4,  6,  7,
    8,  10, 9,  8,  11, 10,
    12, 13, 14, 12, 14, 15,
    16, 18, 17, 16, 19, 18,
    20, 21, 22, 20, 22, 23,
};

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&cube_vertices) });
    state.bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&cube_indices),
    });

    var desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.faceCullingShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS, .write_enabled = true },

        .face_winding = .CCW,
    };
    desc.layout.attrs[shd.ATTR_face_culling_position].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_face_culling_color0].format = .FLOAT3;

    desc.cull_mode = .NONE;
    state.no_culling_pipeline = sg.makePipeline(desc);

    desc.cull_mode = .BACK;
    state.back_ccw_pipeline = sg.makePipeline(desc);

    desc.cull_mode = .FRONT;
    state.front_ccw_pipeline = sg.makePipeline(desc);

    desc.cull_mode = .BACK;
    desc.face_winding = .CW;
    state.back_cw_pipeline = sg.makePipeline(desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.035, .g = 0.045, .b = 0.065, .a = 1 },
    };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

export fn frame() void {
    if (!state.paused) {
        const frame_scale: f32 = @floatCast(sapp.frameDuration() * 60.0);
        state.rotation_x += 0.15 * frame_scale;
        state.rotation_y += 0.35 * frame_scale;
    }

    const projection = Mat4.persp(60, sapp.widthf() / sapp.heightf(), 0.01, 10.0);
    const view = if (state.camera_inside)
        Mat4.lookat(Vec3.zero(), .{ .x = 0, .y = 0, .z = -1 }, Vec3.up())
    else
        Mat4.lookat(.{ .x = 0, .y = 0, .z = 2.6 }, Vec3.zero(), Vec3.up());
    const rotate_x = Mat4.rotate(state.rotation_x, .{ .x = 1, .y = 0, .z = 0 });
    const rotate_y = Mat4.rotate(state.rotation_y, .{ .x = 0, .y = 1, .z = 0 });
    const model = Mat4.mul(rotate_x, rotate_y);
    const params = shd.VsParams{ .mvp = Mat4.mul(Mat4.mul(projection, view), model) };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    if (state.mode != .both) {
        sg.applyPipeline(switch (state.mode) {
            .none => state.no_culling_pipeline,
            .back_ccw => state.back_ccw_pipeline,
            .front_ccw => state.front_ccw_pipeline,
            .back_cw => state.back_cw_pipeline,
            .both => unreachable,
        });
        sg.applyBindings(state.bindings);
        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&params));
        sg.draw(0, cube_indices.len, 1);
    }

    sg.endPass();
    sg.commit();
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    if (event.type != .KEY_DOWN or event.key_repeat) return;
    switch (event.key_code) {
        ._1 => state.mode = .none,
        ._2 => state.mode = .back_ccw,
        ._3 => state.mode = .front_ccw,
        ._4 => state.mode = .back_cw,
        ._5 => state.mode = .both,
        .I => state.camera_inside = !state.camera_inside,
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
        .window_title = "LearnOpenGL Face Culling — 1-5 modes, I: inside, Space: pause",
        .logger = .{ .func = slog.func },
    });
}
