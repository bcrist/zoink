um: isize,

const Micron = @This();

pub fn mm(self: Micron, comptime F: type) F {
    const um: F = @floatFromInt(self.um);
    return um / 1000;
}

pub fn formatNumber(self: Micron, writer: *std.io.Writer, options: std.fmt.Number) !void {
    const precision = options.precision orelse 0;
    std.debug.assert((options.mode.base() orelse 10) == 10);

    var buf: [32]u8 = undefined;
    var end: usize = 0;
    var slice = buf[0..];

    const abs = @abs(self.um);
    if (self.um < 0) {
        buf[0] = '-';
        slice = slice[1..];
        end += 1;
    }

    const slice_len = std.fmt.printInt(slice, abs, 10, .lower, .{ .width = 4, .fill = '0' });
    const slice_end_of_int_part = slice_len - 3;
    end += slice_end_of_int_part;

    const frac = slice[slice_end_of_int_part..slice_len];
    var frac_trimmed = std.mem.trimRight(u8, frac, '0');
    if (frac_trimmed.len < precision) {
        // options requested more precision, but we won't give more than 3 digits since that's all that we have
        frac_trimmed = frac[0..@min(frac.len, precision)];
    } else if (frac_trimmed.len > precision) {
        // options requested less precision, and we're discarding some information.  We may need to round up the last displayed digit.
        const truncated = frac_trimmed[precision];
        if (truncated >= '5') {
            frac_trimmed[precision - 1] = switch(truncated) {
                '0'...'8' => truncated + 1,
                '9' => '0',
                else => unreachable,
            };
        }
        frac_trimmed = frac_trimmed[0..precision];
    }
    if (frac_trimmed.len > 0) {
        const moved_frac = slice[slice_end_of_int_part + 1..][0..frac_trimmed.len];
        std.mem.copyBackwards(u8, moved_frac, frac_trimmed);
        slice[slice_end_of_int_part] = '.';
        end += 1 + frac_trimmed.len;
    }

    buf[end] = 'm';
    buf[end+1] = 'm';

    return writer.alignBuffer(buf[0 .. end + 2], options.width, options.alignment, options.fill);
}

const std = @import("std");
