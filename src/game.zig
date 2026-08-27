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
const player = @import("player.zig");
const systems = @import("systems.zig");
const game_audio = @import("game_audio.zig");
const ig = @import("cimgui");
const shd = @import("generated/character_shader.zig");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;
const sshape = sokol.shape;
const sdtx = sokol.debugtext;
const saudio = sokol.audio;
const simgui = sokol.imgui;
const sappimgui = sokol.appimgui;
const sgimgui = sokol.gfximgui;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

const state = @import("state.zig");
const presentation = @import("presentation.zig");
const render = @import("render.zig");
const worldmod = @import("world.zig");
const interaction = @import("interaction.zig");
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
const initPhysics = worldmod.initPhysics;
const addStaticBox = worldmod.addStaticBox;
const addBreakableBody = worldmod.addBreakableBody;
const addActorProxy = worldmod.addActorProxy;
const setBreakableCollision = worldmod.setBreakableCollision;
const syncBreakableCollision = worldmod.syncBreakableCollision;
const yawRotation = worldmod.yawRotation;
const chooseDoorHingeSign = worldmod.chooseDoorHingeSign;
const doorHingeObstructionScore = worldmod.doorHingeObstructionScore;
const addDoorPhysics = worldmod.addDoorPhysics;
const replaceDoorJoint = worldmod.replaceDoorJoint;
const restoreDoorState = worldmod.restoreDoorState;
const resetActorProxies = worldmod.resetActorProxies;
const setProxyTransform = worldmod.setProxyTransform;
const targetProxy = worldmod.targetProxy;
const pushDoorsFromPlayerMovement = worldmod.pushDoorsFromPlayerMovement;
const stepDoorPhysics = worldmod.stepDoorPhysics;
const openDoorInHunterPath = worldmod.openDoorInHunterPath;
const applyDoorPush = worldmod.applyDoorPush;
const interactDoor = worldmod.interactDoor;
const loadValidatedLevel = worldmod.loadValidatedLevel;
const levelPlayerSpawn = worldmod.levelPlayerSpawn;
const levelHunterSpawn = worldmod.levelHunterSpawn;
const latestSaveIndex = worldmod.latestSaveIndex;
const placePlayerFromSlot = worldmod.placePlayerFromSlot;
const placePlayerAtSpawn = worldmod.placePlayerAtSpawn;
const resetRoundTransient = worldmod.resetRoundTransient;
const spawnPlayerAndHunter = worldmod.spawnPlayerAndHunter;
const restartRun = worldmod.restartRun;
const resetHunter = worldmod.resetHunter;
const respawnAfterCatch = worldmod.respawnAfterCatch;
const faceHunterTowardPlayer = worldmod.faceHunterTowardPlayer;
const hunterContacted = worldmod.hunterContacted;
const seedSpawnRandomness = worldmod.seedSpawnRandomness;
const updatePlayerFootsteps = worldmod.updatePlayerFootsteps;
const updateHunterFootsteps = worldmod.updateHunterFootsteps;
const fireShot = interaction.fireShot;
const closestShootableBox = interaction.closestShootableBox;
const rayBoxFraction = interaction.rayBoxFraction;
const clipRayAxis = interaction.clipRayAxis;
const addImpact = interaction.addImpact;
const alertHunterToGunshot = interaction.alertHunterToGunshot;
const updateCombatVisuals = interaction.updateCombatVisuals;
const punchPlayer = interaction.punchPlayer;
const updateInteractionTarget = interaction.updateInteractionTarget;
const activateInteraction = interaction.activateInteraction;
const targetPosition = interaction.targetPosition;
const targetDiscoveryBit = interaction.targetDiscoveryBit;
const inventoryKeyMask = interaction.inventoryKeyMask;
const interactionScore = interaction.interactionScore;
const updateActionsAndDebris = interaction.updateActionsAndDebris;
const breakBox = interaction.breakBox;
const collectInteractionItem = interaction.collectInteractionItem;
const revealBoxDrop = interaction.revealBoxDrop;
const rollBoxDrop = interaction.rollBoxDrop;
const randomUnit = interaction.randomUnit;
const spawnBoxDebris = interaction.spawnBoxDebris;
const breakableIndexForBody = interaction.breakableIndexForBody;
const draw = render.draw;
const uploadMapRoute = render.uploadMapRoute;
const makeScaledInstance = render.makeScaledInstance;
const initRenderer = render.initRenderer;
const updateQuickTurn = player.updateQuickTurn;
const keyboardQuickTurnDelta = player.keyboardQuickTurnDelta;
const hasBackwardQuickTurnIntent = player.hasBackwardQuickTurnIntent;
const beginQuickTurn = player.beginQuickTurn;
const stepPlayer = player.stepPlayer;
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
    sgimgui.setup(.{});
    sappimgui.setup();
    simgui.setup(.{ .logger = .{ .func = slog.func } });
    systems.init(game);
    seedSpawnRandomness();
    saves.loadFromCwd(app_io.io());
    loadValidatedLevel();
    initPhysics();
    initRenderer();
    spawnPlayerAndHunter();
    sapp.lockMouse(true);
}

