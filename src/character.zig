//! Data-oriented character mover scene.
//!
//! Plain state is kept separate from the systems that transform it. Box3D owns
//! collision geometry, Sokol owns rendering, and the character capsule moves
//! explicitly while a kinematic proxy transfers its contacts to dynamic doors.

const std = @import("std");
const b3 = @import("box3d");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("level.zig");
const controller = @import("character_controller.zig");
const combat = @import("combat.zig");
const inventory = @import("inventory.zig");
const player_condition = @import("player_condition.zig");
const hunter = @import("hunter.zig");
const deformation = @import("character_deformation.zig");
const deformed_box = @import("deformed_box.zig");
const navmesh = @import("navmesh.zig");
const saves = @import("saves.zig");
const camera = @import("third_person_camera.zig");
const game_audio = @import("game_audio.zig");
const shd = @import("generated/character_shader.zig");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const sshape = sokol.shape;
const sdtx = sokol.debugtext;
const saudio = sokol.audio;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;


const state = @import("state.zig");
const presentation = @import("presentation.zig");
const render = @import("render.zig");
const game = &state.game;
const doorBaseYaw = presentation.doorBaseYaw;
const doorHingePosition = presentation.doorHingePosition;
const doorIsUnlocked = presentation.doorIsUnlocked;
const doorKey = presentation.doorKey;
const doorColor = presentation.doorColor;
const doorDisplayColor = presentation.doorDisplayColor;
const doorPose = presentation.doorPose;
const DoorPose = presentation.DoorPose;
const mapHalfHeight = presentation.mapHalfHeight;
const mapHalfWidth = presentation.mapHalfWidth;
const mapWorldAtScreen = presentation.mapWorldAtScreen;
const nearSaveFixture = presentation.nearSaveFixture;
const draw = render.draw;
const uploadMapRoute = render.uploadMapRoute;
const makeScaledInstance = render.makeScaledInstance;
const initRenderer = render.initRenderer;
const itemName = presentation.itemName;
const itemColor = presentation.itemColor;
const draculaPurple = presentation.draculaPurple;
const draculaPink = presentation.draculaPink;
const draculaCyan = presentation.draculaCyan;
const boxDropPosition = presentation.boxDropPosition;
const boxDropItem = presentation.boxDropItem;
const targetColor = presentation.targetColor;
const targetName = presentation.targetName;
const targetItem = presentation.targetItem;
const doorName = presentation.doorName;
const kickAmount = presentation.kickAmount;
const mapItemVisible = presentation.mapItemVisible;
const hunterKnockdownAmount = presentation.hunterKnockdownAmount;
const rootMenuItemRect = presentation.rootMenuItemRect;
const inventoryLayout = presentation.inventoryLayout;
const inventoryCellRect = presentation.inventoryCellRect;
const inventoryCellAt = presentation.inventoryCellAt;
const inventoryPopupRect = presentation.inventoryPopupRect;
const InventoryLayout = state.InventoryLayout;
const ScreenRect = state.ScreenRect;
const fbool = state.fbool;
const smoothstep = state.smoothstep;
const rgb = state.rgb;

// Re-export the shared declarations so the orchestrator can keep
// referencing them by their short names.
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

fn init() callconv(.c) void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });
    saudio.setup(.{
        .sample_rate = 44_100,
        .num_channels = audio_channel_count,
        .logger = .{ .func = slog.func },
    });
    if (saudio.isvalid()) game.audio.reset(@floatFromInt(saudio.sampleRate()));
    sdtx.setup(.{
        .fonts = init: {
            var fonts: [8]sdtx.FontDesc = @splat(.{});
            fonts[0] = sdtx.fontKc853();
            break :init fonts;
        },
        .logger = .{ .func = slog.func },
    });
    presentation.init(game);
    render.init(game);
    seedSpawnRandomness();
    saves.loadFromCwd(app_io.io());
    loadValidatedLevel();
    initPhysics();
    initRenderer();
    spawnPlayerAndHunter();
    sapp.lockMouse(true);
}

// Advance the quick-turn swing at render cadence. The controller may update on
// fixed simulation ticks, but orientation is presentation-only here; updating
// it once per rendered frame avoids visible 60 Hz stepping on faster displays.
fn updateQuickTurn(dt: f32) void {
    if (!game.quick_turn.active) return;
    game.quick_turn.timer += dt;
    const t = std.math.clamp(game.quick_turn.timer / game.quick_turn.duration, 0, 1);
    // Smoothstep: accelerate into the turn, then ease to a stop.
    const eased = t * t * (3.0 - 2.0 * t);
    game.character.yaw = game.quick_turn.character_start + (game.quick_turn.character_target - game.quick_turn.character_start) * eased;
    game.camera.yaw = game.quick_turn.camera_start + (game.quick_turn.camera_target - game.quick_turn.camera_start) * eased;
    if (t >= 1) game.quick_turn.active = false;
}

// Signed shortest turn from forward toward the held keyboard direction. In
// this yaw convention local right is negative rotation: S+A is +135 degrees,
// S+D is -135 degrees, and S alone uses the deterministic +180-degree case.
fn keyboardQuickTurnDelta(left: bool, right: bool) f32 {
    const lateral = fbool(right) - fbool(left);
    if (lateral == 0) return std.math.pi;
    return std.math.atan2(-lateral, -1.0);
}

fn hasBackwardQuickTurnIntent(input: InputState) bool {
    return input.back and !input.forward;
}

fn beginQuickTurn() void {
    camera.cancelRecenter(&game.camera);
    const delta = keyboardQuickTurnDelta(game.input.left, game.input.right);
    game.quick_turn = .{
        .active = true,
        .character_start = game.character.yaw,
        .character_target = game.character.yaw + delta,
        .camera_start = game.camera.yaw,
        .camera_target = game.camera.yaw + delta,
    };
}

