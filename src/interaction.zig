//! World-object interaction, combat firing, and breakable boxes.
//!
//! Resolves the interaction target in front of the player, drives the pickup /
//! kick actions, spawns box debris, and handles the weapon raycast / impact
//! visuals. Receives the shared scene state by dependency injection (`init`).

const std = @import("std");
const b3 = @import("box3d");
const math = @import("math.zig");
const level = @import("level.zig");
const controller = @import("character_controller.zig");
const combat = @import("combat.zig");
const inventory = @import("inventory.zig");
const camera = @import("third_person_camera.zig");
const player_condition = @import("player_condition.zig");
const game_audio = @import("game_audio.zig");
const state = @import("state.zig");
const presentation = @import("presentation.zig");
const world = @import("world.zig");

const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

var game: *state.GameState = undefined;

pub fn init(g: *state.GameState) void {
    game = g;
}

const setBreakableCollision = world.setBreakableCollision;
const interactDoor = world.interactDoor;
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

pub fn fireShot(focus: f32) void {
    game.audio.play(.gunshot);
    const forward = game.camera.forward;
    const right = Vec3.normalized(Vec3.cross(forward, .{ .y = 1 }));
    const up = Vec3.normalized(Vec3.cross(right, forward));
    const spread = 0.035 + (0.0015 - 0.035) * focus;
    const spread_x = game.combat.randomSigned() * spread;
    const spread_y = game.combat.randomSigned() * spread;
    const direction = Vec3.normalized(Vec3.add(forward, Vec3.add(Vec3.scale(right, spread_x), Vec3.scale(up, spread_y))));
    const translation = Vec3.scale(direction, game.combat_config.shot_range);
    const ray_translation = b3.b3Vec3{ .x = translation.x, .y = translation.y, .z = translation.z };
    const origin = b3.b3Pos{ .x = game.camera.eye.x, .y = game.camera.eye.y, .z = game.camera.eye.z };

    var filter = b3.b3DefaultQueryFilter();
    filter.maskBits = controller.level_category | controller.door_category;
    const level_hit = b3.b3World_CastRayClosest(game.world, origin, ray_translation, filter);
    const level_fraction = if (level_hit.hit) level_hit.fraction else 1.0;
    const box_hit = closestShootableBox(origin, ray_translation, level_fraction + 0.002);

    const hunter_local_origin = b3.b3Vec3{
        .x = origin.x - game.hunter.position.x,
        .y = origin.y - game.hunter.position.y,
        .z = origin.z - game.hunter.position.z,
    };
    const hunter_capsule = b3.b3Capsule{
        .center1 = .{ .y = -game.hunter_config.capsule_half_segment },
        .center2 = .{ .y = game.hunter_config.capsule_half_segment },
        .radius = game.hunter_config.capsule_radius,
    };
    var ray_input: b3.b3RayCastInput = .{
        .origin = hunter_local_origin,
        .translation = ray_translation,
        .maxFraction = level_fraction,
    };
    const hunter_hit = b3.b3RayCastCapsule(&hunter_capsule, &ray_input);
    if (hunter_hit.hit and !game.combat.hunterKnockedDown()) {
        const knocked_down = game.combat.applyHunterHit(game.combat_config, focus);
        game.hunter.previous_position = game.hunter.position;
        game.hunter_punch = .{};
        if (knocked_down) {
            game.hunter_reaction = .{};
            game.audio.play(.hunter_knockdown);
        } else {
            game.hunter_reaction.begin(if (spread_x < 0) -1 else 1);
            game.audio.play(.hunter_hit);
        }
        game.combat_visuals.hunter_hit_flash = hunter_hit_flash_seconds;
    } else if (box_hit) |box_index| {
        _ = breakBox(box_index);
    } else if (level_hit.hit) {
        const hit_body = b3.b3Shape_GetBody(level_hit.shapeId);
        if (breakableIndexForBody(hit_body)) |box_index| {
            _ = breakBox(box_index);
        } else {
            addImpact(.{ .x = level_hit.point.x, .y = level_hit.point.y, .z = level_hit.point.z }, level_hit.normal);
            game.audio.play(.bullet_impact);
        }
    }
    alertHunterToGunshot();
    camera.addRecoil(&game.camera, shot_recoil_radians);
}

