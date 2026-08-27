//! Shared presentation and resolution helpers used by both the gameplay
//! orchestrator and the renderer (door pose math, item/door colours & names,
//! inventory and menu layout). This module is the common seam so the renderer
//! never has to import the orchestrator, which would create a cycle.
//!
//! Receives the scene state once via `init`.

const std = @import("std");
const sokol = @import("sokol");
const math = @import("math.zig");
const level = @import("level.zig");
const inventory = @import("inventory.zig");
const state = @import("state.zig");

const sapp = sokol.app;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;

var game: *state.GameState = undefined;

/// Inject the shared scene state. Called once from the orchestrator's init.
pub fn init(g: *state.GameState) void {
    game = g;
}

const smoothstep = state.smoothstep;
const rgb = state.rgb;
const hunter_knockdown_enter_seconds = state.hunter_knockdown_enter_seconds;
const hunter_knockdown_exit_seconds = state.hunter_knockdown_exit_seconds;
const box_ammo_amount = state.box_ammo_amount;
const action_duration = state.action_duration;
const map_margin = state.map_margin;
const save_interaction_radius = state.save_interaction_radius;
const ScreenRect = state.ScreenRect;
const InventoryLayout = state.InventoryLayout;
const InteractionTarget = state.InteractionTarget;

pub fn doorBaseYaw(door: level.DoorDef) f32 {
    return if (door.axis == .x) 0 else std.math.pi * 0.5;
}

pub fn doorHingePosition(door: level.DoorDef, index: usize, y: f32) Vec3 {
    const yaw = doorBaseYaw(door);
    const sign = game.door_hinge_sign[index];
    return .{
        .x = door.position.x + @cos(yaw) * sign * door.width * 0.5,
        .y = y,
        .z = door.position.z - @sin(yaw) * sign * door.width * 0.5,
    };
}

pub fn targetName(target: InteractionTarget) []const u8 {
    return switch (target.kind) {
        .pickup => game.pickup_defs[target.index].name,
        .breakable => game.breakable_defs[target.index].name,
        .box_drop => itemName(boxDropItem(target.index)),
        .door => doorName(level.current.doors[target.index], target.index),
    };
}

pub fn targetColor(target: InteractionTarget) Vec4 {
    return switch (target.kind) {
        .pickup, .box_drop => switch ((targetItem(target) orelse inventory.Item{}).kind) {
            .ammo => .{ .x = 0.12, .y = 0.43, .z = 0.98, .w = 1 },
            .health => .{ .x = 0.12, .y = 0.76, .z = 0.30, .w = 1 },
            .key_purple => draculaPurple(),
            .key_pink => draculaPink(),
            .key_cyan => draculaCyan(),
            .empty => .{},
        },
        .breakable => .{ .x = 1.0, .y = 0.48, .z = 0.08, .w = 1 },
        .door => doorDisplayColor(level.current.doors[target.index], target.index),
    };
}

pub fn itemName(item: inventory.Item) []const u8 {
    return switch (item.kind) {
        .ammo => "Handgun Ammo",
        .health => "First Aid Spray",
        .key_purple => "Purple Key",
        .key_pink => "Pink Key",
        .key_cyan => "Cyan Key",
        .empty => "Item",
    };
}

pub fn itemColor(item: inventory.Item) Vec4 {
    return switch (item.kind) {
        .ammo => rgb(0.15, 0.48, 1.0),
        .health => rgb(0.18, 0.82, 0.37),
        .key_purple => draculaPurple(),
        .key_pink => draculaPink(),
        .key_cyan => draculaCyan(),
        .empty => .{},
    };
}

pub fn draculaPurple() Vec4 {
    return rgb(0.741, 0.576, 0.976);
}

pub fn draculaPink() Vec4 {
    return rgb(1.0, 0.475, 0.776);
}

pub fn draculaCyan() Vec4 {
    return rgb(0.545, 0.914, 0.992);
}

