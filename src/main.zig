const std = @import("std");
const b3 = @import("box3d");
const ig = @import("cimgui");
const sokol = @import("sokol");
const shd = @import("shader.zig");
const math = @import("math.zig");

const sapp = sokol.app;
const sappimgui = sokol.appimgui;
const sg = sokol.gfx;
const sgimgui = sokol.gfximgui;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const slog = sokol.log;
const sshape = sokol.shape;
const stm = sokol.time;

const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

const max_shapes = 1024;
const max_instances = max_shapes / 2 + 1;
const ground_size: f32 = 200.0;
const ball_radius: f32 = 1.0;
const box_size: f32 = 1.5;
const shadow_map_size = 2048;
const usec_per_sec: f64 = 1_000_000.0;
const physics_tick_usec: i64 = 4_000;
const spawn_interval_sec: f64 = 0.25;

const InstanceData = extern struct {
    xxxx: Vec4 = .{},
    yyyy: Vec4 = .{},
    zzzz: Vec4 = .{},
    color: Vec4 = .{},
};

comptime {
    std.debug.assert(@sizeOf(InstanceData) == 64);
}

const Camera = struct {
    min_dist: f32 = 2.0,
    max_dist: f32 = 300.0,
    min_lat: f32 = -85.0,
    max_lat: f32 = 85.0,
    distance: f32 = 50.0,
    latitude: f32 = 25.0,
    longitude: f32 = 225.0,
    center: Vec3 = .{},
    eye_pos: Vec3 = .{},

    fn update(self: *Camera) void {
        const lat = math.degreesToRadians(self.latitude);
        const lng = math.degreesToRadians(self.longitude);
        const direction: Vec3 = .{
            .x = @cos(lat) * @sin(lng),
            .y = @sin(lat),
            .z = @cos(lat) * @cos(lng),
        };
        self.eye_pos = Vec3.add(self.center, Vec3.scale(direction, self.distance));
    }

    fn orbit(self: *Camera, dx: f32, dy: f32) void {
        self.longitude -= dx;
        if (self.longitude < 0.0) self.longitude += 360.0;
        if (self.longitude > 360.0) self.longitude -= 360.0;
        self.latitude = std.math.clamp(self.latitude + dy, self.min_lat, self.max_lat);
    }

    fn zoom(self: *Camera, delta: f32) void {
        self.distance = std.math.clamp(
            self.distance + delta * self.distance * 0.1,
            self.min_dist,
            self.max_dist,
        );
    }

    fn handleEvent(self: *Camera, event: sapp.Event) void {
        switch (event.type) {
            .MOUSE_DOWN => if (event.mouse_button == .LEFT) sapp.lockMouse(true),
            .MOUSE_UP => if (event.mouse_button == .LEFT) sapp.lockMouse(false),
            .MOUSE_SCROLL => self.zoom(event.scroll_y * 0.5),
            .MOUSE_MOVE => if (sapp.mouseLocked()) {
                self.orbit(event.mouse_dx * 0.25, event.mouse_dy * 0.25);
            },
            else => {},
        }
    }
};

const State = struct {
    vbuf: sg.Buffer = .{},
    ibuf: sg.Buffer = .{},
    box_inst_buf: sg.Buffer = .{},
    ball_inst_buf: sg.Buffer = .{},
    shapes: struct {
        plane: sshape.ElementRange = .{},
        ball: sshape.ElementRange = .{},
        box: sshape.ElementRange = .{},
    } = .{},
    shadow: struct {
        pass: sg.Pass = .{},
        tex_view: sg.View = .{},
        sampler: sg.Sampler = .{},
        inst_pipeline: sg.Pipeline = .{},
    } = .{},
    display: struct {
        pass_action: sg.PassAction = .{},
        pipeline: sg.Pipeline = .{},
        inst_pipeline: sg.Pipeline = .{},
    } = .{},
    spawn_timer: f64 = 0.0,
    camera: Camera = .{},
    light_pos: Vec3 = .{},
    light_view_proj: Mat4 = .{},
    view_proj: Mat4 = .{},
    profiling: struct {
        physics_world_step_time: u64 = 0,
        copy_transforms_time: u64 = 0,
        sub_steps_per_frame: i32 = 0,
        num_awake_bodies: i32 = 0,
    } = .{},
    ui: struct {
        show_sleeping: bool = false,
    } = .{},
    physics: struct {
        world: b3.b3WorldId = b3.b3_nullWorldId,
        ground: b3.b3BodyId = b3.b3_nullBodyId,
        tick_error_us: i64 = 0,
        num_bodies: usize = 0,
        bodies: [max_shapes]b3.b3BodyId = @splat(b3.b3_nullBodyId),
    } = .{},
    instances: struct {
        num_boxes: usize = 0,
        num_balls: usize = 0,
        boxes: [max_instances]InstanceData = @splat(.{}),
        balls: [max_instances]InstanceData = @splat(.{}),
    } = .{},
};

