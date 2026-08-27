const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;
const shd = @import("generated/light_casters_shader.zig");

pub const Scene = enum {
    directional,
    point,
    spotlight,
};

const texture_width = 500;
const texture_height = 500;
const texture_byte_count = texture_width * texture_height * 4;
const diffuse_pixels = @embedFile("assets/lighting_maps/container2.rgba");
const specular_pixels = @embedFile("assets/lighting_maps/container2_specular.rgba");

comptime {
    std.debug.assert(diffuse_pixels.len == texture_byte_count);
    std.debug.assert(specular_pixels.len == texture_byte_count);
}

const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
    uv: [2]f32,
};

const state = struct {
    var bind: sg.Bindings = .{};
    var pipeline: sg.Pipeline = .{};
    var lamp_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};

    const cube_positions = [_]vec3{
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .{ .x = 2.0, .y = 5.0, .z = -15.0 },
        .{ .x = -1.5, .y = -2.2, .z = -2.5 },
        .{ .x = -3.8, .y = -2.0, .z = -12.3 },
        .{ .x = 2.4, .y = -0.4, .z = -3.5 },
        .{ .x = -1.7, .y = 3.0, .z = -7.5 },
        .{ .x = 1.3, .y = -2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 0.2, .z = -1.5 },
        .{ .x = -1.3, .y = 1.0, .z = -1.5 },
    };
};

pub fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]Vertex{
            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ 0.0, 0.0, -1.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 0.0, 0.0, -1.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 0.0, 0.0, -1.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ 0.0, 0.0, -1.0 }, .uv = .{ 0.0, 1.0 } },

            .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ 0.0, 0.0, 1.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 0.0, 0.0, 1.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 0.0, 0.0, 1.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ 0.0, 0.0, 1.0 }, .uv = .{ 0.0, 1.0 } },

            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ -1.0, 0.0, 0.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ -1.0, 0.0, 0.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ -1.0, 0.0, 0.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ -1.0, 0.0, 0.0 }, .uv = .{ 0.0, 1.0 } },

            .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 1.0, 0.0, 0.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 1.0, 0.0, 0.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 1.0, 0.0, 0.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 1.0, 0.0, 0.0 }, .uv = .{ 0.0, 1.0 } },

            .{ .position = .{ -0.5, -0.5, -0.5 }, .normal = .{ 0.0, -1.0, 0.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ -0.5, -0.5, 0.5 }, .normal = .{ 0.0, -1.0, 0.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ 0.5, -0.5, 0.5 }, .normal = .{ 0.0, -1.0, 0.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ 0.5, -0.5, -0.5 }, .normal = .{ 0.0, -1.0, 0.0 }, .uv = .{ 0.0, 1.0 } },

            .{ .position = .{ -0.5, 0.5, -0.5 }, .normal = .{ 0.0, 1.0, 0.0 }, .uv = .{ 0.0, 0.0 } },
            .{ .position = .{ -0.5, 0.5, 0.5 }, .normal = .{ 0.0, 1.0, 0.0 }, .uv = .{ 1.0, 0.0 } },
            .{ .position = .{ 0.5, 0.5, 0.5 }, .normal = .{ 0.0, 1.0, 0.0 }, .uv = .{ 1.0, 1.0 } },
            .{ .position = .{ 0.5, 0.5, -0.5 }, .normal = .{ 0.0, 1.0, 0.0 }, .uv = .{ 0.0, 1.0 } },
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

    state.bind.views[shd.VIEW_diffuse_texture] = makeTextureView(diffuse_pixels);
    state.bind.views[shd.VIEW_specular_texture] = makeTextureView(specular_pixels);
    state.bind.samplers[shd.SMP_texture_sampler] = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .REPEAT,
        .wrap_v = .REPEAT,
    });

    var pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.objectShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .BACK,
    };
    pipeline_desc.layout.buffers[0].stride = @sizeOf(Vertex);
    pipeline_desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
    pipeline_desc.layout.attrs[shd.ATTR_object_normal0].format = .FLOAT3;
    pipeline_desc.layout.attrs[shd.ATTR_object_texcoord0].format = .FLOAT2;
    state.pipeline = sg.makePipeline(pipeline_desc);

    var lamp_pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.lampShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .BACK,
    };
    lamp_pipeline_desc.layout.buffers[0].stride = @sizeOf(Vertex);
    lamp_pipeline_desc.layout.attrs[shd.ATTR_lamp_position].format = .FLOAT3;
    state.lamp_pipeline = sg.makePipeline(lamp_pipeline_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };
}

