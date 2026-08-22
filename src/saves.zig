//! Persistent save slots for the typewriter save stations.
//!
//! Eight numbered slots in the spirit of Resident Evil 2 Remake. A slot
//! records the player's position and heading inside the level; the world is
//! static, so nothing else is needed to restore a moment. All slots live in
//! one JSON file so a single read/write keeps them consistent.

const std = @import("std");

pub const slot_count = 8;

pub const Slot = struct {
    occupied: bool = false,
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    yaw: f32 = 0,
    // Unix epoch seconds when the slot was written, for the slot list UI.
    timestamp: i64 = 0,
};

pub var slots: [slot_count]Slot = @splat(.{});

const file_name = "saves.json";
const file_limit = 1 << 20;
const current_version: u32 = 2;

const FileFormat = struct {
    version: u32 = current_version,
    slots: [slot_count]Slot = @splat(.{}),
};

// Read all slots from disk. A missing or corrupt file simply leaves every
// slot empty; saving is never blocked by load problems.
pub fn loadFromDir(dir: std.Io.Dir, io: std.Io) void {
    slots = @splat(.{});
    const contents = dir.readFileAlloc(io, file_name, std.heap.page_allocator, std.Io.Limit.limited(file_limit)) catch return;
    defer std.heap.page_allocator.free(contents);
    const parsed = std.json.parseFromSlice(FileFormat, std.heap.page_allocator, contents, .{
        .ignore_unknown_fields = true,
    }) catch return;
    defer parsed.deinit();
    if (parsed.value.version == current_version and parsed.value.slots.len == slot_count) {
        slots = parsed.value.slots;
    }
}

// Write every slot back to disk atomically enough for this game's purposes:
// dump to a temp name, then rename over the real file.
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
    slots[2] = .{ .occupied = true, .x = 3.5, .y = 0.9, .z = -7.25, .yaw = 1.5708, .timestamp = 1755892800 };
    slots[7] = .{ .occupied = true, .x = -12, .y = 0.9, .z = 15, .yaw = -0.5 };
    try writeToDir(tmp.dir, io);

    slots = @splat(.{});
    loadFromDir(tmp.dir, io);
    try std.testing.expect(slots[2].occupied);
    try std.testing.expectEqual(@as(f32, 3.5), slots[2].x);
    try std.testing.expectEqual(@as(f32, -7.25), slots[2].z);
    try std.testing.expectEqual(@as(f32, 1.5708), slots[2].yaw);
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

test "old level saves are ignored" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var old_slots: [slot_count]Slot = @splat(.{});
    old_slots[0] = .{ .occupied = true, .x = 15.5, .z = 12.4 };
    const data = try std.json.Stringify.valueAlloc(
        std.heap.page_allocator,
        FileFormat{ .version = 1, .slots = old_slots },
        .{},
    );
    defer std.heap.page_allocator.free(data);
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = file_name, .data = data });

    loadFromDir(tmp.dir, std.testing.io);
    for (slots) |slot| try std.testing.expect(!slot.occupied);
}