pub fn closestShootableBox(origin: b3.b3Pos, translation: b3.b3Vec3, max_fraction: f32) ?usize {
    if (!level.hasGameplayMetadata()) return null;
    var closest_index: ?usize = null;
    var closest_fraction = max_fraction;
    for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.broken_boxes & bit != 0) continue;
        const fraction = rayBoxFraction(origin, translation, box.position, box.half_extent) orelse continue;
        if (fraction > closest_fraction) continue;
        closest_fraction = fraction;
        closest_index = index;
    }
    return closest_index;
}

pub fn rayBoxFraction(origin: b3.b3Pos, translation: b3.b3Vec3, center: Vec3, half_extent: f32) ?f32 {
    var minimum: f32 = 0;
    var maximum: f32 = 1;
    if (!clipRayAxis(origin.x, translation.x, center.x - half_extent, center.x + half_extent, &minimum, &maximum)) return null;
    if (!clipRayAxis(origin.y, translation.y, center.y - half_extent, center.y + half_extent, &minimum, &maximum)) return null;
    if (!clipRayAxis(origin.z, translation.z, center.z - half_extent, center.z + half_extent, &minimum, &maximum)) return null;
    return minimum;
}

pub fn clipRayAxis(origin: f32, translation: f32, lower: f32, upper: f32, minimum: *f32, maximum: *f32) bool {
    if (@abs(translation) < 0.000001) return origin >= lower and origin <= upper;
    var near = (lower - origin) / translation;
    var far = (upper - origin) / translation;
    if (near > far) std.mem.swap(f32, &near, &far);
    minimum.* = @max(minimum.*, near);
    maximum.* = @min(maximum.*, far);
    return minimum.* <= maximum.*;
}

pub fn addImpact(point: Vec3, normal: b3.b3Vec3) void {
    const index = game.combat_visuals.next_impact;
    game.combat_visuals.impacts[index] = .{
        .position = Vec3.add(point, Vec3.scale(.{ .x = normal.x, .y = normal.y, .z = normal.z }, 0.02)),
        .timer = impact_seconds,
    };
    game.combat_visuals.next_impact = (index + 1) % impact_capacity;
}

pub fn alertHunterToGunshot() void {
    if (game.combat.hunterKnockedDown()) return;
    game.hunter.acquired = false;
    game.hunter.investigating = true;
    game.hunter.investigate_timer = game.hunter_config.search_time;
    game.hunter.last_known = game.character.position;
    game.hunter.repath_timer = 0;
}

pub fn updateCombatVisuals(dt: f32) void {
    game.combat_visuals.hunter_hit_flash = @max(0, game.combat_visuals.hunter_hit_flash - dt);
    for (&game.combat_visuals.impacts) |*impact| impact.timer = @max(0, impact.timer - dt);
}

pub fn punchPlayer() void {
    if (!game.condition.punch(game.condition_config)) return;
    game.run_stats.damage_events +|= 1;
    game.hunter_punch.begin();
    game.audio.play(.punch);
    var dx = game.character.position.x - game.hunter.position.x;
    var dz = game.character.position.z - game.hunter.position.z;
    const length = @sqrt(dx * dx + dz * dz);
    if (length > 0.001) {
        dx /= length;
        dz /= length;
    } else {
        dx = @sin(game.hunter.yaw);
        dz = @cos(game.hunter.yaw);
    }
    game.character.velocity = .{
        .x = dx * game.condition_config.launch_speed,
        .y = game.condition_config.lift_speed,
        .z = dz * game.condition_config.launch_speed,
    };
    game.character.grounded = false;
    game.quick_turn = .{};
    game.kick = .{};
    game.pickup_action = .{};
    game.interaction_target = null;
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
}

pub fn updateInteractionTarget() void {
    if (!level.hasGameplayMetadata()) {
        game.interaction_target = null;
        return;
    }
    var best: ?InteractionTarget = null;
    var best_score: f32 = -std.math.inf(f32);
    for (game.pickup_defs[0..game.pickup_count], 0..) |pickup, index| {
        const bit = @as(u32, 1) << @intCast(index);
        if (game.collected_pickups & bit != 0) continue;
        const score = interactionScore(pickup.position, interaction_radius) orelse continue;
        if (score > best_score) {
            best = .{ .kind = .pickup, .index = index };
            best_score = score;
        }
    }
    for (game.breakable_defs[0..game.breakable_count], 0..) |box, index| {
        const bit = @as(u32, 1) << @intCast(index);
        const broken = game.broken_boxes & bit != 0;
        const item = boxDropItem(index);
        if (broken and !item.occupied()) continue;
        const position = if (broken) boxDropPosition(index) else box.position;
        const score = interactionScore(position, interaction_radius) orelse continue;
        if (score > best_score) {
            best = .{ .kind = if (broken) .box_drop else .breakable, .index = index };
            best_score = score;
        }
    }
    for (level.current.doorSlice(), 0..) |door, index| {
        const score = interactionScore(doorPose(door, index, door.position.y).center, door_interaction_radius) orelse continue;
        if (score > best_score) {
            best = .{ .kind = .door, .index = index };
            best_score = score;
        }
    }
    game.interaction_target = best;
    if (best) |target| game.discovered_items |= targetDiscoveryBit(target);
}

