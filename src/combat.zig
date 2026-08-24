//! Deterministic aiming, ammunition, and hunter damage state.

const std = @import("std");

pub const Config = struct {
    magazine_capacity: u16 = 24,
    starting_reserve: u16 = 0,
    fire_interval: f32 = 0.1,
    reload_duration: f32 = 1.6,
    focus_seconds: f32 = 1.0,
    focus_loss_rate_moving: f32 = 1.6,
    focus_loss_per_shot: f32 = 0.35,
    focus_recovery_delay: f32 = 0.15,
    base_damage: f32 = 10,
    focused_damage: f32 = 15,
    hunter_health: f32 = 300,
    knockdown_duration: f32 = 8,
    shot_range: f32 = 100,
};

pub const Input = struct {
    aiming: bool = false,
    firing: bool = false,
    reload_pressed: bool = false,
    moving: bool = false,
};

pub const max_shots_per_tick = 4;

pub const Events = struct {
    shot_focus: [max_shots_per_tick]f32 = @splat(0),
    shot_count: u8 = 0,
    reload_started: bool = false,
    reload_completed: bool = false,
    hunter_revived: bool = false,
};

pub const State = struct {
    magazine: u16 = 24,
    reserve: u16 = 120,
    focus: f32 = 0,
    fire_cooldown: f32 = 0,
    focus_delay: f32 = 0,
    reload_timer: f32 = 0,
    aiming_last_tick: bool = false,
    hunter_health: f32 = 300,
    knockdown_timer: f32 = 0,
    random_state: u32 = 0x8ab4_93e1,

    pub fn init(config: Config, magazine: u16, reserve: u16) State {
        return .{
            .magazine = @min(magazine, config.magazine_capacity),
            .reserve = reserve,
            .hunter_health = config.hunter_health,
        };
    }

    pub fn hunterKnockedDown(self: State) bool {
        return self.knockdown_timer > 0;
    }

    pub fn reloading(self: State) bool {
        return self.reload_timer > 0;
    }

    pub fn damageForFocus(self: State, config: Config, focus: f32) f32 {
        _ = self;
        return config.base_damage + (config.focused_damage - config.base_damage) * std.math.clamp(focus, 0, 1);
    }

    pub fn applyHunterHit(self: *State, config: Config, focus: f32) bool {
        if (self.hunterKnockedDown()) return false;
        self.hunter_health = @max(0, self.hunter_health - self.damageForFocus(config, focus));
        if (self.hunter_health > 0) return false;
        self.knockdown_timer = config.knockdown_duration;
        return true;
    }

    pub fn randomSigned(self: *State) f32 {
        self.random_state ^= self.random_state << 13;
        self.random_state ^= self.random_state >> 17;
        self.random_state ^= self.random_state << 5;
        const unit = @as(f32, @floatFromInt(self.random_state & 0xffff)) / 65535.0;
        return unit * 2.0 - 1.0;
    }
};

pub fn update(config: Config, state: *State, input: Input, dt: f32) Events {
    var events: Events = .{};

    if (state.knockdown_timer > 0) {
        state.knockdown_timer = @max(0, state.knockdown_timer - dt);
        if (state.knockdown_timer == 0) {
            state.hunter_health = config.hunter_health;
            events.hunter_revived = true;
        }
    }

    if (state.fire_cooldown > 0) state.fire_cooldown -= dt;
    state.focus_delay = @max(0, state.focus_delay - dt);

    if (state.reload_timer > 0) {
        state.reload_timer = @max(0, state.reload_timer - dt);
        state.focus = 0;
        if (state.reload_timer == 0) {
            const wanted = config.magazine_capacity - state.magazine;
            const loaded = @min(wanted, state.reserve);
            state.magazine += loaded;
            state.reserve -= loaded;
            events.reload_completed = true;
        }
    }

    if (input.aiming and !state.aiming_last_tick) {
        state.focus = 0;
        state.focus_delay = 0;
    }
    state.aiming_last_tick = input.aiming;

    const wants_reload = input.reload_pressed or (input.aiming and input.firing and state.magazine == 0);
    if (state.reload_timer == 0 and wants_reload and state.magazine < config.magazine_capacity and state.reserve > 0) {
        state.reload_timer = config.reload_duration;
        state.focus = 0;
        events.reload_started = true;
    }

    if (!input.aiming) {
        state.focus = 0;
        state.fire_cooldown = @max(0, state.fire_cooldown);
        return events;
    }
    if (state.reload_timer > 0) return events;

    if (input.moving) {
        state.focus = approach(state.focus, 0, config.focus_loss_rate_moving * dt);
    } else if (state.focus_delay == 0) {
        state.focus = approach(state.focus, 1, dt / config.focus_seconds);
    }

    while (input.firing and state.fire_cooldown <= 0 and state.magazine > 0 and events.shot_count < max_shots_per_tick) {
        events.shot_focus[events.shot_count] = state.focus;
        events.shot_count += 1;
        state.magazine -= 1;
        state.focus = @max(0, state.focus - config.focus_loss_per_shot);
        state.focus_delay = config.focus_recovery_delay;
        state.fire_cooldown += config.fire_interval;
    }
    if (!input.firing) state.fire_cooldown = @max(0, state.fire_cooldown);
    return events;
}

fn approach(value: f32, target: f32, amount: f32) f32 {
    if (value < target) return @min(value + amount, target);
    return @max(value - amount, target);
}

test "focus contracts while still and blooms from movement and fire" {
    const config: Config = .{};
    var state = State.init(config, 24, 120);
    for (0..60) |_| _ = update(config, &state, .{ .aiming = true }, 1.0 / 60.0);
    try std.testing.expectApproxEqAbs(@as(f32, 1), state.focus, 0.001);
    _ = update(config, &state, .{ .aiming = true, .firing = true }, 1.0 / 60.0);
    try std.testing.expect(state.focus < 0.7);
    const after_shot = state.focus;
    for (0..15) |_| _ = update(config, &state, .{ .aiming = true, .moving = true }, 1.0 / 60.0);
    try std.testing.expect(state.focus < after_shot);
}

test "automatic fire respects cadence and reload transfers finite reserve" {
    const config: Config = .{};
    var state = State.init(config, 2, 3);
    var shots: usize = 0;
    for (0..30) |_| shots += update(config, &state, .{ .aiming = true, .firing = true }, 1.0 / 60.0).shot_count;
    try std.testing.expectEqual(@as(usize, 2), shots);
    try std.testing.expect(state.reloading());
    for (0..100) |_| _ = update(config, &state, .{}, 1.0 / 60.0);
    try std.testing.expectEqual(@as(u16, 3), state.magazine);
    try std.testing.expectEqual(@as(u16, 0), state.reserve);
}

test "automatic fire emits ten rounds per second" {
    const config: Config = .{};
    var state = State.init(config, 24, 120);
    var shots: usize = 0;
    for (0..60) |_| shots += update(config, &state, .{ .aiming = true, .firing = true }, 1.0 / 60.0).shot_count;
    try std.testing.expectEqual(@as(usize, 10), shots);
}

test "hunter knockdown expires and restores health" {
    const config: Config = .{ .hunter_health = 10, .base_damage = 10, .focused_damage = 10, .knockdown_duration = 0.1 };
    var state = State.init(config, 24, 120);
    try std.testing.expect(state.applyHunterHit(config, 0));
    try std.testing.expect(state.hunterKnockedDown());
    _ = update(config, &state, .{}, 0.11);
    try std.testing.expect(!state.hunterKnockedDown());
    try std.testing.expectEqual(config.hunter_health, state.hunter_health);
}
