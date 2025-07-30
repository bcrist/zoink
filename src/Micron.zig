um: isize,

const Micron = @This();

pub fn mm(self: Micron, comptime F: type) F {
    const um: F = @floatFromInt(self.um);
    return um / 1000;
}

pub fn format(self: Micron, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    if (fmt.len > 0) {
        return try std.fmt.formatInt(self.um, 10, .lower, options, writer);
    }    

    const abs = @abs(self.um);
    if (self.um < 0) try writer.writeByte('-');

    var buf: [22]u8 = undefined;
    const buf_len = std.fmt.formatIntBuf(&buf, abs, 10, .lower, .{ .width = 4, .fill = '0' });
    try writer.writeAll(buf[0 .. buf_len - 3]);

    const frac = buf[buf_len - 3 .. buf_len];
    const frac_trimmed = std.mem.trimRight(u8, frac, '0');
    if (frac_trimmed.len > 0) {
        try writer.writeByte('.');
        try writer.writeAll(frac_trimmed);
    }
}

const std = @import("std");
