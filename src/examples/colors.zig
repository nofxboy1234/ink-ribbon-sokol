const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;
const shd = @import("generated/colors_shader.zig");

const state = struct {
    var bind: sg.Bindings = .{};
    var object_pipeline: sg.Pipeline = .{};
    var lamp_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};

    const light_position = vec3{ .x = 1.2, .y = 1.0, .z = 2.0 };
    const view = mat4.lookat(
        .{ .x = 0.0, .y = 1.0, .z = 6.0 },
        vec3.zero(),
        vec3.up(),
    );
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            -0.5, -0.5, -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, -0.5, 0.5,  -0.5,
            -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  0.5,  0.5,  -0.5, 0.5,  0.5,
            -0.5, -0.5, -0.5, -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, -0.5, 0.5,
            0.5,  -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  0.5,  0.5,  -0.5, 0.5,
            -0.5, -0.5, -0.5, -0.5, -0.5, 0.5,  0.5,  -0.5, 0.5,  0.5,  -0.5, -0.5,
            -0.5, 0.5,  -0.5, -0.5, 0.5,  0.5,  0.5,  0.5,  0.5,  0.5,  0.5,  -0.5,
        }),
    });
    state.bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&[_]u16{
            0,  1,  2,  0,  2,  3,
            6,  5,  4,  7,  6,  4,
            8,  9,  10, 8,  10, 11,
            14, 13, 12, 15, 14, 12,
            16, 17, 18, 16, 18, 19,
            22, 21, 20, 23, 22, 20,
        }),
    });

    state.object_pipeline = makePipeline(
        sg.makeShader(shd.objectShaderDesc(sg.queryBackend())),
        shd.ATTR_object_position,
    );
    state.lamp_pipeline = makePipeline(
        sg.makeShader(shd.lampShaderDesc(sg.queryBackend())),
        shd.ATTR_lamp_position,
    );

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };
}

fn makePipeline(shader: sg.Shader, position_attribute: u32) sg.Pipeline {
    return sg.makePipeline(.{
        .shader = shader,
        .layout = layout: {
            var value: sg.VertexLayoutState = .{};
            value.attrs[position_attribute].format = .FLOAT3;
            break :layout value;
        },
        .index_type = .UINT16,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
    });
}

export fn frame() void {
    const aspect = sapp.widthf() / sapp.heightf();
    const projection = mat4.persp(45.0, aspect, 0.1, 100.0);
    const view_projection = mat4.mul(projection, state.view);

    const object_vs_params = shd.VsParams{
        .mvp = mat4.mul(view_projection, mat4.identity()),
    };
    const object_fs_params = shd.ObjectFsParams{
        .object_color = .{ 1.0, 0.5, 0.31, 1.0 },
        .light_color = .{ 1.0, 1.0, 1.0, 1.0 },
    };

    const lamp_model = mat4.mul(
        mat4.translate(state.light_position),
        uniformScale(0.2),
    );
    const lamp_vs_params = shd.VsParams{
        .mvp = mat4.mul(view_projection, lamp_model),
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.object_pipeline);
    sg.applyBindings(state.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&object_vs_params));
    sg.applyUniforms(shd.UB_object_fs_params, sg.asRange(&object_fs_params));
    sg.draw(0, 36, 1);

    sg.applyPipeline(state.lamp_pipeline);
    sg.applyBindings(state.bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&lamp_vs_params));
    sg.draw(0, 36, 1);

    sg.endPass();
    sg.commit();
}

fn uniformScale(amount: f32) mat4 {
    var result = mat4.identity();
    result.m[0][0] = amount;
    result.m[1][1] = amount;
    result.m[2][2] = amount;
    return result;
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "LearnOpenGL Colors — Sokol + Zig",
        .logger = .{ .func = slog.func },
    });
}