var state: State = .{};
var random_state: u32 = 0x12345678;

fn init() callconv(.c) void {
    stm.setup();
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sgimgui.setup(.{});
    sappimgui.setup();
    simgui.setup(.{ .logger = .{ .func = slog.func } });
    physicsInit();
    graphicsInit();
}

fn frame() callconv(.c) void {
    state.camera.update();
    state.spawn_timer -= sapp.frameDuration();
    if (state.spawn_timer <= 0.0) {
        state.spawn_timer += spawn_interval_sec;
        physicsAddBody();
    }
    physicsUpdate();
    updateInstanceBuffers();
    updateMatrices();
    drawUi();

    sg.beginPass(state.shadow.pass);
    drawInstancedShadow(state.shapes.box, state.box_inst_buf, state.instances.num_boxes);
    drawInstancedShadow(state.shapes.ball, state.ball_inst_buf, state.instances.num_balls);
    sg.endPass();

    sg.beginPass(.{
        .action = state.display.pass_action,
        .swapchain = sglue.swapchain(),
    });
    drawShapeDisplay(state.shapes.plane, Mat4.identity(), .{
        .x = 0.5,
        .y = 0.5,
        .z = 0.5,
        .w = 1.0,
    });
    drawInstancedDisplay(state.shapes.box, state.box_inst_buf, state.instances.num_boxes);
    drawInstancedDisplay(state.shapes.ball, state.ball_inst_buf, state.instances.num_balls);
    simgui.render();
    sg.endPass();
    sg.commit();
}

fn cleanup() callconv(.c) void {
    b3.b3DestroyWorld(state.physics.world);
    sgimgui.shutdown();
    sappimgui.shutdown();
    simgui.shutdown();
    sg.shutdown();
}

fn input(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const event = event_ptr[0];
    sappimgui.trackEvent(event);
    if (simgui.handleEvent(event)) return;
    state.camera.handleEvent(event);
}

fn updateMatrices() void {
    const light_view = Mat4.lookAtRh(state.light_pos, .{}, .{ .y = 1.0 });
    const light_projection = Mat4.orthoOffCenterRh(
        -100.0,
        100.0,
        -100.0,
        100.0,
        1.0,
        250.0,
    );
    state.light_view_proj = Mat4.mul(light_view, light_projection);

    const projection = Mat4.perspectiveFovRh(
        math.degreesToRadians(60.0),
        sapp.widthf() / sapp.heightf(),
        0.1,
        500.0,
    );
    const view = Mat4.lookAtRh(state.camera.eye_pos, .{}, .{ .y = 1.0 });
    state.view_proj = Mat4.mul(view, projection);
}

fn updateInstanceBuffers() void {
    if (state.instances.num_boxes > 0) {
        sg.updateBuffer(
            state.box_inst_buf,
            sg.asRange(state.instances.boxes[0..state.instances.num_boxes]),
        );
    }
    if (state.instances.num_balls > 0) {
        sg.updateBuffer(
            state.ball_inst_buf,
            sg.asRange(state.instances.balls[0..state.instances.num_balls]),
        );
    }
}

