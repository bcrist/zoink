deg: isize = 0,

const Rotation = @This();

pub const ccw: Rotation = .{ .deg = 90 };
pub const ccw45: Rotation = .{ .deg = 45 };
pub const cw: Rotation = .{ .deg = -90 };
pub const cw45: Rotation = .{ .deg = -45 };
pub const flip: Rotation = .{ .deg = 180 };

pub fn format(self: Rotation, fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    return try std.fmt.formatInt(self.deg, 10, .lower, options, writer);
}

const std = @import("std");
