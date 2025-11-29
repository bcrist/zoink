pub fn JTAG(comptime vcc: Net_ID) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.bmc.Trident.pkg,
            .prefix = .J,
        },

        pwr: power.Single(vcc, void) = .{},
        tck: Net_ID,
        tms: Net_ID,
        tdi: Net_ID,
        tdo: Net_ID,
        sense: Net_ID = .gnd,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => .no_connect,
                1 => self.tck,
                2 => self.tdi,
                3 => self.pwr.gnd,
                4 => self.sense,
                5 => @field(self.pwr, @tagName(vcc)),
                6 => self.tdo,
                7 => self.tms,
                else => unreachable,
            };
        }
    };
}

pub fn SWD(comptime vcc: Net_ID) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.bmc.Trident.pkg,
            .prefix = .J,
        },

        pwr: power.Single(vcc, void) = .{},
        swclk: Net_ID,
        swdio: Net_ID,
        reset: Net_ID,
        swo_or_uart: Net_ID,
        sense: Net_ID = .gnd,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => .no_connect,
                1 => self.swclk,
                2 => self.swdio,
                3 => self.pwr.gnd,
                4 => self.sense,
                5 => @field(self.pwr, @tagName(vcc)),
                6 => self.swo_or_uart,
                7 => self.reset,
                else => unreachable,
            };
        }
    };
}

pub fn Generic(comptime vcc: Net_ID) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.bmc.Trident.pkg,
            .prefix = .J,
        },

        pwr: power.Single(vcc, void) = .{},
        p1: Net_ID,
        p2: Net_ID,
        p6: Net_ID,
        p7: Net_ID,
        sense: Net_ID = .gnd,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => .no_connect,
                1 => self.p1,
                2 => self.p2,
                3 => self.pwr.gnd,
                4 => self.sense,
                5 => @field(self.pwr, @tagName(vcc)),
                6 => self.p6,
                7 => self.p7,
                else => unreachable,
            };
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
