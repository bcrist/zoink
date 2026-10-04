/// I2C voltage/current monitor + 2-channel temperature sensor (1 internal + 1 external diode)
/// https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/EMC1702-Data-Sheet-DS20006455A.pdf
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

/// I2C 2-channel temperature sensor (1 internal + 1 external diodes)
/// https://ww1.microchip.com/downloads/en/DeviceDoc/20005751D.pdf
pub fn EMC1812(comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.DFN_8_2x2_EP.pkg,
            .prefix = .U,
            .value = "EMC1812",
        },

        pwr: power.Single(.unset, Decoupler) = .{},
        @"d+": Net_ID = .unset,
        @"d-": Net_ID = .unset,
        @"n_therm/address_sel": Net_ID = .unset,
        @"n_alert/n_therm2": Net_ID = .unset,
        sda: Net_ID = .unset,
        scl: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.pwr.vcc(0),
                2 => self.@"d+",
                3 => self.@"d-",
                4 => self.@"n_therm/address_sel",
                5 => self.pwr.gnd,
                6 => self.@"n_alert/n_therm2",
                7 => self.sda,
                8 => self.scl,
                else => std.debug.panic("EMC1812 does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        // TODO check voltages in valid range during validation
    };
}

/// I2C 3-channel temperature sensor (1 internal + 2 external diodes)
/// https://ww1.microchip.com/downloads/en/DeviceDoc/20005751D.pdf
pub fn EMC1813(comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.@"DFN_10_2.5x2".pkg,
            .prefix = .U,
            .value = "EMC1813",
        },

        pwr: power.Single(.unset, Decoupler) = .{},
        @"d1+": Net_ID = .unset,
        @"d1-": Net_ID = .unset,
        @"d2+": Net_ID = .unset,
        @"d2-": Net_ID = .unset,
        @"n_therm/address_sel": Net_ID = .unset,
        @"n_alert/n_therm2": Net_ID = .unset,
        sda: Net_ID = .unset,
        scl: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.pwr.vcc(0),
                2 => self.@"d1+",
                3 => self.@"d1-",
                4 => self.@"d2+",
                5 => self.@"d2-",
                6 => self.pwr.gnd,
                7 => self.@"n_therm/address_sel",
                8 => self.@"n_alert/n_therm2",
                9 => self.sda,
                10 => self.scl,
                else => std.debug.panic("EMC1813 does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        // TODO check voltages in valid range during validation
    };
}

/// I2C 4-channel temperature sensor (1 internal + 3 external diodes)
/// https://ww1.microchip.com/downloads/en/DeviceDoc/20005751D.pdf
pub fn EMC1814(comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.@"DFN_10_2.5x2".pkg,
            .prefix = .U,
            .value = "EMC1814",
        },

        pwr: power.Single(.unset, Decoupler) = .{},
        @"d1+": Net_ID = .unset,
        @"d1-": Net_ID = .unset,
        @"d2+/d3-": Net_ID = .unset,
        @"d2-/d3+": Net_ID = .unset,
        @"n_therm/address_sel": Net_ID = .unset,
        @"n_alert/n_therm2": Net_ID = .unset,
        sda: Net_ID = .unset,
        scl: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.pwr.vcc(0),
                2 => self.@"d1+",
                3 => self.@"d1-",
                4 => self.@"d2+/d3-",
                5 => self.@"d2-/d3+",
                6 => self.pwr.gnd,
                7 => self.@"n_therm/address_sel",
                8 => self.@"n_alert/n_therm2",
                9 => self.sda,
                10 => self.scl,
                else => std.debug.panic("EMC1814 does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        // TODO check voltages in valid range during validation
    };
}

/// I2C 5-channel temperature sensor (1 internal + 4 external diodes)
/// https://ww1.microchip.com/downloads/en/DeviceDoc/20005751D.pdf
pub fn EMC1815(comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.@"DFN_10_2.5x2".pkg,
            .prefix = .U,
            .value = "EMC1815",
        },

        pwr: power.Single(.unset, Decoupler) = .{},
        @"d1+/d2-": Net_ID = .unset,
        @"d1-/d2+": Net_ID = .unset,
        @"d3+/d4-": Net_ID = .unset,
        @"d3-/d4+": Net_ID = .unset,
        @"n_therm/address_sel": Net_ID = .unset,
        @"n_alert/n_therm2": Net_ID = .unset,
        sda: Net_ID = .unset,
        scl: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => self.pwr.gnd,
                1 => self.pwr.vcc(0),
                2 => self.@"d1+/d2-",
                3 => self.@"d1-/d2+",
                4 => self.@"d3+/d4-",
                5 => self.@"d3-/d4+",
                6 => self.pwr.gnd,
                7 => self.@"n_therm/address_sel",
                8 => self.@"n_alert/n_therm2",
                9 => self.sda,
                10 => self.scl,
                else => std.debug.panic("EMC1815 does not have pin {}", .{ @intFromEnum(pin_id) }),
            };
        }

        // TODO check voltages in valid range during validation
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
const std = @import("std");
