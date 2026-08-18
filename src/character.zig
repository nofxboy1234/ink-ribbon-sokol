//! Data-oriented character mover scene.
//!
//! Plain state is kept separate from the systems that transform it. Box3D owns
//! collision geometry, Sokol owns rendering, and the character capsule belongs
//! to neither as a rigid body: it is moved explicitly by application code.

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const controller = @import("character_controller.zig");
const camera = @import("third_person_camera.zig");
const shd = @import("generated/character_shader.zig");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const sshape = sokol.shape;
const sdtx = sokol.debugtext;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

const fixed_dt: f64 = 1.0 / 60.0;
const max_frame_dt: f64 = 0.1;
const max_ticks_per_frame = 6;
const shadow_map_size = 2048;
const character_half_extents = Vec3{ .x = 0.32, .y = 0.9, .z = 0.22 };

const SceneBox = struct {
    center: Vec3,
    half_extents: Vec3,
    color: Vec4,
};

// One description feeds both Box3D and the immutable render-instance buffer.
const scene_boxes = [_]SceneBox{
    .{ .center = .{ .y = -0.25 }, .half_extents = .{ .x = 10, .y = 0.25, .z = 10 }, .color = rgb(0.26, 0.29, 0.31) },
    .{ .center = .{ .x = -10, .y = 1.5 }, .half_extents = .{ .x = 0.25, .y = 1.75, .z = 10 }, .color = rgb(0.38, 0.40, 0.42) },
    .{ .center = .{ .x = 10, .y = 1.5 }, .half_extents = .{ .x = 0.25, .y = 1.75, .z = 10 }, .color = rgb(0.38, 0.40, 0.42) },
    .{ .center = .{ .z = -10, .y = 1.5 }, .half_extents = .{ .x = 10, .y = 1.75, .z = 0.25 }, .color = rgb(0.38, 0.40, 0.42) },
    .{ .center = .{ .z = 10, .y = 1.5 }, .half_extents = .{ .x = 10, .y = 1.75, .z = 0.25 }, .color = rgb(0.38, 0.40, 0.42) },
    .{ .center = .{ .x = -3.2, .y = 0.75, .z = -1.5 }, .half_extents = .{ .x = 1.2, .y = 0.75, .z = 1.2 }, .color = rgb(0.55, 0.31, 0.20) },
    .{ .center = .{ .x = 2.8, .y = 1.0, .z = -2.8 }, .half_extents = .{ .x = 0.7, .y = 1.0, .z = 2.2 }, .color = rgb(0.25, 0.42, 0.52) },
    .{ .center = .{ .x = 0.5, .y = 0.5, .z = 3.5 }, .half_extents = .{ .x = 2.5, .y = 0.5, .z = 0.6 }, .color = rgb(0.43, 0.35, 0.22) },
    .{ .center = .{ .x = -5.8, .y = 1.2, .z = 5.0 }, .half_extents = .{ .x = 0.5, .y = 1.2, .z = 2.5 }, .color = rgb(0.32, 0.45, 0.30) },
};

const Instance = extern struct {
    x: Vec4,
    y: Vec4,
    z: Vec4,
    color: Vec4,
};

const Clock = struct {
    accumulator: f64 = 0,

    fn addFrame(self: *Clock, frame_time: f64) void {
        self.accumulator += @min(frame_time, max_frame_dt);
    }

    fn consumeTick(self: *Clock) bool {
        if (self.accumulator < fixed_dt) return false;
        self.accumulator -= fixed_dt;
        return true;
    }

    fn alpha(self: Clock) f32 {
        return @floatCast(self.accumulator / fixed_dt);
    }
};

const InputState = struct {
    forward: bool = false,
    back: bool = false,
    left: bool = false,
    right: bool = false,
    run: bool = false,
    mouse_delta: math.Vec2 = .{},

    fn characterInput(self: InputState) controller.Input {
        return .{
            .move = .{
                .x = @as(f32, @floatFromInt(@intFromBool(self.right))) - @as(f32, @floatFromInt(@intFromBool(self.left))),
                .y = @as(f32, @floatFromInt(@intFromBool(self.forward))) - @as(f32, @floatFromInt(@intFromBool(self.back))),
            },
            .run = self.run,
        };
    }
};

