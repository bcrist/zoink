numer: usize = 1,
denom: usize = 1,

const Ratio = @This();

pub fn mul(self: Ratio, val: Micron) Micron {
    return .{
        .um = @divTrunc(val.um * self.numer, self.denom),
    };
}

const Micron = @import("Micron.zig");
