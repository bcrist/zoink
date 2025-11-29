raw: u128,

pub const nil: Uuid = .{ .raw = 0 };

pub fn init_v8_from_hash(hash: u64) Uuid {
    const high_part: u128 = @as(u128, hash & 0xFFFF_FFFF_0000_0000) << 64;
    const low_part: u128 = hash & 0xFFFF_FFFF;
    const fixed_part: u128 = 0x8888_8888_8888_8888_0000_0000;
    return .{
        .raw = high_part | fixed_part | low_part,
    };
}

pub fn set_mid(self: *Uuid, mid: u16) void {
    self.raw = (self.raw & 0xFFFF_FFFF_FFFF_FFFF_FFFF_0000_FFFF_FFFF) | (@as(u128, mid) << 32);
}

pub fn to_hash(self: Uuid) ?u64 {
    if ((self.raw & 0xFFFF_FFFF_FFFF_FFFF_0000_0000) == 0x8888_8888_8888_8888_0000_0000) {
        const low: u32 = @truncate(self.raw);
        const high: u64 = @intCast((self.raw >> 64) & 0xFFFF_FFFF_0000_0000);
        return high | low;
    }
    return null;
}

pub fn read(r: *sx.Reader) !?Uuid {
    if (!try r.expression("uuid")) return null;

    var uuid: Uuid = .nil;

    if (try r.any_string()) |raw| {
        for (raw) |ch| {
            const val: u4 = @intCast(switch (ch) {
                '0'...'9' => ch - '0',
                'a'...'f' => ch - 'a' + 10,
                'A'...'F' => ch - 'A' + 10,
                else => continue,
            });
            uuid.raw = (uuid.raw << 4) | val;
        }
    }

    try r.require_close();
    return uuid;
}

pub fn write(self: Uuid, w: *sx.Writer) !void {
    if (self.raw == 0) return;

    try w.expression("uuid");
        try w.print_quoted("{x:0>8}-{x:0>4}-{x:0>4}-{x:0>4}-{x:0>12}", .{
        self.raw >> 96,
        @as(u16, @truncate(self.raw >> 80)),
        @as(u16, @truncate(self.raw >> 64)),
        @as(u16, @truncate(self.raw >> 48)),
        @as(u48, @truncate(self.raw)),
    });
    try w.close();
}

pub fn format(self: Uuid, w: *std.io.Writer) !void {
    try w.print("{x:0>8}-{x:0>4}-{x:0>4}-{x:0>4}-{x:0>12}", .{
        self.raw >> 96,
        @as(u16, @truncate(self.raw >> 80)),
        @as(u16, @truncate(self.raw >> 64)),
        @as(u16, @truncate(self.raw >> 48)),
        @as(u48, @truncate(self.raw)),
    });
}

const Uuid = @This();

const sx = @import("sx");
const std = @import("std");
