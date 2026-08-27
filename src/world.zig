//! Level construction, physics world, doors, and run lifecycle.
//!
//! Owns the Box3D bodies (level boxes, breakables, doors, actor proxies) and
//! the spawn / save / restart logic that re-seats the actors and resets a run.
//! Receives the shared scene state by dependency injection (`init`).

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("level.zig");
const controller = @import("character_controller.zig");
const hunter = @import("hunter.zig");
const combat = @import("combat.zig");
const inventory = @import("inventory.zig");
const player_condition = @import("player_condition.zig");
const navmesh = @import("navmesh.zig");
const saves = @import("saves.zig");
const camera = @import("third_person_camera.zig");
const game_audio = @import("game_audio.zig");
const state = @import("state.zig");
const presentation = @import("presentation.zig");

const sg = sokol.gfx;
const sapp = sokol.app;
const playerActionActive = state.playerActionActive;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

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
const mapHalfHeight = presentation.mapHalfHeight;
const mapHalfWidth = presentation.mapHalfWidth;
const mapWorldAtScreen = presentation.mapWorldAtScreen;
const nearSaveFixture = presentation.nearSaveFixture;

pub fn initPhysics() void {
    // Give every visible, collidable level box and stair step a Box3D body so
    // the character and camera can collide against them.
    var world_def = b3.b3DefaultWorldDef();
    game.world = b3.b3CreateWorld(&world_def);
    for (level.current.boxSlice()) |box| if (box.collidable) addStaticBox(box);
    game.breakable_bodies = @splat(b3.b3_nullBodyId);
    game.door_bodies = @splat(b3.b3_nullBodyId);
    game.door_anchor_bodies = @splat(b3.b3_nullBodyId);
    game.door_joints = @splat(b3.b3_nullJointId);
    if (level.hasGameplayMetadata()) {
        for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| game.breakable_bodies[index] = addBreakableBody(box);
        for (level.current.doorSlice(), 0..) |door, index| addDoorPhysics(door, index);
    }
    game.player_proxy_body = addActorProxy(game.character_config.capsule_half_segment, game.character_config.capsule_radius, controller.player_query_category);
    game.hunter_proxy_body = addActorProxy(game.hunter_config.capsule_half_segment, game.hunter_config.capsule_radius, controller.hunter_query_category);
}

pub fn addStaticBox(box: level.Box) void {
    var body_def = b3.b3DefaultBodyDef();
    body_def.position = .{ .x = box.center.x, .y = box.center.y, .z = box.center.z };
    const orientation = b3.b3Matrix3{
        .cx = .{ .x = box.basis_x.x, .y = box.basis_x.y, .z = box.basis_x.z },
        .cy = .{ .x = box.basis_y.x, .y = box.basis_y.y, .z = box.basis_y.z },
        .cz = .{ .x = box.basis_z.x, .y = box.basis_z.y, .z = box.basis_z.z },
    };
    body_def.rotation = b3.b3MakeQuatFromMatrix(&orientation);
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    if (box.hunter_block) {
        // Save-room barrier: only the hunter's capsule collides with it.
        shape_def.filter.categoryBits = controller.hunter_block_category;
        shape_def.filter.maskBits = controller.hunter_query_category;
    } else {
        // The character and camera query these boxes; other objects ignore them.
        shape_def.filter.categoryBits = controller.level_category;
        shape_def.filter.maskBits = controller.player_query_category | camera.camera_query_category | controller.hunter_query_category;
    }
    var hull = b3.b3MakeBoxHull(box.half_extents.x, box.half_extents.y, box.half_extents.z);
    _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
}

pub fn addBreakableBody(box: BreakableDef) b3.b3BodyId {
    var body_def = b3.b3DefaultBodyDef();
    body_def.position = .{ .x = box.position.x, .y = box.position.y, .z = box.position.z };
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    shape_def.filter.categoryBits = controller.level_category;
    shape_def.filter.maskBits = controller.player_query_category | camera.camera_query_category | controller.hunter_query_category;
    var hull = b3.b3MakeBoxHull(box.half_extent, box.half_extent, box.half_extent);
    _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);
    return body;
}