const RenderState = struct {
    vertex_buffer: sg.Buffer = .{},
    index_buffer: sg.Buffer = .{},
    level_instances: sg.Buffer = .{},
    character_instance: sg.Buffer = .{},
    display_pipeline: sg.Pipeline = .{},
    shadow_pipeline: sg.Pipeline = .{},
    shadow_pass: sg.Pass = .{},
    shadow_view: sg.View = .{},
    shadow_sampler: sg.Sampler = .{},
    light_view_projection: Mat4 = Mat4.identity(),
    index_range: sshape.ElementRange = .{},
    pass_action: sg.PassAction = .{},
};

const GameState = struct {
    world: b3.b3WorldId = b3.b3_nullWorldId,
    clock: Clock = .{},
    input: InputState = .{},
    character_config: controller.Config = .{},
    character: controller.State = initialCharacter(),
    mover_scratch: controller.MoverScratch = .{},
    camera_config: camera.Config = .{},
    camera: camera.State = .{},
    render: RenderState = .{},
};

var game: GameState = .{};

fn initialCharacter() controller.State {
    var character = controller.State.init(.{ .x = 0, .y = 0.9, .z = 0 });
    // The initial camera looks toward -Z, so the character must face -Z too for
    // the shoulder camera to begin behind it rather than in front of it.
    character.yaw = std.math.pi;
    return character;
}

fn init() callconv(.c) void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
    sdtx.setup(.{
        .fonts = init: {
            var fonts: [8]sdtx.FontDesc = @splat(.{});
            fonts[0] = sdtx.fontKc853();
            break :init fonts;
        },
        .logger = .{ .func = slog.func },
    });
    initPhysics();
    initRenderer();
    sapp.lockMouse(true);
}

fn frame() callconv(.c) void {
    const frame_time: f32 = @floatCast(@min(sapp.frameDuration(), max_frame_dt));
    game.clock.addFrame(frame_time);

    var ticks: usize = 0;
    while (ticks < max_ticks_per_frame and game.clock.consumeTick()) : (ticks += 1) {
        controller.update(
            game.character_config,
            &game.character,
            &game.mover_scratch,
            game.world,
            game.input.characterInput(),
            game.camera.basis,
            @floatCast(fixed_dt),
        );
    }
    // Discard excess backlog after the bounded catch-up budget.
    if (ticks == max_ticks_per_frame and game.clock.accumulator >= fixed_dt) {
        game.clock.accumulator = @mod(game.clock.accumulator, fixed_dt);
    }

    const render_position = controller.interpolatedPosition(game.character, game.clock.alpha());
    camera.update(
        game.camera_config,
        &game.camera,
        render_position,
        game.input.mouse_delta,
        game.world,
        frame_time,
        sapp.widthf() / @max(sapp.heightf(), 1),
    );
    game.input.mouse_delta = .{};
    draw(render_position);
}

fn cleanup() callconv(.c) void {
    b3.b3DestroyWorld(game.world);
    game.world = b3.b3_nullWorldId;
    sdtx.shutdown();
    sg.shutdown();
}

fn event(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const value = event_ptr[0];
    switch (value.type) {
        .KEY_DOWN, .KEY_UP => {
            const down = value.type == .KEY_DOWN;
            switch (value.key_code) {
                .W => game.input.forward = down,
                .S => game.input.back = down,
                .A => game.input.left = down,
                .D => game.input.right = down,
                .LEFT_SHIFT, .RIGHT_SHIFT => game.input.run = down,
                .ESCAPE => if (down) sapp.lockMouse(false),
                else => {},
            }
        },
        .MOUSE_DOWN => sapp.lockMouse(true),
        .MOUSE_MOVE => if (sapp.mouseLocked()) {
            game.input.mouse_delta.x += value.mouse_dx;
            game.input.mouse_delta.y += value.mouse_dy;
        },
        .UNFOCUSED => {
            game.input = .{};
            sapp.lockMouse(false);
        },
        else => {},
    }
}

