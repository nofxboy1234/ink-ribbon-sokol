const sokol = @import("sokol");

const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const sdtx = sokol.debugtext;

const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;

const shd = @import("generated/cube_shader.zig");

const state = struct {
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;

    var pip: sg.Pipeline = .{};

    var cube_bind: sg.Bindings = .{};
    var pyramid_bind: sg.Bindings = .{};

    var pass_action: sg.PassAction = .{};

    const view: mat4 = mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, vec3.zero(), vec3.up());
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    sdtx.setup(.{
        .fonts = init: {
            var f: [8]sdtx.FontDesc = @splat(.{});
            f[0] = sdtx.fontKc853();
            break :init f;
        },
        .logger = .{ .func = slog.func },
    });

    state.cube_bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
            -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 1.0, 0.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 1.0, 0.0, 1.0,

            -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, 1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            -1.0, -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,

            1.0,  -1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
            1.0,  1.0,  -1.0, 1.0, 0.5, 0.0, 1.0,
            1.0,  1.0,  1.0,  1.0, 0.5, 0.0, 1.0,
            1.0,  -1.0, 1.0,  1.0, 0.5, 0.0, 1.0,

            -1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,
            -1.0, -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,

            -1.0, 1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
            -1.0, 1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
            1.0,  1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
            1.0,  1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
        }),
    });

    state.cube_bind.index_buffer = sg.makeBuffer(.{
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

    state.pyramid_bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 1.0, 0.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,
            -1.0, -1.0, 1.0,  1.0, 0.5, 0.0, 1.0,
            0.0,  1.0,  0.0,  1.0, 0.0, 1.0, 1.0,
        }),
    });
    state.pyramid_bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&[_]u16{
            0, 3, 2, 0, 2, 1,
            0, 1, 4, 1, 2, 4,
            2, 3, 4, 3, 0, 4,
        }),
    });

    state.pip = sg.makePipeline(.{
        .shader = sg.makeShader(shd.cubeShaderDesc(sg.queryBackend())),

        .layout = init: {
            var l = sg.VertexLayoutState{};

            l.attrs[shd.ATTR_cube_position].format = .FLOAT3;

            l.attrs[shd.ATTR_cube_color0].format = .FLOAT4;
            break :init l;
        },

        .index_type = .UINT16,

        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },

        .cull_mode = .BACK,

        .color_count = 1,
        .colors = init: {
            var clrs: [8]sg.ColorTargetState = @splat(.{});

            clrs[0].blend = .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
            };
            break :init clrs;
        },
    });

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.5, .b = 0.75, .a = 1 },
    };
}

export fn frame() void {
    const frame_dt = sapp.frameDuration();
    const dt: f32 = @floatCast(frame_dt * 60);

    const fps: f64 = if (frame_dt > 0) 1.0 / frame_dt else 0;

    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(1, 1);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:.1}\nFrame: {d:.3}ms", .{ fps, frame_dt * 1000 });

    state.rx += 1.0 * dt;
    state.ry += 2.0 * dt;

    const first_cube_vs_params = computeVsParams(state.rx, state.ry, vec3.zero());
    const right_cube_vs_params = computeVsParams(
        state.rx,
        state.ry,
        .{ .x = 2.5, .y = 0.0, .z = 0.0 },
    );
    const pyramid_vs_params = computeVsParams(
        state.rx,
        state.ry,
        .{ .x = -2.5, .y = 0.0, .z = 0.0 },
    );

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.pip);

    sg.applyBindings(state.cube_bind);

    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&first_cube_vs_params));

    sg.draw(0, 36, 1);

    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&right_cube_vs_params));
    sg.draw(0, 36, 1);

    sg.applyBindings(state.pyramid_bind);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&pyramid_vs_params));
    sg.draw(0, 18, 1);

    sdtx.draw();

    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sdtx.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,

        .fullscreen = true,

        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "ink-ribbon-sokol",
        .logger = .{ .func = slog.func },
    });
}

fn computeVsParams(rx: f32, ry: f32, position: vec3) shd.VsParams {
    const rxm = mat4.rotate(rx, .{ .x = 1.0, .y = 0.0, .z = 0.0 });

    const rym = mat4.rotate(ry, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    const rotation = mat4.mul(rxm, rym);
    const translation = mat4.translate(position);
    const model = mat4.mul(translation, rotation);

    const aspect = sapp.widthf() / sapp.heightf();

    const proj = mat4.persp(60.0, aspect, 0.01, 10.0);

    return shd.VsParams{ .mvp = mat4.mul(mat4.mul(proj, state.view), model) };
}
