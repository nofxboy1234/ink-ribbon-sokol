//! Persistent save slots for the typewriter save stations.
//!
//! Eight numbered slots in the spirit of Resident Evil 2 Remake. A slot
//! records pose, ammunition, health, inventory layout, discovered items,
//! collected pickups, broken containers, and randomized container drops.
//! All slots live in one JSON file so a single read/write keeps them consistent.

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
    reserve: u16 = 120,
    health: f32 = 100,
    inventory: inventory.State = .{},
    // Bit N is set after authored world pickup N has been collected.
    collected_pickups: u32 = 0,
    discovered_items: u32 = 0,
    broken_boxes: u32 = 0,
    // Broken-box outcomes are stored once so loading cannot reroll a box.
    box_drops_present: u32 = 0,
    box_drops_health: u32 = 0,
    collected_box_drops: u32 = 0,
    // Door masks preserve permanent unlock/open state and the chosen swing
    // direction for each authored door.
    unlocked_doors: u32 = 0,
    opened_doors: u32 = 0,
    door_swing_positive: u32 = 0,
    // Unix epoch seconds when the slot was written, for the slot list UI.
    timestamp: i64 = 0,
};

pub var slots: [slot_count]Slot = @splat(.{});

const file_name = "saves.json";
const file_limit = 1 << 20;
const current_version: u32 = 8;

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
    if ((parsed.value.version >= 2 and parsed.value.version <= current_version) and parsed.value.slots.len == slot_count) {
        slots = parsed.value.slots;
        // Versions 2/3 predate the grid. Reconstruct their reserve ammunition
        // as an inventory item and grant one healing item.
        if (parsed.value.version <= 3) {
            for (&slots) |*slot| if (slot.occupied) {
                slot.inventory = inventory.State.defaultLoadout(slot.reserve);
                slot.health = 100;
                slot.collected_pickups = 0;
            };
        }
        // Version 8 removes false T-junction doors and appends an explicit
        // hunter-room door. Preserve state for every surviving physical door,
        // while carrying the three colored lock states to their new entrances.
        if (parsed.value.version == 7) {
            for (&slots) |*slot| if (slot.occupied) {
                slot.opened_doors = remapDoorMaskV7(slot.opened_doors);
                slot.door_swing_positive = remapDoorMaskV7(slot.door_swing_positive);
                var unlocked = remapDoorMaskV7(slot.unlocked_doors);
                const colored_mask = doorBit(0) | doorBit(5) | doorBit(10);
                unlocked &= ~colored_mask;
                if (slot.unlocked_doors & doorBit(0) != 0) unlocked |= doorBit(0); // pink
                if (slot.unlocked_doors & doorBit(5) != 0) unlocked |= doorBit(5); // purple
                if (slot.unlocked_doors & doorBit(9) != 0) unlocked |= doorBit(10); // cyan
                slot.unlocked_doors = unlocked;
            };
        }
    }
}

fn doorBit(index: u5) u32 {
    return @as(u32, 1) << index;
}

fn remapDoorMaskV7(old: u32) u32 {
    const mapping = [_]struct { old: u5, new: u5 }{
        .{ .old = 0, .new = 0 },
        .{ .old = 1, .new = 1 },
        .{ .old = 2, .new = 2 },
        .{ .old = 3, .new = 3 },
        .{ .old = 4, .new = 4 },
        .{ .old = 6, .new = 5 },
        .{ .old = 7, .new = 6 },
        .{ .old = 8, .new = 7 },
        .{ .old = 11, .new = 8 },
        .{ .old = 12, .new = 9 },
        .{ .old = 13, .new = 10 },
        .{ .old = 14, .new = 11 },
        .{ .old = 15, .new = 12 },
        .{ .old = 16, .new = 13 },
        .{ .old = 18, .new = 14 },
        .{ .old = 19, .new = 15 },
        .{ .old = 21, .new = 16 },
    };
    var result: u32 = 0;
    for (mapping) |entry| {
        if (old & doorBit(entry.old) != 0) result |= doorBit(entry.new);
    }
    return result;
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
        .opened_doors = 0b0011,
        .door_swing_positive = 0b0010,
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
    try std.testing.expectEqual(@as(u32, 0b0011), slots[2].opened_doors);
    try std.testing.expectEqual(@as(u32, 0b0010), slots[2].door_swing_positive);
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

test "version seven door masks migrate to validated door indices" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;
    var old_slots: [slot_count]Slot = @splat(.{});
    old_slots[0] = .{
        .occupied = true,
        .opened_doors = doorBit(0) | doorBit(6) | doorBit(11) | doorBit(21),
        .door_swing_positive = doorBit(7) | doorBit(19),
        .unlocked_doors = doorBit(0) | doorBit(5) | doorBit(9),
    };
    const data = try std.json.Stringify.valueAlloc(
        std.heap.page_allocator,
        FileFormat{ .version = 7, .slots = old_slots },
        .{},
    );
    defer std.heap.page_allocator.free(data);
    try tmp.dir.writeFile(io, .{ .sub_path = file_name, .data = data });

    loadFromDir(tmp.dir, io);
    try std.testing.expectEqual(doorBit(0) | doorBit(5) | doorBit(8) | doorBit(16), slots[0].opened_doors);
    try std.testing.expectEqual(doorBit(6) | doorBit(15), slots[0].door_swing_positive);
    try std.testing.expectEqual(doorBit(0) | doorBit(5) | doorBit(10), slots[0].unlocked_doors);
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

test "version two saves migrate with a full default loadout" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const data =
        \\{"version":2,"slots":[{"occupied":true,"x":1,"y":0.9,"z":2,"yaw":3},{},{},{},{},{},{},{}]}
    ;
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = file_name, .data = data });
    loadFromDir(tmp.dir, std.testing.io);
    try std.testing.expect(slots[0].occupied);
    try std.testing.expectEqual(@as(u16, 24), slots[0].magazine);
    try std.testing.expectEqual(@as(u16, 120), slots[0].reserve);
    try std.testing.expectEqual(@as(u16, 120), slots[0].inventory.totalAmmo());
    try std.testing.expectEqual(inventory.ItemKind.health, slots[0].inventory.cells[1].kind);
}
