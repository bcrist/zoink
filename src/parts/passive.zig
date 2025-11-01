pub fn Cap(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .C,
        },
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        value_nf: f32 = 100,
        voltage_rating: f32 = 50,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.b,
                else => .unset
            };
        }

        pub fn check_config(self: *@This(), b: *Board) !void {
            if (self.base.value.len == 0) {
                if (self.value_nf < 1) {
                    self.base.value = b.fmt("{} pF", .{ self.value_nf * 1000 });
                } else if (self.value_nf < 1000) {
                    self.base.value = b.fmt("{} nF", .{ self.value_nf });
                } else {
                    self.base.value = b.fmt("{} µF", .{ self.value_nf / 1000 });
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            if (!self.base.populate) return;
            switch (mode) {
                .reset => {},
                .commit => try v.verify_voltage_rating(self.a, self.b, self.voltage_rating),
                .nets_only => {},
            }
        }
    };
}

pub fn Cap_Decoupler(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .C,
        },
        gnd: Net_ID = .gnd,
        internal: Net_ID = .unset,
        external: Net_ID = .unset,
        value_nf: f32 = 100,
        voltage_rating: f32 = 50,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.gnd,
                2 => self.gnd,
                3 => self.internal,
                4 => self.external,
                else => .unset
            };
        }

        pub fn check_config(self: *@This(), b: *Board) !void {
            if (self.base.value.len == 0) {
                if (self.value_nf < 1) {
                    self.base.value = b.fmt("{} pF", .{ self.value_nf * 1000 });
                } else if (self.value_nf < 1000) {
                    self.base.value = b.fmt("{} nF", .{ self.value_nf });
                } else {
                    self.base.value = b.fmt("{} µF", .{ self.value_nf / 1000 });
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            if (!self.base.populate) return;
            switch (mode) {
                .reset => {},
                .commit => try v.verify_voltage_rating(self.gnd, self.external, self.voltage_rating),
                .nets_only => try v.connect_nets(self.internal, self.external, 0.001),
            }
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

        pub fn check_config(self: *@This(), b: *Board) !void {
            if (self.base.value.len == 0) {
                if (self.value < 1000) {
                    self.base.value = b.fmt("{}", .{ self.value });
                } else if (self.value < 1000000) {
                    self.base.value = b.fmt("{} k", .{ self.value / 1000 });
                } else {
                    self.base.value = b.fmt("{} M", .{ self.value / 1000000 });
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            if (!self.base.populate) return;
            switch (mode) {
                .reset => {},
                .commit => try v.verify_power_limit(self.a, self.b, @max(0.001, self.value), self.max_power),
                .nets_only => try v.connect_nets(self.a, self.b, @max(0.001, self.value)),
            }
        }
    };
}

pub fn Resistor_Kelvin(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .R,
        },
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        a_sense: Net_ID = .unset,
        b_sense: Net_ID = .unset,
        value: f32 = 1,
        max_power: f32 = 1,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.a_sense,
                3 => self.b_sense,
                4 => self.b,
                else => .unset
            };
        }

        pub fn check_config(self: *@This(), b: *Board) !void {
            if (self.base.value.len == 0) {
                if (self.value < 1000) {
                    self.base.value = b.fmt("{}", .{ self.value });
                } else if (self.value < 1000000) {
                    self.base.value = b.fmt("{} k", .{ self.value / 1000 });
                } else {
                    self.base.value = b.fmt("{} M", .{ self.value / 1000000 });
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            if (!self.base.populate) return;
            switch (mode) {
                .reset => {},
                .commit => try v.verify_power_limit(self.a, self.b, @max(0.001, self.value), self.max_power),
                .nets_only => {
                    try v.connect_nets(self.a, self.b, @max(0.001, self.value));
                    try v.connect_nets(self.a, self.a_sense, 0.001);
                    try v.connect_nets(self.a, self.b_sense, 0.001);
                },
            }
        }
    };
}

pub fn Inductor(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .R,
        },
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        value_nh: f32 = 1_000,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.b,
                else => .unset
            };
        }

        pub fn check_config(self: *@This(), b: *Board) !void {
            if (self.base.value.len == 0) {
                if (self.value_nh < 1) {
                    self.base.value = b.fmt("{} pH", .{ self.value_nh * 1000 });
                } else if (self.value_nh < 1000) {
                    self.base.value = b.fmt("{} nH", .{ self.value_nh });
                } else {
                    self.base.value = b.fmt("{} µH", .{ self.value_nh / 1000 });
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            if (!self.base.populate) return;
            switch (mode) {
                .reset => {},
                .commit => {},
                .nets_only => try v.connect_nets(self.a, self.b, 0.1),
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
const Board = @import("../Board.zig");
