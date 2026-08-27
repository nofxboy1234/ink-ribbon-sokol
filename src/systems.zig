const state = @import("state.zig");
const presentation = @import("presentation.zig");
const render = @import("render.zig");
const player = @import("player.zig");
const world = @import("world.zig");
const interaction = @import("interaction.zig");

pub fn init(game: *state.GameState) void {
    presentation.init(game);
    render.init(game);
    player.init(game);
    world.init(game);
    interaction.init(game);
}
