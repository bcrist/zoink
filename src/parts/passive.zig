
pub fn Cap(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .C,
        },
        a: Net_ID = .unset,
        b: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.b,
                else => .unset
            };
        }
    };
}

pub fn Cap_Decoupler(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .C,
        },
        gnd: Net_ID = .unset,
        internal: Net_ID = .unset,
        external: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.gnd,
                2 => self.internal,
                3 => self.external,
                else => .unset
            };
        }
    };
}

pub fn Resistor(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .R,
        },
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        value: f32 = 1_000,
        max_power: f32 = 0.1,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.b,
                else => .unset
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => try v.verify_power_limit(self.a, self.b, self.value, self.max_power),
                .nets_only => try v.connect_nets(self.a, self.b, self.value),
            }
        }
    };
}

const Package = @import("../Package.zig");
const Net_ID = enums.Net_ID;
const Pin_ID = enums.Pin_ID;
const enums = @import("../enums.zig");
const Part = @import("../Part.zig");
const Validator = @import("../Validator.zig");
