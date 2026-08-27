const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const math = @import("cube_math.zig");
const Mat4 = math.Mat4;
const Vec3 = math.Vec3;
const shd = @import("generated/geometry_shader_shader.zig");

const HouseVertex = extern struct {
    position: [2]f32,
    color: [3]f32,
};

const MeshVertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
};

const Mode = enum { houses, explode, normals };

const state = struct {
    var house_bindings: sg.Bindings = .{};
    var mesh_bindings: sg.Bindings = .{};
    var line_bindings: sg.Bindings = .{};
    var house_pipeline: sg.Pipeline = .{};
    var mesh_pipeline: sg.Pipeline = .{};
    var line_pipeline: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var mode: Mode = .houses;
    var time: f32 = 0.0;
};

const house_vertices = makeHouses();

const cube_vertices = [_]MeshVertex{
    v(-0.5, -0.5, -0.5, 0, 0, -1), v(0.5, -0.5, -0.5, 0, 0, -1),
    v(0.5, 0.5, -0.5, 0, 0, -1),   v(-0.5, 0.5, -0.5, 0, 0, -1),

    v(-0.5, -0.5, 0.5, 0, 0, 1),   v(0.5, -0.5, 0.5, 0, 0, 1),
    v(0.5, 0.5, 0.5, 0, 0, 1),     v(-0.5, 0.5, 0.5, 0, 0, 1),

    v(-0.5, -0.5, -0.5, -1, 0, 0), v(-0.5, 0.5, -0.5, -1, 0, 0),
    v(-0.5, 0.5, 0.5, -1, 0, 0),   v(-0.5, -0.5, 0.5, -1, 0, 0),

    v(0.5, -0.5, -0.5, 1, 0, 0),   v(0.5, 0.5, -0.5, 1, 0, 0),
    v(0.5, 0.5, 0.5, 1, 0, 0),     v(0.5, -0.5, 0.5, 1, 0, 0),

    v(-0.5, -0.5, -0.5, 0, -1, 0), v(-0.5, -0.5, 0.5, 0, -1, 0),
    v(0.5, -0.5, 0.5, 0, -1, 0),   v(0.5, -0.5, -0.5, 0, -1, 0),

    v(-0.5, 0.5, -0.5, 0, 1, 0),   v(-0.5, 0.5, 0.5, 0, 1, 0),
    v(0.5, 0.5, 0.5, 0, 1, 0),     v(0.5, 0.5, -0.5, 0, 1, 0),
};

const cube_indices = [_]u16{
    0,  1,  2,  0,  2,  3,
    6,  5,  4,  7,  6,  4,
    8,  9,  10, 8,  10, 11,
    14, 13, 12, 15, 14, 12,
    16, 17, 18, 16, 18, 19,
    22, 21, 20, 23, 22, 20,
};

fn v(x: f32, y: f32, z: f32, nx: f32, ny: f32, nz: f32) MeshVertex {
    return .{ .position = .{ x, y, z }, .normal = .{ nx, ny, nz } };
}

fn makeHouses() [36]HouseVertex {
    const centers = [_][2]f32{
        .{ -0.55, 0.45 }, .{ 0.55, 0.45 }, .{ -0.55, -0.55 }, .{ 0.55, -0.55 },
    };
    const colors = [_][3]f32{
        .{ 0.95, 0.2, 0.18 }, .{ 0.2, 0.85, 0.25 },
        .{ 0.2, 0.4, 1.0 },   .{ 0.95, 0.78, 0.12 },
    };
    var result: [36]HouseVertex = undefined;
    for (centers, colors, 0..) |center, color, house| {
        const x = center[0];
        const y = center[1];
        const left = x - 0.2;
        const right = x + 0.2;
        const bottom = y - 0.2;
        const top = y + 0.2;
        const white = [3]f32{ 1.0, 1.0, 1.0 };
        const out = result[house * 9 ..][0..9];
        out.* = .{
            hv(left, bottom, color),  hv(right, bottom, color), hv(left, top, color),
            hv(right, bottom, color), hv(right, top, color),    hv(left, top, color),
            hv(left, top, color),     hv(right, top, color),    hv(x, y + 0.4, white),
        };
    }
    return result;
}