fn frame() callconv(.c) void {
    const frame_time: f32 = @floatCast(@min(sapp.frameDuration(), max_frame_dt));
    game.clock.addFrame(frame_time);
    if (game.notice_timer > 0) {
        game.notice_timer = @max(0, game.notice_timer - frame_time);
        if (game.notice_timer == 0) game.notice = .none;
    }
    updateCombatVisuals(frame_time);

    // Menus freeze the round exactly like map mode does.
    const gameplay_active = !game.map.active and game.menu.kind == .none and !game.inventory_ui.active;
    if (gameplay_active) game.run_stats.elapsed_active_seconds += @as(f64, frame_time);

    const render_position = blk: {
        var ticks: usize = 0;
        while (ticks < max_ticks_per_frame and game.clock.consumeTick()) : (ticks += 1) {
            // Map/menu modes always freeze the player. On the map the hunter
            // is independently paused by default and can be resumed with F3;
            // F4 holds the hunter in every mode.
            const hunter_sim_active = level.hunterEnabled() and !game.hunter_hold and game.menu.kind == .none and !game.inventory_ui.active and (!game.map.active or !game.map.hunter_paused);
            if (gameplay_active) {
                controller.update(
                    game.character_config,
                    &game.character,
                    &game.mover_scratch,
                    game.world,
                    if (game.condition.canMove() and !playerActionActive()) game.input.characterInput() else .{},
                    game.camera.basis,
                    @floatCast(fixed_dt),
                );
                if (game.condition.canMove() and !playerActionActive()) pushDoorsFromPlayerMovement(@floatCast(fixed_dt));
                updatePlayerFootsteps();
                if (game.condition.canMove() and !playerActionActive()) {
                    const reserve_before = game.combat.reserve;
                    const combat_events = combat.update(game.combat_config, &game.combat, .{
                        .aiming = game.input.aiming,
                        .firing = game.input.firing,
                        .reload_pressed = game.input.reload_queued,
                        .moving = game.input.moving(),
                    }, @floatCast(fixed_dt));
                    game.input.reload_queued = false;
                    if (game.combat.reserve < reserve_before) {
                        _ = game.inventory.consumeAmmo(reserve_before - game.combat.reserve);
                    }
                    if (combat_events.reload_started) game.audio.play(.reload_start);
                    if (combat_events.reload_completed) game.audio.play(.reload_complete);
                    for (combat_events.shot_focus[0..combat_events.shot_count]) |shot_focus| fireShot(shot_focus);
                }
                updateActionsAndDebris(@floatCast(fixed_dt));
                const condition_before = game.condition.phase;
                const condition_event = game.condition.update(game.condition_config, game.character.grounded, @floatCast(fixed_dt));
                if (condition_before == .airborne and game.condition.phase == .down) game.audio.play(.body_fall);
                if (condition_event == .defeated) {
                    game.run_stats.deaths +|= 1;
                    respawnAfterCatch();
                    break;
                }
            }
            if (hunter_sim_active) {
                game.hunter_punch.update(@floatCast(fixed_dt));
                game.hunter_reaction.update(@floatCast(fixed_dt));
                if (!game.combat.hunterKnockedDown() and !game.hunter_reaction.active()) {
                    if (game.condition.hunter_watch_timer > 0) {
                        faceHunterTowardPlayer(@floatCast(fixed_dt));
                        hunter.updateIdlePhysics(
                            game.hunter_config,
                            &game.hunter,
                            &game.mover_scratch,
                            game.world,
                            @floatCast(fixed_dt),
                        );
                    } else {
                        hunter.update(
                            game.hunter_config,
                            &game.hunter,
                            &game.mover_scratch,
                            game.world,
                            game.character.position,
                            @floatCast(fixed_dt),
                        );
                        openDoorInHunterPath();
                        updateHunterFootsteps();
                        if (hunterContacted()) punchPlayer();
                    }
                } else {
                    hunter.updateIdlePhysics(
                        game.hunter_config,
                        &game.hunter,
                        &game.mover_scratch,
                        game.world,
                        @floatCast(fixed_dt),
                    );
                }
            }
            if (gameplay_active or hunter_sim_active) stepDoorPhysics(gameplay_active, hunter_sim_active);
        }
        // Discard excess backlog after the bounded catch-up budget.
        if (ticks == max_ticks_per_frame and game.clock.accumulator >= fixed_dt) {
            game.clock.accumulator = @mod(game.clock.accumulator, fixed_dt);
        }
        // The clock keeps consuming ticks while the map or a menu is open so
        // no backlog accumulates. Render the exact paused pose instead of
        // using its cycling interpolation alpha, which would replay the last
        // movement every tick.
        break :blk if (gameplay_active)
            controller.interpolatedPosition(game.character, game.clock.alpha())
        else
            game.character.position;
    };

    if (gameplay_active and game.condition.canMove() and !playerActionActive() and !game.input.aiming) updateQuickTurn(frame_time);

    if (game.map.active) {
        // WASD pans the map camera around the level.
        const pan_speed = map_pan_speed * frame_time;
        game.map.pan.x += (fbool(game.input.right) - fbool(game.input.left)) * pan_speed;
        game.map.pan.z += (fbool(game.input.back) - fbool(game.input.forward)) * pan_speed;
        game.map.pan.x = std.math.clamp(game.map.pan.x, level.current.walk_min_x, level.current.walk_max_x);
        game.map.pan.z = std.math.clamp(game.map.pan.z, level.current.walk_min_z, level.current.walk_max_z);
        game.camera.view_projection = mapViewProjection();
    } else if (game.menu.kind == .none and !game.inventory_ui.active) {
        camera.update(
            game.camera_config,
            &game.camera,
            render_position,
            game.input.mouse_delta,
            game.input.aiming,
            game.world,
            frame_time,
            sapp.widthf() / @max(sapp.heightf(), 1),
        );
        game.input.mouse_delta = .{};
    }
    if (gameplay_active and game.condition.canMove() and !playerActionActive()) {
        updateInteractionTarget();
    } else {
        game.interaction_target = null;
    }
    if (gameplay_active and allRequiredDoorsUnlocked() and level.current.isInEndingArea(game.character.position.x, game.character.position.z)) {
        openResults();
    }
    uploadMapRoute();
    pumpAudio();
    draw(render_position, frame_time, gameplay_active);
}

fn cleanup() callconv(.c) void {
    b3.b3DestroyWorld(game.world);
    game.world = b3.b3_nullWorldId;
    saudio.shutdown();
    sdtx.shutdown();
    sg.shutdown();
}