fn frame() callconv(.c) void {
    const frame_time: f32 = @floatCast(@min(sapp.frameDuration(), max_frame_dt));
    game.clock.addFrame(frame_time);
    updateNoticeTimer(frame_time);
    updateCombatVisuals(frame_time);

    const gameplay_active = !game.map.active and game.menu.kind == .none and !game.inventory_ui.active;
    if (gameplay_active) game.run_stats.elapsed_active_seconds += @as(f64, frame_time);

    const render_position = runSimulationTicks(gameplay_active);

    if (gameplay_active and game.condition.canMove() and !playerActionActive() and !game.input.aiming) updateQuickTurn(frame_time);
    updateView(frame_time, render_position);

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

fn updateNoticeTimer(frame_time: f32) void {
    if (game.notice_timer <= 0) return;
    game.notice_timer = @max(0, game.notice_timer - frame_time);
    if (game.notice_timer == 0) game.notice = .none;
}

fn runSimulationTicks(gameplay_active: bool) b3.b3Pos {
    var ticks: usize = 0;
    while (ticks < max_ticks_per_frame and game.clock.consumeTick()) : (ticks += 1) {
        const hunter_sim_active = level.hunterEnabled() and !game.hunter_hold and game.menu.kind == .none and !game.inventory_ui.active and (!game.map.active or !game.map.hunter_paused);
        if (!stepFixedTick(gameplay_active, hunter_sim_active)) break;
        if (gameplay_active or hunter_sim_active) stepDoorPhysics(gameplay_active, hunter_sim_active);
    }

    if (ticks == max_ticks_per_frame and game.clock.accumulator >= fixed_dt) {
        game.clock.accumulator = @mod(game.clock.accumulator, fixed_dt);
    }

    return if (gameplay_active)
        controller.interpolatedPosition(game.character, game.clock.alpha())
    else
        game.character.position;
}

fn stepFixedTick(gameplay_active: bool, hunter_sim_active: bool) bool {
    if (gameplay_active) {
        stepPlayer();
        stepCombat();
        updateActionsAndDebris(@floatCast(fixed_dt));
        if (stepPlayerCondition() == .defeated) {
            game.run_stats.deaths +|= 1;
            respawnAfterCatch();
            return false;
        }
    }
    if (hunter_sim_active) stepHunter();
    return true;
}

fn stepCombat() void {
    if (!game.condition.canMove() or playerActionActive()) return;
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

fn stepPlayerCondition() player_condition.Event {
    const before = game.condition.phase;
    const condition_event = game.condition.update(game.condition_config, game.character.grounded, @floatCast(fixed_dt));
    if (before == .airborne and game.condition.phase == .down) game.audio.play(.body_fall);
    return condition_event;
}

fn stepHunter() void {
    game.hunter_punch.update(@floatCast(fixed_dt));
    game.hunter_reaction.update(@floatCast(fixed_dt));
    if (game.combat.hunterKnockedDown() or game.hunter_reaction.active()) {
        hunter.updateIdlePhysics(game.hunter_config, &game.hunter, &game.mover_scratch, game.world, @floatCast(fixed_dt));
        return;
    }
    if (game.condition.hunter_watch_timer > 0) {
        faceHunterTowardPlayer(@floatCast(fixed_dt));
        hunter.updateIdlePhysics(game.hunter_config, &game.hunter, &game.mover_scratch, game.world, @floatCast(fixed_dt));
        return;
    }
    hunter.update(game.hunter_config, &game.hunter, &game.mover_scratch, game.world, game.character.position, @floatCast(fixed_dt));
    openDoorInHunterPath();
    updateHunterFootsteps();
    if (hunterContacted()) punchPlayer();
}

fn updateView(frame_time: f32, render_position: b3.b3Pos) void {
    if (game.map.active) {
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
}

fn cleanup() callconv(.c) void {
    b3.b3DestroyWorld(game.world);
    game.world = b3.b3_nullWorldId;
    saudio.shutdown();
    sdtx.shutdown();
    simgui.shutdown();
    sappimgui.shutdown();
    sgimgui.shutdown();
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
    if (game.debug.draw_physics and game.debug.imgui_fps_open) {
        sappimgui.trackEvent(value);
        if (simgui.handleEvent(value)) return;
    }
    switch (value.type) {
        .KEY_DOWN, .KEY_UP => handleKey(value, value.type == .KEY_DOWN),
        .MOUSE_DOWN => handleMouseDown(value),
        .MOUSE_UP => handleMouseUp(value),
        .MOUSE_MOVE => handleMouseMove(value),
        .UNFOCUSED => handleUnfocused(),
        else => {},
    }
}

fn handleKey(value: sapp.Event, down: bool) void {
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
            game.input.run = true;
        },
        .LEFT_ALT, .RIGHT_ALT => if (down and !value.key_repeat) resetCameraBehindCharacter(),
        .R => if (down and !value.key_repeat and game.menu.kind == .none and !game.map.active) {
            game.input.reload_queued = true;
        },
        .F1 => if (down and !value.key_repeat) {
            game.debug.draw_physics = !game.debug.draw_physics;
            syncDebugUiMouseLock();
        },
        .GRAVE_ACCENT => if (down and !value.key_repeat and game.debug.draw_physics) {
            game.debug.imgui_fps_open = !game.debug.imgui_fps_open;
            syncDebugUiMouseLock();
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
}

fn handleMouseDown(value: sapp.Event) void {
    switch (value.mouse_button) {
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
    }
}

fn handleMouseUp(value: sapp.Event) void {
    switch (value.mouse_button) {
        .LEFT => game.input.firing = false,
        .RIGHT => game.input.aiming = false,
        else => {},
    }
}

fn handleMouseMove(value: sapp.Event) void {
    if (game.map.active) {
        game.map.cursor = .{ .x = value.mouse_x, .y = value.mouse_y };
    } else if (game.menu.kind == .pause or game.menu.kind == .results) {
        hoverMenu(value.mouse_x, value.mouse_y);
    } else if (sapp.mouseLocked()) {
        game.input.mouse_delta.x += value.mouse_dx;
        game.input.mouse_delta.y += value.mouse_dy;
    }
}

fn handleUnfocused() void {
    game.input = .{};
    sapp.lockMouse(false);
    sapp.showMouse(true);
}

const playerActionActive = state.playerActionActive;

fn openMenu(kind: MenuKind) void {
    game.menu = .{ .kind = kind, .slot = 0 };

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

fn syncDebugUiMouseLock() void {
    // while the imgui debug hud is visible the mouse must be free to click it
    if (game.debug.draw_physics and game.debug.imgui_fps_open and game.menu.kind == .none) {
        sapp.lockMouse(false);
        sapp.showMouse(true);
    } else if (game.menu.kind == .none) {
        if (!game.map.active and !game.inventory_ui.active and !playerActionActive()) {
            sapp.lockMouse(true);
        }
        sapp.showMouse(false);
    }
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
    const count = presentation.rootMenuItemCount();
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
        .pause => 4,
        .results => 2,
        .save, .load => saves.slot_count,
        .none => return,
    };
    const current: i32 = @intCast(game.menu.slot);
    game.menu.slot = @intCast(@mod(current + delta + count, count));
}

fn deleteSelectedSlot() void {
    if (game.menu.kind != .save and game.menu.kind != .load) return;
    if (!saves.slots[game.menu.slot].occupied) return;
    saves.slots[game.menu.slot] = .{};
    if (saves.writeToCwd(app_io.io())) |_| {
        game.notice = .deleted;
        game.notice_timer = notice_seconds;
    } else |_| {
        game.notice = .save_failed;
        game.notice_timer = notice_seconds;
    }
}

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
                2 => game.render_resolution = presentation.cycleResolutionChoice(game.render_resolution),
                3 => sapp.requestQuit(),
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

fn mapViewProjection() Mat4 {
    const half_h = mapHalfHeight();
    const center = game.map.pan;
    const eye = Vec3{ .x = center.x, .y = 80, .z = center.z };
    const at = Vec3{ .x = center.x, .y = 0, .z = center.z };
    const view = Mat4.lookAtRh(eye, at, .{ .x = 0, .y = 0, .z = -1 });
    const half_w = mapHalfWidth();
    const projection = Mat4.orthoOffCenterRh(-half_w, half_w, -half_h, half_h, 1, 200);
    return Mat4.mul(view, projection);
}

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