fn drawInstancedShadow(shape: sshape.ElementRange, inst_buf: sg.Buffer, count: usize) void {
    if (count == 0) return;
    const vs_params: shd.ShadowInstVsParams = .{
        .light_view_proj = state.light_view_proj,
    };
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = state.vbuf;
    bindings.vertex_buffers[1] = inst_buf;
    bindings.index_buffer = state.ibuf;
    sg.applyPipeline(state.shadow.inst_pipeline);
    sg.applyBindings(bindings);
    sg.applyUniforms(shd.UB_shadow_inst_vs_params, sg.asRange(&vs_params));
    sg.draw(@intCast(shape.base_element), @intCast(shape.num_elements), @intCast(count));
}

fn drawShapeDisplay(shape: sshape.ElementRange, model: Mat4, color: Vec4) void {
    const vs_params: shd.DisplayVsParams = .{
        .model = model,
        .mvp = Mat4.mul(model, state.view_proj),
        .light_mvp = Mat4.mul(model, state.light_view_proj),
        .diff_color = color,
    };
    const fs_params: shd.DisplayFsParams = .{
        .eye_pos = state.camera.eye_pos,
        .light_dir = Vec3.normalized(state.light_pos),
    };
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = state.vbuf;
    bindings.index_buffer = state.ibuf;
    bindings.views[shd.VIEW_shadow_map] = state.shadow.tex_view;
    bindings.samplers[shd.SMP_shadow_sampler] = state.shadow.sampler;
    sg.applyPipeline(state.display.pipeline);
    sg.applyBindings(bindings);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    sg.draw(@intCast(shape.base_element), @intCast(shape.num_elements), 1);
}