fn pumpAudio() void {
    if (!saudio.isvalid()) return;
    const channels: usize = @intCast(saudio.channels());
    if (channels == 0 or channels > audio_channel_count) return;

    var expected = saudio.expect();
    while (expected > 0) {
        const frames: usize = @min(@as(usize, @intCast(expected)), audio_buffer_frames);
        game.audio.mix(game.audio_buffer[0 .. frames * channels], frames, channels);
        const pushed = saudio.push(&game.audio_buffer[0], @intCast(frames));
        if (pushed <= 0) break;
        expected -= pushed;
    }
}

fn toggleMap() void {
    if (game.menu.kind != .none or (!game.map.active and playerActionActive())) return;
    game.map.active = !game.map.active;
    if (game.map.active) {
        game.map.hunter_paused = true;
        game.map.pan = .{
            .x = (level.current.walk_min_x + level.current.walk_max_x) * 0.5,
            .z = (level.current.walk_min_z + level.current.walk_max_z) * 0.5,
        };
        game.map.cursor = .{ .x = sapp.widthf() * 0.5, .y = sapp.heightf() * 0.5 };
        rebuildMapRoute();
        game.camera.aim_alpha = 0;
        game.combat.focus = 0;
        game.combat.aiming_last_tick = false;
    }
    sapp.lockMouse(!game.map.active);
    sapp.showMouse(game.map.active);
    // Drop held keys so the map doesn't immediately pan and gameplay doesn't
    // resume with the character moving.
    game.input = .{};
}

fn resetCameraBehindCharacter() void {
    if (game.menu.kind != .none or game.map.active or !game.condition.canMove() or playerActionActive()) return;
    game.input.run = false;
    game.quick_turn.active = false;
    camera.beginRecenter(&game.camera, game.character.yaw);
}

fn activateGameplayInteraction() void {
    if (game.menu.kind != .none or game.map.active or !game.condition.canMove() or playerActionActive()) return;
    if (game.interaction_target != null) {
        activateInteraction();
    } else if (nearSaveFixture()) {
        openMenu(.save);
    }
}

fn event(event_ptr: [*c]const sapp.Event) callconv(.c) void {
    const value = event_ptr[0];
    switch (value.type) {
        .KEY_DOWN, .KEY_UP => {
            const down = value.type == .KEY_DOWN;
            if (game.inventory_ui.active) {
                if (down and !value.key_repeat and (value.key_code == .I or value.key_code == .TAB or value.key_code == .ESCAPE)) closeInventory();
                return;
            }
            switch (value.key_code) {
                .W => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(-1);
                } else {
                    game.input.forward = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .S => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) moveMenuSlot(1);
                } else {
                    game.input.back = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .A => {
                    game.input.left = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .D => if (game.menu.kind != .none) {
                    if (down and !value.key_repeat) deleteSelectedSlot();
                } else {
                    game.input.right = down;
                    if (down) camera.cancelRecenter(&game.camera);
                },
                .LEFT_SHIFT, .RIGHT_SHIFT => if (down and !value.key_repeat and game.input.moving() and game.menu.kind == .none and !game.map.active) {
                    // Arm running when Shift accompanies a movement key.
                    game.input.run = true;
                },
                .LEFT_ALT, .RIGHT_ALT => if (down and !value.key_repeat) resetCameraBehindCharacter(),
                .R => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active) {
                    game.input.reload_queued = true;
                },
                .F1 => if (down and !value.key_repeat) {
                    game.debug.draw_physics = !game.debug.draw_physics;
                },
                .F2 => if (down and !value.key_repeat and game.menu.kind == .none) {
                    game.hunter_friendly = !game.hunter_friendly;
                    game.notice = if (game.hunter_friendly) .hunter_friendly else .hunter_hostile;
                    game.notice_timer = notice_seconds;
                },
                .F3 => if (down and !value.key_repeat and game.map.active) {
                    game.map.hunter_paused = !game.map.hunter_paused;
                },
                .F4 => if (down and !value.key_repeat) {
                    game.hunter_hold = !game.hunter_hold;
                },
                .M, .LEFT_CONTROL, .RIGHT_CONTROL => if (down and !value.key_repeat) toggleMap(),
                .I, .TAB => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active and game.condition.canMove() and !playerActionActive()) {
                    openInventory();
                },
                .F => if (down and !value.key_repeat) activateGameplayInteraction(),
                .UP => if (down and !value.key_repeat and game.menu.kind != .none) {
                    moveMenuSlot(-1);
                },
                .DOWN => if (down and !value.key_repeat and game.menu.kind != .none) {
                    moveMenuSlot(1);
                },
                .SPACE => if (down and !value.key_repeat) {
                    if (game.menu.kind != .none) confirmMenu();
                },
                .P => if (down and !value.key_repeat) openPause(),
                .ENTER => if (down and !value.key_repeat and game.menu.kind != .none) {
                    confirmMenu();
                },
                .Q => if (down and !value.key_repeat) {
                    if (game.menu.kind == .none and !game.map.active and game.condition.canMove() and !playerActionActive() and hasBackwardQuickTurnIntent(game.input) and !game.input.aiming and !game.quick_turn.active) {
                        beginQuickTurn();
                    }
                },
                .ESCAPE => if (down) {
                    if (game.menu.kind == .results) {
                        return;
                    } else if (game.menu.kind != .none) {
                        closeMenu();
                    } else {
                        game.input.aiming = false;
                        game.input.firing = false;
                        sapp.lockMouse(false);
                    }
                },
                else => {},
            }
        },
        .MOUSE_DOWN => switch (value.mouse_button) {
            .LEFT => {
                if (game.inventory_ui.active) {
                    inventoryClick(value.mouse_x, value.mouse_y);
                } else if (game.map.active) {
                    selectMapSaveAt(value.mouse_x, value.mouse_y);
                } else if (game.menu.kind == .pause or game.menu.kind == .results) {
                    menuClick(value.mouse_x, value.mouse_y);
                } else if (game.menu.kind == .none and !playerActionActive()) {
                    sapp.lockMouse(true);
                    if (game.input.aiming) {
                        game.input.firing = true;
                    } else {
                        activateGameplayInteraction();
                    }
                }
            },
            .RIGHT => if (!game.inventory_ui.active and !game.map.active and game.menu.kind == .none and !playerActionActive()) {
                sapp.lockMouse(true);
                game.input.aiming = true;
                game.input.run = false;
                game.quick_turn.active = false;
                camera.cancelRecenter(&game.camera);
            },
            .MIDDLE => if (!game.inventory_ui.active and !game.map.active and game.menu.kind == .none) {
                sapp.lockMouse(true);
                resetCameraBehindCharacter();
            },
            else => if (!game.map.active and game.menu.kind == .none) sapp.lockMouse(true),
        },
        .MOUSE_UP => switch (value.mouse_button) {
            .LEFT => game.input.firing = false,
            .RIGHT => game.input.aiming = false,
            else => {},
        },
        .MOUSE_MOVE => {
            if (game.map.active) {
                game.map.cursor = .{ .x = value.mouse_x, .y = value.mouse_y };
            } else if (game.menu.kind == .pause or game.menu.kind == .results) {
                hoverMenu(value.mouse_x, value.mouse_y);
            } else if (sapp.mouseLocked()) {
                game.input.mouse_delta.x += value.mouse_dx;
                game.input.mouse_delta.y += value.mouse_dy;
            }
        },
        .UNFOCUSED => {
            game.input = .{};
            sapp.lockMouse(false);
            sapp.showMouse(true);
        },
        else => {},
    }
}