pub fn addActorProxy(half_segment: f32, radius: f32, category: u64) b3.b3BodyId {
    var body_def = b3.b3DefaultBodyDef();
    body_def.type = @intCast(b3.b3_kinematicBody);
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    shape_def.filter.categoryBits = category;
    shape_def.filter.maskBits = controller.door_category | if (category == controller.player_query_category)
        controller.hunter_query_category
    else
        controller.player_query_category;
    var capsule = b3.b3Capsule{
        .center1 = .{ .y = -half_segment },
        .center2 = .{ .y = half_segment },
        .radius = radius,
    };
    _ = b3.b3CreateCapsuleShape(body, &shape_def, &capsule);
    return body;
}

pub fn setBreakableCollision(index: usize, enabled: bool) void {
    const body = game.breakable_bodies[index];
    if (!b3.b3Body_IsValid(body) or b3.b3Body_IsEnabled(body) == enabled) return;
    if (enabled) b3.b3Body_Enable(body) else b3.b3Body_Disable(body);
}

pub fn syncBreakableCollision() void {
    for (game.breakable_defs[0..game.breakable_count], 0..) |_, index| {
        const bit = @as(u32, 1) << @intCast(index);
        setBreakableCollision(index, game.broken_boxes & bit == 0);
    }
}

pub fn yawRotation(yaw: f32) b3.b3Quat {
    const half_yaw = yaw * 0.5;
    return .{ .v = .{ .y = @sin(half_yaw) }, .s = @cos(half_yaw) };
}

pub fn chooseDoorHingeSign(door: level.DoorDef) f32 {
    const negative_score = doorHingeObstructionScore(door, -1);
    const positive_score = doorHingeObstructionScore(door, 1);
    return if (positive_score + 0.001 < negative_score) 1 else -1;
}

pub fn doorHingeObstructionScore(door: level.DoorDef, sign: f32) f32 {
    const hinge_x = door.position.x + (if (door.axis == .x) sign * door.width * 0.5 else 0);
    const hinge_z = door.position.z + (if (door.axis == .z) sign * door.width * 0.5 else 0);
    var score: f32 = 0;
    for (level.current.boxSlice()) |box| {
        if (!box.collidable or box.is_roof or box.hunter_block) continue;
        if (box.center.y + box.half_extents.y <= level.current.ground_y or box.center.y - box.half_extents.y >= door.position.y + door.height * 0.5) continue;
        const parallel_to_door = if (door.axis == .x)
            box.half_extents.x > box.half_extents.z
        else
            box.half_extents.z > box.half_extents.x;
        if (parallel_to_door) continue;
        const dx = @max(@abs(hinge_x - box.center.x) - box.half_extents.x, 0);
        const dz = @max(@abs(hinge_z - box.center.z) - box.half_extents.z, 0);
        const distance = std.math.hypot(dx, dz);
        if (distance < 0.35) score += 0.35 - distance;
    }
    return score;
}

pub fn addDoorPhysics(door: level.DoorDef, index: usize) void {
    const yaw = doorBaseYaw(door);
    const rotation = yawRotation(yaw);
    game.door_hinge_sign[index] = chooseDoorHingeSign(door);
    const hinge = doorHingePosition(door, index, door.position.y);

    var anchor_def = b3.b3DefaultBodyDef();
    anchor_def.position = .{ .x = hinge.x, .y = hinge.y, .z = hinge.z };
    const anchor = b3.b3CreateBody(game.world, &anchor_def);

    var body_def = b3.b3DefaultBodyDef();
    body_def.type = @intCast(b3.b3_dynamicBody);
    body_def.position = .{ .x = door.position.x, .y = door.position.y, .z = door.position.z };
    body_def.rotation = rotation;
    body_def.angularDamping = door_angular_damping;
    const body = b3.b3CreateBody(game.world, &body_def);
    var shape_def = b3.b3DefaultShapeDef();
    shape_def.density = door_density;
    shape_def.filter.categoryBits = controller.door_category;
    shape_def.filter.maskBits = controller.player_query_category | controller.hunter_query_category | camera.camera_query_category;
    var hull = b3.b3MakeBoxHull(
        door.width * 0.5 - door_physics_edge_clearance,
        door.height * 0.5 - door_physics_vertical_clearance,
        door.half_thickness,
    );
    _ = b3.b3CreateHullShape(body, &shape_def, &hull.base);

    game.door_anchor_bodies[index] = anchor;
    game.door_bodies[index] = body;
    replaceDoorJoint(index, door.lock == .none);
}