pub fn doorColor(door: level.DoorDef) Vec4 {
    return switch (door.lock) {
        .none => rgb(0.93, 0.94, 0.95),
        .purple => draculaPurple(),
        .pink => draculaPink(),
        .cyan => draculaCyan(),
    };
}

pub fn doorIsUnlocked(door: level.DoorDef, index: usize) bool {
    if (door.lock == .none) return true;
    return game.unlocked_doors & (@as(u32, 1) << @intCast(index)) != 0;
}

pub fn doorDisplayColor(door: level.DoorDef, index: usize) Vec4 {
    return if (doorIsUnlocked(door, index)) rgb(0.93, 0.94, 0.95) else doorColor(door);
}

pub fn doorKey(lock: level.DoorLock) ?inventory.ItemKind {
    return switch (lock) {
        .none => null,
        .purple => .key_purple,
        .pink => .key_pink,
        .cyan => .key_cyan,
    };
}

pub fn boxDropPosition(index: usize) Vec3 {
    const box = game.breakable_defs[index].position;
    // Drops rest on the walk surface. The old test level had its floor top at
    // y = 0; the authored blockout sits a full metre higher, so an absolute
    // height here would bury the item inside the floor slab.
    return .{ .x = box.x, .y = level.current.ground_y + 0.18, .z = box.z };
}

pub fn boxDropItem(index: usize) inventory.Item {
    const bit = @as(u32, 1) << @intCast(index);
    if (game.box_drops_present & bit == 0 or game.collected_box_drops & bit != 0) return .{};
    return if (game.box_drops_health & bit != 0)
        .{ .kind = .health, .amount = 1 }
    else
        .{ .kind = .ammo, .amount = box_ammo_amount };
}

pub fn kickAmount() f32 {
    if (!game.kick.active) return 0;
    return @sin(std.math.pi * std.math.clamp(game.kick.timer / action_duration, 0, 1));
}

pub fn rootMenuItemRect(index: usize) ScreenRect {
    const count: usize = if (game.menu.kind == .results) 2 else 3;
    const width: f32 = 320;
    const height: f32 = 48;
    const gap: f32 = 12;
    const total = @as(f32, @floatFromInt(count)) * height + @as(f32, @floatFromInt(count - 1)) * gap;
    return .{
        .x = (sapp.widthf() - width) * 0.5,
        .y = (sapp.heightf() - total) * 0.5 + @as(f32, @floatFromInt(index)) * (height + gap) + 45,
        .w = width,
        .h = height,
    };
}

pub fn inventoryLayout() InventoryLayout {
    const gap: f32 = 10;
    const cell = std.math.clamp(sapp.heightf() * 0.105, 58, 92);
    const width = cell * @as(f32, @floatFromInt(inventory.columns)) + gap * @as(f32, @floatFromInt(inventory.columns - 1));
    const height = cell * @as(f32, @floatFromInt(inventory.rows)) + gap * @as(f32, @floatFromInt(inventory.rows - 1));
    return .{
        .left = (sapp.widthf() - width) * 0.5,
        .top = (sapp.heightf() - height) * 0.5 + 22,
        .cell = cell,
        .gap = gap,
    };
}

pub fn inventoryCellRect(layout: InventoryLayout, cell: usize) ScreenRect {
    const column = cell % inventory.columns;
    const row = cell / inventory.columns;
    return .{
        .x = layout.left + @as(f32, @floatFromInt(column)) * (layout.cell + layout.gap),
        .y = layout.top + @as(f32, @floatFromInt(row)) * (layout.cell + layout.gap),
        .w = layout.cell,
        .h = layout.cell,
    };
}

pub fn inventoryCellAt(x: f32, y: f32) ?usize {
    const layout = inventoryLayout();
    for (0..inventory.cell_count) |cell| if (inventoryCellRect(layout, cell).contains(x, y)) return cell;
    return null;
}

