const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("level.zig");
const hunter = @import("hunter.zig");
const deformation = @import("character_deformation.zig");
const deformed_box = @import("deformed_box.zig");
const shd = @import("generated/character_shader.zig");
const inventory = @import("inventory.zig");
const saves = @import("saves.zig");
const state = @import("state.zig");
const presentation = @import("presentation.zig");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const sshape = sokol.shape;
const sdtx = sokol.debugtext;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

const rgb = state.rgb;
const fbool = state.fbool;
const smoothstep = state.smoothstep;

const mapWorldAtScreen = presentation.mapWorldAtScreen;
const nearSaveFixture = presentation.nearSaveFixture;
var game: *state.GameState = undefined;

pub fn init(g: *state.GameState) void {
    game = g;
}

const InventoryLayout = state.InventoryLayout;
const ScreenRect = state.ScreenRect;
const fixed_dt = state.fixed_dt;
const max_frame_dt = state.max_frame_dt;
const max_ticks_per_frame = state.max_ticks_per_frame;
const shadow_map_size = state.shadow_map_size;
const character_half_extents = state.character_half_extents;
const hunter_half_extents = state.hunter_half_extents;
const hunter_color = state.hunter_color;
const player_spawn_y = state.player_spawn_y;
const hunter_spawn_y = state.hunter_spawn_y;
const save_interaction_radius = state.save_interaction_radius;
const notice_seconds = state.notice_seconds;
const impact_capacity = state.impact_capacity;
const impact_seconds = state.impact_seconds;
const hunter_hit_flash_seconds = state.hunter_hit_flash_seconds;
const hunter_flinch_seconds = state.hunter_flinch_seconds;
const hunter_knockdown_enter_seconds = state.hunter_knockdown_enter_seconds;
const hunter_knockdown_exit_seconds = state.hunter_knockdown_exit_seconds;
const shot_recoil_radians = state.shot_recoil_radians;
const HudNotice = state.HudNotice;
const map_pan_speed = state.map_pan_speed;
const map_margin = state.map_margin;
const map_route_capacity = state.map_route_capacity;
const map_route_width = state.map_route_width;
const map_route_height = state.map_route_height;
const map_route_danger_radius = state.map_route_danger_radius;
const map_route_danger_penalty = state.map_route_danger_penalty;
const map_direction_color = state.map_direction_color;
const map_direction_instance_count = state.map_direction_instance_count;
const map_save_capacity = state.map_save_capacity;
const PickupDef = state.PickupDef;
const max_pickups = state.max_pickups;
const BreakableDef = state.BreakableDef;
const max_breakables = state.max_breakables;
const world_render_capacity = state.world_render_capacity;
const window_render_capacity = state.window_render_capacity;
const interaction_radius = state.interaction_radius;
const door_interaction_radius = state.door_interaction_radius;
const door_limit_radians = state.door_limit_radians;
const door_spring_hertz = state.door_spring_hertz;
const door_spring_damping = state.door_spring_damping;
const door_density = state.door_density;
const door_angular_damping = state.door_angular_damping;
const door_push_impulse = state.door_push_impulse;
const door_walk_push_strength = state.door_walk_push_strength;
const door_run_push_strength = state.door_run_push_strength;
const door_physics_edge_clearance = state.door_physics_edge_clearance;
const door_physics_vertical_clearance = state.door_physics_vertical_clearance;
const door_ai_push_cooldown_seconds = state.door_ai_push_cooldown_seconds;
const physics_substeps = state.physics_substeps;
const debris_capacity = state.debris_capacity;
const debris_seconds = state.debris_seconds;
const action_duration = state.action_duration;
const action_contact_time = state.action_contact_time;
const hunter_punch_duration = state.hunter_punch_duration;
const hunter_punch_extend_fraction = state.hunter_punch_extend_fraction;
const hunter_punch_hold_fraction = state.hunter_punch_hold_fraction;
const box_item_chance = state.box_item_chance;
const box_health_share = state.box_health_share;
const box_ammo_amount = state.box_ammo_amount;
const breakable_half_extent = state.breakable_half_extent;
const audio_buffer_frames = state.audio_buffer_frames;
const audio_channel_count = state.audio_channel_count;
const InteractionKind = state.InteractionKind;
const InteractionTarget = state.InteractionTarget;
const KickState = state.KickState;
const PickupAction = state.PickupAction;
const Debris = state.Debris;
const Instance = state.Instance;
const Clock = state.Clock;
const InputState = state.InputState;
const Impact = state.Impact;
const CombatVisuals = state.CombatVisuals;
const HunterReaction = state.HunterReaction;
const HunterPunchAction = state.HunterPunchAction;
const DebugState = state.DebugState;
const MapRouteStatus = state.MapRouteStatus;
const MenuKind = state.MenuKind;
const MenuState = state.MenuState;
const RunStats = state.RunStats;
const InventoryUi = state.InventoryUi;
const MapState = state.MapState;
const QuickTurn = state.QuickTurn;
const RenderState = state.RenderState;
const GameState = state.GameState;
const doorBaseYaw = presentation.doorBaseYaw;
const doorHingePosition = presentation.doorHingePosition;
const targetName = presentation.targetName;
const targetColor = presentation.targetColor;
const itemName = presentation.itemName;
const itemColor = presentation.itemColor;
const draculaPurple = presentation.draculaPurple;
const draculaPink = presentation.draculaPink;
const draculaCyan = presentation.draculaCyan;
const doorColor = presentation.doorColor;
const doorIsUnlocked = presentation.doorIsUnlocked;
const doorDisplayColor = presentation.doorDisplayColor;
const doorKey = presentation.doorKey;
const boxDropPosition = presentation.boxDropPosition;
const boxDropItem = presentation.boxDropItem;
const kickAmount = presentation.kickAmount;
const rootMenuItemRect = presentation.rootMenuItemRect;
const inventoryLayout = presentation.inventoryLayout;
const inventoryCellRect = presentation.inventoryCellRect;
const inventoryCellAt = presentation.inventoryCellAt;
const inventoryPopupRect = presentation.inventoryPopupRect;
const doorPose = presentation.doorPose;
const hunterKnockdownAmount = presentation.hunterKnockdownAmount;
const mapItemVisible = presentation.mapItemVisible;
const targetItem = presentation.targetItem;
const doorName = presentation.doorName;

pub fn uploadMapRoute() void {
    if (!game.map.route_upload_pending) return;
    if (game.map.active and game.map.route_segment_count > 0) {
        sg.updateBuffer(
            game.render.route_instances,
            sg.asRange(game.map.route_instances[0..game.map.route_segment_count]),
        );
    }
    game.map.route_upload_pending = false;
}

pub fn uploadLevelInstances() void {
    var level_instances: [level.max_boxes]Instance = undefined;
    var roof_instances: [level.max_boxes]Instance = undefined;
    var level_count: usize = 0;
    var roof_count: usize = 0;
    for (level.current.boxSlice()) |box| {
        if (!box.visible) continue;
        const instance = makeOrientedInstance(box);
        if (box.is_roof) {
            roof_instances[roof_count] = instance;
            roof_count += 1;
        } else {
            level_instances[level_count] = instance;
            level_count += 1;
        }
    }
    if (level_count > 0) sg.updateBuffer(game.render.level_instances, sg.asRange(level_instances[0..level_count]));
    if (roof_count > 0) sg.updateBuffer(game.render.roof_instance, sg.asRange(roof_instances[0..roof_count]));
    game.render.level_instance_count = level_count;
    game.render.roof_instance_count = roof_count;
}

pub fn uploadWindowInstances() void {
    if (!level.hasGameplayMetadata()) {
        game.render.window_instance_count = 0;
        return;
    }
    var instances: [window_render_capacity]Instance = undefined;
    for (level.windowSlice(), 0..) |window, index| {
        instances[index] = makeInstance(
            window.center,
            window.half_extents,
            0,
            .{ .x = 0.36, .y = 0.76, .z = 0.90, .w = 0.38 },
        );
    }
    if (instances.len > 0) sg.updateBuffer(game.render.window_instances, sg.asRange(&instances));
    game.render.window_instance_count = instances.len;
}

