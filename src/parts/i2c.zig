pub fn EMC1702(comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.QFN_12_4x4_EP.pkg,
            .prefix = .U,
            .value = "EMC1702",
        },

        pwr: power.Single(.unset, Decoupler) = .{},
        @"sense+": Net_ID = .unset,
        @"sense-": Net_ID = .unset,
        @"d+": Net_ID = .unset,
        @"d-": Net_ID = .unset,
        address_sel: Net_ID = .unset,
        duration_sel: Net_ID = .unset,
        threshold_sel: Net_ID = .unset,
        n_therm: Net_ID = .unset,
        n_alert: Net_ID = .unset,
        sda: Net_ID = .unset,
        scl: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.pwr.vcc,
                2 => self.@"d+",
                3 => self.@"d-",
                4 => self.address_sel,
                5 => self.n_therm,
                6 => self.n_alert,
                7 => self.sda,
                8 => self.scl,
                9 => self.duration_sel,
                10 => self.threshold_sel,
                11 => self.@"sense-",
                12 => self.@"sense+",
                else => std.debug.panic("EMC1702 does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        // TODO check voltages in valid range during validation
    };
}

pub fn Linear_5pin(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        v_in: Net_ID = .unset,
        enable: Net_ID = .unset,
        gnd: Net_ID = .gnd,
        v_out: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.v_in,
                2 => self.gnd,
                3 => self.enable,
                4 => .no_connect,
                5 => self.v_out,
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
const std = @import("std");
