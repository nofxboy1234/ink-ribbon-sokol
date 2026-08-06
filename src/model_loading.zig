//------------------------------------------------------------------------------
// LearnOpenGL Model Loading, using the same architecture as cgltf-sapp.c:
//
//   sokol.fetch loads files -> cgltf parses the glTF scene description
//   -> the loader creates Sokol buffers, textures, bindings and draw data.
//
// Sokol deliberately does not prescribe a model format. cgltf is the small,
// idiomatic companion library used by the upstream Sokol C sample for glTF.
//------------------------------------------------------------------------------
const std = @import("std");
const builtin = @import("builtin");
const cgltf = @import("cgltf");
const model_image = @import("model_image");
const sokol = @import("sokol");
const sapp = sokol.app;
const sfetch = sokol.fetch;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/model_loading_shader.zig");

const max_gltf_bytes = 16 * 1024;
const max_vertex_bytes = 7 * 1024 * 1024;
const max_encoded_texture_bytes = 1024 * 1024;
const asset_prefix = if (builtin.target.os.tag == .emscripten) "" else "src/assets/backpack/";

const LoadBits = packed struct(u8) {
    vertices: bool = false,
    diffuse: bool = false,
    specular: bool = false,
    _padding: u5 = 0,
};

const state = struct {
    var gltf_bytes: [max_gltf_bytes]u8 = undefined;
    var vertex_bytes: [max_vertex_bytes]u8 = undefined;
    var diffuse_bytes: [max_encoded_texture_bytes]u8 = undefined;
    var specular_bytes: [max_encoded_texture_bytes]u8 = undefined;

    var gltf: [*c]cgltf.cgltf_data = null;
    var bindings: sg.Bindings = .{};
    var pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var loaded: LoadBits = .{};
    var vertex_count: u32 = 0;
    var failed = false;
};

fn fetchRange(bytes: []u8) sfetch.Range {
    return .{ .ptr = bytes.ptr, .size = bytes.len };
}

fn gfxRange(range: sfetch.Range) sg.Range {
    return .{ .ptr = range.ptr, .size = range.size };
}

fn assetPath(buffer: []u8, uri: [*c]const u8) ![:0]u8 {
    return std.fmt.bufPrintSentinel(buffer, "{s}{s}", .{ asset_prefix, std.mem.span(uri) }, 0);
}

fn sendAsset(uri: [*c]const u8, callback: *const fn ([*c]const sfetch.Response) callconv(.c) void, buffer: []u8) void {
    var path_buffer: [256]u8 = undefined;
    const path = assetPath(&path_buffer, uri) catch {
        state.failed = true;
        return;
    };
    _ = sfetch.send(.{ .path = path.ptr, .callback = callback, .buffer = fetchRange(buffer) });
}

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
    sfetch.setup(.{ .num_channels = 1, .num_lanes = 4, .logger = .{ .func = slog.func } });

    var pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.modelShaderDesc(sg.queryBackend())),
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .NONE,
    };
    pipeline_desc.layout.buffers[0].stride = 8 * @sizeOf(f32);
    pipeline_desc.layout.attrs[shd.ATTR_model_position].format = .FLOAT3;
    pipeline_desc.layout.attrs[shd.ATTR_model_normal0].format = .FLOAT3;
    pipeline_desc.layout.attrs[shd.ATTR_model_texcoord0].format = .FLOAT2;
    state.pipeline = sg.makePipeline(pipeline_desc);
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };

    const model_path = asset_prefix ++ "backpack.gltf";
    _ = sfetch.send(.{
        .path = model_path,
        .callback = gltfFetched,
        .buffer = fetchRange(&state.gltf_bytes),
    });
}

fn gltfFetched(response_ptr: [*c]const sfetch.Response) callconv(.c) void {
    const response = response_ptr.*;
    if (response.fetched) parseGltf(response.data);
    if (response.failed) state.failed = true;
}

fn parseGltf(file: sfetch.Range) void {
    var options: cgltf.cgltf_options = .{};
    if (cgltf.cgltf_parse(&options, file.ptr, file.size, &state.gltf) != cgltf.cgltf_result_success) {
        state.failed = true;
        return;
    }
    const data = state.gltf.*;
    if (data.meshes_count == 0 or data.buffers_count == 0 or data.materials_count == 0) {
        state.failed = true;
        return;
    }

    const primitive = data.meshes[0].primitives[0];
    if (primitive.type != cgltf.cgltf_primitive_type_triangles or primitive.attributes_count < 3) {
        state.failed = true;
        return;
    }
    for (primitive.attributes[0..primitive.attributes_count]) |attribute| {
        if (attribute.type == cgltf.cgltf_attribute_type_position) {
            state.vertex_count = @intCast(attribute.data.*.count);
            break;
        }
    }
    if (state.vertex_count == 0) {
        state.failed = true;
        return;
    }

    // The glTF document, rather than Zig source code, selects the buffer and
    // material images. This is the key architectural change from @embedFile.
    sendAsset(data.buffers[0].uri, vertexBufferFetched, &state.vertex_bytes);
    const material = primitive.material.*;
    sendAsset(
        material.pbr_metallic_roughness.base_color_texture.texture.*.image.*.uri,
        diffuseTextureFetched,
        &state.diffuse_bytes,
    );
    sendAsset(
        material.specular.specular_texture.texture.*.image.*.uri,
        specularTextureFetched,
        &state.specular_bytes,
    );
}