fn updateCombatVisuals(dt: f32) void {
    game.combat_visuals.hunter_hit_flash = @max(0, game.combat_visuals.hunter_hit_flash - dt);
    for (&game.combat_visuals.impacts) |*impact| impact.timer = @max(0, impact.timer - dt);
}

fn updatePlayerFootsteps() void {
    if (!game.character.grounded or !game.condition.canMove() or playerActionActive()) {
        if (!game.character.grounded) game.player_step_distance = 0;
        return;
    }
    const dx = game.character.position.x - game.character.previous_position.x;
    const dz = game.character.position.z - game.character.previous_position.z;
    game.player_step_distance += std.math.hypot(dx, dz);
    const stride: f32 = if (game.input.run) 0.92 else if (game.input.aiming) 0.58 else 0.72;
    if (game.player_step_distance >= stride) {
        game.player_step_distance = @mod(game.player_step_distance, stride);
        game.audio.play(.player_step);
    }
}

fn updateHunterFootsteps() void {
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

fn openDoorInHunterPath() void {
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

fn fireShot(focus: f32) void {
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

fn closestShootableBox(origin: b3.b3Pos, translation: b3.b3Vec3, max_fraction: f32) ?usize {
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

fn rayBoxFraction(origin: b3.b3Pos, translation: b3.b3Vec3, center: Vec3, half_extent: f32) ?f32 {
    var minimum: f32 = 0;
    var maximum: f32 = 1;
    if (!clipRayAxis(origin.x, translation.x, center.x - half_extent, center.x + half_extent, &minimum, &maximum)) return null;
    if (!clipRayAxis(origin.y, translation.y, center.y - half_extent, center.y + half_extent, &minimum, &maximum)) return null;
    if (!clipRayAxis(origin.z, translation.z, center.z - half_extent, center.z + half_extent, &minimum, &maximum)) return null;
    return minimum;
}

fn clipRayAxis(origin: f32, translation: f32, lower: f32, upper: f32, minimum: *f32, maximum: *f32) bool {
    if (@abs(translation) < 0.000001) return origin >= lower and origin <= upper;
    var near = (lower - origin) / translation;
    var far = (upper - origin) / translation;
    if (near > far) std.mem.swap(f32, &near, &far);
    minimum.* = @max(minimum.*, near);
    maximum.* = @min(maximum.*, far);
    return minimum.* <= maximum.*;
}

fn addImpact(point: Vec3, normal: b3.b3Vec3) void {
    const index = game.combat_visuals.next_impact;
    game.combat_visuals.impacts[index] = .{
        .position = Vec3.add(point, Vec3.scale(.{ .x = normal.x, .y = normal.y, .z = normal.z }, 0.02)),
        .timer = impact_seconds,
    };
    game.combat_visuals.next_impact = (index + 1) % impact_capacity;
}

fn alertHunterToGunshot() void {
    if (game.combat.hunterKnockedDown()) return;
    game.hunter.acquired = false;
    game.hunter.investigating = true;
    game.hunter.investigate_timer = game.hunter_config.search_time;
    game.hunter.last_known = game.character.position;
    game.hunter.repath_timer = 0;
}

fn initPhysics() void {
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

fn addStaticBox(box: level.Box) void {
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

fn addBreakableBody(box: BreakableDef) b3.b3BodyId {
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

fn addDoorPhysics(door: level.DoorDef, index: usize) void {
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

fn replaceDoorJoint(index: usize, unlocked: bool) void {
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

fn addActorProxy(half_segment: f32, radius: f32, category: u64) b3.b3BodyId {
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

fn setBreakableCollision(index: usize, enabled: bool) void {
    const body = game.breakable_bodies[index];
    if (!b3.b3Body_IsValid(body) or b3.b3Body_IsEnabled(body) == enabled) return;
    if (enabled) b3.b3Body_Enable(body) else b3.b3Body_Disable(body);
}

fn syncBreakableCollision() void {
    for (game.breakable_defs[0..game.breakable_count], 0..) |_, index| {
        const bit = @as(u32, 1) << @intCast(index);
        setBreakableCollision(index, game.broken_boxes & bit == 0);
    }
}


fn yawRotation(yaw: f32) b3.b3Quat {
    const half_yaw = yaw * 0.5;
    return .{ .v = .{ .y = @sin(half_yaw) }, .s = @cos(half_yaw) };
}

fn chooseDoorHingeSign(door: level.DoorDef) f32 {
    const negative_score = doorHingeObstructionScore(door, -1);
    const positive_score = doorHingeObstructionScore(door, 1);
    return if (positive_score + 0.001 < negative_score) 1 else -1;
}

fn doorHingeObstructionScore(door: level.DoorDef, sign: f32) f32 {
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


fn restoreDoorState() void {
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

fn resetActorProxies() void {
    setProxyTransform(game.player_proxy_body, game.character.position);
    setProxyTransform(game.hunter_proxy_body, game.hunter.position);
}

fn setProxyTransform(body: b3.b3BodyId, position: b3.b3Pos) void {
    if (!b3.b3Body_IsValid(body)) return;
    b3.b3Body_SetTransform(body, position, b3.b3Quat_identity);
    b3.b3Body_SetLinearVelocity(body, .{});
}

fn targetProxy(body: b3.b3BodyId, previous: b3.b3Pos, current: b3.b3Pos) void {
    if (!b3.b3Body_IsValid(body)) return;
    b3.b3Body_SetTransform(body, previous, b3.b3Quat_identity);
    b3.b3Body_SetTargetTransform(body, .{ .p = .{ .x = current.x, .y = current.y, .z = current.z }, .q = b3.b3Quat_identity }, @floatCast(fixed_dt), true);
}

// The characters are query-driven capsule movers rather than simulated rigid
// bodies. Their kinematic proxies block a closing leaf, while this contact
// force carries sustained walk/run intent into the hinge after the mover has
// reached the panel and can no longer advance its proxy through it.
fn pushDoorsFromPlayerMovement(dt: f32) void {
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

fn stepDoorPhysics(player_active: bool, hunter_active: bool) void {
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

fn breakableIndexForBody(body: b3.b3BodyId) ?usize {
    const body_key = b3.b3StoreBodyId(body);
    for (game.breakable_bodies, 0..) |candidate, index| {
        if (b3.b3Body_IsValid(candidate) and b3.b3StoreBodyId(candidate) == body_key) return index;
    }
    return null;
}

// Mix ASLR-derived addresses into the PRNG seed: both a stack local and the
// global game state live at different addresses in each process.
fn seedSpawnRandomness() void {
    var stack_marker: u32 = 0;
    const entropy = @as(u64, @intCast(@intFromPtr(&stack_marker))) ^ @as(u64, @intCast(@intFromPtr(&game)));
    hunter.seedRandom(@truncate(entropy));
}

fn loadValidatedLevel() void {
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

fn levelPlayerSpawn() b3.b3Pos {
    return .{
        .x = level.current.player_spawn.x,
        .y = level.current.player_spawn.y + player_spawn_y,
        .z = level.current.player_spawn.z,
    };
}

fn levelHunterSpawn() b3.b3Pos {
    return .{
        .x = level.current.hunter_spawn.x,
        .y = level.current.hunter_spawn.y + hunter_spawn_y,
        .z = level.current.hunter_spawn.z,
    };
}

// Index of the most recently written occupied save slot, if any.
fn latestSaveIndex() ?usize {
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

// Teleport the player onto a recorded pose. The static world never changes,
// so a saved position is always a valid capsule spot.
fn placePlayerFromSlot(slot: saves.Slot) void {
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

// Place the player at the authored spawn with a fresh character, camera,
// weapon, and cleared world-progression bits. `magazine` and `reserve` seed
// the weapon from the caller (0 on a restart, the configured starting reserve
// on a new run or respawn). Run stats and the HUD notice are caller-owned.
fn placePlayerAtSpawn(spawn: b3.b3Pos, magazine: u16, reserve: u16) void {
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

// Clear the transient per-round fields shared by a fresh start, a restart,
// and a respawn. Values the caller owns (ammo, run stats, weapon reserve,
// HUD notice) and the world-sync passes are established around this.
fn resetRoundTransient() void {
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

// Place both actors, then reset the round. The player resumes from the most
// recent save when one exists; otherwise they start at the level's spawn.
fn spawnPlayerAndHunter() void {
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

fn restartRun() void {
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

// Send the hunter back to his authored spawn room facing the player, with a
// fresh patrol destination so he sets off walking immediately.
fn resetHunter(player_pos: b3.b3Pos) void {
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

// The hunter catches the player when their capsules touch horizontally.
fn hunterContacted() bool {
    if (game.hunter_friendly or game.combat.hunterKnockedDown() or !game.condition.canBeHit()) return false;
    const dx = game.hunter.position.x - game.character.position.x;
    const dz = game.hunter.position.z - game.character.position.z;
    const radius = game.hunter_config.contact_radius;
    return dx * dx + dz * dz < radius * radius;
}

fn punchPlayer() void {
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

// During the player's knockdown the hunter holds position and tracks them,
// recreating the deliberate pause after Mr X's punch.
fn faceHunterTowardPlayer(dt: f32) void {
    game.hunter.previous_position = game.hunter.position;
    const dx = game.character.position.x - game.hunter.position.x;
    const dz = game.character.position.z - game.hunter.position.z;
    const target = std.math.atan2(dx, dz);
    var delta = @mod(target - game.hunter.yaw + std.math.pi, 2.0 * std.math.pi) - std.math.pi;
    delta = std.math.clamp(delta, -game.hunter_config.turn_speed * dt, game.hunter_config.turn_speed * dt);
    game.hunter.yaw += delta;
}

fn targetPosition(target: InteractionTarget) Vec3 {
    return switch (target.kind) {
        .pickup => game.pickup_defs[target.index].position,
        .breakable => game.breakable_defs[target.index].position,
        .box_drop => boxDropPosition(target.index),
        .door => doorPose(level.current.doors[target.index], target.index, level.current.doors[target.index].position.y).center,
    };
}



fn targetDiscoveryBit(target: InteractionTarget) u32 {
    const index = switch (target.kind) {
        .pickup => target.index,
        .breakable, .box_drop => game.pickup_count + target.index,
        .door => return 0,
    };
    return @as(u32, 1) << @intCast(index);
}












// Bitmask of locked doors whose key the player carries. A held key makes a
// door traversable for route planning even while its mesh is still closed:
// the player can unlock it on the way.
fn inventoryKeyMask() u32 {
    var mask: u32 = 0;
    for (level.current.doorSlice(), 0..) |door, index| {
        const key = doorKey(door.lock) orelse continue;
        if (game.inventory.has(key)) mask |= @as(u32, 1) << @intCast(index);
    }
    return mask;
}



fn interactionScore(position: Vec3, radius: f32) ?f32 {
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

fn updateInteractionTarget() void {
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

fn activateInteraction() void {
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

fn interactDoor(index: usize) void {
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

fn applyDoorPush(index: usize, opener: b3.b3Pos) void {
    const door = level.current.doors[index];
    if (!doorIsUnlocked(door, index)) return;
    const opener_side = if (door.axis == .x)
        opener.z - door.position.z
    else
        opener.x - door.position.x;
    const direction: f32 = if (opener_side >= 0) 1 else -1;
    b3.b3Body_ApplyAngularImpulse(game.door_bodies[index], .{ .y = -game.door_hinge_sign[index] * direction * door_push_impulse }, true);
}

fn updateActionsAndDebris(dt: f32) void {
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

fn breakBox(index: usize) bool {
    const bit = @as(u32, 1) << @intCast(index);
    if (game.broken_boxes & bit != 0) return false;
    setBreakableCollision(index, false);
    game.broken_boxes |= bit;
    revealBoxDrop(index);
    spawnBoxDebris(index);
    game.audio.play(.box_break);
    return true;
}

fn collectInteractionItem(target: InteractionTarget) void {
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

fn revealBoxDrop(index: usize) void {
    const item = rollBoxDrop(randomUnit(), randomUnit());
    if (!item.occupied()) return;
    const bit = @as(u32, 1) << @intCast(index);
    game.box_drops_present |= bit;
    if (item.kind == .health) game.box_drops_health |= bit;
}

fn rollBoxDrop(item_roll: f32, kind_roll: f32) inventory.Item {
    if (item_roll >= box_item_chance) return .{};
    if (kind_roll < box_health_share) return .{ .kind = .health, .amount = 1 };
    return .{ .kind = .ammo, .amount = box_ammo_amount };
}

fn randomUnit() f32 {
    return (game.combat.randomSigned() + 1.0) * 0.5;
}

fn spawnBoxDebris(box_index: usize) void {
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


fn playerActionActive() bool {
    return game.kick.active or game.pickup_action.active;
}

// Defeated: restore the most recent save (or the initial loadout) and move the
// hunter home so the next chase starts fairly.
fn respawnAfterCatch() void {
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

// True while the character stands within the interaction area of a typewriter.

fn openMenu(kind: MenuKind) void {
    game.menu = .{ .kind = kind, .slot = 0 };
    // Drop held keys so gameplay doesn't resume with the character moving.
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
}

fn closeMenu() void {
    if (game.menu.kind == .load and game.menu.load_returns_to_pause) {
        game.menu = .{ .kind = .pause };
    } else {
        game.menu = .{};
        sapp.lockMouse(true);
        sapp.showMouse(false);
    }
    game.input = .{};
}

fn openPause() void {
    if (game.map.active or game.inventory_ui.active or game.menu.kind == .save or game.menu.kind == .load or game.menu.kind == .results) return;
    if (game.menu.kind == .pause) {
        closeMenu();
        return;
    }
    openMenu(.pause);
    sapp.lockMouse(false);
    sapp.showMouse(true);
}

fn openResults() void {
    game.menu = .{ .kind = .results };
    game.input = .{};
    game.interaction_target = null;
    sapp.lockMouse(false);
    sapp.showMouse(true);
}

fn allRequiredDoorsUnlocked() bool {
    for (level.current.doorSlice(), 0..) |door, index| {
        if (door.lock != .none and !doorIsUnlocked(door, index)) return false;
    }
    return true;
}

fn hoverMenu(x: f32, y: f32) void {
    const count: usize = if (game.menu.kind == .results) 2 else 3;
    for (0..count) |index| {
        if (rootMenuItemRect(index).contains(x, y)) {
            game.menu.slot = index;
            return;
        }
    }
}

fn menuClick(x: f32, y: f32) void {
    hoverMenu(x, y);
    if (rootMenuItemRect(game.menu.slot).contains(x, y)) confirmMenu();
}





fn openInventory() void {
    game.inventory_ui = .{ .active = true };
    game.input = .{};
    game.camera.aim_alpha = 0;
    game.combat.focus = 0;
    game.combat.aiming_last_tick = false;
    sapp.lockMouse(false);
    sapp.showMouse(true);
}

fn closeInventory() void {
    game.inventory_ui = .{};
    game.input = .{};
    sapp.lockMouse(true);
}

fn inventoryClick(x: f32, y: f32) void {
    if (game.inventory_ui.popup_cell) |popup_cell| {
        const popup = inventoryPopupRect(popup_cell);
        if (popup.contains(x, y)) {
            if (y < popup.y + popup.h * 0.5) {
                if (game.inventory.useHealth(
                    popup_cell,
                    &game.condition.health,
                    game.condition_config.max_health,
                    game.condition_config.heal_amount,
                )) {
                    game.notice = .healed;
                    game.audio.play(.heal);
                } else {
                    game.notice = .full_health;
                }
                game.notice_timer = notice_seconds;
            } else {
                game.inventory_ui.moving_cell = popup_cell;
            }
            game.inventory_ui.popup_cell = null;
            return;
        }
        game.inventory_ui.popup_cell = null;
    }

    const cell = inventoryCellAt(x, y) orelse {
        game.inventory_ui.moving_cell = null;
        return;
    };
    if (game.inventory_ui.moving_cell) |from| {
        _ = game.inventory.moveOrSwap(from, cell);
        game.inventory_ui.moving_cell = null;
        return;
    }
    switch (game.inventory.cells[cell].kind) {
        .empty => {},
        .ammo, .key_purple, .key_pink, .key_cyan => game.inventory_ui.moving_cell = cell,
        .health => game.inventory_ui.popup_cell = cell,
    }
}

fn moveMenuSlot(delta: i32) void {
    const count: i32 = switch (game.menu.kind) {
        .pause => 3,
        .results => 2,
        .save, .load => saves.slot_count,
        .none => return,
    };
    const current: i32 = @intCast(game.menu.slot);
    game.menu.slot = @intCast(@mod(current + delta + count, count));
}

// Clear the selected slot (when it holds a save) and persist the change.
fn deleteSelectedSlot() void {
    if (game.menu.kind != .save and game.menu.kind != .load) return;
    if (!saves.slots[game.menu.slot].occupied) return;
    saves.slots[game.menu.slot] = .{};
    if (saves.writeToCwd(app_io.io())) |_| {
        game.notice = .deleted;
        game.notice_timer = notice_seconds;
    } else |_| {
        // The slot is cleared in memory either way, but flag the disk trouble.
        game.notice = .save_failed;
        game.notice_timer = notice_seconds;
    }
}

// Apply the highlighted slot: write the player's pose into it (save) or
// teleport the player to it (load), then close the window.
fn confirmMenu() void {
    switch (game.menu.kind) {
        .none => return,
        .save => {
            saves.slots[game.menu.slot] = .{
                .occupied = true,
                .x = game.character.position.x,
                .y = game.character.position.y,
                .z = game.character.position.z,
                .yaw = game.character.yaw,
                .magazine = game.combat.magazine,
                .reserve = game.combat.reserve,
                .health = game.condition.health,
                .inventory = game.inventory,
                .collected_pickups = game.collected_pickups,
                .discovered_items = game.discovered_items,
                .broken_boxes = game.broken_boxes,
                .box_drops_present = game.box_drops_present,
                .box_drops_health = game.box_drops_health,
                .collected_box_drops = game.collected_box_drops,
                .unlocked_doors = game.unlocked_doors,
                .elapsed_active_seconds = game.run_stats.elapsed_active_seconds,
                .damage_events = game.run_stats.damage_events,
                .deaths = game.run_stats.deaths,
                .timestamp = std.Io.Timestamp.now(app_io.io(), .real).toSeconds(),
            };
            if (saves.writeToCwd(app_io.io())) |_| {
                game.notice = .saved;
                game.notice_timer = notice_seconds;
            } else |_| {
                game.notice = .save_failed;
                game.notice_timer = notice_seconds;
            }
        },
        .load => {
            const slot = saves.slots[game.menu.slot];
            if (slot.occupied) {
                placePlayerFromSlot(slot);
                game.menu.load_returns_to_pause = false;
            }
        },
        .pause => {
            switch (game.menu.slot) {
                0 => closeMenu(),
                1 => game.menu = .{ .kind = .load, .load_returns_to_pause = true },
                2 => sapp.requestQuit(),
                else => unreachable,
            }
            return;
        },
        .results => switch (game.menu.slot) {
            0 => restartRun(),
            1 => sapp.requestQuit(),
            else => unreachable,
        },
    }
    if (game.menu.kind == .save or game.menu.kind == .load) closeMenu();
}

fn rebuildMapRoute() void {
    game.map.route_len = 0;
    game.map.route_segment_count = 0;
    game.map.route_upload_pending = true;
    // Plan through locked doors the player can unlock on the way. This only
    // reopens doors in the player grid; the hunter must still respect them.
    navmesh.buildPlayerNav(game.unlocked_doors | inventoryKeyMask());
    const selected = @min(game.map.selected_save, level.current.save_target_count - 1);
    if (level.current.isInSaveRoomIndex(selected, game.character.position.x, game.character.position.z)) {
        game.map.route_status = .arrived;
        return;
    }

    const target = level.current.save_targets[selected];
    const influence = navmesh.HunterInfluence{
        .x = game.hunter.position.x,
        .z = game.hunter.position.z,
        .hard_radius = game.hunter_config.contact_radius,
        .danger_radius = map_route_danger_radius,
        .danger_penalty = map_route_danger_penalty,
    };
    const route_start_cell = navmesh.player_nav.nearestWalkableWithInfluence(
        game.character.position.x,
        game.character.position.z,
        influence,
    ) orelse {
        game.map.route_status = .no_path;
        return;
    };
    const player_cell = navmesh.player_nav.cellAt(game.character.position.x, game.character.position.z);
    game.map.route_start = if (player_cell != null and player_cell.? == route_start_cell)
        game.character.position
    else
        navmesh.player_nav.worldAt(route_start_cell);
    game.map.route_len = navmesh.player_nav.findPathWithInfluence(
        game.character.position.x,
        game.character.position.z,
        target.x,
        target.z,
        game.map.route[0..],
        influence,
    );
    if (game.map.route_len == 0) {
        game.map.route_status = .no_path;
        return;
    }

    var from = game.map.route_start;
    for (game.map.route[0..game.map.route_len]) |waypoint| {
        const dx = waypoint.x - from.x;
        const dz = waypoint.z - from.z;
        const segment_length = @sqrt(dx * dx + dz * dz);
        if (segment_length > 0.0001) {
            game.map.route_instances[game.map.route_segment_count] = makeScaledInstance(
                .{
                    .x = (from.x + waypoint.x) * 0.5,
                    .y = level.current.ground_y + 0.1,
                    .z = (from.z + waypoint.z) * 0.5,
                },
                .{ .x = map_route_width, .y = map_route_height, .z = segment_length },
                std.math.atan2(dx, dz),
                rgb(0.3137255, 0.9803922, 0.4823529),
            );
            game.map.route_segment_count += 1;
        }
        from = waypoint;
    }
    game.map.route_status = .found;
}






























// Centered transient HUD message on its own row near the top of the screen.

// Centered RE2R-style slot list: eight numbered lines, cursor on the selected
// one, EMPTY or a date stamp per row.

// "YYYY-MM-DD HH:MM" in local wall-clock-free UTC from epoch seconds.






// Draw `count` instances of one mesh from the shared buffers. Each debug
// capsule uses three records: a cylinder followed by its two end spheres.



// Half-extents -> full scale (a unit box spans -1..1 before scaling).

// Like makeScaledInstance, but pitched about the X axis (used by level boxes,
// which the level data leans over rather than yawing).


// Full actor orientation used by the knockdown presentation: pitch happens in
// character-local space, then yaw keeps the fall aligned with the actor.




// Orthographic top-down view of the level, centred on the map pan position.
// North (-Z) points up on screen; the roof is hidden so interiors are visible.
fn mapViewProjection() Mat4 {
    const half_h = mapHalfHeight(); // covers z +-19
    const center = game.map.pan;
    const eye = Vec3{ .x = center.x, .y = 80, .z = center.z };
    const at = Vec3{ .x = center.x, .y = 0, .z = center.z };
    const view = Mat4.lookAtRh(eye, at, .{ .x = 0, .y = 0, .z = -1 });
    const half_w = mapHalfWidth();
    const projection = Mat4.orthoOffCenterRh(-half_w, half_w, -half_h, half_h, 1, 200);
    return Mat4.mul(view, projection);
}



// The save-file APIs need an Io instance; the app owns one for its lifetime.
var app_io: std.Io.Threaded = undefined;


fn selectMapSaveAt(screen_x: f32, screen_y: f32) void {
    const world = mapWorldAtScreen(screen_x, screen_y);
    const selected = level.current.saveRoomAt(world.x, world.z) orelse return;
    game.map.selected_save = selected;
    rebuildMapRoute();
}

pub fn main() void {
    app_io = .init(std.heap.page_allocator, .{});
    defer app_io.deinit();
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

test "keyboard quick turn chooses shortest backward direction" {
    const tolerance: f32 = 0.0001;
    try std.testing.expectApproxEqAbs(std.math.pi, keyboardQuickTurnDelta(false, false), tolerance);
    try std.testing.expectApproxEqAbs(std.math.pi * 0.75, keyboardQuickTurnDelta(true, false), tolerance);
    try std.testing.expectApproxEqAbs(-std.math.pi * 0.75, keyboardQuickTurnDelta(false, true), tolerance);
    // Opposing lateral keys cancel back to a straight 180-degree turn.
    try std.testing.expectApproxEqAbs(std.math.pi, keyboardQuickTurnDelta(true, true), tolerance);
}

test "quick turn requires an unopposed backward movement input" {
    try std.testing.expect(hasBackwardQuickTurnIntent(.{ .back = true }));
    try std.testing.expect(hasBackwardQuickTurnIntent(.{ .back = true, .left = true }));
    try std.testing.expect(!hasBackwardQuickTurnIntent(.{}));
    try std.testing.expect(!hasBackwardQuickTurnIntent(.{ .forward = true }));
    try std.testing.expect(!hasBackwardQuickTurnIntent(.{ .forward = true, .back = true }));
}

test "hunter flinch stops briefly and eases back to neutral" {
    var reaction = HunterReaction{};
    reaction.begin(-1);
    try std.testing.expect(reaction.active());
    reaction.update(hunter_flinch_seconds * 0.18);
    try std.testing.expect(reaction.amount() > 0.99);
    reaction.update(hunter_flinch_seconds);
    try std.testing.expect(!reaction.active());
    try std.testing.expectEqual(@as(f32, 0), reaction.amount());
}

test "hunter punch snaps forward, holds, and retracts" {
    var punch = HunterPunchAction{};
    punch.begin();
    try std.testing.expect(punch.active);
    try std.testing.expectEqual(@as(f32, 0), punch.amount());

    punch.update(hunter_punch_duration * hunter_punch_extend_fraction);
    try std.testing.expectApproxEqAbs(@as(f32, 1), punch.amount(), 0.0001);
    punch.update(hunter_punch_duration * hunter_punch_hold_fraction * 0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 1), punch.amount(), 0.0001);

    punch.update(hunter_punch_duration * 0.35);
    try std.testing.expect(punch.amount() > 0 and punch.amount() < 1);
    punch.update(hunter_punch_duration);
    try std.testing.expect(!punch.active);
    try std.testing.expectEqual(@as(f32, 0), punch.amount());
}

test "hunter knockdown eases into and out of the recovery bend" {
    const duration: f32 = 8;
    try std.testing.expectEqual(@as(f32, 0), hunterKnockdownAmount(duration, duration));
    const entering = hunterKnockdownAmount(duration - hunter_knockdown_enter_seconds * 0.5, duration);
    try std.testing.expect(entering > 0 and entering < 1);
    try std.testing.expectApproxEqAbs(@as(f32, 1), hunterKnockdownAmount(duration - hunter_knockdown_enter_seconds, duration), 0.0001);
    const recovering = hunterKnockdownAmount(hunter_knockdown_exit_seconds * 0.5, duration);
    try std.testing.expect(recovering > 0 and recovering < 1);
    try std.testing.expectEqual(@as(f32, 0), hunterKnockdownAmount(0, duration));
}

test "pickup action commits at contact and finishes after retracting" {
    var action = PickupAction{ .active = true, .target = .{ .kind = .box_drop, .index = 3 } };
    var events = action.advance(action_contact_time - 0.01);
    try std.testing.expect(!events.collect);
    try std.testing.expect(action.amount() > 0);

    events = action.advance(0.02);
    try std.testing.expect(events.collect);
    try std.testing.expect(!events.finished);
    try std.testing.expectEqual(InteractionKind.box_drop, action.target.kind);
    try std.testing.expectEqual(@as(usize, 3), action.target.index);

    events = action.advance(action_duration);
    try std.testing.expect(!events.collect);
    try std.testing.expect(events.finished);
    try std.testing.expect(!action.active);
    try std.testing.expectEqual(@as(f32, 0), action.amount());
}

test "box drop roll can produce nothing ammo or health" {
    try std.testing.expectEqual(inventory.ItemKind.empty, rollBoxDrop(box_item_chance, 0).kind);
    const health = rollBoxDrop(0, box_health_share - 0.01);
    try std.testing.expectEqual(inventory.ItemKind.health, health.kind);
    try std.testing.expectEqual(@as(u16, 1), health.amount);
    const ammo = rollBoxDrop(box_item_chance - 0.01, box_health_share);
    try std.testing.expectEqual(inventory.ItemKind.ammo, ammo.kind);
    try std.testing.expectEqual(box_ammo_amount, ammo.amount);
}

test "gun ray intersects a breakable box and rejects a miss" {
    const center = Vec3{ .x = 2, .y = 0.42, .z = -3 };
    const hit = rayBoxFraction(
        .{ .x = 2, .y = 0.42, .z = 2 },
        .{ .z = -10 },
        center,
        breakable_half_extent,
    ) orelse return error.TestUnexpectedResult;
    try std.testing.expectApproxEqAbs(@as(f32, 0.458), hit, 0.0001);
    try std.testing.expect(rayBoxFraction(
        .{ .x = 3, .y = 0.42, .z = 2 },
        .{ .z = -10 },
        center,
        breakable_half_extent,
    ) == null);
}

test "hunter AI tests" {
    std.testing.refAllDecls(@import("hunter.zig"));
}

test "combat tests" {
    std.testing.refAllDecls(@import("combat.zig"));
}