pub fn inventoryPopupRect(cell: usize) ScreenRect {
    const item_rect = inventoryCellRect(inventoryLayout(), cell);
    const width: f32 = 150;
    const height: f32 = 82;
    var x = item_rect.x + item_rect.w + 12;
    if (x + width > sapp.widthf() - 12) x = item_rect.x - width - 12;
    return .{ .x = x, .y = item_rect.y, .w = width, .h = height };
}

pub const DoorPose = struct { center: Vec3, yaw: f32 };

pub fn doorPose(door: level.DoorDef, index: usize, y: f32) DoorPose {
    const base_yaw = doorBaseYaw(door);
    const angle = game.door_previous_angle[index] + (game.door_current_angle[index] - game.door_previous_angle[index]) * game.clock.alpha();
    const yaw = base_yaw + angle;
    const half_width = door.width * 0.5;
    const hinge = doorHingePosition(door, index, y);
    const center_direction = -game.door_hinge_sign[index];
    const center = Vec3{
        .x = hinge.x + @cos(yaw) * half_width * center_direction,
        .y = hinge.y,
        .z = hinge.z - @sin(yaw) * half_width * center_direction,
    };
    return .{ .center = center, .yaw = yaw };
}

pub fn hunterKnockdownAmount(remaining: f32, duration: f32) f32 {
    if (remaining <= 0 or duration <= 0) return 0;
    const elapsed = @max(0, duration - remaining);
    const bend_in = smoothstep(elapsed / hunter_knockdown_enter_seconds);
    const stand_up = smoothstep(remaining / hunter_knockdown_exit_seconds);
    return @min(bend_in, stand_up);
}

pub fn mapItemVisible(discovery_bit: u32) bool {
    return game.debug.draw_physics or game.discovered_items & discovery_bit != 0;
}

pub fn targetItem(target: InteractionTarget) ?inventory.Item {
    return switch (target.kind) {
        .pickup => game.pickup_defs[target.index].item,
        .box_drop => blk: {
            const item = boxDropItem(target.index);
            break :blk if (item.occupied()) item else null;
        },
        .breakable, .door => null,
    };
}

pub fn doorName(door: level.DoorDef, index: usize) []const u8 {
    if (doorIsUnlocked(door, index)) return "Door";
    return switch (door.lock) {
        .none => "Door",
        .purple => "Purple Door",
        .pink => "Pink Door",
        .cyan => "Cyan Door",
    };
}

pub fn mapHalfHeight() f32 {
    return mapHalfWidth() / (sapp.widthf() / @max(sapp.heightf(), 1));
}

pub fn mapHalfWidth() f32 {
    const aspect = sapp.widthf() / @max(sapp.heightf(), 1);
    const half_x = (level.current.walk_max_x - level.current.walk_min_x) * 0.5 + map_margin;
    const half_z = (level.current.walk_max_z - level.current.walk_min_z) * 0.5 + map_margin;
    return @max(half_x, half_z * aspect);
}

pub fn mapWorldAtScreen(screen_x: f32, screen_y: f32) Vec3 {
    const normalized_x = screen_x / @max(sapp.widthf(), 1) * 2.0 - 1.0;
    const normalized_y = screen_y / @max(sapp.heightf(), 1) * 2.0 - 1.0;
    return .{
        .x = game.map.pan.x + normalized_x * mapHalfWidth(),
        .z = game.map.pan.z + normalized_y * mapHalfHeight(),
    };
}


pub fn nearSaveFixture() bool {
    const radius_squared = save_interaction_radius * save_interaction_radius;
    for (level.current.save_fixtures[0..level.current.save_fixture_count]) |fixture| {
        const dx = game.character.position.x - fixture.x;
        const dz = game.character.position.z - fixture.z;
        if (dx * dx + dz * dz <= radius_squared) return true;
    }
    return false;
}

