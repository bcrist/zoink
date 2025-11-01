numer: usize = 1,
denom: usize = 1,

const Ratio = @This();

pub fn mul(self: Ratio, val: Micron) Micron {
    const numer: isize = @intCast(self.numer);
    const denom: isize = @intCast(self.denom);
    return .{
        .um = @divTrunc(val.um * numer, denom),
    };
}

const Micron = @import("Micron.zig");