fn initPhysics() void {
    var world_def = b3.b3DefaultWorldDef();
    game.world = b3.b3CreateWorld(&world_def);
    for (scene_boxes) |box| {
        var body_def = b3.b3DefaultBodyDef();
        body_def.position = .{ .x = box.center.x, .y = box.center.y, .z = box.center.z };
        const body = b3.b3CreateBody(game.world, &body_def);
        var shape_def = b3.b3DefaultShapeDef();
        shape_def.filter.categoryBits = controller.level_category;
        shape_def.filter.maskBits = controller.player_query_category | camera.camera_query_category;
        var hull = b3.b3MakeBoxHull(box.half_extents.x, box.half_extents.y, box.half_extents.z);
        _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
    }
}

fn initRenderer() void {
    var vertices: [sshape.max_vertex_size * 24]u8 = undefined;
    var indices: [36]u16 = undefined;
    var builder: sshape.State = .{
        .vertices = .{ .buffer = sshape.asRange(&vertices) },
        .indices = .{ .buffer = sshape.asRange(&indices) },
        .disable = .{ .texcoords = true, .colors = true },
    };
    sshape.buildBox(&builder, .{ .width = 1, .height = 1, .depth = 1 });
    game.render.index_range = sshape.elementRange(builder);
    game.render.vertex_buffer = sg.makeBuffer(sshape.vertexBufferDesc(builder));
    game.render.index_buffer = sg.makeBuffer(sshape.indexBufferDesc(builder));

    var instances: [scene_boxes.len]Instance = undefined;
    for (scene_boxes, 0..) |box, i| instances[i] = makeInstance(box.center, box.half_extents, 0, box.color);
    game.render.level_instances = sg.makeBuffer(.{ .data = sg.asRange(&instances), .label = "character-level-instances" });
    game.render.character_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-dynamic-instance",
    });

    var layout: sg.VertexLayoutState = .{};
    layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    layout.attrs[shd.ATTR_display_position] = sshape.positionVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_normal] = sshape.normalVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_inst_x] = instanceAttr(0);
    layout.attrs[shd.ATTR_display_inst_y] = instanceAttr(16);
    layout.attrs[shd.ATTR_display_inst_z] = instanceAttr(32);
    layout.attrs[shd.ATTR_display_inst_color] = instanceAttr(48);
    game.render.display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-scene-pipeline",
    });

    const shadow_image = sg.makeImage(.{
        .usage = .{ .depth_stencil_attachment = true },
        .width = shadow_map_size,
        .height = shadow_map_size,
        .pixel_format = .DEPTH,
        .sample_count = 1,
        .label = "character-shadow-map",
    });
    game.render.shadow_view = sg.makeView(.{ .texture = .{ .image = shadow_image } });
    game.render.shadow_sampler = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
        .compare = .LESS,
    });
    game.render.shadow_pass = .{
        .action = .{ .depth = .{ .load_action = .CLEAR, .store_action = .STORE, .clear_value = 1 } },
        .attachments = .{ .depth_stencil = sg.makeView(.{ .depth_stencil_attachment = .{ .image = shadow_image } }) },
        .label = "character-shadow-pass",
    };

    var shadow_layout: sg.VertexLayoutState = .{};
    shadow_layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    shadow_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    shadow_layout.attrs[shd.ATTR_shadow_position] = sshape.positionVertexAttrState(builder);
    shadow_layout.attrs[shd.ATTR_shadow_inst_x] = instanceAttr(0);
    shadow_layout.attrs[shd.ATTR_shadow_inst_y] = instanceAttr(16);
    shadow_layout.attrs[shd.ATTR_shadow_inst_z] = instanceAttr(32);
    game.render.shadow_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.shadowShaderDesc(sg.queryBackend())),
        .layout = shadow_layout,
        .depth = .{ .pixel_format = .DEPTH, .write_enabled = true, .compare = .LESS_EQUAL },
        .colors = noColorTargets(),
        .sample_count = 1,
        .index_type = .UINT16,
        .cull_mode = .FRONT,
        .label = "character-shadow-pipeline",
    });

    const light_position = Vec3{ .x = 8, .y = 14, .z = -10 };
    const light_view = Mat4.lookAtRh(light_position, .{}, .{ .y = 1 });
    const light_projection = Mat4.orthoOffCenterRh(-14, 14, -14, 14, 1, 40);
    game.render.light_view_projection = Mat4.mul(light_view, light_projection);
    game.render.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.045, .b = 0.055, .a = 1 } };
}

