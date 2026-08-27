const std = @import("std");
const controller = @import("character_controller.zig");
const camera = @import("third_person_camera.zig");
const game_audio = @import("game_audio.zig");
const state = @import("state.zig");
const world = @import("world.zig");

var game: *state.GameState = undefined;

pub fn init(g: *state.GameState) void {
    game = g;
}

const fbool = state.fbool;
const playerActionActive = state.playerActionActive;
const fixed_dt = state.fixed_dt;
const InputState = state.InputState;
const pushDoorsFromPlayerMovement = world.pushDoorsFromPlayerMovement;

pub fn updateQuickTurn(dt: f32) void {
    if (!game.quick_turn.active) return;
    game.quick_turn.timer += dt;
    const t = std.math.clamp(game.quick_turn.timer / game.quick_turn.duration, 0, 1);

    const eased = t * t * (3.0 - 2.0 * t);
    game.character.yaw = game.quick_turn.character_start + (game.quick_turn.character_target - game.quick_turn.character_start) * eased;
    game.camera.yaw = game.quick_turn.camera_start + (game.quick_turn.camera_target - game.quick_turn.camera_start) * eased;
    if (t >= 1) game.quick_turn.active = false;
}

pub fn keyboardQuickTurnDelta(left: bool, right: bool) f32 {
    const lateral = fbool(right) - fbool(left);
    if (lateral == 0) return std.math.pi;
    return std.math.atan2(-lateral, -1.0);
}

pub fn hasBackwardQuickTurnIntent(input: InputState) bool {
    return input.back and !input.forward;
}

pub fn beginQuickTurn() void {
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

pub fn stepPlayer() void {
    const can_move = game.condition.canMove() and !playerActionActive();
    controller.update(
        game.character_config,
        &game.character,
        &game.mover_scratch,
        game.world,
        if (can_move) game.input.characterInput() else .{},
        game.camera.basis,
        @floatCast(fixed_dt),
    );
    if (can_move) pushDoorsFromPlayerMovement(@floatCast(fixed_dt));
    updatePlayerFootsteps();
}

pub fn updatePlayerFootsteps() void {
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
