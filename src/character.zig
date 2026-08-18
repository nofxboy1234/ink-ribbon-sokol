//! Data-oriented character mover scene.
//!
//! Plain state is kept separate from the systems that transform it. Box3D owns
//! collision geometry, Sokol owns rendering, and the character capsule belongs
//! to neither as a rigid body: it is moved explicitly by application code.

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("rpd_level.zig");
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
    // Entrance shell and the broad central Main Hall.
    .{ .center = .{ .y = -0.25 }, .half_extents = .{ .x = 22, .y = 0.25, .z = 20 }, .color = rgb(0.20, 0.23, 0.25) },
    .{ .center = .{ .x = -22, .y = 1.75 }, .half_extents = .{ .x = 0.2, .y = 1.75, .z = 20 }, .color = rgb(0.42, 0.43, 0.45) },
    .{ .center = .{ .x = 22, .y = 1.75 }, .half_extents = .{ .x = 0.2, .y = 1.75, .z = 20 }, .color = rgb(0.42, 0.43, 0.45) },
    .{ .center = .{ .z = -20, .y = 1.75 }, .half_extents = .{ .x = 22, .y = 1.75, .z = 0.2 }, .color = rgb(0.42, 0.43, 0.45) },
    .{ .center = .{ .x = -12, .y = 1.75, .z = 20 }, .half_extents = .{ .x = 10, .y = 1.75, .z = 0.2 }, .color = rgb(0.42, 0.43, 0.45) },
    .{ .center = .{ .x = 12, .y = 1.75, .z = 20 }, .half_extents = .{ .x = 10, .y = 1.75, .z = 0.2 }, .color = rgb(0.42, 0.43, 0.45) },

    // Main Hall edges. Matching gaps lead into narrow west and east corridors.
    .{ .center = .{ .x = -7, .y = 1.5, .z = -18 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = -7, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = -7, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 4 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = -7, .y = 1.5, .z = 7.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3.5 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = -7, .y = 1.5, .z = 15.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2.5 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = 7, .y = 1.5, .z = -18 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = 7, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = 7, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 4 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = 7, .y = 1.5, .z = 7.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3.5 }, .color = rgb(0.52, 0.52, 0.54) },
    .{ .center = .{ .x = 7, .y = 1.5, .z = 15.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2.5 }, .color = rgb(0.52, 0.52, 0.54) },

    // Room-facing sides of the west/east corridors, with aligned doorways.
    .{ .center = .{ .x = -9, .y = 1.5, .z = -18 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = -9, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = -9, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 4 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = -9, .y = 1.5, .z = 7.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3.5 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = -9, .y = 1.5, .z = 15.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2.5 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = 9, .y = 1.5, .z = -18 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = 9, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = 9, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 4 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = 9, .y = 1.5, .z = 7.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 3.5 }, .color = rgb(0.46, 0.47, 0.49) },
    .{ .center = .{ .x = 9, .y = 1.5, .z = 15.5 }, .half_extents = .{ .x = 0.15, .y = 1.5, .z = 2.5 }, .color = rgb(0.46, 0.47, 0.49) },

    // West: Reception, West Office, Safety Deposit, Operations/Dark Room zone.
    .{ .center = .{ .x = -15.5, .y = 1.5, .z = 8 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },
    .{ .center = .{ .x = -15.5, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },
    .{ .center = .{ .x = -15.5, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },
    // East: East Office, Press Room, Waiting, Watchman's side.
    .{ .center = .{ .x = 15.5, .y = 1.5, .z = 8 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },
    .{ .center = .{ .x = 15.5, .y = 1.5, .z = -2 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },
    .{ .center = .{ .x = 15.5, .y = 1.5, .z = -11 }, .half_extents = .{ .x = 6.5, .y = 1.5, .z = 0.15 }, .color = rgb(0.48, 0.49, 0.51) },

    // Blockout furniture establishes the office/press-room scale.
    .{ .center = .{ .x = -15, .y = 0.55, .z = 3 }, .half_extents = .{ .x = 3.0, .y = 0.55, .z = 0.7 }, .color = rgb(0.43, 0.28, 0.17) },
    .{ .center = .{ .x = -16, .y = 0.9, .z = -7 }, .half_extents = .{ .x = 0.7, .y = 0.9, .z = 3.0 }, .color = rgb(0.25, 0.38, 0.47) },
    .{ .center = .{ .x = 15, .y = 0.55, .z = 12 }, .half_extents = .{ .x = 2.6, .y = 0.55, .z = 0.8 }, .color = rgb(0.40, 0.31, 0.19) },
    .{ .center = .{ .x = 15, .y = 0.7, .z = 3 }, .half_extents = .{ .x = 2.0, .y = 0.7, .z = 1.2 }, .color = rgb(0.31, 0.40, 0.29) },
};

const stair_placeholder = SceneBox{
    .center = .{ .x = 0, .y = 1.0, .z = -14 },
    .half_extents = .{ .x = 4.0, .y = 1.0, .z = 2.0 },
    .color = .{ .x = 0.35, .y = 0.78, .z = 1.0, .w = 0.32 },
};

const static_instance_count = visible: {
    var count: usize = level.tread_count;
    for (level.boxes) |box| count += @intFromBool(box.visible);
    break :visible count;
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

const DebugState = struct {
    draw_physics: bool = true,
};

const RenderState = struct {
    vertex_buffer: sg.Buffer = .{},
    index_buffer: sg.Buffer = .{},
    level_instances: sg.Buffer = .{},
    character_instance: sg.Buffer = .{},
    capsule_instances: sg.Buffer = .{},
    display_pipeline: sg.Pipeline = .{},
    debug_pipeline: sg.Pipeline = .{},
    shadow_pipeline: sg.Pipeline = .{},
    shadow_pass: sg.Pass = .{},
    shadow_view: sg.View = .{},
    shadow_sampler: sg.Sampler = .{},
    light_view_projection: Mat4 = Mat4.identity(),
    box_range: sshape.ElementRange = .{},
    capsule_cylinder_range: sshape.ElementRange = .{},
    capsule_sphere_range: sshape.ElementRange = .{},
    pass_action: sg.PassAction = .{},
};

const GameState = struct {
    world: b3.b3WorldId = b3.b3_nullWorldId,
    clock: Clock = .{},
    input: InputState = .{},
    debug: DebugState = .{},
    character_config: controller.Config = .{},
    character: controller.State = initialCharacter(),
    mover_scratch: controller.MoverScratch = .{},
    camera_config: camera.Config = .{},
    camera: camera.State = .{},
    render: RenderState = .{},
};

var game: GameState = .{};

fn initialCharacter() controller.State {
    var character = controller.State.init(.{ .x = 0, .y = 0.9, .z = 17 });
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
                .F1 => if (down and !value.key_repeat) {
                    game.debug.draw_physics = !game.debug.draw_physics;
                },
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
    for (level.boxes) |box| if (box.collidable) addStaticBox(box);
    for (level.staircases) |staircase| addStaticBox(level.collisionRamp(staircase));
}

fn addStaticBox(box: level.Box) void {
    var body_def = b3.b3DefaultBodyDef();
    body_def.position = .{ .x = box.center.x, .y = box.center.y, .z = box.center.z };
    // Build the X-axis quaternion locally. The generated Zig wrapper for
    // b3MakeQuatFromAxisAngle references Box3D's non-exported assert helper.
    const half_pitch = box.pitch * 0.5;
    body_def.rotation = .{ .v = .{ .x = @sin(half_pitch) }, .s = @cos(half_pitch) };
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    shape_def.filter.categoryBits = controller.level_category;
    shape_def.filter.maskBits = controller.player_query_category | camera.camera_query_category;
    var hull = b3.b3MakeBoxHull(box.half_extents.x, box.half_extents.y, box.half_extents.z);
    _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
}

fn initRenderer() void {
    var vertices: [sshape.max_vertex_size * 4096]u8 = undefined;
    var indices: [4096]u16 = undefined;
    var builder: sshape.State = .{
        .vertices = .{ .buffer = sshape.asRange(&vertices) },
        .indices = .{ .buffer = sshape.asRange(&indices) },
        .disable = .{ .texcoords = true, .colors = true },
    };
    sshape.buildBox(&builder, .{ .width = 1, .height = 1, .depth = 1 });
    game.render.box_range = sshape.elementRange(builder);
    sshape.buildCylinder(&builder, .{ .radius = 1, .height = 1, .slices = 16, .stacks = 1 });
    game.render.capsule_cylinder_range = sshape.elementRange(builder);
    sshape.buildSphere(&builder, .{ .radius = 1, .slices = 16, .stacks = 8 });
    game.render.capsule_sphere_range = sshape.elementRange(builder);
    game.render.vertex_buffer = sg.makeBuffer(sshape.vertexBufferDesc(builder));
    game.render.index_buffer = sg.makeBuffer(sshape.indexBufferDesc(builder));

    var instances: [static_instance_count]Instance = undefined;
    var instance_count: usize = 0;
    for (level.boxes) |box| {
        if (!box.visible) continue;
        instances[instance_count] = makePitchedInstance(box.center, box.half_extents, box.pitch, box.color);
        instance_count += 1;
    }
    for (level.staircases) |staircase| {
        for (0..staircase.steps) |step| {
            const box = level.tread(staircase, step);
            instances[instance_count] = makePitchedInstance(box.center, box.half_extents, box.pitch, box.color);
            instance_count += 1;
        }
    }
    std.debug.assert(instance_count == static_instance_count);
    game.render.level_instances = sg.makeBuffer(.{ .data = sg.asRange(&instances), .label = "character-level-instances" });
    game.render.character_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-dynamic-instance",
    });
    game.render.capsule_instances = sg.makeBuffer(.{
        .size = 3 * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-capsule-debug-instances",
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
    game.render.debug_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = layout,
        .depth = .{ .write_enabled = false, .compare = .LESS_EQUAL },
        .colors = blendingTargets(),
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-capsule-debug-pipeline",
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

    const light_position = Vec3{ .x = 20, .y = 32, .z = -24 };
    const light_view = Mat4.lookAtRh(light_position, .{}, .{ .y = 1 });
    const light_projection = Mat4.orthoOffCenterRh(-38, 38, -38, 38, 1, 100);
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
    if (game.debug.draw_physics) updateCapsuleInstances(position);

    const shadow_params: shd.ShadowVsParams = .{ .light_view_projection = game.render.light_view_projection };
    sg.beginPass(game.render.shadow_pass);
    sg.applyPipeline(game.render.shadow_pipeline);
    sg.applyUniforms(shd.UB_shadow_vs_params, sg.asRange(&shadow_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, static_instance_count, false);
    drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
    sg.endPass();

    const vs_params: shd.DisplayVsParams = .{
        .view_projection = game.camera.view_projection,
        .light_view_projection = game.render.light_view_projection,
    };
    const fs_params: shd.DisplayFsParams = .{
        .light_direction = Vec3.normalized(.{ .x = 20, .y = 32, .z = -24 }),
        .eye_position = game.camera.eye,
        // xyz is fixture position; w is its attenuation radius.
        .indoor_light_0 = .{ .x = 0, .y = 4.5, .z = 12, .w = 18 },
        .indoor_light_1 = .{ .x = -19, .y = 4.2, .z = 0, .w = 17 },
        .indoor_light_2 = .{ .x = 19, .y = 4.2, .z = 0, .w = 17 },
        .indoor_light_3 = .{ .x = 0, .y = 10, .z = 10, .w = 18 },
        .indoor_light_4 = .{ .x = -19, .y = 9.7, .z = -3, .w = 17 },
        .indoor_light_5 = .{ .x = 19, .y = 9.7, .z = -3, .w = 17 },
        .indoor_light_6 = .{ .x = -17, .y = 15, .z = -3, .w = 17 },
        .indoor_light_7 = .{ .x = -17, .y = 20.5, .z = 0, .w = 10 },
    };

    sg.beginPass(.{ .action = game.render.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(game.render.display_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, static_instance_count, true);
    drawInstances(game.render.character_instance, game.render.box_range, 0, 1, true);
    sg.applyPipeline(game.render.debug_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    if (game.debug.draw_physics) {
        drawInstances(game.render.capsule_instances, game.render.capsule_cylinder_range, 0, 1, true);
        drawInstances(game.render.capsule_instances, game.render.capsule_sphere_range, @sizeOf(Instance), 2, true);
    }
    drawHud(position);
    sg.endPass();
    sg.commit();
}

fn updateCapsuleInstances(position: b3.b3Pos) void {
    const radius = game.character_config.capsule_radius;
    const half_segment = game.character_config.capsule_half_segment;
    const color = Vec4{ .x = 0.25, .y = 1.0, .z = 0.55, .w = 0.32 };
    const instances = [_]Instance{
        makeScaledInstance(
            .{ .x = position.x, .y = position.y, .z = position.z },
            .{ .x = radius, .y = 2 * half_segment, .z = radius },
            0,
            color,
        ),
        makeScaledInstance(
            .{ .x = position.x, .y = position.y - half_segment, .z = position.z },
            .{ .x = radius, .y = radius, .z = radius },
            0,
            color,
        ),
        makeScaledInstance(
            .{ .x = position.x, .y = position.y + half_segment, .z = position.z },
            .{ .x = radius, .y = radius, .z = radius },
            0,
            color,
        ),
    };
    sg.updateBuffer(game.render.capsule_instances, sg.asRange(&instances));
}

fn drawHud(position: b3.b3Pos) void {
    const frame_duration = sapp.frameDuration();
    const fps = if (frame_duration > 0) 1.0 / frame_duration else 0;
    const text_width = 11.0; // "FPS: " plus a six-character numeric field.
    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(@max(1.0, sapp.widthf() / 8.0 - text_width - 1.0), 1.0);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:>6.1}", .{fps});
    if (game.debug.draw_physics) {
        sdtx.pos(1.0, 1.0);
        sdtx.print("POS {d:.1} {d:.1} {d:.1}", .{ position.x, position.y, position.z });
    }
    sdtx.draw();
}

fn drawInstances(
    instance_buffer: sg.Buffer,
    range: sshape.ElementRange,
    instance_offset: usize,
    count: usize,
    with_shadow_texture: bool,
) void {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = game.render.vertex_buffer;
    bindings.vertex_buffers[1] = instance_buffer;
    bindings.vertex_buffer_offsets[1] = @intCast(instance_offset);
    bindings.index_buffer = game.render.index_buffer;
    if (with_shadow_texture) {
        bindings.views[shd.VIEW_shadow_map] = game.render.shadow_view;
        bindings.samplers[shd.SMP_shadow_sampler] = game.render.shadow_sampler;
    }
    sg.applyBindings(bindings);
    sg.draw(
        @intCast(range.base_element),
        @intCast(range.num_elements),
        @intCast(count),
    );
}

fn noColorTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].pixel_format = .NONE;
    return colors;
}

fn blendingTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].blend = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
        .src_factor_alpha = .ONE,
        .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
    };
    return colors;
}

fn makeInstance(center: Vec3, half: Vec3, yaw: f32, color: Vec4) Instance {
    return makeScaledInstance(center, Vec3.scale(half, 2), yaw, color);
}

fn makePitchedInstance(center: Vec3, half: Vec3, pitch: f32, color: Vec4) Instance {
    const scale = Vec3.scale(half, 2);
    const c = @cos(pitch);
    const s = @sin(pitch);
    return .{
        .x = .{ .x = scale.x, .w = center.x },
        .y = .{ .y = scale.y * c, .z = -scale.z * s, .w = center.y },
        .z = .{ .y = scale.y * s, .z = scale.z * c, .w = center.z },
        .color = color,
    };
}

fn makeScaledInstance(center: Vec3, scale: Vec3, yaw: f32, color: Vec4) Instance {
    const c = @cos(yaw);
    const s = @sin(yaw);
    // Each row maps the unit box directly into world space. Scale is baked in,
    // so the shader needs no per-object uniform or matrix multiplication.
    return .{
        .x = .{ .x = scale.x * c, .y = 0, .z = scale.z * s, .w = center.x },
        .y = .{ .x = 0, .y = scale.y, .z = 0, .w = center.y },
        .z = .{ .x = -scale.x * s, .y = 0, .z = scale.z * c, .w = center.z },
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
        // Sokol implements desktop fullscreen as a borderless fullscreen window.
        .fullscreen = true,
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