pub fn initRenderer() void {
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
    const actor_mesh = deformed_box.build();
    game.render.actor_vertex_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&actor_mesh.vertices),
        .label = "character-deformed-actor-vertices",
    });
    game.render.actor_index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&actor_mesh.indices),
        .label = "character-deformed-actor-indices",
    });

    game.render.level_instances = sg.makeBuffer(.{
        .size = level.max_boxes * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-level-instances",
    });
    game.render.roof_instance = sg.makeBuffer(.{
        .size = level.max_boxes * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-roof-instance",
    });
    uploadLevelInstances();

    game.render.character_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-dynamic-instance",
    });
    game.render.map_direction_instances = sg.makeBuffer(.{
        .size = map_direction_instance_count * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-direction-instances",
    });
    game.render.map_save_instances = sg.makeBuffer(.{
        .size = map_save_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-save-instances",
    });

    game.render.hunter_instance = sg.makeBuffer(.{
        .size = @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-hunter-instance",
    });
    game.render.impact_instances = sg.makeBuffer(.{
        .size = impact_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-combat-impact-instances",
    });
    game.render.pickup_instances = sg.makeBuffer(.{
        .size = world_render_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-pickup-instances",
    });
    game.render.map_item_instances = sg.makeBuffer(.{
        .size = world_render_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-item-instances",
    });
    game.render.window_instances = sg.makeBuffer(.{
        .size = window_render_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-window-instances",
    });
    uploadWindowInstances();
    game.render.debris_instances = sg.makeBuffer(.{
        .size = debris_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-breakable-debris-instances",
    });
    game.render.route_instances = sg.makeBuffer(.{
        .size = map_route_capacity * @sizeOf(Instance),
        .usage = .{ .stream_update = true },
        .label = "character-map-route-instances",
    });
    game.render.capsule_instances = sg.makeBuffer(.{
        .size = 6 * @sizeOf(Instance),
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

    var actor_layout: sg.VertexLayoutState = .{};
    actor_layout.buffers[0].stride = @sizeOf(deformed_box.Vertex);
    actor_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    actor_layout.attrs[shd.ATTR_deformed_display_position] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "position"),
    };
    actor_layout.attrs[shd.ATTR_deformed_display_normal] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "normal"),
    };
    actor_layout.attrs[shd.ATTR_deformed_display_inst_x] = instanceAttr(0);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_y] = instanceAttr(16);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_z] = instanceAttr(32);
    actor_layout.attrs[shd.ATTR_deformed_display_inst_color] = instanceAttr(48);
    game.render.actor_display_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.deformedDisplayShaderDesc(sg.queryBackend())),
        .layout = actor_layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,

        .cull_mode = .NONE,
        .label = "character-deformed-actor-pipeline",
    });

    var route_layout: sg.VertexLayoutState = .{};
    route_layout.buffers[0] = sshape.vertexBufferLayoutState(builder);
    route_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    route_layout.attrs[shd.ATTR_route_position] = sshape.positionVertexAttrState(builder);
    route_layout.attrs[shd.ATTR_route_inst_x] = instanceAttr(0);
    route_layout.attrs[shd.ATTR_route_inst_y] = instanceAttr(16);
    route_layout.attrs[shd.ATTR_route_inst_z] = instanceAttr(32);
    route_layout.attrs[shd.ATTR_route_inst_color] = instanceAttr(48);
    const route_shader = sg.makeShader(shd.routeShaderDesc(sg.queryBackend()));
    game.render.route_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = false, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-map-route-pipeline",
    });

    game.render.map_item_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-map-item-pipeline",
    });
    game.render.window_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = false, .compare = .LESS_EQUAL },
        .colors = blendingTargets(),
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .label = "character-window-pipeline",
    });
    game.render.map_actor_pipeline = sg.makePipeline(.{
        .shader = route_shader,
        .layout = route_layout,
        .depth = .{ .write_enabled = true, .compare = .LESS_EQUAL },
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .label = "character-map-actor-pipeline",
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

    game.render.reticle_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.reticleShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-aim-reticle-pipeline",
    });
    game.render.ui_rect_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.uiRectShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-inventory-rect-pipeline",
    });
    game.render.hud_circle_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.hudCircleShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-hud-circle-pipeline",
    });
    game.render.axis_gizmo_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.axisGizmoShaderDesc(sg.queryBackend())),
        .depth = .{ .write_enabled = false, .compare = .ALWAYS },
        .colors = blendingTargets(),
        .label = "character-axis-gizmo-pipeline",
    });
    game.render.post_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.postShaderDesc(sg.queryBackend())),
        .label = "character-scene-post-pipeline",
    });
    game.render.scene_sampler = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
        .label = "character-scene-post-sampler",
    });
    game.render.post_bindings.samplers[shd.SMP_scene_sampler] = game.render.scene_sampler;
    recreateSceneTargets(@max(sapp.width(), 1), @max(sapp.height(), 1));

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

    var actor_shadow_layout: sg.VertexLayoutState = .{};
    actor_shadow_layout.buffers[0].stride = @sizeOf(deformed_box.Vertex);
    actor_shadow_layout.buffers[1] = .{ .step_func = .PER_INSTANCE, .stride = @sizeOf(Instance) };
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_position] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(deformed_box.Vertex, "position"),
    };
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_x] = instanceAttr(0);
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_y] = instanceAttr(16);
    actor_shadow_layout.attrs[shd.ATTR_deformed_shadow_inst_z] = instanceAttr(32);
    game.render.actor_shadow_pipeline = sg.makePipeline(.{
        .shader = sg.makeShader(shd.deformedShadowShaderDesc(sg.queryBackend())),
        .layout = actor_shadow_layout,
        .depth = .{ .pixel_format = .DEPTH, .write_enabled = true, .compare = .LESS_EQUAL },
        .colors = noColorTargets(),
        .sample_count = 1,
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .label = "character-deformed-actor-shadow-pipeline",
    });

    const light_position = Vec3{ .x = 20, .y = 32, .z = -24 };

    const light_view = Mat4.lookAtRh(light_position, .{}, .{ .y = 1 });
    const light_projection = Mat4.orthoOffCenterRh(-38, 38, -38, 38, 1, 100);
    game.render.light_view_projection = Mat4.mul(light_view, light_projection);
    game.render.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.035, .g = 0.045, .b = 0.055, .a = 1 } };
}

pub fn recreateSceneTargets(width: i32, height: i32) void {
    if (width == game.render.scene_target_width and height == game.render.scene_target_height) return;
    if (game.render.scene_target_width != 0) {
        sg.destroyView(game.render.scene_color_view);
        sg.destroyView(game.render.scene_depth_view);
        sg.destroyView(game.render.scene_resolve_view);
        sg.destroyView(game.render.scene_texture_view);
        sg.destroyImage(game.render.scene_color_image);
        sg.destroyImage(game.render.scene_depth_image);
        sg.destroyImage(game.render.scene_resolve_image);
    }
    const defaults = sglue.environment().defaults;
    game.render.scene_color_image = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = defaults.color_format,
        .sample_count = defaults.sample_count,
        .label = "character-scene-msaa-color",
    });
    game.render.scene_depth_image = sg.makeImage(.{
        .usage = .{ .depth_stencil_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = defaults.depth_format,
        .sample_count = defaults.sample_count,
        .label = "character-scene-msaa-depth",
    });
    game.render.scene_resolve_image = sg.makeImage(.{
        .usage = .{ .resolve_attachment = true },
        .width = width,
        .height = height,
        .pixel_format = defaults.color_format,
        .sample_count = 1,
        .label = "character-scene-resolve",
    });
    game.render.scene_color_view = sg.makeView(.{ .color_attachment = .{ .image = game.render.scene_color_image } });
    game.render.scene_depth_view = sg.makeView(.{ .depth_stencil_attachment = .{ .image = game.render.scene_depth_image } });
    game.render.scene_resolve_view = sg.makeView(.{ .resolve_attachment = .{ .image = game.render.scene_resolve_image } });
    game.render.scene_texture_view = sg.makeView(.{ .texture = .{ .image = game.render.scene_resolve_image } });
    game.render.scene_pass.attachments.colors[0] = game.render.scene_color_view;
    game.render.scene_pass.attachments.depth_stencil = game.render.scene_depth_view;
    game.render.scene_pass.attachments.resolves[0] = game.render.scene_resolve_view;
    game.render.post_bindings.views[shd.VIEW_scene_color] = game.render.scene_texture_view;
    game.render.scene_target_width = width;
    game.render.scene_target_height = height;
}

