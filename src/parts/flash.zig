
pub fn QSPI(
    comptime value: []const u8,
    comptime Power: type,
    comptime levels: type,
    comptime Pkg: type,
) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
            .value = value,
        },

        pwr: Power = .{},
        n_cs: Net_ID = .unset,
        clk: Net_ID = .unset,
        data: [4]Net_ID = @splat(.unset),

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.n_cs,
                2 => self.data[1], // SO in SPI mode
                3 => self.data[2],
                4 => self.pwr.gnd,
                5 => self.data[0], // SI in SPI mode
                6 => self.clk,
                7 => self.data[3],
                8 => self.pwr.vcc(0),
                else => std.debug.panic("QSPI flash does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            // TODO simulate SPI protocol & memory
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.n_cs, levels);
                    try v.expect_valid(self.clk, levels);
                    try v.expect_below(self.data, levels.Vclamp);
                },
                .nets_only => {},
            }
        }
    };
}

const log = std.log.scoped(.zoink);

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const packages = @import("../packages.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
const std = @import("std");