fn drawInstancedDisplay(shape: sshape.ElementRange, inst_buf: sg.Buffer, count: usize) void {
    if (count == 0) return;
    const vs_params: shd.DisplayInstVsParams = .{
        .view_proj = state.view_proj,
        .light_view_proj = state.light_view_proj,
        .awake_filter = if (state.ui.show_sleeping) 1.0 else 0.0,
    };
    const fs_params: shd.DisplayFsParams = .{
        .eye_pos = state.camera.eye_pos,
        .light_dir = Vec3.normalized(state.light_pos),
    };
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = state.vbuf;
    bindings.vertex_buffers[1] = inst_buf;
    bindings.index_buffer = state.ibuf;
    bindings.views[shd.VIEW_shadow_map] = state.shadow.tex_view;
    bindings.samplers[shd.SMP_shadow_sampler] = state.shadow.sampler;
    sg.applyPipeline(state.display.inst_pipeline);
    sg.applyBindings(bindings);
    sg.applyUniforms(shd.UB_display_inst_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    sg.draw(@intCast(shape.base_element), @intCast(shape.num_elements), @intCast(count));
}

fn physicsInit() void {
    var world_def = b3.b3DefaultWorldDef();
    state.physics.world = b3.b3CreateWorld(&world_def);

    var ground_body_def = b3.b3DefaultBodyDef();
    ground_body_def.position = .{ .x = 0.0, .y = -10.0, .z = 0.0 };
    state.physics.ground = b3.b3CreateBody(state.physics.world, &ground_body_def);

    const half_size = ground_size * 0.5;
    var ground_box = b3.b3MakeBoxHull(half_size, 10.0, half_size);
    var ground_shape_def = b3.b3DefaultShapeDef();
    _ = b3.b3CreateHullShape(state.physics.ground, &ground_shape_def, &ground_box.base);
}

fn copyInstanceTransform(instance: *InstanceData, transform: b3.b3WorldTransform) void {
    const rotation = Mat4.fromQuaternion(
        transform.q.v.x,
        transform.q.v.y,
        transform.q.v.z,
        transform.q.s,
    );
    const translation = Mat4.translation(.{
        .x = transform.p.x,
        .y = transform.p.y,
        .z = transform.p.z,
    });
    const matrix = Mat4.transpose(Mat4.mul(rotation, translation));
    instance.xxxx = rowAsVec4(matrix.m[0]);
    instance.yyyy = rowAsVec4(matrix.m[1]);
    instance.zzzz = rowAsVec4(matrix.m[2]);
}

fn rowAsVec4(row: [4]f32) Vec4 {
    return .{ .x = row[0], .y = row[1], .z = row[2], .w = row[3] };
}

fn physicsUpdate() void {
    const dt_sec = sapp.frameDuration();
    const dt_usec: i64 = @intFromFloat(dt_sec * usec_per_sec);
    state.physics.tick_error_us += dt_usec;
    const num_sub_steps = @divTrunc(state.physics.tick_error_us, physics_tick_usec);
    state.physics.tick_error_us -= num_sub_steps * physics_tick_usec;

    var start = stm.now();
    b3.b3World_Step(state.physics.world, @floatCast(dt_sec), @intCast(num_sub_steps));
    state.profiling.physics_world_step_time = stm.since(start);
    state.profiling.sub_steps_per_frame = @intCast(num_sub_steps);

    start = stm.now();
    const events = b3.b3World_GetBodyEvents(state.physics.world);
    for (0..@intCast(events.moveCount)) |index| {
        const event = &events.moveEvents[index];
        const instance: *InstanceData = @ptrCast(@alignCast(event.userData.?));
        copyInstanceTransform(instance, event.transform);
    }
    state.profiling.copy_transforms_time = stm.since(start);
    state.profiling.num_awake_bodies = b3.b3World_GetAwakeBodyCount(state.physics.world);

    if (state.ui.show_sleeping) {
        for (state.physics.bodies[0..state.physics.num_bodies]) |body| {
            const instance: *InstanceData = @ptrCast(@alignCast(b3.b3Body_GetUserData(body).?));
            instance.color.w = if (b3.b3Body_IsAwake(body)) 0.0 else 1.0;
        }
    }
}

fn xorshift32() u32 {
    random_state ^= random_state << 13;
    random_state ^= random_state >> 17;
    random_state ^= random_state << 5;
    return random_state;
}

fn randomUnitVec3() Vec3 {
    const bits = xorshift32();
    return .{
        .x = @as(f32, @floatFromInt(bits & 255)) / 255.0,
        .y = @as(f32, @floatFromInt((bits >> 8) & 255)) / 255.0,
        .z = @as(f32, @floatFromInt((bits >> 16) & 255)) / 255.0,
    };
}

fn randomIntervalVec3() Vec3 {
    const v = randomUnitVec3();
    return Vec3.scale(.{ .x = v.x - 0.5, .y = v.y - 0.5, .z = v.z - 0.5 }, 2.0);
}

fn physicsAddBody() void {
    const index = state.physics.num_bodies;
    if (index >= max_shapes) return;
    const is_box = (index & 1) == 0;
    const instance = if (is_box) blk: {
        const result = &state.instances.boxes[state.instances.num_boxes];
        state.instances.num_boxes += 1;
        break :blk result;
    } else blk: {
        const result = &state.instances.balls[state.instances.num_balls];
        state.instances.num_balls += 1;
        break :blk result;
    };

    var body_def = b3.b3DefaultBodyDef();
    body_def.type = @intCast(b3.b3_dynamicBody);
    body_def.position = .{ .x = 0.0, .y = 15.0, .z = 0.0 };
    body_def.userData = @ptrCast(instance);
    const body = b3.b3CreateBody(state.physics.world, &body_def);

    var shape_def = b3.b3DefaultShapeDef();
    shape_def.density = 1.0;
    shape_def.baseMaterial.restitution = 0.25;
    if (is_box) {
        var hull = b3.b3MakeCubeHull(box_size * 0.5);
        _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
    } else {
        shape_def.baseMaterial.rollingResistance = 0.05;
        var sphere: b3.b3Sphere = .{ .radius = ball_radius };
        _ = b3.b3CreateSphereShape(body, &shape_def, &sphere);
    }
    state.physics.bodies[index] = body;
    const color = randomUnitVec3();
    instance.color = .{ .x = color.x, .y = color.y, .z = color.z, .w = 1.0 };
    const transform = b3.b3Body_GetTransform(body);
    copyInstanceTransform(instance, transform);

    var random = randomIntervalVec3();
    const linear_impulse = Vec3.scale(
        Vec3.normalized(.{ .x = random.x, .y = random.y + 10.0, .z = random.z }),
        75.0,
    );
    b3.b3Body_ApplyLinearImpulseToCenter(body, toBox3dVec3(linear_impulse), true);
    random = randomIntervalVec3();
    b3.b3Body_ApplyAngularImpulse(body, toBox3dVec3(Vec3.scale(random, 5.0)), true);
    state.physics.num_bodies += 1;
}

fn toBox3dVec3(v: Vec3) b3.b3Vec3 {
    return .{ .x = v.x, .y = v.y, .z = v.z };
}

fn graphicsInit() void {
    state.light_pos = .{ .x = 50.0, .y = 100.0, .z = -75.0 };
    state.display.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.4, .b = 0.8, .a = 1.0 },
    };

    var vertices: [sshape.max_vertex_size * 4096]u8 = undefined;
    var indices: [4096]u16 = undefined;
    var shape_builder: sshape.State = .{
        .disable = .{ .texcoords = true, .colors = true },
        .vertices = .{ .buffer = sshape.asRange(&vertices) },
        .indices = .{ .buffer = sshape.asRange(&indices) },
    };
    sshape.buildPlane(&shape_builder, .{ .width = ground_size, .depth = ground_size });
    state.shapes.plane = sshape.elementRange(shape_builder);
    sshape.buildSphere(&shape_builder, .{
        .radius = ball_radius,
        .slices = 15,
        .stacks = 11,
    });
    state.shapes.ball = sshape.elementRange(shape_builder);
    sshape.buildBox(&shape_builder, .{
        .width = box_size,
        .height = box_size,
        .depth = box_size,
    });
    state.shapes.box = sshape.elementRange(shape_builder);
    state.vbuf = sg.makeBuffer(sshape.vertexBufferDesc(shape_builder));
    state.ibuf = sg.makeBuffer(sshape.indexBufferDesc(shape_builder));

    state.display.pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayShaderDesc(sg.queryBackend())),
        .layout = displayLayout(shape_builder),
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "display-pipeline",
    });
    state.display.inst_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.displayInstancedShaderDesc(sg.queryBackend())),
        .layout = displayInstancedLayout(shape_builder),
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "display-instanced-pipeline",
    });

    const shadow_image = sg.makeImage(.{
        .usage = .{ .depth_stencil_attachment = true },
        .width = shadow_map_size,
        .height = shadow_map_size,
        .pixel_format = .DEPTH,
        .sample_count = 1,
        .label = "shadow-map-image",
    });
    state.shadow.tex_view = sg.makeView(.{
        .texture = .{ .image = shadow_image },
        .label = "shadow-map-texview",
    });
    state.shadow.pass = .{
        .action = .{ .depth = .{
            .load_action = .CLEAR,
            .store_action = .STORE,
            .clear_value = 1.0,
        } },
        .attachments = .{
            .depth_stencil = sg.makeView(.{
                .depth_stencil_attachment = .{ .image = shadow_image },
                .label = "shadow-map-dsview",
            }),
        },
        .label = "shadow-pass",
    };
    state.shadow.sampler = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
        .compare = .LESS,
        .label = "shadow-map-sampler",
    });
    state.shadow.inst_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.shadowInstancedShaderDesc(sg.queryBackend())),
        .layout = shadowInstancedLayout(shape_builder),
        .depth = .{
            .pixel_format = .DEPTH,
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .index_type = .UINT16,
        .cull_mode = .FRONT,
        .sample_count = 1,
        .colors = noColorTargets(),
        .label = "shadow-instanced-pipeline",
    });

    state.box_inst_buf = sg.makeBuffer(.{
        .usage = .{ .stream_update = true },
        .size = max_instances * @sizeOf(InstanceData),
        .label = "box-instance-buffer",
    });
    state.ball_inst_buf = sg.makeBuffer(.{
        .usage = .{ .stream_update = true },
        .size = max_instances * @sizeOf(InstanceData),
        .label = "ball-instance-buffer",
    });
}

