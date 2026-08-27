//! Central dependency-injection wiring for the scene subsystems.
//!
//! Every subsystem module that needs the runtime state exposes an
//! `init(*GameState)` that stores the injected pointer. This module is the
//! single place that calls them all, so a newly added subsystem cannot be
//! forgotten at startup (which would leave its `game` pointer null and crash
//! the first time it dereferences it).

const state = @import("state.zig");
const presentation = @import("presentation.zig");
const render = @import("render.zig");
const player = @import("player.zig");
const world = @import("world.zig");
const interaction = @import("interaction.zig");

/// Inject the shared scene state into every subsystem. Called once at startup.
pub fn init(game: *state.GameState) void {
    presentation.init(game);
    render.init(game);
    player.init(game);
    world.init(game);
    interaction.init(game);
}
