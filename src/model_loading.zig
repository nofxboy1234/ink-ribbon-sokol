//------------------------------------------------------------------------------
// LearnOpenGL: Model Loading / Assimp + Mesh + Model
//
// Sokol is a rendering API, not a model importer. The upstream cgltf-sapp.c
// example pairs Sokol with cgltf. This backpack is Wavefront OBJ, so this
// learning example uses a deliberately small OBJ parser, then converts the
// imported attributes into the same Sokol buffers and bindings a glTF loader
// would create.
//------------------------------------------------------------------------------
const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;
const shd = @import("generated/model_loading_shader.zig");

const vertex_bytes = @embedFile("assets/backpack/vertices.bin");
const diffuse_pixels = @embedFile("assets/backpack/diffuse.rgba");
const specular_pixels = @embedFile("assets/backpack/specular.rgba");
const texture_size = 512;

const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
    uv: [2]f32,
};

const state = struct {
    var bindings: sg.Bindings = .{};
    var pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var vertex_count: u32 = 0;
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // backpack.mtl names one diffuse and one specular texture. They become two
    // Sokol image views plus one shared sampler—the material part of our mesh.
    state.bindings.views[shd.VIEW_diffuse_texture] = makeTextureView(diffuse_pixels);
    state.bindings.views[shd.VIEW_specular_texture] = makeTextureView(specular_pixels);
    state.bindings.samplers[shd.SMP_texture_sampler] = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .REPEAT,
        .wrap_v = .REPEAT,
    });

    // tools/convert_backpack_obj.py has already performed Assimp's conversion
    // job: the OBJ index tuples are expanded into the Mesh chapter's 32-byte
    // interleaved Vertex layout. Runtime loading is therefore one direct,
    // fast upload—even in a browser—instead of reparsing 7 MB of text.
    std.debug.assert(vertex_bytes.len % @sizeOf(Vertex) == 0);
    state.vertex_count = @intCast(vertex_bytes.len / @sizeOf(Vertex));
    state.bindings.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertex_bytes) });

    var desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.modelShaderDesc(sg.queryBackend())),
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        // OBJ files do not mandate the same front-face winding convention as
        // every Sokol backend, so this first importer renders both sides.
        .cull_mode = .NONE,
    };
    desc.layout.buffers[0].stride = @sizeOf(Vertex);
    desc.layout.attrs[shd.ATTR_model_position].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_model_normal0].format = .FLOAT3;
    desc.layout.attrs[shd.ATTR_model_texcoord0].format = .FLOAT2;
    state.pipeline = sg.makePipeline(desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
    };
}

const ObjIndex = struct {
    position: usize,
    uv: usize,
    normal: usize,
};

fn parseObj(allocator: std.mem.Allocator, source: []const u8) ![]Vertex {
    var positions: std.ArrayList([3]f32) = .empty;
    defer positions.deinit(allocator);
    var normals: std.ArrayList([3]f32) = .empty;
    defer normals.deinit(allocator);
    var uvs: std.ArrayList([2]f32) = .empty;
    defer uvs.deinit(allocator);
    var vertices: std.ArrayList(Vertex) = .empty;
    errdefer vertices.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, source, '\n');
    while (lines.next()) |line_untrimmed| {
        const line = std.mem.trim(u8, line_untrimmed, " \r\t");
        if (std.mem.startsWith(u8, line, "v ")) {
            try positions.append(allocator, try parseVec3(line[2..]));
        } else if (std.mem.startsWith(u8, line, "vn ")) {
            try normals.append(allocator, try parseVec3(line[3..]));
        } else if (std.mem.startsWith(u8, line, "vt ")) {
            var values = std.mem.tokenizeAny(u8, line[3..], " \t");
            const u = try std.fmt.parseFloat(f32, values.next() orelse return error.InvalidObj);
            const v = try std.fmt.parseFloat(f32, values.next() orelse return error.InvalidObj);
            try uvs.append(allocator, .{ u, v });
        } else if (std.mem.startsWith(u8, line, "f ")) {
            var face = std.mem.tokenizeAny(u8, line[2..], " \t");
            var corners: [3]ObjIndex = undefined;
            for (0..3) |corner| {
                corners[corner] = try parseObjIndex(face.next() orelse return error.InvalidObj);
            }
            // The archive is already triangulated. Expanding its indexed OBJ
            // references keeps this first loader small and makes one sg.draw
            // sufficient; a production loader would deduplicate these tuples.
            for (corners) |corner| {
                try vertices.append(allocator, .{
                    .position = positions.items[corner.position],
                    .normal = normals.items[corner.normal],
                    .uv = uvs.items[corner.uv],
                });
            }
        }
    }
    return vertices.toOwnedSlice(allocator);
}