fn displayLayout(builder: sshape.State) sg.VertexLayoutState {
    var layout: sg.VertexLayoutState = .{};
    layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    layout.attrs[shd.ATTR_display_pos] = sshape.positionVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_normal] = sshape.normalVertexAttrState(builder);
    return layout;
}

fn displayInstancedLayout(builder: sshape.State) sg.VertexLayoutState {
    var layout: sg.VertexLayoutState = .{};
    layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    layout.buffers[1] = .{
        .step_func = .PER_INSTANCE,
        .stride = @sizeOf(InstanceData),
    };
    layout.attrs[shd.ATTR_display_instanced_pos] = sshape.positionVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_instanced_normal] = sshape.normalVertexAttrState(builder);
    layout.attrs[shd.ATTR_display_instanced_inst_xxxx] = instanceAttribute(0);
    layout.attrs[shd.ATTR_display_instanced_inst_yyyy] = instanceAttribute(16);
    layout.attrs[shd.ATTR_display_instanced_inst_zzzz] = instanceAttribute(32);
    layout.attrs[shd.ATTR_display_instanced_inst_color] = instanceAttribute(48);
    return layout;
}

fn shadowInstancedLayout(builder: sshape.State) sg.VertexLayoutState {
    var layout: sg.VertexLayoutState = .{};
    layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    layout.buffers[1] = .{
        .step_func = .PER_INSTANCE,
        .stride = @sizeOf(InstanceData),
    };
    layout.attrs[shd.ATTR_shadow_instanced_pos] = sshape.positionVertexAttrState(builder);
    layout.attrs[shd.ATTR_shadow_instanced_inst_xxxx] = instanceAttribute(0);
    layout.attrs[shd.ATTR_shadow_instanced_inst_yyyy] = instanceAttribute(16);
    layout.attrs[shd.ATTR_shadow_instanced_inst_zzzz] = instanceAttribute(32);
    return layout;
}