pub fn replaceDoorJoint(index: usize, unlocked: bool) void {
    const old_joint = game.door_joints[index];
    if (b3.b3Joint_IsValid(old_joint)) b3.b3DestroyJoint(old_joint, true);

    // Revolute joints rotate around their local Z axis. Rotate both joint
    // frames so that axis becomes world Y, while keeping their initial frames
    // coincident for either authored door orientation.
    const door = level.current.doors[index];
    const rotation = yawRotation(doorBaseYaw(door));
    const vertical_hinge_frame = b3.b3Quat{ .v = .{ .x = -@sin(std.math.pi * 0.25) }, .s = @cos(std.math.pi * 0.25) };
    var joint_def = b3.b3DefaultRevoluteJointDef();
    joint_def.base.bodyIdA = game.door_anchor_bodies[index];
    joint_def.base.bodyIdB = game.door_bodies[index];
    joint_def.base.localFrameA = b3.b3Transform_identity;
    joint_def.base.localFrameA.q = vertical_hinge_frame;
    joint_def.base.localFrameB = b3.b3Transform_identity;
    joint_def.base.localFrameB.p = .{ .x = game.door_hinge_sign[index] * door.width * 0.5 };
    joint_def.base.localFrameB.q = b3.b3MulQuat(b3.b3Conjugate(rotation), vertical_hinge_frame);
    joint_def.enableSpring = true;
    joint_def.hertz = door_spring_hertz;
    joint_def.dampingRatio = door_spring_damping;
    joint_def.targetAngle = 0;
    joint_def.enableLimit = true;
    joint_def.lowerAngle = if (unlocked) -door_limit_radians else 0;
    joint_def.upperAngle = if (unlocked) door_limit_radians else 0;
    game.door_joints[index] = b3.b3CreateRevoluteJoint(game.world, &joint_def);
}

pub fn restoreDoorState() void {
    for (level.current.doorSlice(), 0..) |door, index| {
        const body = game.door_bodies[index];
        if (!b3.b3Body_IsValid(body)) continue;
        b3.b3Body_SetTransform(body, .{ .x = door.position.x, .y = door.position.y, .z = door.position.z }, yawRotation(doorBaseYaw(door)));
        b3.b3Body_SetLinearVelocity(body, .{});
        b3.b3Body_SetAngularVelocity(body, .{});
        replaceDoorJoint(index, doorIsUnlocked(door, index));
        b3.b3Body_SetAwake(body, true);
        game.door_previous_angle[index] = 0;
        game.door_current_angle[index] = 0;
        game.door_ai_push_cooldown[index] = 0;
    }
    resetActorProxies();
    navmesh.buildLevel(game.unlocked_doors);
}

pub fn resetActorProxies() void {
    setProxyTransform(game.player_proxy_body, game.character.position);
    setProxyTransform(game.hunter_proxy_body, game.hunter.position);
}

pub fn setProxyTransform(body: b3.b3BodyId, position: b3.b3Pos) void {
    if (!b3.b3Body_IsValid(body)) return;
    b3.b3Body_SetTransform(body, position, b3.b3Quat_identity);
    b3.b3Body_SetLinearVelocity(body, .{});
}

pub fn targetProxy(body: b3.b3BodyId, previous: b3.b3Pos, current: b3.b3Pos) void {
    if (!b3.b3Body_IsValid(body)) return;
    b3.b3Body_SetTransform(body, previous, b3.b3Quat_identity);
    b3.b3Body_SetTargetTransform(body, .{ .p = .{ .x = current.x, .y = current.y, .z = current.z }, .q = b3.b3Quat_identity }, @floatCast(fixed_dt), true);
}