pub fn draw(position: b3.b3Pos, frame_time: f32, gameplay_active: bool) void {
    recreateSceneTargets(@max(sapp.width(), 1), @max(sapp.height(), 1));
    const hunter_enabled = level.hunterEnabled();

    const fall = game.condition.fallAmount(game.condition_config);
    const instance = makeYawPitchedInstance(
        .{
            .x = position.x,
            .y = position.y - (character_half_extents.y - character_half_extents.z) * fall,
            .z = position.z,
        },
        character_half_extents,
        game.character.yaw,
        fall * std.math.pi * 0.5,
        rgb(0.20, 0.694, 1.0),
    );
    sg.updateBuffer(game.render.character_instance, sg.asRange(&instance));
    const direction_instances = makeMapDirectionInstances(position, game.character.yaw);
    sg.updateBuffer(game.render.map_direction_instances, sg.asRange(&direction_instances));
    var save_instances: [map_save_capacity]Instance = undefined;
    for (level.current.save_targets[0..level.current.save_target_count], 0..) |target, index| {
        const selected = index == game.map.selected_save;
        save_instances[index] = makeScaledInstance(
            .{ .x = target.x, .y = level.current.ground_y + 0.18, .z = target.z },
            if (selected) .{ .x = 1.2, .y = 0.08, .z = 1.2 } else .{ .x = 0.75, .y = 0.06, .z = 0.75 },
            0,
            if (selected) rgb(1.0, 0.82, 0.22) else rgb(1.0, 0.49, 0.71),
        );
    }
    sg.updateBuffer(game.render.map_save_instances, sg.asRange(save_instances[0..level.current.save_target_count]));

    const hunter_render = if ((game.map.active and game.map.hunter_paused) or game.menu.kind != .none or game.inventory_ui.active or game.condition.hunter_watch_timer > 0)
        game.hunter.position
    else
        hunter.interpolatedPosition(game.hunter, game.clock.alpha());
    if (game.debug.draw_physics) updateCapsuleInstances(position, hunter_render);
    const knocked_down = game.combat.hunterKnockedDown();

    const hunter_capsule_half_height = game.hunter_config.capsule_half_segment + game.hunter_config.capsule_radius;
    const hunter_visual_ground_offset = @max(0, hunter_capsule_half_height - hunter_half_extents.y);
    const hunter_center = Vec3{
        .x = hunter_render.x,
        .y = hunter_render.y - hunter_visual_ground_offset,
        .z = hunter_render.z,
    };
    const hunter_render_color = if (game.combat_visuals.hunter_hit_flash > 0)
        rgb(1.0, 0.78, 0.24)
    else if (knocked_down)
        rgb(0.32, 0.045, 0.05)
    else
        hunter_color;
    const hunter_instance = makeInstance(
        hunter_center,
        hunter_half_extents,
        game.hunter.yaw,
        hunter_render_color,
    );
    sg.updateBuffer(game.render.hunter_instance, sg.asRange(&hunter_instance));
    updateImpactInstances();
    updatePickupInstances();

    const player_sample: deformation.Sample = .{
        .position = .{ .x = position.x, .y = position.y, .z = position.z },
        .yaw = game.character.yaw,
        .height = character_half_extents.y * 2.0,
        .max_speed = game.character_config.run_speed,
        .aiming = game.input.aiming,
    };
    const hunter_sample: deformation.Sample = .{
        .position = hunter_center,
        .yaw = game.hunter.yaw,
        .height = hunter_half_extents.y * 2.0,
        .max_speed = game.hunter_config.far_speed,
    };
    const player_pose = if (gameplay_active and game.condition.canMove())
        game.player_deformation.update(game.deformation_config, player_sample, frame_time)
    else blk: {
        game.player_deformation.reset(player_sample);
        break :blk deformation.Pose{};
    };
    var hunter_pose = if (gameplay_active and !knocked_down)
        game.hunter_deformation.update(game.deformation_config, hunter_sample, frame_time)
    else blk: {
        game.hunter_deformation.reset(hunter_sample);
        break :blk deformation.Pose{};
    };
    const flinch = game.hunter_reaction.amount();
    hunter_pose.bend_x += game.hunter_reaction.side * flinch * 0.20;
    hunter_pose.bend_z += flinch * 0.12;
    hunter_pose.twist += game.hunter_reaction.side * flinch * 0.24;
    hunter_pose.foot_roll -= game.hunter_reaction.side * flinch * 0.035;
    const punch = game.hunter_punch.amount();
    hunter_pose.bend_z += punch * 0.10;
    hunter_pose.twist -= punch * 0.055;
    const knockdown = hunterKnockdownAmount(game.combat.knockdown_timer, game.combat_config.knockdown_duration);
    const breath_phase = (game.combat_config.knockdown_duration - game.combat.knockdown_timer) * 2.0 * std.math.pi * 0.72;
    const breath = @sin(breath_phase) * knockdown;
    hunter_pose.bend_z += knockdown * 0.82 + breath * 0.035;
    hunter_pose.bend_x += breath * 0.018;
    hunter_pose.twist += breath * 0.025;
    hunter_pose.squash += knockdown * 0.055 + breath * 0.008;
    hunter_pose.foot_pitch += knockdown * 0.045;

    const shadow_params: shd.ShadowVsParams = .{ .light_view_projection = game.render.light_view_projection };
    sg.beginPass(game.render.shadow_pass);
    sg.applyPipeline(game.render.shadow_pipeline);
    sg.applyUniforms(shd.UB_shadow_vs_params, sg.asRange(&shadow_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, game.render.level_instance_count, false);
    if (game.map.active) {
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
        if (hunter_enabled) drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    } else {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, false);
        sg.applyPipeline(game.render.actor_shadow_pipeline);
        var actor_shadow_params: shd.DeformedShadowVsParams = .{
            .light_view_projection = game.render.light_view_projection,
            .deformation = poseVector(player_pose),
            .lower_motion = footVector(player_pose),
            .action_motion = actionVector(),
        };
        sg.applyUniforms(shd.UB_deformed_shadow_vs_params, sg.asRange(&actor_shadow_params));
        drawDeformedActor(game.render.character_instance, false);
        if (hunter_enabled) {
            actor_shadow_params.deformation = poseVector(hunter_pose);
            actor_shadow_params.lower_motion = footVector(hunter_pose);
            actor_shadow_params.action_motion = hunterActionVector();
            sg.applyUniforms(shd.UB_deformed_shadow_vs_params, sg.asRange(&actor_shadow_params));
            drawDeformedActor(game.render.hunter_instance, false);
        }
    }
    sg.endPass();

    const vs_params: shd.DisplayVsParams = .{
        .view_projection = game.camera.view_projection,
        .light_view_projection = game.render.light_view_projection,
    };
    const fs_params: shd.DisplayFsParams = .{
        .light_direction = Vec3.normalized(.{ .x = 20, .y = 32, .z = -24 }),
        .eye_position = game.camera.eye,

        .indoor_light_0 = level.current.lights[0],
        .indoor_light_1 = level.current.lights[1],
        .indoor_light_2 = level.current.lights[2],
        .indoor_light_3 = level.current.lights[3],
        .indoor_light_4 = level.current.lights[4],
        .indoor_light_5 = level.current.lights[5],
        .indoor_light_6 = level.current.lights[6],
        .indoor_light_7 = level.current.lights[7],
    };

    game.render.scene_pass.action = game.render.pass_action;
    sg.beginPass(game.render.scene_pass);
    sg.applyPipeline(game.render.display_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    drawInstances(game.render.level_instances, game.render.box_range, 0, game.render.level_instance_count, true);
    if (!game.map.active) {
        drawInstances(game.render.roof_instance, game.render.box_range, 0, game.render.roof_instance_count, true);
    }
    if (game.map.active) {
        const route_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        if (game.map.route_segment_count > 0) {
            drawInstances(game.render.route_instances, game.render.box_range, 0, game.map.route_segment_count, false);
        }
        drawInstances(game.render.map_save_instances, game.render.box_range, 0, level.current.save_target_count, false);
        if (game.render.map_item_instance_count > 0) {
            sg.applyPipeline(game.render.map_item_pipeline);

            sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
            drawInstances(game.render.map_item_instances, game.render.box_range, 0, game.render.map_item_instance_count, false);
        }
        drawInstances(game.render.map_direction_instances, game.render.box_range, 0, map_direction_instance_count, false);

        sg.applyPipeline(game.render.map_actor_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&route_params));
        drawInstances(game.render.character_instance, game.render.box_range, 0, 1, false);
        if (hunter_enabled) drawInstances(game.render.hunter_instance, game.render.box_range, 0, 1, false);
    } else {
        if (game.render.window_instance_count > 0) {
            const window_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
            sg.applyPipeline(game.render.window_pipeline);
            sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&window_params));
            drawInstances(game.render.window_instances, game.render.box_range, 0, game.render.window_instance_count, false);
        }
        sg.applyPipeline(game.render.actor_display_pipeline);
        sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
        var actor_vs_params: shd.DeformedDisplayVsParams = .{
            .view_projection = game.camera.view_projection,
            .light_view_projection = game.render.light_view_projection,
            .deformation = poseVector(player_pose),
            .lower_motion = footVector(player_pose),
            .action_motion = actionVector(),
        };
        sg.applyUniforms(shd.UB_deformed_display_vs_params, sg.asRange(&actor_vs_params));
        drawDeformedActor(game.render.character_instance, true);
        if (hunter_enabled) {
            actor_vs_params.deformation = poseVector(hunter_pose);
            actor_vs_params.lower_motion = footVector(hunter_pose);
            actor_vs_params.action_motion = hunterActionVector();
            sg.applyUniforms(shd.UB_deformed_display_vs_params, sg.asRange(&actor_vs_params));
            drawDeformedActor(game.render.hunter_instance, true);
        }
    }
    if (!game.map.active and game.render.pickup_instance_count > 0) {
        const pickup_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&pickup_params));
        drawInstances(game.render.pickup_instances, game.render.box_range, 0, game.render.pickup_instance_count, false);
    }
    if (!game.map.active and game.render.debris_instance_count > 0) {
        const debris_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&debris_params));
        drawInstances(game.render.debris_instances, game.render.box_range, 0, game.render.debris_instance_count, false);
    }
    if (!game.map.active and game.render.impact_instance_count > 0) {
        const impact_params: shd.RouteVsParams = .{ .view_projection = game.camera.view_projection };
        sg.applyPipeline(game.render.route_pipeline);
        sg.applyUniforms(shd.UB_route_vs_params, sg.asRange(&impact_params));
        drawInstances(game.render.impact_instances, game.render.capsule_sphere_range, 0, game.render.impact_instance_count, false);
    }
    sg.applyPipeline(game.render.debug_pipeline);
    sg.applyUniforms(shd.UB_display_vs_params, sg.asRange(&vs_params));
    sg.applyUniforms(shd.UB_display_fs_params, sg.asRange(&fs_params));
    if (game.debug.draw_physics and !game.map.active) {
        drawInstances(game.render.capsule_instances, game.render.capsule_cylinder_range, 0, 1, true);
        drawInstances(game.render.capsule_instances, game.render.capsule_sphere_range, @sizeOf(Instance), 2, true);
        if (hunter_enabled) {
            drawInstances(game.render.capsule_instances, game.render.capsule_cylinder_range, 3 * @sizeOf(Instance), 1, true);
            drawInstances(game.render.capsule_instances, game.render.capsule_sphere_range, 4 * @sizeOf(Instance), 2, true);
        }
    }
    sg.endPass();

    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    const pause_backdrop = game.menu.kind == .pause or (game.menu.kind == .load and game.menu.load_returns_to_pause);
    const post_params: shd.PostFsParams = .{ .post_options = .{
        .x = 1.0 / @as(f32, @floatFromInt(@max(sapp.width(), 1))),
        .y = 1.0 / @as(f32, @floatFromInt(@max(sapp.height(), 1))),
        .z = fbool(pause_backdrop),
        .w = 0.43,
    } };
    sg.applyPipeline(game.render.post_pipeline);
    sg.applyBindings(game.render.post_bindings);
    sg.applyUniforms(shd.UB_post_fs_params, sg.asRange(&post_params));
    sg.draw(0, 3, 1);

    drawReticle();
    drawInventoryRects();
    drawRootMenuRects();
    drawHudShapes();
    drawHud(position);
    drawAxisGizmo();
    sg.endPass();
    sg.commit();
}

