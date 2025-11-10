deg: isize = 0,

const Rotation = @This();

pub const none: Rotation = .{ .deg = 0 };
pub const ccw: Rotation = .{ .deg = 90 };
pub const ccw45: Rotation = .{ .deg = 45 };
pub const cw: Rotation = .{ .deg = -90 };
pub const cw45: Rotation = .{ .deg = -45 };
pub const _180: Rotation = .{ .deg = 180 };

pub fn formatNumber(self: Rotation, options: std.fmt.Number, writer: *std.io.Writer) !void {
    var buf: [32]u8 = undefined;
    var w = std.io.Writer.fixed(&buf);
    try w.printInt(self.deg, options.mode.base() orelse 10, options.case, .{
        .precision = options.precision,
        .width = if (options.width) |width| (if (width > 0) 1 else null) else null,
    });
    try w.writeAll("deg");
    try writer.alignBuffer(w.buffered(), options.width, options.alignment, options.fill);
}

const std = @import("std");