pub fn pushDoorsFromPlayerMovement(dt: f32) void {
    if (!level.hasGameplayMetadata()) return;
    const move_x = @as(f32, @floatFromInt(@intFromBool(game.input.right))) - @as(f32, @floatFromInt(@intFromBool(game.input.left)));
    const move_y = @as(f32, @floatFromInt(@intFromBool(game.input.forward))) - @as(f32, @floatFromInt(@intFromBool(game.input.back)));
    const move_length = std.math.hypot(move_x, move_y);
    if (move_length < 0.001) return;
    const inverse_length = 1.0 / @max(move_length, 1.0);
    const wish = b3.b3Vec3{
        .x = (game.camera.basis.forward.x * move_y + game.camera.basis.right.x * move_x) * inverse_length,
        .z = (game.camera.basis.forward.z * move_y + game.camera.basis.right.z * move_x) * inverse_length,
    };
    const strength = if (game.input.run and !game.input.aiming) door_run_push_strength else door_walk_push_strength;

    for (level.current.doorSlice(), 0..) |door, index| {
        if (!doorIsUnlocked(door, index)) continue;
        const yaw = doorBaseYaw(door) + game.door_current_angle[index];
        const tangent = b3.b3Vec3{ .x = @cos(yaw), .z = -@sin(yaw) };
        const normal = b3.b3Vec3{ .x = @sin(yaw), .z = @cos(yaw) };
        const hinge = doorHingePosition(door, index, door.position.y);
        const center_direction = -game.door_hinge_sign[index];
        const center_x = hinge.x + tangent.x * door.width * 0.5 * center_direction;
        const center_z = hinge.z + tangent.z * door.width * 0.5 * center_direction;
        const relative_x = game.character.position.x - center_x;
        const relative_z = game.character.position.z - center_z;
        const along = relative_x * tangent.x + relative_z * tangent.z;
        if (@abs(along) > door.width * 0.5 + game.character_config.capsule_radius) continue;
        const normal_distance = relative_x * normal.x + relative_z * normal.z;
        if (@abs(normal_distance) > door.half_thickness + game.character_config.capsule_radius + 0.12) continue;
        const toward_panel = wish.x * normal.x + wish.z * normal.z;
        if (normal_distance * toward_panel >= -0.01) continue;

        const contact_along = std.math.clamp(along, -door.width * 0.5, door.width * 0.5);
        const contact_x = center_x + tangent.x * contact_along;
        const contact_z = center_z + tangent.z * contact_along;
        const radial_x = contact_x - hinge.x;
        const radial_z = contact_z - hinge.z;
        const torque_sign = radial_z * wish.x - radial_x * wish.z;
        if (@abs(torque_sign) < 0.001) continue;
        const leverage = std.math.clamp(@abs(torque_sign) / (door.width * 0.5), 0.35, 1.0);
        const direction: f32 = if (torque_sign >= 0) 1 else -1;
        b3.b3Body_ApplyAngularImpulse(game.door_bodies[index], .{ .y = direction * strength * leverage * dt }, true);
    }
}

pub fn stepDoorPhysics(player_active: bool, hunter_active: bool) void {
    for (level.current.doorSlice(), 0..) |_, index| {
        game.door_previous_angle[index] = game.door_current_angle[index];
        game.door_ai_push_cooldown[index] = @max(0, game.door_ai_push_cooldown[index] - @as(f32, @floatCast(fixed_dt)));
    }

    if (player_active) targetProxy(game.player_proxy_body, game.character.previous_position, game.character.position) else setProxyTransform(game.player_proxy_body, game.character.position);
    if (hunter_active) targetProxy(game.hunter_proxy_body, game.hunter.previous_position, game.hunter.position) else setProxyTransform(game.hunter_proxy_body, game.hunter.position);
    b3.b3World_Step(game.world, @floatCast(fixed_dt), physics_substeps);

    for (level.current.doorSlice(), 0..) |_, index| {
        const joint = game.door_joints[index];
        if (!b3.b3Joint_IsValid(joint)) continue;
        const angle = b3.b3RevoluteJoint_GetAngle(joint);
        game.door_current_angle[index] = angle;
    }
}

