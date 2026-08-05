//------------------------------------------------------------------------------
// LearnOpenGL: Lighting / Materials
//
// A material describes how a surface reflects ambient, diffuse, and specular
// light. The light independently describes how strongly it emits each part.
//------------------------------------------------------------------------------
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;
const shd = @import("generated/materials_shader.zig");

const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
};

const state = struct {
    var bind: sg.Bindings = .{};
    var object_pipeline: sg.Pipeline = .{};
    var lamp_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};

    const light_position = vec3{ .x = 1.2, .y = 1.0, .z = 2.0 };
    const camera_position = vec3{ .x = 0.0, .y = 1.0, .z = 6.0 };
    const view = mat4.lookat(camera_position, vec3.zero(), vec3.up());
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // The position/normal mesh is the same shape used by basic_lighting.zig.
    // Corners are repeated because each cube face needs a different normal.
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]Vertex{
            // zig fmt: off
            // -Z face
            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{  0.0,  0.0, -1.0 } },
            .{ .position = .{  0.5, -0.5, -0.5 }, .normal = .{  0.0,  0.0, -1.0 } },
            .{ .position = .{  0.5,  0.5, -0.5 }, .normal = .{  0.0,  0.0, -1.0 } },
            .{ .position = .{ -0.5,  0.5, -0.5 }, .normal = .{  0.0,  0.0, -1.0 } },
            // +Z face
            .{ .position = .{ -0.5, -0.5,  0.5 }, .normal = .{  0.0,  0.0,  1.0 } },
            .{ .position = .{  0.5, -0.5,  0.5 }, .normal = .{  0.0,  0.0,  1.0 } },
            .{ .position = .{  0.5,  0.5,  0.5 }, .normal = .{  0.0,  0.0,  1.0 } },
            .{ .position = .{ -0.5,  0.5,  0.5 }, .normal = .{  0.0,  0.0,  1.0 } },
            // -X face
            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ -1.0,  0.0,  0.0 } },
            .{ .position = .{ -0.5,  0.5, -0.5 }, .normal = .{ -1.0,  0.0,  0.0 } },
            .{ .position = .{ -0.5,  0.5,  0.5 }, .normal = .{ -1.0,  0.0,  0.0 } },
            .{ .position = .{ -0.5, -0.5,  0.5 }, .normal = .{ -1.0,  0.0,  0.0 } },
            // +X face
            .{ .position = .{  0.5, -0.5, -0.5 }, .normal = .{  1.0,  0.0,  0.0 } },
            .{ .position = .{  0.5,  0.5, -0.5 }, .normal = .{  1.0,  0.0,  0.0 } },
            .{ .position = .{  0.5,  0.5,  0.5 }, .normal = .{  1.0,  0.0,  0.0 } },
            .{ .position = .{  0.5, -0.5,  0.5 }, .normal = .{  1.0,  0.0,  0.0 } },
            // -Y face
            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{  0.0, -1.0,  0.0 } },
            .{ .position = .{ -0.5, -0.5,  0.5 }, .normal = .{  0.0, -1.0,  0.0 } },
            .{ .position = .{  0.5, -0.5,  0.5 }, .normal = .{  0.0, -1.0,  0.0 } },
            .{ .position = .{  0.5, -0.5, -0.5 }, .normal = .{  0.0, -1.0,  0.0 } },
            // +Y face
            .{ .position = .{ -0.5,  0.5, -0.5 }, .normal = .{  0.0,  1.0,  0.0 } },
            .{ .position = .{ -0.5,  0.5,  0.5 }, .normal = .{  0.0,  1.0,  0.0 } },
            .{ .position = .{  0.5,  0.5,  0.5 }, .normal = .{  0.0,  1.0,  0.0 } },
            .{ .position = .{  0.5,  0.5, -0.5 }, .normal = .{  0.0,  1.0,  0.0 } },
            // zig fmt: on
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

    state.object_pipeline = makeObjectPipeline();
    state.lamp_pipeline = makeLampPipeline();
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };
}

fn commonPipelineDesc(shader: sg.Shader) sg.PipelineDesc {
    return .{
        .shader = shader,
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .BACK,
    };
}

fn makeObjectPipeline() sg.Pipeline {
    var desc = commonPipelineDesc(sg.makeShader(shd.objectShaderDesc(sg.queryBackend())));
    desc.layout.buffers[0].stride = @sizeOf(Vertex);
    desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_object_normal0].format = .FLOAT3;
    return sg.makePipeline(desc);
}

fn makeLampPipeline() sg.Pipeline {
    var desc = commonPipelineDesc(sg.makeShader(shd.lampShaderDesc(sg.queryBackend())));
    desc.layout.buffers[0].stride = @sizeOf(Vertex);
    desc.layout.attrs[shd.ATTR_lamp_position].format = .FLOAT3;
    return sg.makePipeline(desc);
}

export fn frame() void {
    const projection = mat4.persp(45.0, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view_projection = mat4.mul(projection, state.view);
    const object_model = mat4.identity();

    const object_vs_params = shd.ObjectVsParams{
        .mvp = mat4.mul(view_projection, object_model),
        .model = object_model,
    };

    // These values match the chapter's final material and light setup.
    const materials_fs_params = shd.MaterialsFsParams{
        // The coral surface reflects ambient and diffuse light in its body color.
        .material_ambient = .{ 1.0, 0.5, 0.31, 1.0 },
        .material_diffuse = .{ 1.0, 0.5, 0.31, 1.0 },
        // Its shiny reflection is neutral gray rather than coral.
        .material_specular = .{ 0.5, 0.5, 0.5, 1.0 },
        .material_properties = .{ 32.0, 0.0, 0.0, 0.0 },

        .light_position = .{ state.light_position.x, state.light_position.y, state.light_position.z, 1.0 },
        // Ambient is deliberately weak, diffuse is half-strength, and specular
        // remains full-strength so highlights can still appear bright.
        .light_ambient = .{ 0.2, 0.2, 0.2, 1.0 },
        .light_diffuse = .{ 0.5, 0.5, 0.5, 1.0 },
        .light_specular = .{ 1.0, 1.0, 1.0, 1.0 },
        .view_position = .{ state.camera_position.x, state.camera_position.y, state.camera_position.z, 1.0 },
    };

    const lamp_model = mat4.mul(mat4.translate(state.light_position), uniformScale(0.2));
    const lamp_vs_params = shd.LampVsParams{
        .mvp = mat4.mul(view_projection, lamp_model),
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    sg.applyPipeline(state.object_pipeline);
    sg.applyBindings(state.bind);
    sg.applyUniforms(shd.UB_object_vs_params, sg.asRange(&object_vs_params));
    sg.applyUniforms(shd.UB_materials_fs_params, sg.asRange(&materials_fs_params));
    sg.draw(0, 36, 1);

    sg.applyPipeline(state.lamp_pipeline);
    sg.applyBindings(state.bind);
    sg.applyUniforms(shd.UB_lamp_vs_params, sg.asRange(&lamp_vs_params));
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
        .window_title = "LearnOpenGL Materials — Sokol + Zig",
        .logger = .{ .func = slog.func },
    });
}
