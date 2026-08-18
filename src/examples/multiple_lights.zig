//------------------------------------------------------------------------------
// LearnOpenGL: Lighting / Multiple lights
//
// The earlier lessons calculated one light. This lesson sends six lights to
// one fragment shader: one directional light, four point lights, and the
// camera's spotlight. The shader calculates each contribution separately and
// adds them together.
//------------------------------------------------------------------------------
const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;
const shd = @import("generated/multiple_lights_shader.zig");

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
    var object_pipeline: sg.Pipeline = .{};
    var lamp_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};

    // Static approximation of the movable camera used for the chapter's final
    // screenshot. Its position/direction also define the flashlight.
    const camera_position = vec3{ .x = -0.35, .y = 0.15, .z = 2.9 };
    const camera_target = vec3{ .x = 0.75, .y = -0.15, .z = 0.0 };

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

    // This array is new in the Multiple Lights chapter. Its four elements are
    // uploaded together, used by the shader loop, and drawn as white markers.
    const point_light_positions = [_]vec3{
        .{ .x = 0.7, .y = 0.2, .z = 2.0 },
        .{ .x = 2.3, .y = -3.3, .z = -4.0 },
        .{ .x = -4.0, .y = 2.0, .z = -12.0 },
        .{ .x = 0.0, .y = 0.0, .z = -3.0 },
    };
};

fn cubeVertices() [24]Vertex {
    const positions = [6][4][3]f32{
        .{ .{ -0.5, -0.5, -0.5 }, .{ 0.5, -0.5, -0.5 }, .{ 0.5, 0.5, -0.5 }, .{ -0.5, 0.5, -0.5 } },
        .{ .{ -0.5, -0.5, 0.5 }, .{ 0.5, -0.5, 0.5 }, .{ 0.5, 0.5, 0.5 }, .{ -0.5, 0.5, 0.5 } },
        .{ .{ -0.5, -0.5, -0.5 }, .{ -0.5, 0.5, -0.5 }, .{ -0.5, 0.5, 0.5 }, .{ -0.5, -0.5, 0.5 } },
        .{ .{ 0.5, -0.5, -0.5 }, .{ 0.5, 0.5, -0.5 }, .{ 0.5, 0.5, 0.5 }, .{ 0.5, -0.5, 0.5 } },
        .{ .{ -0.5, -0.5, -0.5 }, .{ -0.5, -0.5, 0.5 }, .{ 0.5, -0.5, 0.5 }, .{ 0.5, -0.5, -0.5 } },
        .{ .{ -0.5, 0.5, -0.5 }, .{ -0.5, 0.5, 0.5 }, .{ 0.5, 0.5, 0.5 }, .{ 0.5, 0.5, -0.5 } },
    };
    const normals = [6][3]f32{
        .{ 0, 0, -1 }, .{ 0, 0, 1 },  .{ -1, 0, 0 },
        .{ 1, 0, 0 },  .{ 0, -1, 0 }, .{ 0, 1, 0 },
    };
    const uvs = [4][2]f32{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } };

    var result: [24]Vertex = undefined;
    for (0..6) |face| {
        for (0..4) |corner| {
            result[face * 4 + corner] = .{
                .position = positions[face][corner],
                .normal = normals[face],
                .uv = uvs[corner],
            };
        }
    }
    return result;
}

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    const vertices = cubeVertices();
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&vertices) });
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

    var object_desc = commonPipelineDesc(sg.makeShader(shd.objectShaderDesc(sg.queryBackend())));
    object_desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
    object_desc.layout.attrs[shd.ATTR_object_normal0].format = .FLOAT3;
    object_desc.layout.attrs[shd.ATTR_object_texcoord0].format = .FLOAT2;
    state.object_pipeline = sg.makePipeline(object_desc);

    var lamp_desc = commonPipelineDesc(sg.makeShader(shd.lampShaderDesc(sg.queryBackend())));
    lamp_desc.layout.attrs[shd.ATTR_lamp_position].format = .FLOAT3;
    state.lamp_pipeline = sg.makePipeline(lamp_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };
}

fn commonPipelineDesc(shader: sg.Shader) sg.PipelineDesc {
    return .{
        .shader = shader,
        .layout = .{ .buffers = layout: {
            var buffers: [sg.max_vertexbuffer_bindslots]sg.VertexBufferLayoutState = @splat(.{});
            buffers[0].stride = @sizeOf(Vertex);
            break :layout buffers;
        } },
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .BACK,
    };
}