pub fn openDoorInHunterPath() void {
    if (!level.hasGameplayMetadata()) return;
    var nearest: ?usize = null;
    var nearest_distance: f32 = 1.65;
    for (level.current.doorSlice(), 0..) |door, index| {
        if (!doorIsUnlocked(door, index) or game.door_ai_push_cooldown[index] > 0) continue;
        if (@abs(game.door_current_angle[index]) > 0.65) continue;
        const dx = door.position.x - game.hunter.position.x;
        const dz = door.position.z - game.hunter.position.z;
        const distance = std.math.hypot(dx, dz);
        if (distance <= nearest_distance) {
            nearest = index;
            nearest_distance = distance;
        }
    }
    // The navmesh decides which doorway the route crosses. Activation itself
    // uses proximity because the next conservative grid waypoint can sit just
    // before the leaf and briefly point away from it.
    if (nearest) |index| {
        applyDoorPush(index, game.hunter.position);
        game.door_ai_push_cooldown[index] = door_ai_push_cooldown_seconds;
    }
}

pub fn applyDoorPush(index: usize, opener: b3.b3Pos) void {
    const door = level.current.doors[index];
    if (!doorIsUnlocked(door, index)) return;
    const opener_side = if (door.axis == .x)
        opener.z - door.position.z
    else
        opener.x - door.position.x;
    const direction: f32 = if (opener_side >= 0) 1 else -1;
    b3.b3Body_ApplyAngularImpulse(game.door_bodies[index], .{ .y = -game.door_hinge_sign[index] * direction * door_push_impulse }, true);
}

pub fn interactDoor(index: usize) void {
    const door = level.current.doors[index];
    const bit = @as(u32, 1) << @intCast(index);
    if (!doorIsUnlocked(door, index)) {
        if (doorKey(door.lock)) |key| {
            if (!game.inventory.consumeOne(key)) {
                game.notice = .door_locked;
                game.notice_timer = notice_seconds;
                return;
            }
            game.unlocked_doors |= bit;
            navmesh.buildLevel(game.unlocked_doors);
            replaceDoorJoint(index, true);
            b3.b3Body_SetAwake(game.door_bodies[index], true);
            game.notice = .door_unlocked;
            game.notice_timer = notice_seconds;
        }
    }

    applyDoorPush(index, game.character.position);
    game.character.velocity.x = 0;
    game.character.velocity.z = 0;
    game.interaction_target = null;
}

pub fn loadValidatedLevel() void {
    level.loadDefault();
    game.pickup_count = level.current.pickup_count;
    for (level.current.pickupSlice(), 0..) |pickup, index| {
        game.pickup_defs[index] = .{
            .position = pickup.position,
            .item = pickup.item,
            .name = switch (pickup.item.kind) {
                .ammo => "Handgun Ammo",
                .health => "First Aid Spray",
                .key_purple => "Purple Key",
                .key_pink => "Pink Key",
                .key_cyan => "Cyan Key",
                .empty => "Item",
            },
        };
    }
    game.breakable_count = level.current.breakable_count;
    for (level.current.breakableSlice(), 0..) |box, index| {
        game.breakable_defs[index] = .{ .position = box.position, .half_extent = box.half_extent };
    }
    navmesh.buildLevel(0);
    game.hunter_config.level_center_x = (level.current.walk_min_x + level.current.walk_max_x) * 0.5;
    game.hunter_config.level_center_z = (level.current.walk_min_z + level.current.walk_max_z) * 0.5;
    game.hunter_config.level_half_x = (level.current.walk_max_x - level.current.walk_min_x) * 0.5;
    game.hunter_config.level_half_z = (level.current.walk_max_z - level.current.walk_min_z) * 0.5;
    // Blender geometry uses imported Box3D collision directly and can extend
    // beyond the optional fixed navigation grid.
    if (!navmesh.validateLevel()) @panic("default level failed navmesh validation");
}