fn draw(position: b3.b3Pos) void {
    const instance = makeInstance(
        .{ .x = position.x, .y = position.y, .z = position.z },
        character_half_extents,
        game.character.yaw,
        rgb(0.20, 0.694, 1.0), // Oxocarbon blue: #33B1FF
    );
    sg.updateBuffer(game.render.character_instance, sg.asRange(&instance));

    const shadow_params: shd.ShadowVsParams = .{ .light_view_projection = game.render.light_view_projection };
    sg.beginPass(game.render.shadow_pass);
    sg.applyPipeline(game.render.shadow_pipeline);
    sg.applyUniforms(shd.UB_shadow_vs_params, sg.asRange(&shadow_params));
    drawInstances(game.render.level_instances, scene_boxes.len, false);
    drawInstances(game.render.character_instance, 1, false);
    sg.endPass();

    const vs_params: shd.DisplayVsParams = .{
        .view_projection = game.camera.view_projection,
        .light_view_projection = game.render.light_view_projection,
    };
    const fs_params: shd.DisplayFsParams = .{
        .light_direction = Vec3.normalized(.{ .x = 8, .y = 14, .z = -10 }),
        .eye_position = game.camera.eye,
    };

    sg.beginPass(.{ .action = game.render.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(game.render.display_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    drawInstances(game.render.level_instances, scene_boxes.len, true);
    drawInstances(game.render.character_instance, 1, true);
    drawFps();
    sg.endPass();
    sg.commit();
}

fn drawFps() void {
    const frame_duration = sapp.frameDuration();
    const fps = if (frame_duration > 0) 1.0 / frame_duration else 0;
    const text_width = 11.0; // "FPS: " plus a six-character numeric field.
    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(@max(1.0, sapp.widthf() / 8.0 - text_width - 1.0), 1.0);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:>6.1}", .{fps});
    sdtx.draw();
}

fn drawInstances(instance_buffer: sg.Buffer, count: usize, with_shadow_texture: bool) void {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = game.render.vertex_buffer;
    bindings.vertex_buffers[1] = instance_buffer;
    bindings.index_buffer = game.render.index_buffer;
    if (with_shadow_texture) {
        bindings.views[shd.VIEW_shadow_map] = game.render.shadow_view;
        bindings.samplers[shd.SMP_shadow_sampler] = game.render.shadow_sampler;
    }
    sg.applyBindings(bindings);
    sg.draw(
        @intCast(game.render.index_range.base_element),
        @intCast(game.render.index_range.num_elements),
        @intCast(count),
    );
}

fn noColorTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].pixel_format = .NONE;
    return colors;
}

fn makeInstance(center: Vec3, half: Vec3, yaw: f32, color: Vec4) Instance {
    const c = @cos(yaw);
    const s = @sin(yaw);
    // Each row maps the unit box directly into world space. Scale is baked in,
    // so the shader needs no per-object uniform or matrix multiplication.
    return .{
        .x = .{ .x = 2 * half.x * c, .y = 0, .z = 2 * half.z * s, .w = center.x },
        .y = .{ .x = 0, .y = 2 * half.y, .z = 0, .w = center.y },
        .z = .{ .x = -2 * half.x * s, .y = 0, .z = 2 * half.z * c, .w = center.z },
        .color = color,
    };
}

fn instanceAttr(offset: i32) sg.VertexAttrState {
    return .{ .format = .FLOAT4, .buffer_index = 1, .offset = offset };
}

fn rgb(r: f32, g: f32, b: f32) Vec4 {
    return .{ .x = r, .y = g, .z = b, .w = 1 };
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 1280,
        .height = 720,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "Character Mover",
        .logger = .{ .func = slog.func },
    });
}

test "clock consumes fixed ticks independent of frame chunks" {
    var a: Clock = .{};
    var b: Clock = .{};
    var count_a: usize = 0;
    var count_b: usize = 0;
    for (0..30) |_| {
        a.addFrame(1.0 / 30.0);
        while (a.consumeTick()) count_a += 1;
    }
    for (0..120) |_| {
        b.addFrame(1.0 / 120.0);
        while (b.consumeTick()) count_b += 1;
    }
    try std.testing.expectEqual(count_a, count_b);
}
