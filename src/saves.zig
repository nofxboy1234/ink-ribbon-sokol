const std = @import("std");
const inventory = @import("inventory.zig");

pub const slot_count = 8;

pub const Slot = struct {
    occupied: bool = false,
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    yaw: f32 = 0,
    magazine: u16 = 24,
    reserve: u16 = 0,
    health: f32 = 100,
    inventory: inventory.State = .{},

    collected_pickups: u32 = 0,
    discovered_items: u32 = 0,
    broken_boxes: u32 = 0,

    box_drops_present: u32 = 0,
    box_drops_health: u32 = 0,
    collected_box_drops: u32 = 0,

    unlocked_doors: u32 = 0,
    elapsed_active_seconds: f64 = 0,
    damage_events: u32 = 0,
    deaths: u32 = 0,

    timestamp: i64 = 0,
};

pub var slots: [slot_count]Slot = @splat(.{});

const file_name = "saves.json";
const file_limit = 1 << 20;
const current_version: u32 = 10;

const FileFormat = struct {
    version: u32 = current_version,
    slots: [slot_count]Slot = @splat(.{}),
};

pub fn loadFromDir(dir: std.Io.Dir, io: std.Io) void {
    slots = @splat(.{});
    const contents = dir.readFileAlloc(io, file_name, std.heap.page_allocator, std.Io.Limit.limited(file_limit)) catch return;
    defer std.heap.page_allocator.free(contents);
    const parsed = std.json.parseFromSlice(FileFormat, std.heap.page_allocator, contents, .{
        .ignore_unknown_fields = true,
    }) catch return;
    defer parsed.deinit();
    if (parsed.value.version == current_version and parsed.value.slots.len == slot_count) slots = parsed.value.slots;
}

pub fn writeToDir(dir: std.Io.Dir, io: std.Io) !void {
    const data = try std.json.Stringify.valueAlloc(
        std.heap.page_allocator,
        FileFormat{ .version = current_version, .slots = slots },
        .{},
    );
    defer std.heap.page_allocator.free(data);
    const temp_name = file_name ++ ".tmp";
    try dir.writeFile(io, .{ .sub_path = temp_name, .data = data });
    try dir.rename(temp_name, dir, file_name, io);
}

pub fn loadFromCwd(io: std.Io) void {
    loadFromDir(std.Io.Dir.cwd(), io);
}

pub fn writeToCwd(io: std.Io) !void {
    try writeToDir(std.Io.Dir.cwd(), io);
}

test "slots round-trip through disk" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;

    slots = @splat(.{});
    slots[2] = .{
        .occupied = true,
        .x = 3.5,
        .y = 0.9,
        .z = -7.25,
        .yaw = 1.5708,
        .magazine = 7,
        .reserve = 61,
        .health = 42,
        .inventory = inventory.State.defaultLoadout(61),
        .collected_pickups = 0b101,
        .discovered_items = 0b10_1010,
        .broken_boxes = 0b011,
        .box_drops_present = 0b010,
        .box_drops_health = 0b010,
        .collected_box_drops = 0b001,
        .unlocked_doors = 0b0101,
        .timestamp = 1755892800,
    };
    slots[7] = .{ .occupied = true, .x = -12, .y = 0.9, .z = 15, .yaw = -0.5 };
    try writeToDir(tmp.dir, io);

    slots = @splat(.{});
    loadFromDir(tmp.dir, io);
    try std.testing.expect(slots[2].occupied);
    try std.testing.expectEqual(@as(f32, 3.5), slots[2].x);
    try std.testing.expectEqual(@as(f32, -7.25), slots[2].z);
    try std.testing.expectEqual(@as(f32, 1.5708), slots[2].yaw);
    try std.testing.expectEqual(@as(u16, 7), slots[2].magazine);
    try std.testing.expectEqual(@as(u16, 61), slots[2].reserve);
    try std.testing.expectEqual(@as(f32, 42), slots[2].health);
    try std.testing.expectEqual(@as(u16, 61), slots[2].inventory.totalAmmo());
    try std.testing.expectEqual(@as(u32, 0b101), slots[2].collected_pickups);
    try std.testing.expectEqual(@as(u32, 0b10_1010), slots[2].discovered_items);
    try std.testing.expectEqual(@as(u32, 0b011), slots[2].broken_boxes);
    try std.testing.expectEqual(@as(u32, 0b010), slots[2].box_drops_present);
    try std.testing.expectEqual(@as(u32, 0b010), slots[2].box_drops_health);
    try std.testing.expectEqual(@as(u32, 0b001), slots[2].collected_box_drops);
    try std.testing.expectEqual(@as(u32, 0b0101), slots[2].unlocked_doors);
    try std.testing.expectEqual(@as(i64, 1755892800), slots[2].timestamp);
    try std.testing.expect(slots[7].occupied);
    try std.testing.expect(!slots[0].occupied);
    try std.testing.expect(!slots[3].occupied);
}

test "missing save file leaves empty slots" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    slots[4] = .{ .occupied = true };
    defer slots[4] = .{};
    loadFromDir(tmp.dir, std.testing.io);
    for (slots) |slot| try std.testing.expect(!slot.occupied);
}

test "corrupt save file leaves empty slots" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = file_name, .data = "{not json at all" });

    slots[1] = .{ .occupied = true };
    defer slots[1] = .{};
    loadFromDir(tmp.dir, std.testing.io);
    for (slots) |slot| try std.testing.expect(!slot.occupied);
}