fn hv(x: f32, y: f32, color: [3]f32) HouseVertex {
    return .{ .position = .{ x, y }, .color = color };
}

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    state.house_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&house_vertices),
        .label = "CPU-expanded house triangles",
    });
    state.mesh_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&cube_vertices),
        .label = "flat-normal cube vertices",
    });
    state.mesh_bindings.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&cube_indices),
        .label = "cube indices",
    });

    var normal_lines: [cube_vertices.len * 2][3]f32 = undefined;
    for (cube_vertices, 0..) |vertex, i| {
        normal_lines[i * 2] = vertex.position;
        normal_lines[i * 2 + 1] = .{
            vertex.position[0] + vertex.normal[0] * 0.28,
            vertex.position[1] + vertex.normal[1] * 0.28,
            vertex.position[2] + vertex.normal[2] * 0.28,
        };
    }
    state.line_bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&normal_lines),
        .label = "CPU-built normal lines",
    });

    state.house_pipeline = makeHousePipeline();
    state.mesh_pipeline = makeMeshPipeline();
    state.line_pipeline = makeLinePipeline();
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.055, .g = 0.06, .b = 0.08, .a = 1.0 },
    };
    state.pass_action.depth = .{ .load_action = .CLEAR, .clear_value = 1.0 };
}

fn makeHousePipeline() sg.Pipeline {
    var layout = sg.VertexLayoutState{};
    layout.buffers[0].stride = @sizeOf(HouseVertex);
    layout.attrs[shd.ATTR_houses_position] = .{ .format = .FLOAT2, .offset = @offsetOf(HouseVertex, "position") };
    layout.attrs[shd.ATTR_houses_color0] = .{ .format = .FLOAT3, .offset = @offsetOf(HouseVertex, "color") };
    return sg.makePipeline(.{
        .shader = sg.makeShader(shd.housesShaderDesc(sg.queryBackend())),
        .layout = layout,
        .sample_count = 4,
        .label = "houses",
    });
}

fn makeMeshPipeline() sg.Pipeline {
    var layout = sg.VertexLayoutState{};
    layout.buffers[0].stride = @sizeOf(MeshVertex);
    layout.attrs[shd.ATTR_mesh_position] = .{ .format = .FLOAT3, .offset = @offsetOf(MeshVertex, "position") };
    layout.attrs[shd.ATTR_mesh_normal] = .{ .format = .FLOAT3, .offset = @offsetOf(MeshVertex, "normal") };
    return sg.makePipeline(.{
        .shader = sg.makeShader(shd.meshShaderDesc(sg.queryBackend())),
        .layout = layout,
        .index_type = .UINT16,
        .depth = .{ .compare = .LESS_EQUAL, .write_enabled = true },
        .cull_mode = .BACK,
        .sample_count = 4,
        .label = "exploding mesh",
    });
}

fn makeLinePipeline() sg.Pipeline {
    var layout = sg.VertexLayoutState{};
    layout.attrs[shd.ATTR_normal_lines_position].format = .FLOAT3;
    return sg.makePipeline(.{
        .shader = sg.makeShader(shd.normalLinesShaderDesc(sg.queryBackend())),
        .layout = layout,
        .primitive_type = .LINES,
        .depth = .{ .compare = .LESS_EQUAL },
        .sample_count = 4,
        .label = "normal debug lines",
    });
}

export fn frame() void {
    state.time += @floatCast(sapp.frameDuration());
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    switch (state.mode) {
        .houses => {
            sg.applyPipeline(state.house_pipeline);
            sg.applyBindings(state.house_bindings);
            sg.draw(0, house_vertices.len, 1);
        },
        .explode, .normals => drawCubeScene(),
    }

    sg.endPass();
    sg.commit();
}

fn drawCubeScene() void {
    const projection = Mat4.persp(45.0, sapp.widthf() / sapp.heightf(), 0.1, 100.0);
    const view = Mat4.lookat(.{ .x = 2.4, .y = 1.8, .z = 3.4 }, Vec3.zero(), Vec3.up());
    const mvp = Mat4.mul(projection, view);
    const distance: f32 = if (state.mode == .explode)
        0.45 * (0.5 + 0.5 * @sin(state.time * 1.7))
    else
        0.0;

    const mesh_params = shd.MeshVsParams{ .mvp = mvp, .explode_distance = distance };
    sg.applyPipeline(state.mesh_pipeline);
    sg.applyBindings(state.mesh_bindings);
    sg.applyUniforms(shd.UB_mesh_vs_params, sg.asRange(&mesh_params));
    sg.draw(0, cube_indices.len, 1);

    if (state.mode == .normals) {
        const line_params = shd.LineVsParams{ .mvp = mvp };
        sg.applyPipeline(state.line_pipeline);
        sg.applyBindings(state.line_bindings);
        sg.applyUniforms(shd.UB_line_vs_params, sg.asRange(&line_params));
        sg.draw(0, cube_vertices.len * 2, 1);
    }
}

export fn input(event: ?*const sapp.Event) void {
    const ev = event orelse return;
    if (ev.type != .KEY_DOWN or ev.key_repeat) return;
    state.mode = switch (ev.key_code) {
        ._1 => .houses,
        ._2 => .explode,
        ._3 => .normals,
        else => state.mode,
    };
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
        .window_title = "Geometry Shader ideas — 1: houses  2: explode  3: normals",
        .logger = .{ .func = slog.func },
    });
}
