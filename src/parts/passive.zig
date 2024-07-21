
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
        value: u32 = 1_000,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.b,
                else => .unset
            };
        }

        const Direction = enum {
            unknown,
            a_to_b,
            b_to_a,
            none,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Direction, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset, .commit => state.* = .unknown,
                .nets_only => switch (state.*) {
                    .none => {},
                    .a_to_b => {
                        const a = v.read_net(self.a);
                        const str = v.read_net_strength(self.a);
                        try v.drive_net(self.b, a, @enumFromInt(@max(1, str.raw() / self.value)));
                    },
                    .b_to_a => {
                        const b = v.read_net(self.b);
                        const str = v.read_net_strength(self.b);
                        try v.drive_net(self.a, b, @enumFromInt(@max(1, str.raw() / self.value)));
                    },
                    .unknown => {
                        const as = v.read_net_strength(self.a);
                        const bs = v.read_net_strength(self.b);
                        if (self.b.is_power() and !self.a.is_power() or bs != .hiz and as == .hiz) {
                            state.* = .b_to_a;
                            const b = v.read_net(self.b);
                            const str = v.read_net_strength(self.b);
                            try v.drive_net(self.a, b, @enumFromInt(@max(1, str.raw() / self.value)));
                        } else if (self.a.is_power() and !self.b.is_power() or as != .hiz and bs == .hiz) {
                            state.* = .a_to_b;
                            const a = v.read_net(self.a);
                            const str = v.read_net_strength(self.a);
                            try v.drive_net(self.b, a, @enumFromInt(@max(1, str.raw() / self.value)));
                        } else {
                            state.* = .none;
                        }
                    },
                },
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
