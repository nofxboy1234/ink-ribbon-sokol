//! Player health and deterministic punch/recovery presentation state.

const std = @import("std");

pub const Config = struct {
    max_health: f32 = 100,
    punch_damage: f32 = 35,
    heal_amount: f32 = 35,
    launch_speed: f32 = 7.0,
    lift_speed: f32 = 4.2,
    minimum_air_time: f32 = 0.28,
    down_seconds: f32 = 0.75,
    rise_seconds: f32 = 1.05,
    defeated_seconds: f32 = 1.2,
    hunter_watch_seconds: f32 = 2.8,
    invulnerability_seconds: f32 = 3.2,
};

pub const Phase = enum {
    ready,
    airborne,
    down,
    rising,
};

pub const Event = enum {
    none,
    defeated,
};

pub const State = struct {
    health: f32 = 100,
    phase: Phase = .ready,
    phase_timer: f32 = 0,
    invulnerability_timer: f32 = 0,
    hunter_watch_timer: f32 = 0,

    pub fn reset(self: *State, config: Config, health: f32) void {
        self.* = .{ .health = std.math.clamp(health, 0, config.max_health) };
    }

    pub fn canMove(self: State) bool {
        return self.phase == .ready;
    }

    pub fn canBeHit(self: State) bool {
        return self.phase == .ready and self.invulnerability_timer <= 0 and self.health > 0;
    }

    pub fn punch(self: *State, config: Config) bool {
        if (!self.canBeHit()) return false;
        self.health = @max(0, self.health - config.punch_damage);
        self.phase = .airborne;
        self.phase_timer = 0;
        self.invulnerability_timer = config.invulnerability_seconds;
        self.hunter_watch_timer = config.hunter_watch_seconds;
        return true;
    }

    pub fn update(self: *State, config: Config, grounded: bool, dt: f32) Event {
        self.invulnerability_timer = @max(0, self.invulnerability_timer - dt);
        self.hunter_watch_timer = @max(0, self.hunter_watch_timer - dt);
        self.phase_timer += dt;
        switch (self.phase) {
            .ready => self.phase_timer = 0,
            .airborne => if (grounded and self.phase_timer >= config.minimum_air_time) {
                self.phase = .down;
                self.phase_timer = 0;
            },
            .down => {
                if (self.health <= 0 and self.phase_timer >= config.defeated_seconds) return .defeated;
                if (self.health > 0 and self.phase_timer >= config.down_seconds) {
                    self.phase = .rising;
                    self.phase_timer = 0;
                }
            },
            .rising => if (self.phase_timer >= config.rise_seconds) {
                self.phase = .ready;
                self.phase_timer = 0;
            },
        }
        return .none;
    }

    pub fn fallAmount(self: State, config: Config) f32 {
        return switch (self.phase) {
            .ready => 0,
            .airborne => smooth(std.math.clamp(self.phase_timer / 0.32, 0, 1)),
            .down => 1,
            .rising => 1.0 - smooth(std.math.clamp(self.phase_timer / config.rise_seconds, 0, 1)),
        };
    }
};

fn smooth(value: f32) f32 {
    return value * value * (3.0 - 2.0 * value);
}

test "punch damages once then progresses through landing and recovery" {
    const config: Config = .{};
    var state: State = .{};
    try std.testing.expect(state.punch(config));
    try std.testing.expectEqual(@as(f32, 65), state.health);
    try std.testing.expect(!state.punch(config));
    _ = state.update(config, false, 0.3);
    try std.testing.expectEqual(Phase.airborne, state.phase);
    _ = state.update(config, true, 0.01);
    try std.testing.expectEqual(Phase.down, state.phase);
    _ = state.update(config, true, config.down_seconds);
    try std.testing.expectEqual(Phase.rising, state.phase);
    _ = state.update(config, true, config.rise_seconds);
    try std.testing.expectEqual(Phase.ready, state.phase);
}

test "lethal punch requests defeat after the down beat" {
    const config: Config = .{};
    var state: State = .{ .health = 20 };
    try std.testing.expect(state.punch(config));
    _ = state.update(config, true, config.minimum_air_time);
    try std.testing.expectEqual(Event.defeated, state.update(config, true, config.defeated_seconds));
}