pub fn activateInteraction() void {
    const target = game.interaction_target orelse return;
    switch (target.kind) {
        .pickup, .box_drop => {
            const item = targetItem(target) orelse return;
            var inventory_preview = game.inventory;
            if (inventory_preview.add(item) == null) {
                game.notice = .inventory_full;
                game.notice_timer = notice_seconds;
                return;
            }
            const position = targetPosition(target);
            const dx = position.x - game.character.position.x;
            const dz = position.z - game.character.position.z;
            game.character.yaw = std.math.atan2(dx, dz);
            game.character.velocity.x = 0;
            game.character.velocity.z = 0;
            game.pickup_action = .{ .active = true, .target = target };
            game.input = .{};
            game.interaction_target = null;
        },
        .breakable => {
            const box = game.breakable_defs[target.index];
            const dx = box.position.x - game.character.position.x;
            const dz = box.position.z - game.character.position.z;
            game.character.yaw = std.math.atan2(dx, dz);
            game.character.velocity.x = 0;
            game.character.velocity.z = 0;
            game.kick = .{ .active = true, .target = target.index };
            game.input = .{};
            game.interaction_target = null;
        },
        .door => interactDoor(target.index),
    }
}

pub fn targetPosition(target: InteractionTarget) Vec3 {
    return switch (target.kind) {
        .pickup => game.pickup_defs[target.index].position,
        .breakable => game.breakable_defs[target.index].position,
        .box_drop => boxDropPosition(target.index),
        .door => doorPose(level.current.doors[target.index], target.index, level.current.doors[target.index].position.y).center,
    };
}

pub fn targetDiscoveryBit(target: InteractionTarget) u32 {
    const index = switch (target.kind) {
        .pickup => target.index,
        .breakable, .box_drop => game.pickup_count + target.index,
        .door => return 0,
    };
    return @as(u32, 1) << @intCast(index);
}

pub fn inventoryKeyMask() u32 {
    var mask: u32 = 0;
    for (level.current.doorSlice(), 0..) |door, index| {
        const key = doorKey(door.lock) orelse continue;
        if (game.inventory.has(key)) mask |= @as(u32, 1) << @intCast(index);
    }
    return mask;
}

pub fn interactionScore(position: Vec3, radius: f32) ?f32 {
    const dx = position.x - game.character.position.x;
    const dz = position.z - game.character.position.z;
    const distance_squared = dx * dx + dz * dz;
    if (distance_squared > radius * radius) return null;
    const distance = @sqrt(distance_squared);
    if (distance < 0.001) return 10;
    const forward_length = @sqrt(game.camera.forward.x * game.camera.forward.x + game.camera.forward.z * game.camera.forward.z);
    if (forward_length < 0.001) return null;
    const alignment = (dx * game.camera.forward.x + dz * game.camera.forward.z) / (distance * forward_length);
    if (alignment < 0.05) return null;
    return alignment * 4.0 - distance * 0.12;
}

pub fn updateActionsAndDebris(dt: f32) void {
    const pickup_events = game.pickup_action.advance(dt);
    if (pickup_events.collect) collectInteractionItem(game.pickup_action.target);
    if (pickup_events.finished) game.pickup_action = .{};

    if (game.kick.active) {
        game.kick.timer += dt;
        if (!game.kick.broke_box and game.kick.timer >= 0.30) {
            game.kick.broke_box = true;
            _ = breakBox(game.kick.target);
        }
        if (game.kick.timer >= action_duration) game.kick = .{};
    }

    for (&game.debris) |*piece| {
        if (!piece.active) continue;
        piece.timer -= dt;
        if (piece.timer <= 0) {
            piece.* = .{};
            continue;
        }
        piece.velocity.y -= 12.0 * dt;
        piece.position = Vec3.add(piece.position, Vec3.scale(piece.velocity, dt));
        if (piece.position.y < 0.07) {
            piece.position.y = 0.07;
            if (@abs(piece.velocity.y) > 0.45) {
                piece.velocity.y = -piece.velocity.y * 0.34;
            } else {
                piece.velocity.y = 0;
            }
            piece.velocity.x *= 0.82;
            piece.velocity.z *= 0.82;
            piece.angular_velocity *= 0.78;
        }
        piece.yaw += piece.angular_velocity * dt;
        piece.pitch += piece.angular_velocity * 0.73 * dt;
    }
}