pub fn levelPlayerSpawn() b3.b3Pos {
    return .{
        .x = level.current.player_spawn.x,
        .y = level.current.player_spawn.y + player_spawn_y,
        .z = level.current.player_spawn.z,
    };
}

pub fn levelHunterSpawn() b3.b3Pos {
    return .{
        .x = level.current.hunter_spawn.x,
        .y = level.current.hunter_spawn.y + hunter_spawn_y,
        .z = level.current.hunter_spawn.z,
    };
}

pub fn latestSaveIndex() ?usize {
    var best_index: ?usize = null;
    var best_timestamp: i64 = std.math.minInt(i64);
    for (saves.slots, 0..) |slot, index| {
        if (slot.occupied and slot.timestamp > best_timestamp) {
            best_timestamp = slot.timestamp;
            best_index = index;
        }
    }
    return best_index;
}

pub fn placePlayerFromSlot(slot: saves.Slot) void {
    game.character.previous_position = .{ .x = slot.x, .y = slot.y, .z = slot.z };
    game.character.position = .{ .x = slot.x, .y = slot.y, .z = slot.z };
    game.character.velocity = .{};
    game.character.grounded = false;
    game.character.yaw = slot.yaw;
    // Re-seat the shoulder camera behind the restored heading.
    game.camera = .{};
    game.camera.yaw = slot.yaw;
    game.quick_turn = .{};
    game.combat = combat.State.init(game.combat_config, slot.magazine, slot.reserve);
    game.inventory = slot.inventory;
    game.collected_pickups = slot.collected_pickups;
    game.discovered_items = slot.discovered_items;
    game.broken_boxes = slot.broken_boxes;
    game.box_drops_present = slot.box_drops_present;
    game.box_drops_health = slot.box_drops_health;
    game.collected_box_drops = slot.collected_box_drops;
    game.unlocked_doors = slot.unlocked_doors;
    game.run_stats = .{
        .elapsed_active_seconds = slot.elapsed_active_seconds,
        .damage_events = slot.damage_events,
        .deaths = slot.deaths,
    };
    game.condition.reset(game.condition_config, slot.health);
    game.combat_visuals = .{};
    game.player_deformation = .{};
    game.interaction_target = null;
    game.kick = .{};
    game.pickup_action = .{};
    game.debris = @splat(.{});
    game.player_step_distance = 0;
    game.hunter_step_distance = 0;
    syncBreakableCollision();
    restoreDoorState();
}

pub fn placePlayerAtSpawn(spawn: b3.b3Pos, magazine: u16, reserve: u16) void {
    game.character = controller.State.init(spawn);
    game.character.yaw = level.current.player_spawn_yaw;
    game.camera = .{};
    game.camera.yaw = game.character.yaw;
    game.quick_turn = .{};
    game.combat = combat.State.init(game.combat_config, magazine, reserve);
    game.inventory = inventory.State.defaultLoadout(reserve);
    game.collected_pickups = 0;
    game.discovered_items = 0;
    game.broken_boxes = 0;
    game.box_drops_present = 0;
    game.box_drops_health = 0;
    game.collected_box_drops = 0;
    game.unlocked_doors = 0;
    game.condition.reset(game.condition_config, game.condition_config.max_health);
}

pub fn resetRoundTransient() void {
    game.player_deformation = .{};
    game.input = .{};
    game.inventory_ui = .{};
    game.interaction_target = null;
    game.kick = .{};
    game.pickup_action = .{};
    game.debris = @splat(.{});
    game.player_step_distance = 0;
    game.hunter_step_distance = 0;
}