fn makeTextureView(pixels: []const u8) sg.View {
    return sg.makeView(.{
        .texture = .{
            .image = sg.makeImage(.{
                .width = texture_width,
                .height = texture_height,
                .pixel_format = .RGBA8,
                .data = data: {
                    var image_data: sg.ImageData = .{};
                    image_data.mip_levels[0] = sg.asRange(pixels);
                    break :data image_data;
                },
            }),
        },
    });
}

pub fn frame(comptime scene: Scene) void {
    const aspect = sapp.widthf() / sapp.heightf();

    const camera = cameraForScene(scene);
    const projection = mat4.persp(58.1, aspect, 0.1, 100.0);
    const view = mat4.lookat(camera.position, camera.target, vec3.up());
    const view_projection = mat4.mul(projection, view);

    const light_position = switch (scene) {
        .directional => vec3.zero(),
        .point => vec3{ .x = 1.2, .y = 1.0, .z = 2.0 },
        .spotlight => camera.position,
    };
    const light_direction = switch (scene) {
        .directional => vec3{ .x = -0.2, .y = -1.0, .z = -0.3 },
        .point => vec3.zero(),
        .spotlight => vec3.norm(vec3.sub(camera.target, camera.position)),
    };
    const scene_number: f32 = switch (scene) {
        .directional => 0.0,
        .point => 1.0,
        .spotlight => 2.0,
    };

    const lighting_fs_params = shd.LightingFsParams{
        .material_properties = .{ 32.0, 0.0, 0.0, 0.0 },
        .light_position = .{ light_position.x, light_position.y, light_position.z, 1.0 },
        .light_direction = .{ light_direction.x, light_direction.y, light_direction.z, 0.0 },
        .light_ambient = .{ 0.1, 0.1, 0.1, 1.0 },
        .light_diffuse = .{ 0.8, 0.8, 0.8, 1.0 },
        .light_specular = .{ 1.0, 1.0, 1.0, 1.0 },
        .attenuation_terms = .{ 1.0, 0.09, 0.032, 0.0 },
        .spotlight_cutoffs = .{
            @cos(std.math.degreesToRadians(12.5)),
            @cos(std.math.degreesToRadians(17.5)),
            0.0,
            0.0,
        },
        .view_position = .{ camera.position.x, camera.position.y, camera.position.z, 1.0 },
        .light_type = .{ scene_number, 0.0, 0.0, 0.0 },
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pipeline);
    sg.applyBindings(state.bind);

    sg.applyUniforms(shd.UB_lighting_fs_params, sg.asRange(&lighting_fs_params));

    for (state.cube_positions, 0..) |position, index| {
        const angle_degrees = 20.0 * @as(f32, @floatFromInt(index));
        const rotation = mat4.rotate(angle_degrees, .{ .x = 1.0, .y = 0.3, .z = 0.5 });
        const model = mat4.mul(mat4.translate(position), rotation);
        const object_vs_params = shd.ObjectVsParams{
            .mvp = mat4.mul(view_projection, model),
            .model = model,
        };

        sg.applyUniforms(shd.UB_object_vs_params, sg.asRange(&object_vs_params));
        sg.draw(0, 36, 1);
    }

    if (scene == .point) {
        const lamp_model = mat4.mul(mat4.translate(light_position), uniformScale(0.2));
        const lamp_vs_params = shd.LampVsParams{
            .mvp = mat4.mul(view_projection, lamp_model),
        };
        sg.applyPipeline(state.lamp_pipeline);
        sg.applyBindings(state.bind);
        sg.applyUniforms(shd.UB_lamp_vs_params, sg.asRange(&lamp_vs_params));
        sg.draw(0, 36, 1);
    }

    sg.endPass();
    sg.commit();
}

const Camera = struct {
    position: vec3,
    target: vec3,
};

fn cameraForScene(comptime scene: Scene) Camera {
    return switch (scene) {
        .directional => .{
            .position = .{ .x = 0.0, .y = 0.0, .z = 6.0 },
            .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        },

        .point => .{
            .position = .{ .x = -1.7, .y = 1.0, .z = 9.0 },
            .target = .{ .x = 0.0, .y = 0.0, .z = -3.0 },
        },

        .spotlight => .{
            .position = .{ .x = -0.35, .y = 0.15, .z = 2.55 },
            .target = .{ .x = 0.85, .y = -0.15, .z = 0.0 },
        },
    };
}

fn uniformScale(amount: f32) mat4 {
    var result = mat4.identity();
    result.m[0][0] = amount;
    result.m[1][1] = amount;
    result.m[2][2] = amount;
    return result;
}

pub fn cleanup() void {
    sg.shutdown();
}