fn parseVec3(text: []const u8) ![3]f32 {
    var values = std.mem.tokenizeAny(u8, text, " \t");
    return .{
        try std.fmt.parseFloat(f32, values.next() orelse return error.InvalidObj),
        try std.fmt.parseFloat(f32, values.next() orelse return error.InvalidObj),
        try std.fmt.parseFloat(f32, values.next() orelse return error.InvalidObj),
    };
}

fn parseObjIndex(text: []const u8) !ObjIndex {
    var values = std.mem.splitScalar(u8, text, '/');
    return .{
        .position = (try std.fmt.parseInt(usize, values.next() orelse return error.InvalidObj, 10)) - 1,
        .uv = (try std.fmt.parseInt(usize, values.next() orelse return error.InvalidObj, 10)) - 1,
        .normal = (try std.fmt.parseInt(usize, values.next() orelse return error.InvalidObj, 10)) - 1,
    };
}

fn makeTextureView(pixels: []const u8) sg.View {
    return sg.makeView(.{ .texture = .{ .image = sg.makeImage(.{
        .width = texture_size,
        .height = texture_size,
        .pixel_format = .RGBA8,
        .data = data: {
            var image_data: sg.ImageData = .{};
            image_data.mip_levels[0] = sg.asRange(pixels);
            break :data image_data;
        },
    }) } });
}

export fn frame() void {
    const camera_position = vec3{ .x = 0.0, .y = 0.6, .z = 8.5 };
    const camera_target = vec3{ .x = 0.0, .y = 0.5, .z = -0.5 };
    const view = mat4.lookat(camera_position, camera_target, vec3.up());
    const projection = mat4.persp(58.1, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view_projection = mat4.mul(projection, view);
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pipeline);
    sg.applyBindings(state.bindings);

    // The reference image presents the model twice: an illuminated front view
    // and a darker rear view. Both draws reuse the exact same vertex buffer,
    // textures, sampler, and pipeline; only the model/MVP uniforms change.
    const object_transforms = [_]struct {
        x: f32,
        angle: f32,
        light_position: [4]f32,
    }{
        .{ .x = -2.25, .angle = 18.0, .light_position = .{ -3.0, 4.0, 4.0, 1.0 } },
        // For the rear presentation, the key light remains on the model's
        // front side. The side facing us therefore receives only ambient and
        // grazing light, as it does in the chapter's final comparison image.
        .{ .x = 2.25, .angle = 145.0, .light_position = .{ 3.0, 4.0, -4.0, 1.0 } },
    };
    for (object_transforms) |object| {
        const model = mat4.mul(
            mat4.translate(.{ .x = object.x, .y = 0.18, .z = 0.0 }),
            mat4.mul(
                mat4.rotate(object.angle, .{ .x = 0.0, .y = 1.0, .z = 0.0 }),
                // Center the imported OBJ bounds around its local origin.
                mat4.translate(.{ .x = 0.05, .y = -0.57, .z = 0.94 }),
            ),
        );
        const vs_params = shd.VsParams{
            .mvp = mat4.mul(view_projection, model),
            .model = model,
        };
        const fs_params = shd.FsParams{
            .light_position = object.light_position,
            .view_position = .{ camera_position.x, camera_position.y, camera_position.z, 1.0 },
        };
        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));
        sg.applyUniforms(shd.UB_fs_params, sg.asRange(&fs_params));
        sg.draw(0, state.vertex_count, 1);
    }
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
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "LearnOpenGL Model Loading — Sokol + Zig",
        .logger = .{ .func = slog.func },
    });
}

test "OBJ parser converts position/UV/normal indices into vertices" {
    const tiny_obj =
        \\v 0 0 0
        \\v 1 0 0
        \\v 0 1 0
        \\vt 0 0
        \\vt 1 0
        \\vt 0 1
        \\vn 0 0 1
        \\f 1/1/1 2/2/1 3/3/1
    ;
    const vertices = try parseObj(std.testing.allocator, tiny_obj);
    defer std.testing.allocator.free(vertices);
    try std.testing.expectEqual(@as(usize, 3), vertices.len);
    try std.testing.expectEqual([3]f32{ 1.0, 0.0, 0.0 }, vertices[1].position);
    try std.testing.expectEqual([2]f32{ 0.0, 1.0 }, vertices[2].uv);
}