pub fn breakBox(index: usize) bool {
    const bit = @as(u32, 1) << @intCast(index);
    if (game.broken_boxes & bit != 0) return false;
    setBreakableCollision(index, false);
    game.broken_boxes |= bit;
    revealBoxDrop(index);
    spawnBoxDebris(index);
    game.audio.play(.box_break);
    return true;
}

pub fn collectInteractionItem(target: InteractionTarget) void {
    const bit = @as(u32, 1) << @intCast(target.index);
    switch (target.kind) {
        .pickup => if (game.collected_pickups & bit != 0) return,
        .box_drop => if (game.collected_box_drops & bit != 0) return,
        .breakable, .door => return,
    }
    const item = targetItem(target) orelse return;
    if (game.inventory.add(item) == null) {
        game.notice = .inventory_full;
        game.notice_timer = notice_seconds;
        return;
    }
    switch (target.kind) {
        .pickup => game.collected_pickups |= bit,
        .box_drop => game.collected_box_drops |= bit,
        .breakable, .door => unreachable,
    }
    if (item.kind == .ammo) {
        game.combat.reserve +|= item.amount;
        game.notice = .ammo_found;
    } else if (item.kind == .health) {
        game.notice = .health_found;
    } else {
        game.notice = .key_found;
    }
    game.audio.play(.pickup);
    game.notice_timer = notice_seconds;
}

pub fn revealBoxDrop(index: usize) void {
    const item = rollBoxDrop(randomUnit(), randomUnit());
    if (!item.occupied()) return;
    const bit = @as(u32, 1) << @intCast(index);
    game.box_drops_present |= bit;
    if (item.kind == .health) game.box_drops_health |= bit;
}

pub fn rollBoxDrop(item_roll: f32, kind_roll: f32) inventory.Item {
    if (item_roll >= box_item_chance) return .{};
    if (kind_roll < box_health_share) return .{ .kind = .health, .amount = 1 };
    return .{ .kind = .ammo, .amount = box_ammo_amount };
}

pub fn randomUnit() f32 {
    return (game.combat.randomSigned() + 1.0) * 0.5;
}

pub fn spawnBoxDebris(box_index: usize) void {
    const origin = game.breakable_defs[box_index].position;
    for (0..8) |piece_index| {
        const angle = @as(f32, @floatFromInt(piece_index)) * std.math.pi * 0.25;
        const direction = Vec3{ .x = @sin(angle), .z = @cos(angle) };
        var slot: ?*Debris = null;
        for (&game.debris) |*candidate| if (!candidate.active) {
            slot = candidate;
            break;
        };
        const piece = slot orelse return;
        const speed = 1.4 + @as(f32, @floatFromInt(piece_index % 3)) * 0.35;
        piece.* = .{
            .active = true,
            .position = .{
                .x = origin.x + direction.x * 0.12,
                .y = origin.y + 0.10 + @as(f32, @floatFromInt(piece_index % 2)) * 0.14,
                .z = origin.z + direction.z * 0.12,
            },
            .velocity = .{
                .x = direction.x * speed,
                .y = 2.8 + @as(f32, @floatFromInt(piece_index % 4)) * 0.38,
                .z = direction.z * speed,
            },
            .yaw = angle,
            .angular_velocity = 3.5 + @as(f32, @floatFromInt(piece_index)) * 0.31,
            .timer = debris_seconds,
        };
    }
}

pub fn breakableIndexForBody(body: b3.b3BodyId) ?usize {
    const body_key = b3.b3StoreBodyId(body);
    for (game.breakable_bodies, 0..) |candidate, index| {
        if (b3.b3Body_IsValid(candidate) and b3.b3StoreBodyId(candidate) == body_key) return index;
    }
    return null;
}