pub fn updatePickupInstances() void {
    if (!level.hasGameplayMetadata()) {
        game.render.pickup_instance_count = 0;
        game.render.map_item_instance_count = 0;
        game.render.debris_instance_count = 0;
        return;
    }
    var instances: [world_render_capacity]Instance = undefined;
    var count: usize = 0;
    for (game.pickup_defs[0..game.pickup_count], 0..) |pickup, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.collected_pickups & bit != 0) continue;
        if (!pickup.item.occupied()) continue;
        const color = itemColor(pickup.item);
        instances[count] = makeInstance(pickup.position, .{ .x = 0.18, .y = 0.18, .z = 0.18 }, 0, color);
        count += 1;
    }
    for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.broken_boxes & bit == 0) {
            instances[count] = makeInstance(
                box.position,
                .{ .x = box.half_extent, .y = box.half_extent, .z = box.half_extent },
                0,
                rgb(1.0, 0.42, 0.06),
            );
        } else {
            const item = boxDropItem(index);
            if (!item.occupied()) continue;
            instances[count] = makeInstance(
                boxDropPosition(index),
                .{ .x = 0.18, .y = 0.18, .z = 0.18 },
                0,
                itemColor(item),
            );
        }
        count += 1;
    }
    for (level.current.doorSlice(), 0..) |door, index| {
        instances[count] = makeDoorInstance(door, index);
        count += 1;
    }
    if (count > 0) sg.updateBuffer(game.render.pickup_instances, sg.asRange(instances[0..count]));
    game.render.pickup_instance_count = count;

    var map_instances: [world_render_capacity]Instance = undefined;
    var map_count: usize = 0;
    for (game.pickup_defs[0..game.pickup_count], 0..) |pickup, index| {
        const collected_bit = @as(u32, 1) << @intCast(index);
        const discovered_bit = collected_bit;
        if (game.collected_pickups & collected_bit != 0 or !mapItemVisible(discovered_bit)) continue;
        if (!pickup.item.occupied()) continue;
        const color = itemColor(pickup.item);
        map_instances[map_count] = makeInstance(
            .{ .x = pickup.position.x, .y = level.current.ground_y + 0.22, .z = pickup.position.z },
            .{ .x = 0.28, .y = 0.06, .z = 0.28 },
            0,
            color,
        );
        map_count += 1;
    }
    for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| {
        const broken_bit = @as(u32, 1) << @intCast(index);
        const discovered_bit = @as(u32, 1) << @intCast(game.pickup_count + index);
        if (!mapItemVisible(discovered_bit)) continue;
        const broken = game.broken_boxes & broken_bit != 0;
        const drop = boxDropItem(index);
        if (broken and !drop.occupied()) continue;
        map_instances[map_count] = makeInstance(
            .{ .x = box.position.x, .y = level.current.ground_y + 0.22, .z = box.position.z },
            .{ .x = 0.28, .y = 0.06, .z = 0.28 },
            0,
            if (broken) itemColor(drop) else rgb(1.0, 0.42, 0.06),
        );
        map_count += 1;
    }
    for (level.current.doorSlice(), 0..) |door, index| {
        map_instances[map_count] = makeInstance(
            .{ .x = door.position.x, .y = level.current.ground_y + 0.26, .z = door.position.z },
            .{ .x = door.width * 0.5, .y = 0.055, .z = @max(door.half_thickness, 0.22) },
            doorBaseYaw(door),
            doorDisplayColor(door, index),
        );
        map_count += 1;
    }
    if (map_count > 0) sg.updateBuffer(game.render.map_item_instances, sg.asRange(map_instances[0..map_count]));
    game.render.map_item_instance_count = map_count;

    var debris_instances: [debris_capacity]Instance = undefined;
    var debris_count: usize = 0;
    for (game.debris) |piece| {
        if (!piece.active) continue;
        debris_instances[debris_count] = makeYawPitchedInstance(
            piece.position,
            .{ .x = 0.11, .y = 0.07, .z = 0.09 },
            piece.yaw,
            piece.pitch,
            rgb(1.0, 0.38, 0.045),
        );
        debris_count += 1;
    }
    if (debris_count > 0) sg.updateBuffer(game.render.debris_instances, sg.asRange(debris_instances[0..debris_count]));
    game.render.debris_instance_count = debris_count;
}