fn makeTextureView(pixels: []const u8) sg.View {
    return sg.makeView(.{ .texture = .{ .image = sg.makeImage(.{
        .width = texture_width,
        .height = texture_height,
        .pixel_format = .RGBA8,
        .data = data: {
            var image_data: sg.ImageData = .{};
            image_data.mip_levels[0] = sg.asRange(pixels);
            break :data image_data;
        },
    }) } });
}

export fn frame() void {
    const camera_forward = vec3.norm(vec3.sub(state.camera_target, state.camera_position));
    const view = mat4.lookat(state.camera_position, state.camera_target, vec3.up());
    const projection = mat4.persp(58.1, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view_projection = mat4.mul(projection, view);

    // These values match the chapter's uniforms. A Sokol uniform block uploads
    // them together instead of calling glUniform separately for every field.
    const lighting = shd.LightingFsParams{
        .material_properties = .{ 32.0, 0.0, 0.0, 0.0 },
        .directional_direction = .{ -0.2, -1.0, -0.3, 0.0 },
        .directional_ambient = .{ 0.05, 0.05, 0.05, 1.0 },
        .directional_diffuse = .{ 0.4, 0.4, 0.4, 1.0 },
        .directional_specular = .{ 0.5, 0.5, 0.5, 1.0 },
        .point_positions = pointPositionsForShader(),
        .point_ambient = .{ 0.05, 0.05, 0.05, 1.0 },
        .point_diffuse = .{ 0.8, 0.8, 0.8, 1.0 },
        .point_specular = .{ 1.0, 1.0, 1.0, 1.0 },
        .point_attenuation = .{ 1.0, 0.09, 0.032, 0.0 },
        .spotlight_position = .{ state.camera_position.x, state.camera_position.y, state.camera_position.z, 1.0 },
        .spotlight_direction = .{ camera_forward.x, camera_forward.y, camera_forward.z, 0.0 },
        .spotlight_ambient = .{ 0.0, 0.0, 0.0, 1.0 },
        .spotlight_diffuse = .{ 1.0, 1.0, 1.0, 1.0 },
        .spotlight_specular = .{ 1.0, 1.0, 1.0, 1.0 },
        .spotlight_attenuation = .{ 1.0, 0.09, 0.032, 0.0 },
        .spotlight_cutoffs = .{
            @cos(std.math.degreesToRadians(12.5)),
            @cos(std.math.degreesToRadians(15.0)),
            0.0,
            0.0,
        },
        .view_position = .{ state.camera_position.x, state.camera_position.y, state.camera_position.z, 1.0 },
    };

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.object_pipeline);
    sg.applyBindings(state.bind);
    sg.applyUniforms(shd.UB_lighting_fs_params, sg.asRange(&lighting));

    for (state.cube_positions, 0..) |position, index| {
        const angle = 20.0 * @as(f32, @floatFromInt(index));
        const model = mat4.mul(
            mat4.translate(position),
            mat4.rotate(angle, .{ .x = 1.0, .y = 0.3, .z = 0.5 }),
        );
        const object_params = shd.ObjectVsParams{
            .mvp = mat4.mul(view_projection, model),
            .model = model,
        };
        sg.applyUniforms(shd.UB_object_vs_params, sg.asRange(&object_params));
        sg.draw(0, 36, 1);
    }

    // The four visible white cubes identify the four point-light positions.
    // The directional light has no position, and the spotlight is the camera.
    sg.applyPipeline(state.lamp_pipeline);
    sg.applyBindings(state.bind);
    for (state.point_light_positions) |position| {
        const model = mat4.mul(mat4.translate(position), uniformScale(0.2));
        const lamp_params = shd.LampVsParams{ .mvp = mat4.mul(view_projection, model) };
        sg.applyUniforms(shd.UB_lamp_vs_params, sg.asRange(&lamp_params));
        sg.draw(0, 36, 1);
    }

    sg.endPass();
    sg.commit();
}

fn pointPositionsForShader() [4][4]f32 {
    var result: [4][4]f32 = undefined;
    for (state.point_light_positions, 0..) |position, index| {
        result[index] = .{ position.x, position.y, position.z, 1.0 };
    }
    return result;
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
        .window_title = "LearnOpenGL Multiple Lights — Sokol + Zig",
        .logger = .{ .func = slog.func },
    });
}
