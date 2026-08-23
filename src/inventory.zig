//! Fixed-grid survival-horror inventory state.

const std = @import("std");

pub const columns = 5;
pub const rows = 4;
pub const cell_count = columns * rows;

pub const ItemKind = enum {
    empty,
    ammo,
    health,
};

pub const Item = struct {
    kind: ItemKind = .empty,
    amount: u16 = 0,

    pub fn occupied(self: Item) bool {
        return self.kind != .empty and self.amount > 0;
    }
};

pub const State = struct {
    cells: [cell_count]Item = @splat(.{}),

    pub fn defaultLoadout(reserve_ammo: u16) State {
        var result: State = .{};
        if (reserve_ammo > 0) result.cells[0] = .{ .kind = .ammo, .amount = reserve_ammo };
        result.cells[1] = .{ .kind = .health, .amount = 1 };
        return result;
    }

    pub fn add(self: *State, item: Item) ?usize {
        if (!item.occupied()) return null;
        for (&self.cells, 0..) |*cell, index| {
            if (!cell.occupied()) {
                cell.* = item;
                return index;
            }
        }
        return null;
    }

    pub fn moveOrSwap(self: *State, from: usize, to: usize) bool {
        if (from >= cell_count or to >= cell_count or from == to) return false;
        if (!self.cells[from].occupied()) return false;
        std.mem.swap(Item, &self.cells[from], &self.cells[to]);
        return true;
    }

    pub fn totalAmmo(self: State) u16 {
        var total: u32 = 0;
        for (self.cells) |item| {
            if (item.kind == .ammo) total += item.amount;
        }
        return @intCast(@min(total, std.math.maxInt(u16)));
    }

    pub fn consumeAmmo(self: *State, requested: u16) u16 {
        var remaining = requested;
        var index: usize = cell_count;
        while (index > 0 and remaining > 0) {
            index -= 1;
            const item = &self.cells[index];
            if (item.kind != .ammo) continue;
            const consumed = @min(item.amount, remaining);
            item.amount -= consumed;
            remaining -= consumed;
            if (item.amount == 0) item.* = .{};
        }
        return requested - remaining;
    }

    pub fn useHealth(self: *State, cell: usize, health: *f32, max_health: f32, heal_amount: f32) bool {
        if (cell >= cell_count or self.cells[cell].kind != .health or health.* >= max_health) return false;
        health.* = @min(max_health, health.* + heal_amount);
        self.cells[cell].amount -= 1;
        if (self.cells[cell].amount == 0) self.cells[cell] = .{};
        return true;
    }
};

test "items can move into empty cells and swap with occupied cells" {
    var state = State.defaultLoadout(120);
    try std.testing.expect(state.moveOrSwap(0, 7));
    try std.testing.expectEqual(ItemKind.ammo, state.cells[7].kind);
    try std.testing.expectEqual(ItemKind.empty, state.cells[0].kind);
    try std.testing.expect(state.moveOrSwap(7, 1));
    try std.testing.expectEqual(ItemKind.health, state.cells[7].kind);
    try std.testing.expectEqual(ItemKind.ammo, state.cells[1].kind);
}

test "ammo consumption follows moved stacks" {
    var state: State = .{};
    _ = state.add(.{ .kind = .ammo, .amount = 20 });
    _ = state.add(.{ .kind = .health, .amount = 1 });
    _ = state.add(.{ .kind = .ammo, .amount = 30 });
    try std.testing.expectEqual(@as(u16, 35), state.consumeAmmo(35));
    try std.testing.expectEqual(@as(u16, 15), state.totalAmmo());
}

test "health items heal once and are not wasted at full health" {
    var state = State.defaultLoadout(0);
    var health: f32 = 100;
    try std.testing.expect(!state.useHealth(1, &health, 100, 35));
    try std.testing.expect(state.cells[1].occupied());
    health = 52;
    try std.testing.expect(state.useHealth(1, &health, 100, 35));
    try std.testing.expectEqual(@as(f32, 87), health);
    try std.testing.expect(!state.cells[1].occupied());
}