pub fn makeDoorInstance(door: level.DoorDef, index: usize) Instance {
    const pose = doorPose(door, index, door.position.y);
    return makeInstance(
        pose.center,
        .{ .x = door.width * 0.5, .y = door.height * 0.5, .z = door.half_thickness },
        pose.yaw,
        doorDisplayColor(door, index),
    );
}

pub fn updateImpactInstances() void {
    var instances: [impact_capacity]Instance = undefined;
    var count: usize = 0;
    for (game.combat_visuals.impacts) |impact| {
        if (impact.timer <= 0) continue;
        const life = impact.timer / impact_seconds;
        const radius = 0.004 + 0.008 * life;
        instances[count] = makeScaledInstance(
            impact.position,
            .{ .x = radius, .y = radius, .z = radius },
            0,
            rgb(1.0, 0.72, 0.18),
        );
        count += 1;
    }
    if (count > 0) sg.updateBuffer(game.render.impact_instances, sg.asRange(instances[0..count]));
    game.render.impact_instance_count = count;
}

pub fn drawAxisGizmo() void {
    if (!game.debug.draw_physics or game.map.active or game.menu.kind != .none) return;
    const scale = sapp.heightf() / 1080.0;
    const radius = 52.0 * scale;
    const margin = 16.0 * scale;
    const thickness = @max(1.5 * scale, 1.25);

    // camera basis, matching Mat4.lookAtRh with a world-up hint
    const back = Vec3.scale(game.camera.forward, -1);
    const right = Vec3.normalized(Vec3.cross(.{ .x = 0, .y = 1, .z = 0 }, back));
    const up = Vec3.cross(back, right);

    var dirs: [3]Vec4 = undefined;
    const world_axes = [3]Vec3{ .{ .x = 1 }, .{ .y = 1 }, .{ .z = 1 } };
    for (world_axes, 0..) |axis, index| {
        dirs[index] = .{
            .x = Vec3.dot(axis, right) * radius,
            .y = -Vec3.dot(axis, up) * radius,
            .z = Vec3.dot(axis, back),
        };
    }

    const params: shd.AxisGizmoFsParams = .{
        .viewport = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .settings = .{
            .x = sapp.widthf() - margin - radius,
            .y = margin + radius,
            .z = radius,
            .w = thickness,
        },
        .x_axis = dirs[0],
        .y_axis = dirs[1],
        .z_axis = dirs[2],
    };
    sg.applyPipeline(game.render.axis_gizmo_pipeline);
    sg.applyUniforms(shd.UB_axis_gizmo_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

pub fn drawReticle() void {
    if (game.map.active or game.menu.kind != .none or game.inventory_ui.active or game.camera.aim_alpha <= 0.01 or game.combat.reloading()) return;
    const scale = sapp.heightf() / 1080.0;
    const gap = (48.0 + (14.0 - 48.0) * game.combat.focus) * scale;
    const params: shd.ReticleFsParams = .{
        .resolution = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .color = .{ .x = 0.27, .y = 1.0, .z = 0.29, .w = 0.92 * game.camera.aim_alpha },
        .geometry = .{ .x = gap, .y = 26.0 * scale, .z = 3.0 * scale, .w = 3.0 * scale },
    };
    sg.applyPipeline(game.render.reticle_pipeline);
    sg.applyUniforms(shd.UB_reticle_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

pub fn drawUiRect(rect: ScreenRect, fill: Vec4, border: Vec4, border_width: f32) void {
    const params: shd.UiRectFsParams = .{
        .viewport = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .rect = .{ .x = rect.x, .y = rect.y, .z = rect.w, .w = rect.h },
        .fill_color = fill,
        .border_color = border,
        .style = .{ .x = border_width },
    };
    sg.applyPipeline(game.render.ui_rect_pipeline);
    sg.applyUniforms(shd.UB_ui_rect_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

pub fn drawHudCircle(center: math.Vec2, radius: f32, thickness: f32, color: Vec4, with_x: bool) void {
    const params: shd.HudCircleFsParams = .{
        .viewport = .{ .x = sapp.widthf(), .y = sapp.heightf() },
        .geometry = .{ .x = center.x, .y = center.y, .z = radius, .w = thickness },
        .color = color,
        .style = .{ .x = fbool(with_x) },
    };
    sg.applyPipeline(game.render.hud_circle_pipeline);
    sg.applyUniforms(shd.UB_hud_circle_fs_params, sg.asRange(&params));
    sg.draw(0, 3, 1);
}

pub fn interactionPromptCenter() math.Vec2 {
    return .{ .x = sapp.widthf() * 0.5 - 150, .y = sapp.heightf() * 0.79 };
}

pub fn mapHoverName() ?[]const u8 {
    if (!game.map.active) return null;
    if (!level.hasGameplayMetadata()) return null;
    const world = mapWorldAtScreen(game.map.cursor.x, game.map.cursor.y);
    for (game.pickup_defs[0..game.pickup_count], 0..) |pickup, index| {
        const item_bit = @as(u32, 1) << @intCast(index);
        if (!mapItemVisible(item_bit) or game.collected_pickups & item_bit != 0) continue;
        const dx = world.x - pickup.position.x;
        const dz = world.z - pickup.position.z;
        if (dx * dx + dz * dz <= 0.8 * 0.8) return pickup.name;
    }
    for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| {
        const discovered_bit = @as(u32, 1) << @intCast(game.pickup_count + index);
        const broken_bit = @as(u32, 1) << @intCast(index);
        if (!mapItemVisible(discovered_bit)) continue;
        const broken = game.broken_boxes & broken_bit != 0;
        const drop = boxDropItem(index);
        if (broken and !drop.occupied()) continue;
        const dx = world.x - box.position.x;
        const dz = world.z - box.position.z;
        if (dx * dx + dz * dz <= 0.9 * 0.9) return if (broken) itemName(drop) else box.name;
    }
    for (level.current.save_fixtures[0..level.current.save_fixture_count]) |fixture| {
        const dx = world.x - fixture.x;
        const dz = world.z - fixture.z;
        if (dx * dx + dz * dz <= 1.0) return "Typewriter";
    }
    return null;
}

pub fn mapTooltipRect() ScreenRect {
    const width: f32 = 176;
    const height: f32 = 32;
    return .{
        .x = std.math.clamp(game.map.cursor.x + 20, 8, @max(8, sapp.widthf() - width - 8)),
        .y = std.math.clamp(game.map.cursor.y + 18, 8, @max(8, sapp.heightf() - height - 8)),
        .w = width,
        .h = height,
    };
}

pub fn drawHudShapes() void {
    if (game.map.active) {
        if (mapHoverName() != null) {
            drawUiRect(
                mapTooltipRect(),
                .{ .x = 0.035, .y = 0.042, .z = 0.048, .w = 0.94 },
                .{ .x = 0.74, .y = 0.76, .z = 0.77, .w = 1 },
                2,
            );
        }
        drawHudCircle(game.map.cursor, 11, 2, .{ .x = 1, .y = 1, .z = 1, .w = 0.95 }, false);
        return;
    }
    const target = game.interaction_target orelse return;
    const center = interactionPromptCenter();
    drawHudCircle(center, 15, 2.2, .{ .x = 1, .y = 1, .z = 1, .w = 0.98 }, false);
    const color = targetColor(target);
    drawUiRect(
        .{ .x = center.x + 27, .y = center.y - 10, .w = 20, .h = 20 },
        color,
        .{ .x = 0.9, .y = 0.9, .z = 0.88, .w = 1 },
        1.5,
    );
}

pub fn drawInventoryRects() void {
    if (!game.inventory_ui.active) return;
    drawUiRect(
        .{ .x = 0, .y = 0, .w = sapp.widthf(), .h = sapp.heightf() },
        .{ .x = 0.025, .y = 0.032, .z = 0.040, .w = 0.90 },
        .{},
        0,
    );
    const layout = inventoryLayout();
    const grid_width = layout.cell * @as(f32, @floatFromInt(inventory.columns)) + layout.gap * @as(f32, @floatFromInt(inventory.columns - 1));
    const grid_height = layout.cell * @as(f32, @floatFromInt(inventory.rows)) + layout.gap * @as(f32, @floatFromInt(inventory.rows - 1));
    drawUiRect(
        .{ .x = layout.left - 18, .y = layout.top - 18, .w = grid_width + 36, .h = grid_height + 36 },
        .{ .x = 0.08, .y = 0.09, .z = 0.10, .w = 0.98 },
        .{ .x = 0.34, .y = 0.36, .z = 0.37, .w = 1 },
        2,
    );
    for (0..inventory.cell_count) |cell| {
        const rect = inventoryCellRect(layout, cell);
        const selected = game.inventory_ui.moving_cell == cell or game.inventory_ui.popup_cell == cell;
        drawUiRect(
            rect,
            .{ .x = 0.12, .y = 0.13, .z = 0.14, .w = 1 },
            if (selected) .{ .x = 0.95, .y = 0.78, .z = 0.25, .w = 1 } else .{ .x = 0.30, .y = 0.32, .z = 0.33, .w = 1 },
            if (selected) 4 else 2,
        );
        const item = game.inventory.cells[cell];
        if (!item.occupied()) continue;
        const inset: f32 = 9;
        const item_color: Vec4 = switch (item.kind) {
            .ammo => .{ .x = 0.12, .y = 0.43, .z = 0.98, .w = 1 },
            .health => .{ .x = 0.12, .y = 0.76, .z = 0.30, .w = 1 },
            .key_purple => draculaPurple(),
            .key_pink => draculaPink(),
            .key_cyan => draculaCyan(),
            .empty => unreachable,
        };
        drawUiRect(
            .{ .x = rect.x + inset, .y = rect.y + inset, .w = rect.w - inset * 2, .h = rect.h - inset * 2 },
            item_color,
            .{ .x = item_color.x + 0.12, .y = item_color.y + 0.12, .z = @min(item_color.z + 0.12, 1), .w = 1 },
            2,
        );
    }
    if (game.inventory_ui.popup_cell) |cell| {
        const popup = inventoryPopupRect(cell);
        drawUiRect(popup, .{ .x = 0.07, .y = 0.08, .z = 0.09, .w = 1 }, .{ .x = 0.68, .y = 0.70, .z = 0.70, .w = 1 }, 2);
        drawUiRect(
            .{ .x = popup.x + 2, .y = popup.y + popup.h * 0.5 - 1, .w = popup.w - 4, .h = 2 },
            .{ .x = 0.32, .y = 0.34, .z = 0.35, .w = 1 },
            .{},
            0,
        );
    }
}

pub fn drawRootMenuRects() void {
    if (game.menu.kind != .pause and game.menu.kind != .results) return;
    drawUiRect(
        .{ .x = 0, .y = 0, .w = sapp.widthf(), .h = sapp.heightf() },
        if (game.menu.kind == .results)
            .{ .x = 0, .y = 0, .z = 0, .w = 1 }
        else
            .{ .x = 0.01, .y = 0.015, .z = 0.02, .w = 0.62 },
        .{},
        0,
    );
    const count: usize = if (game.menu.kind == .results) 2 else 3;
    for (0..count) |index| {
        const selected = game.menu.slot == index;
        drawUiRect(
            rootMenuItemRect(index),
            if (selected) .{ .x = 0.12, .y = 0.14, .z = 0.15, .w = 0.96 } else .{ .x = 0.055, .y = 0.065, .z = 0.075, .w = 0.90 },
            if (selected) .{ .x = 0.55, .y = 0.93, .z = 0.99, .w = 1 } else .{ .x = 0.30, .y = 0.32, .z = 0.33, .w = 1 },
            if (selected) 3 else 1,
        );
    }
}

pub fn updateCapsuleInstances(player_position: b3.b3Pos, hunter_position: b3.b3Pos) void {
    const player_radius = game.character_config.capsule_radius;
    const player_half_segment = game.character_config.capsule_half_segment;
    const hunter_radius = game.hunter_config.capsule_radius;
    const hunter_half_segment = game.hunter_config.capsule_half_segment;
    const player_color = Vec4{ .x = 0.25, .y = 1.0, .z = 0.55, .w = 0.32 };
    const hunter_color_debug = Vec4{ .x = 1.0, .y = 0.32, .z = 0.18, .w = 0.34 };
    const instances = [_]Instance{
        makeScaledInstance(
            .{ .x = player_position.x, .y = player_position.y, .z = player_position.z },
            .{ .x = player_radius, .y = 2 * player_half_segment, .z = player_radius },
            0,
            player_color,
        ),
        makeScaledInstance(
            .{ .x = player_position.x, .y = player_position.y - player_half_segment, .z = player_position.z },
            .{ .x = player_radius, .y = player_radius, .z = player_radius },
            0,
            player_color,
        ),
        makeScaledInstance(
            .{ .x = player_position.x, .y = player_position.y + player_half_segment, .z = player_position.z },
            .{ .x = player_radius, .y = player_radius, .z = player_radius },
            0,
            player_color,
        ),
        makeScaledInstance(
            .{ .x = hunter_position.x, .y = hunter_position.y, .z = hunter_position.z },
            .{ .x = hunter_radius, .y = 2 * hunter_half_segment, .z = hunter_radius },
            0,
            hunter_color_debug,
        ),
        makeScaledInstance(
            .{ .x = hunter_position.x, .y = hunter_position.y - hunter_half_segment, .z = hunter_position.z },
            .{ .x = hunter_radius, .y = hunter_radius, .z = hunter_radius },
            0,
            hunter_color_debug,
        ),
        makeScaledInstance(
            .{ .x = hunter_position.x, .y = hunter_position.y + hunter_half_segment, .z = hunter_position.z },
            .{ .x = hunter_radius, .y = hunter_radius, .z = hunter_radius },
            0,
            hunter_color_debug,
        ),
    };
    sg.updateBuffer(game.render.capsule_instances, sg.asRange(&instances));
}

pub fn drawHud(position: b3.b3Pos) void {
    const frame_duration = sapp.frameDuration();
    const fps = if (frame_duration > 0) 1.0 / frame_duration else 0;
    sdtx.canvas(sapp.widthf(), sapp.heightf());
    if (game.menu.kind == .pause) {
        drawRootMenuText("PAUSED", &.{ "RETURN TO GAME", "LOAD GAME", "QUIT GAME" });
        sdtx.draw();
        return;
    }
    if (game.menu.kind == .results) {
        drawResultsText();
        sdtx.draw();
        return;
    }
    if (game.menu.kind == .load and game.menu.load_returns_to_pause) {
        drawSaveMenu();
        sdtx.draw();
        return;
    }
    sdtx.pos(1.0, 1.0);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:>6.1}", .{fps});
    if (game.map.active) {
        sdtx.pos(1.0, 3.4);
        sdtx.color3b(255, 220, 120);
        sdtx.print("MAP (click save room, WASD pans, F3 hunter, CTRL/M exits)", .{});
        sdtx.pos(1.0, 4.6);
        sdtx.print("HUNTER: {s} / {s}", .{
            if (game.map.hunter_paused) "PAUSED" else "MOVING",
            if (game.hunter_friendly) "FRIENDLY" else "HOSTILE",
        });
        sdtx.pos(1.0, 5.8);
        sdtx.print("TARGET SAVE: {d}", .{game.map.selected_save + 1});
        switch (game.map.route_status) {
            .arrived => {
                sdtx.pos(1.0, 7.0);
                sdtx.color3b(80, 250, 123);
                sdtx.print("SAVE ROOM REACHED", .{});
            },
            .no_path => {
                sdtx.pos(1.0, 7.0);
                sdtx.color3b(255, 85, 85);
                sdtx.print("NO SAFE ROUTE", .{});
            },
            else => {},
        }
        if (mapHoverName()) |name| {
            const tooltip = mapTooltipRect();
            sdtx.pos((tooltip.x + 10) / 8.0, (tooltip.y + 8) / 8.0);
            sdtx.color3b(245, 245, 240);
            sdtx.print("{s}", .{name});
        }
    } else {
        if (game.debug.draw_physics) {
            sdtx.pos(1.0, 2.2);
            sdtx.print("POS {d:.1} {d:.1} {d:.1}", .{ position.x, position.y, position.z });
        }
        if (game.hunter_friendly) {
            sdtx.pos(1.0, 3.4);
            sdtx.color3b(80, 250, 123);
            sdtx.print("HUNTER FRIENDLY (F2 toggles)", .{});
        }
        if (game.hunter_hold) {
            sdtx.pos(1.0, if (game.hunter_friendly) 3.4 else 2.2);
            sdtx.color3b(255, 170, 60);
            sdtx.print("HUNTER HELD (F4 toggles)", .{});
        }
        const ammo_x = @max(1.0, sapp.widthf() / 8.0 - 16.0);
        const ammo_y = @max(1.0, sapp.heightf() / 8.0 - 2.0);
        sdtx.pos(ammo_x, ammo_y);
        if (game.combat.magazine == 0) {
            sdtx.color3b(255, 76, 76);
        } else {
            sdtx.color3b(225, 235, 225);
        }
        sdtx.print("AMMO {d:>2} / {d:>3}", .{ game.combat.magazine, game.combat.reserve });
        sdtx.pos(ammo_x, ammo_y - 2.4);
        if (game.condition.health <= 35) {
            sdtx.color3b(255, 76, 76);
        } else {
            sdtx.color3b(80, 250, 123);
        }
        sdtx.print("HEALTH {d:>3}%", .{@as(u8, @intFromFloat(@round(game.condition.health)))});
        if (game.combat.reloading()) {
            sdtx.pos(ammo_x, ammo_y - 1.2);
            sdtx.color3b(80, 250, 123);
            sdtx.print("RELOADING", .{});
        }
        if (game.interaction_target) |target| {
            const center = interactionPromptCenter();
            sdtx.pos((center.x - 4) / 8.0, (center.y - 5) / 8.0);
            sdtx.color3b(248, 248, 244);
            sdtx.print("F", .{});
            sdtx.pos((center.x + 57) / 8.0, (center.y - 5) / 8.0);
            sdtx.color3b(248, 248, 244);
            sdtx.print("{s}", .{targetName(target)});
        }
    }
    switch (game.notice) {
        .caught => drawNotice("CAUGHT - RETURNED TO LAST SAVE", 255, 60, 60),
        .saved => drawNotice("GAME SAVED", 80, 250, 123),
        .deleted => drawNotice("SAVE DELETED", 255, 220, 120),
        .save_failed => drawNotice("SAVE FAILED", 255, 60, 60),
        .hunter_friendly => drawNotice("HUNTER FRIENDLY", 80, 250, 123),
        .hunter_hostile => drawNotice("HUNTER HOSTILE", 255, 85, 85),
        .ammo_found => drawNotice("HANDGUN AMMO ADDED", 70, 135, 255),
        .health_found => drawNotice("HEALING ITEM ADDED", 80, 250, 123),
        .key_found => drawNotice("KEY ITEM ADDED", 189, 147, 249),
        .inventory_full => drawNotice("INVENTORY FULL", 255, 220, 120),
        .healed => drawNotice("HEALTH RECOVERED", 80, 250, 123),
        .full_health => drawNotice("HEALTH IS ALREADY FULL", 255, 220, 120),
        .door_locked => drawNotice("DOOR IS LOCKED", 255, 121, 198),
        .door_unlocked => drawNotice("KEY USED - DOOR UNLOCKED", 139, 233, 253),
        .none => {},
    }
    if (game.inventory_ui.active) {
        drawInventoryText();
    } else if (game.menu.kind != .none) {
        drawSaveMenu();
    } else if (!game.map.active and nearSaveFixture()) {
        const prompt = "PRESS F OR LEFT MOUSE TO SAVE";
        sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(prompt.len)) / 2.0, sapp.heightf() / 8.0 - 2.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print(prompt, .{});
    }
    sdtx.draw();
}

pub fn drawRootMenuText(title: []const u8, labels: []const []const u8) void {
    const text_w = sapp.widthf() / 8.0;
    sdtx.pos(text_w * 0.5 - @as(f32, @floatFromInt(title.len)) * 0.5, sapp.heightf() / 16.0 - 10.0);
    sdtx.color3b(248, 248, 242);
    sdtx.print("{s}", .{title});
    for (labels, 0..) |label, index| {
        const rect = rootMenuItemRect(index);
        sdtx.pos((rect.x + 22) / 8.0, (rect.y + 16) / 8.0);
        if (index == game.menu.slot) {
            sdtx.color3b(139, 233, 253);
            sdtx.print("> {s}", .{label});
        } else {
            sdtx.color3b(225, 225, 220);
            sdtx.print("  {s}", .{label});
        }
    }
}

pub fn drawResultsText() void {
    var time_buffer: [32]u8 = undefined;
    const formatted = formatRunTime(&time_buffer, game.run_stats.elapsed_active_seconds);
    const text_w = sapp.widthf() / 8.0;
    const left = text_w * 0.5 - 17.0;
    sdtx.pos(text_w * 0.5 - 6.0, sapp.heightf() / 16.0 - 15.0);
    sdtx.color3b(248, 248, 242);
    sdtx.print("RUN COMPLETE", .{});
    sdtx.pos(left, sapp.heightf() / 16.0 - 11.5);
    sdtx.color3b(189, 147, 249);
    sdtx.print("TIME              {s}", .{formatted});
    sdtx.pos(left, sapp.heightf() / 16.0 - 10.0);
    sdtx.color3b(255, 121, 198);
    sdtx.print("TIMES DAMAGED     {d}", .{game.run_stats.damage_events});
    sdtx.pos(left, sapp.heightf() / 16.0 - 8.5);
    sdtx.color3b(139, 233, 253);
    sdtx.print("DEATHS            {d}", .{game.run_stats.deaths});
    drawRootMenuText("", &.{ "RESTART RUN", "QUIT GAME" });
}

pub fn formatRunTime(buffer: []u8, elapsed_seconds: f64) []const u8 {
    const tenths: u64 = @intFromFloat(@max(0, elapsed_seconds) * 10.0);
    const hours = tenths / 36_000;
    const minutes = (tenths / 600) % 60;
    const seconds = (tenths / 10) % 60;
    return std.fmt.bufPrint(buffer, "{d:0>2}:{d:0>2}:{d:0>2}.{d}", .{ hours, minutes, seconds, tenths % 10 }) catch "00:00:00.0";
}

pub fn drawInventoryText() void {
    const layout = inventoryLayout();
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 5.2);
    sdtx.color3b(230, 230, 225);
    sdtx.print("INVENTORY", .{});
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 3.8);
    sdtx.color3b(80, 250, 123);
    sdtx.print("CONDITION  {d}%", .{@as(u8, @intFromFloat(@round(game.condition.health)))});
    sdtx.pos(layout.left / 8.0, layout.top / 8.0 - 2.4);
    sdtx.color3b(150, 155, 155);
    sdtx.print("CLICK ITEM, THEN DESTINATION    TAB / I / ESC CLOSE", .{});

    for (game.inventory.cells, 0..) |item, cell| {
        if (!item.occupied()) continue;
        const rect = inventoryCellRect(layout, cell);
        sdtx.pos((rect.x + 13) / 8.0, (rect.y + rect.h - 20) / 8.0);
        sdtx.color3b(255, 255, 255);
        switch (item.kind) {
            .ammo => sdtx.print("{d}", .{item.amount}),
            .health => sdtx.print("HEAL", .{}),
            .key_purple, .key_pink, .key_cyan => sdtx.print("KEY", .{}),
            .empty => {},
        }
    }
    if (game.inventory_ui.moving_cell != null) {
        sdtx.pos(layout.left / 8.0, (layout.top + layout.cell * 4 + layout.gap * 3 + 28) / 8.0);
        sdtx.color3b(255, 220, 120);
        sdtx.print("SELECT A DESTINATION CELL", .{});
    }
    if (game.inventory_ui.popup_cell) |cell| {
        const popup = inventoryPopupRect(cell);
        sdtx.color3b(235, 235, 230);
        sdtx.pos((popup.x + 14) / 8.0, (popup.y + 13) / 8.0);
        sdtx.print("USE", .{});
        sdtx.pos((popup.x + 14) / 8.0, (popup.y + popup.h * 0.5 + 13) / 8.0);
        sdtx.print("MOVE", .{});
    }
}

pub fn drawNotice(text: []const u8, r: u8, g: u8, b: u8) void {
    sdtx.pos(sapp.widthf() / 8.0 / 2.0 - @as(f32, @floatFromInt(text.len)) / 2.0, 2.0);
    sdtx.color3b(r, g, b);
    sdtx.print("{s}", .{text});
}

pub fn drawSaveMenu() void {
    const text_w = sapp.widthf() / 8.0;
    const text_h = sapp.heightf() / 8.0;
    const title = if (game.menu.kind == .save) "SAVE GAME" else "LOAD GAME";
    var line_buffer: [64]u8 = undefined;

    sdtx.pos(text_w / 2.0 - 10.0, text_h / 2.0 - 6.0);
    sdtx.color3b(255, 220, 120);
    sdtx.print("{s}", .{title});
    for (saves.slots, 0..) |slot, index| {
        sdtx.pos(text_w / 2.0 - 12.0, text_h / 2.0 - 4.0 + @as(f32, @floatFromInt(index)));
        if (index == game.menu.slot) {
            sdtx.color3b(80, 250, 123);
            sdtx.print("> ", .{});
        } else {
            sdtx.color3b(255, 255, 255);
            sdtx.print("  ", .{});
        }
        if (slot.occupied) {
            sdtx.print("SLOT {d}   {s}", .{ index + 1, formatTimestamp(&line_buffer, slot.timestamp) });
        } else {
            sdtx.print("SLOT {d}   EMPTY", .{index + 1});
        }
    }
    const footer = "W/S SELECT   SPACE CONFIRM   D DELETE   ESC CANCEL";
    sdtx.pos(text_w / 2.0 - @as(f32, @floatFromInt(footer.len)) / 2.0, text_h / 2.0 + 5.0);
    sdtx.color3b(160, 160, 160);
    sdtx.print(footer, .{});
}

pub fn formatTimestamp(buffer: []u8, timestamp: i64) []const u8 {
    const epoch: std.time.epoch.EpochSeconds = .{ .secs = @intCast(@max(timestamp, 0)) };
    const day = epoch.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch.getDaySeconds();
    return std.fmt.bufPrint(buffer, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
    }) catch "";
}

pub fn poseVector(pose: deformation.Pose) Vec4 {
    return .{ .x = pose.bend_x, .y = pose.bend_z, .z = pose.twist, .w = pose.squash };
}

pub fn footVector(pose: deformation.Pose) Vec4 {
    return .{ .x = pose.foot_roll, .y = pose.foot_pitch, .z = pose.foot_twist, .w = pose.foot_splay };
}

pub fn actionVector() Vec4 {
    return .{ .x = kickAmount(), .y = game.pickup_action.amount() };
}

pub fn hunterActionVector() Vec4 {
    return .{ .y = game.hunter_punch.amount() * 1.2 };
}

pub fn drawDeformedActor(instance_buffer: sg.Buffer, with_shadow_texture: bool) void {
    var bindings: sg.Bindings = .{};
    bindings.vertex_buffers[0] = game.render.actor_vertex_buffer;
    bindings.vertex_buffers[1] = instance_buffer;
    bindings.index_buffer = game.render.actor_index_buffer;
    if (with_shadow_texture) {
        bindings.views[shd.VIEW_shadow_map] = game.render.shadow_view;
        bindings.samplers[shd.SMP_shadow_sampler] = game.render.shadow_sampler;
    }
    sg.applyBindings(bindings);
    sg.draw(0, deformed_box.index_count, 1);
}

pub fn drawInstances(
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

pub fn noColorTargets() [8]sg.ColorTargetState {
    var colors: [8]sg.ColorTargetState = @splat(.{});
    colors[0].pixel_format = .NONE;
    return colors;
}

pub fn blendingTargets() [8]sg.ColorTargetState {
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

pub fn makeInstance(center: Vec3, half: Vec3, yaw: f32, color: Vec4) Instance {
    return makeScaledInstance(center, Vec3.scale(half, 2), yaw, color);
}

pub fn makePitchedInstance(center: Vec3, half: Vec3, pitch: f32, color: Vec4) Instance {
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

pub fn makeOrientedInstance(box: level.Box) Instance {
    const scale = Vec3.scale(box.half_extents, 2);
    return .{
        .x = .{
            .x = box.basis_x.x * scale.x,
            .y = box.basis_y.x * scale.y,
            .z = box.basis_z.x * scale.z,
            .w = box.center.x,
        },
        .y = .{
            .x = box.basis_x.y * scale.x,
            .y = box.basis_y.y * scale.y,
            .z = box.basis_z.y * scale.z,
            .w = box.center.y,
        },
        .z = .{
            .x = box.basis_x.z * scale.x,
            .y = box.basis_y.z * scale.y,
            .z = box.basis_z.z * scale.z,
            .w = box.center.z,
        },
        .color = box.color,
    };
}

pub fn makeScaledInstance(center: Vec3, scale: Vec3, yaw: f32, color: Vec4) Instance {
    const c = @cos(yaw);
    const s = @sin(yaw);

    return .{
        .x = .{ .x = scale.x * c, .y = 0, .z = scale.z * s, .w = center.x },
        .y = .{ .x = 0, .y = scale.y, .z = 0, .w = center.y },
        .z = .{ .x = -scale.x * s, .y = 0, .z = scale.z * c, .w = center.z },
        .color = color,
    };
}

pub fn makeMapDirectionInstances(position: b3.b3Pos, yaw: f32) [map_direction_instance_count]Instance {
    const forward = Vec3{ .x = @sin(yaw), .z = @cos(yaw) };
    const arrow_y = position.y + character_half_extents.y + 0.12;
    const tip = Vec3{
        .x = position.x + forward.x * 0.9,
        .y = arrow_y,
        .z = position.z + forward.z * 0.9,
    };
    const shaft_center = Vec3{
        .x = position.x + forward.x * 0.525,
        .y = arrow_y,
        .z = position.z + forward.z * 0.525,
    };
    const head_length: f32 = 0.36;
    const head_angle: f32 = std.math.pi / 4.0;
    var result: [map_direction_instance_count]Instance = undefined;
    result[0] = makeScaledInstance(shaft_center, .{ .x = 0.08, .y = 0.04, .z = 0.75 }, yaw, map_direction_color);
    for ([_]f32{ -head_angle, head_angle }, 0..) |offset, index| {
        const branch_yaw = yaw + std.math.pi + offset;
        const branch_forward = Vec3{ .x = @sin(branch_yaw), .z = @cos(branch_yaw) };
        const center = Vec3{
            .x = tip.x + branch_forward.x * head_length * 0.5,
            .y = arrow_y,
            .z = tip.z + branch_forward.z * head_length * 0.5,
        };
        result[index + 1] = makeScaledInstance(center, .{ .x = 0.08, .y = 0.04, .z = head_length }, branch_yaw, map_direction_color);
    }
    return result;
}

pub fn instanceAttr(offset: i32) sg.VertexAttrState {
    return .{ .format = .FLOAT4, .buffer_index = 1, .offset = offset };
}

pub fn makeYawPitchedInstance(center: Vec3, half: Vec3, yaw: f32, pitch: f32, color: Vec4) Instance {
    const scale = Vec3.scale(half, 2);
    const cy = @cos(yaw);
    const sy = @sin(yaw);
    const cp = @cos(pitch);
    const sp = @sin(pitch);
    return .{
        .x = .{ .x = cy * scale.x, .y = sy * sp * scale.y, .z = sy * cp * scale.z, .w = center.x },
        .y = .{ .y = cp * scale.y, .z = -sp * scale.z, .w = center.y },
        .z = .{ .x = -sy * scale.x, .y = cy * sp * scale.y, .z = cy * cp * scale.z, .w = center.z },
        .color = color,
    };
}