pub fn spawnPlayerAndHunter() void {
    if (latestSaveIndex()) |index| {
        placePlayerFromSlot(saves.slots[index]);
    } else {
        placePlayerAtSpawn(levelPlayerSpawn(), game.combat_config.magazine_capacity, game.combat_config.starting_reserve);
        game.run_stats = .{};
    }
    resetRoundTransient();
    resetHunter(game.character.position);
    game.clock = .{};
    game.map = .{};
    game.menu = .{};
    game.notice = .none;
    game.notice_timer = 0;
    syncBreakableCollision();
    restoreDoorState();
}

pub fn restartRun() void {
    placePlayerAtSpawn(levelPlayerSpawn(), game.combat_config.magazine_capacity, 0);
    game.run_stats = .{};
    resetRoundTransient();
    game.clock = .{};
    game.map = .{};
    game.menu = .{};
    game.notice = .none;
    game.notice_timer = 0;
    resetHunter(game.character.position);
    syncBreakableCollision();
    restoreDoorState();
    sapp.lockMouse(true);
    sapp.showMouse(false);
}

pub fn resetHunter(player_pos: b3.b3Pos) void {
    const hunter_spawn = levelHunterSpawn();
    game.hunter = hunter.State.init(hunter_spawn);
    game.hunter.yaw = level.current.hunter_spawn_yaw;
    _ = player_pos;
    game.hunter.target = hunter.randomPatrolTarget(game.hunter_config, game.hunter.position);
    game.hunter.repath_timer = 0;
    game.combat.hunter_health = game.combat_config.hunter_health;
    game.combat.knockdown_timer = 0;
    game.combat_visuals.hunter_hit_flash = 0;
    game.hunter_reaction = .{};
    game.hunter_punch = .{};
    game.hunter_deformation = .{};
}

pub fn respawnAfterCatch() void {
    const retained_stats = game.run_stats;
    if (latestSaveIndex()) |index| {
        placePlayerFromSlot(saves.slots[index]);
    } else {
        placePlayerAtSpawn(levelPlayerSpawn(), game.combat_config.magazine_capacity, game.combat_config.starting_reserve);
    }
    game.run_stats = retained_stats;

    resetRoundTransient();
    resetHunter(game.character.position);
    game.notice = .caught;
    game.notice_timer = notice_seconds;
    syncBreakableCollision();
    restoreDoorState();
}

pub fn faceHunterTowardPlayer(dt: f32) void {
    game.hunter.previous_position = game.hunter.position;
    const dx = game.character.position.x - game.hunter.position.x;
    const dz = game.character.position.z - game.hunter.position.z;
    const target = std.math.atan2(dx, dz);
    var delta = @mod(target - game.hunter.yaw + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    delta = std.math.clamp(delta, -game.hunter_config.turn_speed * dt, game.hunter_config.turn_speed * dt);
    game.hunter.yaw += delta;
}

pub fn hunterContacted() bool {
    if (game.hunter_friendly or game.combat.hunterKnockedDown() or !game.condition.canBeHit()) return false;
    const dx = game.hunter.position.x - game.character.position.x;
    const dz = game.hunter.position.z - game.character.position.z;
    const radius = game.hunter_config.contact_radius;
    return dx * dx + dz * dz < radius * radius;
}

pub fn seedSpawnRandomness() void {
    var stack_marker: u32 = 0;
    const entropy = @as(u64, @intCast(@intFromPtr(&stack_marker))) ^ @as(u64, @intCast(@intFromPtr(&game)));
    hunter.seedRandom(@truncate(entropy));
}


pub fn updateHunterFootsteps() void {
    const dx = game.hunter.position.x - game.hunter.previous_position.x;
    const dz = game.hunter.position.z - game.hunter.previous_position.z;
    game.hunter_step_distance += std.math.hypot(dx, dz);
    const stride: f32 = 1.05;
    if (game.hunter_step_distance < stride) return;
    game.hunter_step_distance = @mod(game.hunter_step_distance, stride);

    const player_dx = game.hunter.position.x - game.character.position.x;
    const player_dz = game.hunter.position.z - game.character.position.z;
    const distance = std.math.hypot(player_dx, player_dz);
    const volume = std.math.clamp(1.0 - distance / 28.0, 0, 1);
    game.audio.playVolume(.hunter_step, volume);
}