fn vertexBufferFetched(response_ptr: [*c]const sfetch.Response) callconv(.c) void {
    const response = response_ptr.*;
    if (response.fetched) {
        state.bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = gfxRange(response.data) });
        state.loaded.vertices = true;
    }
    if (response.failed) state.failed = true;
}

fn makeTextureView(encoded: sfetch.Range) ?sg.View {
    var width: c_int = 0;
    var height: c_int = 0;
    const pixels = model_image.model_image_decode_rgba(
        @ptrCast(encoded.ptr),
        encoded.size,
        &width,
        &height,
    );
    if (pixels == null or width <= 0 or height <= 0) return null;
    defer model_image.model_image_free(pixels);

    var image_data: sg.ImageData = .{};
    image_data.mip_levels[0] = .{
        .ptr = pixels,
        .size = @intCast(width * height * 4),
    };
    return sg.makeView(.{ .texture = .{ .image = sg.makeImage(.{
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        .data = image_data,
    }) } });
}

fn ensureSampler() void {
    if (state.bindings.samplers[shd.SMP_texture_sampler].id == 0) {
        state.bindings.samplers[shd.SMP_texture_sampler] = sg.makeSampler(.{
            .min_filter = .LINEAR,
            .mag_filter = .LINEAR,
            .wrap_u = .REPEAT,
            .wrap_v = .REPEAT,
        });
    }
}

fn diffuseTextureFetched(response_ptr: [*c]const sfetch.Response) callconv(.c) void {
    const response = response_ptr.*;
    if (response.fetched) {
        ensureSampler();
        if (makeTextureView(response.data)) |view| {
            state.bindings.views[shd.VIEW_diffuse_texture] = view;
            state.loaded.diffuse = true;
        } else state.failed = true;
    }
    if (response.failed) state.failed = true;
}

fn specularTextureFetched(response_ptr: [*c]const sfetch.Response) callconv(.c) void {
    const response = response_ptr.*;
    if (response.fetched) {
        ensureSampler();
        if (makeTextureView(response.data)) |view| {
            state.bindings.views[shd.VIEW_specular_texture] = view;
            state.loaded.specular = true;
        } else state.failed = true;
    }
    if (response.failed) state.failed = true;
}

fn modelReady() bool {
    return state.loaded.vertices and state.loaded.diffuse and state.loaded.specular;
}

export fn frame() void {
    sfetch.dowork();
    var pass_action = state.pass_action;
    if (state.failed) {
        // Match cgltf-sapp.c's unmistakable visual signal for loading errors.
        pass_action.colors[0].clear_value = .{ .r = 0.35, .g = 0, .b = 0, .a = 1 };
    }
    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
    if (modelReady() and !state.failed) drawScene();
    sg.endPass();
    sg.commit();
}

fn drawScene() void {
    const camera_position = Vec3{ .x = 0, .y = 0.6, .z = 8.5 };
    const view = Mat4.lookat(camera_position, .{ .x = 0, .y = 0.5, .z = -0.5 }, Vec3.up());
    const projection = Mat4.persp(58.1, sapp.widthf() / sapp.heightf(), 0.1, 100);
    const view_projection = Mat4.mul(projection, view);

    sg.applyPipeline(state.pipeline);
    sg.applyBindings(state.bindings);
    const objects = [_]struct { x: f32, angle: f32, light: [4]f32 }{
        .{ .x = -2.25, .angle = 18, .light = .{ -3, 4, 4, 1 } },
        .{ .x = 2.25, .angle = 145, .light = .{ 3, 4, -4, 1 } },
    };
    for (objects) |object| {
        const model = Mat4.mul(
            Mat4.translate(.{ .x = object.x, .y = 0.18, .z = 0 }),
            Mat4.mul(
                Mat4.rotate(object.angle, .{ .x = 0, .y = 1, .z = 0 }),
                Mat4.translate(.{ .x = 0.05, .y = -0.57, .z = 0.94 }),
            ),
        );
        const vs_params = shd.VsParams{ .mvp = Mat4.mul(view_projection, model), .model = model };
        const fs_params = shd.FsParams{
            .light_position = object.light,
            .view_position = .{ camera_position.x, camera_position.y, camera_position.z, 1 },
        };
        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));
        sg.applyUniforms(shd.UB_fs_params, sg.asRange(&fs_params));
        sg.draw(0, state.vertex_count, 1);
    }
}

export fn cleanup() void {
    if (state.gltf != null) cgltf.cgltf_free(state.gltf);
    sfetch.shutdown();
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
        .window_title = "LearnOpenGL Model Loading — cgltf + Sokol + Zig",
        .logger = .{ .func = slog.func },
    });
}