fn instanceAttribute(offset: i32) sg.VertexAttrState {
    return .{ .format = .FLOAT4, .buffer_index = 1, .offset = offset };
}

fn noColorTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].pixel_format = .NONE;
    return colors;
}

fn drawUi() void {
    sappimgui.trackFrame();
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });
    if (ig.igBeginMainMenuBar()) {
        sgimgui.drawMenu("sokol-gfx");
        sappimgui.drawMenu("sokol-app");
        ig.igEndMainMenuBar();
    }
    sappimgui.draw();
    sgimgui.draw();
    ig.igSetNextWindowPos(.{ .x = 30.0, .y = 50.0 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowBgAlpha(0.5);
    const flags = ig.ImGuiWindowFlags_NoDecoration | ig.ImGuiWindowFlags_AlwaysAutoResize;
    if (ig.igBegin("Status", null, flags)) {
        _ = ig.igCheckbox("Show sleeping", &state.ui.show_sleeping);
        uiText("Total bodies: {d}", .{state.physics.num_bodies});
        uiText("Awake bodies: {d}", .{state.profiling.num_awake_bodies});
        uiText("Sub-steps per frame: {d}", .{state.profiling.sub_steps_per_frame});
        uiText("World Step Time: {d:.3}ms", .{stm.ms(state.profiling.physics_world_step_time)});
        uiText("Copy Transforms Time: {d:.3}ms", .{stm.ms(state.profiling.copy_transforms_time)});
    }
    ig.igEnd();
}

fn uiText(comptime format: []const u8, args: anytype) void {
    var buffer: [128]u8 = undefined;
    const text = std.fmt.bufPrintSentinel(&buffer, format, args, 0) catch return;
    ig.igTextUnformatted(text.ptr);
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .window_title = "box3d-simple-sapp.c",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
