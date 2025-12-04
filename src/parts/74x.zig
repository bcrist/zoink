pub const Family = enum {
    TTL,
    S,
    AS,
    LS,
    ALS,
    F,
    H,
    ABT,
    LVT,
    ALVT,
    C,
    HC,
    HCT,
    FCT,
    AC,
    ACT,
    AHC,
    AHCT,
    VHC,
    VHCT,
    LV,
    LVC,
    ALVC,
    LCX,
    LVX,
    AVC,
    AUP,
    AUC,
    CBT,
    CBTLV,

    pub fn value(comptime self: Family, comptime suffix: []const u8) []const u8 {
        return switch (self) {
            .TTL => "74",
            else => "74" ++ @tagName(self),
        } ++ suffix;
    }

    pub fn default_vcc(self: Family) Net_ID {
        return switch (self) {
            .TTL,
            .S,
            .AS,
            .LS,
            .ALS,
            .F,
            .H,
            .ABT,
            .C,
            .HC,
            .HCT,
            .FCT,
            .AC,
            .ACT,
            .AHC,
            .AHCT,
            .VHC,
            .VHCT,
            .CBT,
            => .p5v,

            .LVT,
            .ALVT,
            .LV,
            .LVC,
            .ALVC,
            .LCX,
            .LVX,
            .AVC,
            .AUP,
            .CBTLV,
            => .p3v3,

            .AUC,
            => .p1v8,
        };
    }

    pub fn levels(comptime self: Family, comptime vcc: Net_ID) type {
        return switch (self) {
            .TTL,
            .S,
            .AS,
            .LS,
            .ALS,
            .F,
            .H,
            => {
                std.debug.assert(vcc == .p5v);
                return Voltage.TTL;
            },

            .ABT => {
                std.debug.assert(vcc == .p5v);
                return Voltage.BiCMOS;
            },

            .LVT,
            .ALVT,
            => {
                std.debug.assert(vcc == .p3v3);
                return Voltage.LVBiCMOS_5VT;
            },

            .C,
            .HC,
            .AC,
            .AHC,
            .VHC,
            => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 2.0);
                std.debug.assert(v <= 6.0);
                return Voltage.CMOS_V(.from_net(vcc), .{});
            },

            .HCT,
            .ACT,
            .AHCT,
            .VHCT,
            .CBT,
            => {
                // N.B. these are not actual BiCMOS families, but their levels are similar: TTL input levels and CMOS output levels
                std.debug.assert(vcc == .p5v);
                return Voltage.BiCMOS;
            },

            .FCT => {
                // N.B. some FCT parts are 5V while others are 3.3V
                // N.B. this is not an actual BiCMOS family, but their levels are similar: TTL input levels and CMOS output levels
                return switch (vcc) {
                    .p5v => Voltage.BiCMOS,
                    .p3v3 => Voltage.LVBiCMOS,
                    else => unreachable,
                };
            },

            .ALVC,
            .AVC,
            => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 1.2);
                std.debug.assert(v <= 3.6);
                return Voltage.CMOS_V(.from_net(vcc), .{});
            },

            .LV,
            .LVC,
            => {
                // N.B. Some LV/LVC parts allow Vcc up to 5.5V, but others max out at 3.6V.
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 1);
                std.debug.assert(v <= 5.5);
                return Voltage.CMOS_V(.from_net(vcc), .{ .clamp = .from_float(@max(v, 5.0)) });
            },

            .CBTLV,
            => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 2.3);
                std.debug.assert(v <= 3.6);
                return Voltage.CMOS_V(.from_net(vcc), .{ .clamp = .from_float(@max(v, 3.3)) });
            },

            .LCX => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 2.3);
                std.debug.assert(v <= 3.6);
                return Voltage.CMOS_V(.from_net(vcc), .{ .clamp = .p5v });
            },

            .LVX => {
                // N.B. LVX pins that are input-only are 5V tolerant, but bidirectional pins are not, even when the output buffer is disabled.
                // Therefore we're going to act like all pins have protection diodes to Vcc
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 2);
                std.debug.assert(v <= 3.6);
                return Voltage.CMOS_V(.from_net(vcc), .{});
            },

            .AUP => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 0.8);
                std.debug.assert(v <= 3.6);
                return Voltage.CMOS_V(.from_net(vcc), .{ .clamp = .p3v3 });
            },

            .AUC => {
                const v = Voltage.from_net(vcc).as_float();
                std.debug.assert(v >= 0.8);
                std.debug.assert(v <= 2.7);
                return Voltage.CMOS_V(.from_net(vcc), .{ .clamp = .p3v3 });
            },
        };
    }

};

pub const Options = struct {
    logic_family: Family,
    Package: type,
    pwr: Net_ID,
    levels: type,
    Decoupler: type,

    pub fn init(comptime logic_family: Family, comptime Pkg: type) Options {
        return comptime .{
            .logic_family = logic_family,
            .Package = Pkg,
            .pwr = logic_family.default_vcc(),
            .levels = logic_family.levels(logic_family.default_vcc()),
            .Decoupler = parts.C0402_Decoupler,
        };
    }

    pub fn base(comptime self: Options, comptime value_suffix: []const u8) Part.Base {
        return .{
            .package = &self.Package.pkg,
            .prefix = .U,
            .value = self.logic_family.value(value_suffix),
        };
    }
};

fn Single_Buffer(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        y: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => .no_connect,
                2 => self.a,
                3 => self.pwr.gnd,
                4 => self.y,
                5 => if (options.Package.data.num_pads() == 6) .no_connect else @field(self.pwr, @tagName(options.pwr)),
                6 => if (options.Package.data.num_pads() == 6) @field(self.pwr, @tagName(options.pwr)) else unreachable,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, options.levels);
                    const a = v.read_logic(self.a, options.levels);
                    try v.expect_output_valid(self.y, if (invert) !a else a, options.levels);
                },
                .nets_only => {
                    const a = v.read_logic(self.a, options.levels);
                    try v.drive_logic(self.y, if (invert) !a else a, options.levels);
                },
            }
        }
    };
}

fn Dual_Buffer(comptime value_suffix: []const u8, comptime options: Options, comptime invert: usize) type {
    const invert_array: [2]bool = .{
        (invert & 1) != 0,
        (invert & 2) != 0,
    };
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [2]Individual_Impl,
        } = .{ .bus = .{} },
        remap: [2]u1 = .{ 0, 1 },

        const Bus_Impl = struct {
            a: [2]Net_ID = @splat(.unset),
            y: [2]Net_ID = @splat(.unset),
        };

        const Individual_Impl = struct {
            a: Net_ID = .unset,
            y: Net_ID = .unset,
        };

        pub fn check_config(self: @This()) !void {
            var mapped_logical_bufs: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_bufs[logical] = true;
            }
            for (0.., mapped_logical_bufs) |logical_buf, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical buffer assigned to logical buffer {}", .{ @typeName(@This()), logical_buf });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    2 => self.pwr.gnd,
                    5 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.a[self.remap[0]],
                    6 => impl.y[self.remap[0]],

                    3 => impl.a[self.remap[1]],
                    4 => impl.y[self.remap[1]],

                    else => unreachable,
                },
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    2 => self.pwr.gnd,
                    5 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[self.remap[0]].a,
                    6 => impl[self.remap[0]].y,

                    3 => impl[self.remap[1]].a,
                    4 => impl[self.remap[1]].y,

                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.a, options.levels);
                        const a = v.read_bus(impl.a, options.levels);
                        try v.expect_output_valid(impl.y, a ^ invert, options.levels);
                    },
                    .individual => |impl| for (0.., impl) |n, buf| {
                        try v.expect_valid(buf.a, options.levels);
                        const a = v.read_logic(buf.a, options.levels);
                        try v.expect_output_valid(buf.y, a != invert_array[n], options.levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const a = v.read_bus(impl.a, options.levels);
                        try v.drive_bus(impl.y, a ^ invert, options.levels);
                    },
                    .individual => |impl| for (0.., impl) |n, buf| {
                        const a = v.read_logic(buf.a, options.levels);
                        try v.drive_logic(buf.y, a != invert_array[n], options.levels);
                    },
                },
            }
        }
    };
}

fn Hex_Buffer(comptime value_suffix: []const u8, comptime options: Options, invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [6]Individual_Impl,
        } = .{ .bus = .{} },
        remap: [6]u3 = .{ 0, 1, 2, 3, 4, 5 },

        const Bus_Impl = struct {
            a: [6]Net_ID = @splat(.unset),
            y: [6]Net_ID = @splat(.unset),
        };

        const Individual_Impl = struct {
            a: Net_ID = .unset,
            y: Net_ID = .unset,
        };

        pub fn check_config(self: @This()) !void {
            var mapped_logical_gates: [6]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_gates[logical] = true;
            }
            for (0.., mapped_logical_gates) |logical_gate, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical gate assigned to logical gate {}", .{ @typeName(@This()), logical_gate });
                    return error.InvalidRemap;
                }
            }
        }

        fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.a[self.remap[0]],
                    2 => impl.y[self.remap[0]],

                    3 => impl.a[self.remap[1]],
                    4 => impl.y[self.remap[1]],

                    5 => impl.a[self.remap[2]],
                    6 => impl.y[self.remap[2]],

                    9 => impl.a[self.remap[3]],
                    8 => impl.y[self.remap[3]],

                    11 => impl.a[self.remap[4]],
                    10 => impl.y[self.remap[4]],

                    13 => impl.a[self.remap[5]],
                    12 => impl.y[self.remap[5]],

                    else => unreachable,
                },
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[self.remap[0]].a,
                    2 => impl[self.remap[0]].y,

                    3 => impl[self.remap[1]].a,
                    4 => impl[self.remap[1]].y,

                    5 => impl[self.remap[2]].a,
                    6 => impl[self.remap[2]].y,

                    9 => impl[self.remap[3]].a,
                    8 => impl[self.remap[3]].y,

                    11 => impl[self.remap[4]].a,
                    10 => impl[self.remap[4]].y,

                    13 => impl[self.remap[5]].a,
                    12 => impl[self.remap[5]].y,

                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.a, options.levels);
                        var a = v.read_bus(impl.a, options.levels);
                        if (invert) a = ~a;
                        try v.expect_output_valid(impl.y, a, options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, options.levels);
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        if (invert) a = !a;
                        try v.expect_output_valid(gate.y, a, options.levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        var a = v.read_bus(impl.a, options.levels);
                        if (invert) a = ~a;
                        try v.drive_bus(impl.y, a, options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        if (invert) a = !a;
                        try v.drive_logic(gate.y, a, options.levels);
                    },
                },
            }
        }
    };
}

fn Single_Gate(comptime value_suffix: []const u8, comptime options: Options, func: *const fn(a: usize, b: usize) usize) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        y: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.b,
                2 => self.a,
                3 => self.pwr.gnd,
                4 => self.y,
                5 => if (options.Package.data.num_pads() == 6) .no_connect else @field(self.pwr, @tagName(options.pwr)),
                6 => if (options.Package.data.num_pads() == 6) @field(self.pwr, @tagName(options.pwr)) else unreachable,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, options.levels);
                    try v.expect_valid(self.b, options.levels);
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    try v.expect_output_valid(self.y, func(a, b) != 0, options.levels);
                },
                .nets_only => {
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    try v.drive_logic(self.y, func(a, b) != 0, options.levels);
                },
            }
        }
    };
}

fn Dual_Gate(comptime value_suffix: []const u8, comptime options: Options, func: *const fn(a: usize, b: usize) usize) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [2]Individual_Impl,
        } = .{ .bus = .{} },
        remap: [4]u2 = .{ 0, 1 },
        
        const Bus_Impl = struct {
            a: [2]Net_ID = @splat(.unset),
            b: [2]Net_ID = @splat(.unset),
            y: [2]Net_ID = @splat(.unset),
        };

        const Individual_Impl = struct {
            a: Net_ID = .unset,
            b: Net_ID = .unset,
            y: Net_ID = .unset,
        };

        pub fn check_config(self: @This()) !void {
            var mapped_logical_gates: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_gates[logical] = true;
            }
            for (0.., mapped_logical_gates) |logical_gate, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical gate assigned to logical gate {}", .{ @typeName(@This()), logical_gate });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.a[self.remap[0]],
                    2 => impl.b[self.remap[0]],
                    7 => impl.y[self.remap[0]],

                    5 => impl.a[self.remap[1]],
                    6 => impl.b[self.remap[1]],
                    3 => impl.y[self.remap[1]],

                    else => unreachable,
                },
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[self.remap[0]].a,
                    2 => impl[self.remap[0]].b,
                    7 => impl[self.remap[0]].y,

                    5 => impl[self.remap[1]].a,
                    6 => impl[self.remap[1]].b,
                    3 => impl[self.remap[1]].y,

                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.a, options.levels);
                        try v.expect_valid(impl.b, options.levels);
                        const a = v.read_bus(impl.a, options.levels);
                        const b = v.read_bus(impl.b, options.levels);
                        try v.expect_output_valid(impl.y, func(a, b), options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, options.levels);
                        try v.expect_valid(gate.b, options.levels);
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        const b = @intFromBool(v.read_logic(gate.b, options.levels));
                        try v.expect_output_valid(gate.y, func(a, b) != 0, options.levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const a = v.read_bus(impl.a, options.levels);
                        const b = v.read_bus(impl.b, options.levels);
                        try v.drive_bus(impl.y, func(a, b), options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        const b = @intFromBool(v.read_logic(gate.b, options.levels));
                        try v.drive_logic(gate.y, func(a, b) != 0, options.levels);
                    },
                },
            }
        }
    };
}

const Quad_Gate_Pinout = enum {
    aby,
    yab, // mainly just 74x02, but also used by some quad gate open-collector chips
};
fn Quad_Gate(comptime value_suffix: []const u8, comptime options: Options, pinout: Quad_Gate_Pinout, func: *const fn(a: usize, b: usize) usize) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [4]Individual_Impl,
        } = .{ .bus = .{} },
        remap: [4]u2 = .{ 0, 1, 2, 3 },

        const Bus_Impl = struct {
            a: [4]Net_ID = @splat(.unset),
            b: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
        };

        const Individual_Impl = struct {
            a: Net_ID = .unset,
            b: Net_ID = .unset,
            y: Net_ID = .unset,
        };

        pub fn check_config(self: @This()) !void {
            var mapped_logical_gates: [4]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_gates[logical] = true;
            }
            for (0.., mapped_logical_gates) |logical_gate, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical gate assigned to logical gate {}", .{ @typeName(@This()), logical_gate });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (pinout) {
                .aby => switch (self.logic) {
                    .bus => |impl| switch (@intFromEnum(pin_id)) {
                        0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                        7 => self.pwr.gnd,
                        14 => @field(self.pwr, @tagName(options.pwr)),

                        1 => impl.a[self.remap[0]],
                        2 => impl.b[self.remap[0]],
                        3 => impl.y[self.remap[0]],

                        4 => impl.a[self.remap[1]],
                        5 => impl.b[self.remap[1]],
                        6 => impl.y[self.remap[1]],

                        9 => impl.a[self.remap[2]],
                        10 => impl.b[self.remap[2]],
                        8 => impl.y[self.remap[2]],

                        12 => impl.a[self.remap[3]],
                        13 => impl.b[self.remap[3]],
                        11 => impl.y[self.remap[3]],

                        else => unreachable,
                    },
                    .individual => |impl| switch (@intFromEnum(pin_id)) {
                        0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                        7 => self.pwr.gnd,
                        14 => @field(self.pwr, @tagName(options.pwr)),

                        1 => impl[self.remap[0]].a,
                        2 => impl[self.remap[0]].b,
                        3 => impl[self.remap[0]].y,

                        4 => impl[self.remap[1]].a,
                        5 => impl[self.remap[1]].b,
                        6 => impl[self.remap[1]].y,

                        9 => impl[self.remap[2]].a,
                        10 => impl[self.remap[2]].b,
                        8 => impl[self.remap[2]].y,

                        12 => impl[self.remap[3]].a,
                        13 => impl[self.remap[3]].b,
                        11 => impl[self.remap[3]].y,

                        else => unreachable,
                    },
                },
                .yab => switch (self.logic) {
                    .bus => |impl| switch (@intFromEnum(pin_id)) {
                        0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                        7 => self.pwr.gnd,
                        14 => @field(self.pwr, @tagName(options.pwr)),

                        1 => impl.y[self.remap[0]],
                        2 => impl.a[self.remap[0]],
                        3 => impl.b[self.remap[0]],

                        4 => impl.y[self.remap[1]],
                        5 => impl.a[self.remap[1]],
                        6 => impl.b[self.remap[1]],

                        10 => impl.y[self.remap[2]],
                        8 => impl.a[self.remap[2]],
                        9 => impl.b[self.remap[2]],

                        13 => impl.y[self.remap[3]],
                        11 => impl.a[self.remap[3]],
                        12 => impl.b[self.remap[3]],

                        else => unreachable,
                    },
                    .individual => |impl| switch (@intFromEnum(pin_id)) {
                        0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                        7 => self.pwr.gnd,
                        14 => @field(self.pwr, @tagName(options.pwr)),

                        1 => impl[self.remap[0]].y,
                        2 => impl[self.remap[0]].a,
                        3 => impl[self.remap[0]].b,

                        4 => impl[self.remap[1]].y,
                        5 => impl[self.remap[1]].a,
                        6 => impl[self.remap[1]].b,

                        10 => impl[self.remap[2]].y,
                        8 => impl[self.remap[2]].a,
                        9 => impl[self.remap[2]].b,

                        13 => impl[self.remap[3]].y,
                        11 => impl[self.remap[3]].a,
                        12 => impl[self.remap[3]].b,

                        else => unreachable,
                    },
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.a, options.levels);
                        try v.expect_valid(impl.b, options.levels);
                        const a = v.read_bus(impl.a, options.levels);
                        const b = v.read_bus(impl.b, options.levels);
                        try v.expect_output_valid(impl.y, func(a, b), options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, options.levels);
                        try v.expect_valid(gate.b, options.levels);
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        const b = @intFromBool(v.read_logic(gate.b, options.levels));
                        try v.expect_output_valid(gate.y, func(a, b) != 0, options.levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const a = v.read_bus(impl.a, options.levels);
                        const b = v.read_bus(impl.b, options.levels);
                        try v.drive_bus(impl.y, func(a, b), options.levels);
                    },
                    .individual => |impl| for (impl) |gate| {
                        const a = @intFromBool(v.read_logic(gate.a, options.levels));
                        const b = @intFromBool(v.read_logic(gate.b, options.levels));
                        try v.drive_logic(gate.y, func(a, b) != 0, options.levels);
                    },
                },
            }
        }

    };
}

fn Single_3in_Gate(comptime value_suffix: []const u8, comptime options: Options, func: *const fn(a: usize, b: usize, c: usize) usize) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        c: Net_ID = .unset,
        y: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.b,
                2 => self.pwr.gnd,
                3 => self.a,
                4 => self.y,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.c,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, options.levels);
                    try v.expect_valid(self.b, options.levels);
                    try v.expect_valid(self.c, options.levels);
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    const c = @intFromBool(v.read_logic(self.c, options.levels));
                    try v.expect_output_valid(self.y, func(a, b, c) != 0, options.levels);
                },
                .nets_only => {
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    const c = @intFromBool(v.read_logic(self.c, options.levels));
                    try v.drive_logic(self.y, func(a, b, c) != 0, options.levels);
                },
            }
        }
    };
}

fn Single_3in_Mux_Gate(comptime value_suffix: []const u8, comptime options: Options, func: *const fn(a: usize, b: usize, sel: usize) usize) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        b: Net_ID = .unset,
        sel: Net_ID = .unset,
        y: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.b,
                2 => self.pwr.gnd,
                3 => self.a,
                4 => self.y,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.sel,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, options.levels);
                    try v.expect_valid(self.b, options.levels);
                    try v.expect_valid(self.sel, options.levels);
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    const sel = @intFromBool(v.read_logic(self.sel, options.levels));
                    try v.expect_output_valid(self.y, func(a, b, sel) != 0, options.levels);
                },
                .nets_only => {
                    const a = @intFromBool(v.read_logic(self.a, options.levels));
                    const b = @intFromBool(v.read_logic(self.b, options.levels));
                    const sel = @intFromBool(v.read_logic(self.sel, options.levels));
                    try v.drive_logic(self.y, func(a, b, sel) != 0, options.levels);
                },
            }
        }
    };
}

fn and_gate(a: usize, b: usize) usize {
    return a & b;
}
fn or_gate(a: usize, b: usize) usize {
    return a | b;
}
fn xor_gate(a: usize, b: usize) usize {
    return a ^ b;
}
fn nand_gate(a: usize, b: usize) usize {
    return ~(a & b);
}
fn nor_gate(a: usize, b: usize) usize {
    return ~(a | b);
}

fn and3_gate(a: usize, b: usize, c: usize) usize {
    return a & b & c;
}
fn or3_gate(a: usize, b: usize, c: usize) usize {
    return a | b | c;
}
fn xor3_gate(a: usize, b: usize, c: usize) usize {
    return a ^ b ^ c;
}
fn nand3_gate(a: usize, b: usize, c: usize) usize {
    return ~(a & b & c);
}
fn nor3_gate(a: usize, b: usize, c: usize) usize {
    return ~(a | b | c);
}
fn and_or_gate(a: usize, b: usize, c: usize) usize {
    return (a & b) | c;
}
fn or_and_gate(a: usize, b: usize, c: usize) usize {
    return (a | b) & c;
}
fn mux57_gate(a: usize, b: usize, c: usize) usize {
    return (~a & ~c) | (b & c);
}
fn mux58_gate(a: usize, b: usize, c: usize) usize {
    return (a & ~c) | (~b & c);
}
fn mux97_gate(a: usize, b: usize, c: usize) usize {
    return (a & c) | (b & ~c);
}
fn mux98_gate(a: usize, b: usize, c: usize) usize {
    return (~a & c) | (~b & ~c);
}
fn mux157_gate(a: usize, b: usize, c: usize) usize {
    return (a & ~c) | (b & c);
}

/// Quad 2-in NAND
pub fn x00(comptime options: Options) type {
    return Quad_Gate("00", options, .aby, nand_gate);
}
/// Single 2-in NAND
pub fn x1G00(comptime options: Options) type {
    return Single_Gate("1G00", options, nand_gate);
}
/// Dual 2-in NAND
pub fn x2G00(comptime options: Options) type {
    return Dual_Gate("2G00", options, nand_gate);
}

/// Quad 2-in NOR
pub fn x02(comptime options: Options) type {
    return Quad_Gate("02", options, .yab, nor_gate);
}
/// Single 2-in NOR
pub fn x1G02(comptime options: Options) type {
    return Single_Gate("1G02", options, nor_gate);
}
/// Single 2-in NOR
pub fn x2G02(comptime options: Options) type {
    return Dual_Gate("2G02", options, nor_gate);
}

/// Hex inverter
pub fn x04(comptime options: Options) type {
    return Hex_Buffer("04", options, true);
}
/// Single inverter
pub fn x1G04(comptime options: Options) type {
    return Single_Buffer("1G04", options, true);
}
/// Dual inverter
pub fn x2G04(comptime options: Options) type {
    return Dual_Buffer("2G04", options, 0b00);
}

/// Quad 2-in AND
pub fn x08(comptime options: Options) type {
    return Quad_Gate("08", options, .aby, and_gate);
}
/// Single 2-in AND
pub fn x1G08(comptime options: Options) type {
    return Single_Gate("1G08", options, and_gate);
}
/// Dual 2-in AND
pub fn x2G08(comptime options: Options) type {
    return Dual_Gate("2G08", options, and_gate);
}

/// Hex inverter, ST inputs
pub fn x14(comptime options: Options) type {
    return Hex_Buffer("14", options, true);
}
/// Single inverter, ST inputs
pub fn x1G14(comptime options: Options) type {
    return Single_Buffer("1G14", options, true);
}
/// Dual inverter, ST inputs
pub fn x2G14(comptime options: Options) type {
    return Dual_Buffer("2G14", options, 0b11);
}

/// Single buffer, ST inputs
pub fn x1G17(comptime options: Options) type {
    return Single_Buffer("1G17", options, false);
}
/// Dual buffer, ST inputs
pub fn x2G17(comptime options: Options) type {
    return Dual_Buffer("2G17", options, 0b00);
}

/// Quad 2-in OR
pub fn x32(comptime options: Options) type {
    return Quad_Gate("32", options, .aby, or_gate);
}
/// Single 2-in OR
pub fn x1G32(comptime options: Options) type {
    return Single_Gate("1G32", options, or_gate);
}
/// Dual 2-in OR
pub fn x2G32(comptime options: Options) type {
    return Dual_Gate("2G32", options, or_gate);
}

/// Single buffer
pub fn x1G34(comptime options: Options) type {
    return Single_Buffer("1G34", options, false);
}
/// Dual buffer
pub fn x2G34(comptime options: Options) type {
    return Dual_Buffer("2G34", options, 0x00);
}

// Single buffer & Single inverter (AUP/AXP families)
pub fn x2G3404(comptime options: Options) type {
    return Dual_Buffer("2G3404", options, 0b10);
}

/// Quad 2-in XOR
pub fn x86(comptime options: Options) type {
    return Quad_Gate("86", options, .aby, xor_gate);
}
/// Single 2-in XOR
pub fn x1G86(comptime options: Options) type {
    return Single_Gate("1G86", options, xor_gate);
}
/// Dual 2-in XOR
pub fn x2G86(comptime options: Options) type {
    return Dual_Gate("2G86", options, xor_gate);
}

/// Single 3-in NAND
pub fn x1G10(comptime options: Options) type {
    return Single_3in_Gate("1G10", options, nand3_gate);
}

/// Single 3-in AND
pub fn x1G11(comptime options: Options) type {
    return Single_3in_Gate("1G11", options, and3_gate);
}

/// Single 3-in NOR
pub fn x1G27(comptime options: Options) type {
    return Single_3in_Gate("1G27", options, nor3_gate);
}

/// Single 3-in OR
pub fn x1G332(comptime options: Options) type {
    return Single_3in_Gate("1G332", options, or3_gate);
}

/// Single 3-in XOR
pub fn x1G386(comptime options: Options) type {
    return Single_3in_Gate("1G386", options, xor3_gate);
}

/// Single OR-AND
pub fn x1G3208(comptime options: Options) type {
    return Single_3in_Gate("1G3208", options, or_and_gate);
}

/// Single AND-OR
pub fn x1G0832(comptime options: Options) type {
    return Single_3in_Gate("1G0832", options, and_or_gate);
}

/// Single 2:1 mux, A input inverted
pub fn x1G57(comptime options: Options) type {
    return Single_3in_Mux_Gate("1G57", options, mux57_gate);
}

/// Single 2:1 mux, B input inverted
pub fn x1G58(comptime options: Options) type {
    return Single_3in_Mux_Gate("1G58", options, mux58_gate);
}

/// Single 2:1 mux, C input inverted
pub fn x1G97(comptime options: Options) type {
    return Single_3in_Mux_Gate("1G97", options, mux97_gate);
}

/// Single 2:1 mux, all inputs inverted
pub fn x1G98(comptime options: Options) type {
    return Single_3in_Mux_Gate("1G98", options, mux98_gate);
}

/// Single 2:1 mux
pub fn x1G157(comptime options: Options) type {
    return Single_3in_Mux_Gate("1G157", options, mux157_gate);
}

/// Single 2:1 bus switch
pub fn x1G3157(comptime options: Options, switch_levels: type) type {
    return struct {
        base: Part.Base = options.base("1G3157"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: [2]Net_ID = @splat(.unset),
        b: Net_ID = .unset,
        sel: Net_ID = .unset,
        r_on: f32 = 5,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a[1],
                2 => self.pwr.gnd,
                3 => self.a[0],
                4 => self.b,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.sel,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, options.levels);
                    try v.expect_below(self.a[0], switch_levels.Vclamp);
                    try v.expect_below(self.a[1], switch_levels.Vclamp);
                    try v.expect_below(self.b, switch_levels.Vclamp);

                    const power_limit = 0.016384 * self.r_on;
                    if (v.read_logic(self.sel, options.levels)) {
                        try v.verify_power_limit(self.a[1], self.b, self.r_on, power_limit);
                    } else {
                        try v.verify_power_limit(self.a[0], self.b, self.r_on, power_limit);
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.sel, options.levels)) {
                        try v.connect_nets(self.a[1], self.b, self.r_on);
                    } else {
                        try v.connect_nets(self.a[0], self.b, self.r_on);
                    }
                },
            }
        }
    };
}

fn Single_1_2_Demux(comptime value_suffix: []const u8, comptime options: Options, comptime hiz_inactive: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        y: [2]Net_ID = @splat(.unset),
        sel: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.sel,
                2 => self.pwr.gnd,
                3 => self.a,
                4 => self.y[1],
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.y[0],
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, options.levels);
                    try v.expect_valid(self.a, options.levels);

                    const sel = v.read_logic(self.sel, options.levels);
                    const a = v.read_logic(self.a, options.levels);
                    try v.expect_output_valid(self.y[@intFromBool(sel)], a, options.levels);

                    if (!hiz_inactive) {
                        try v.expect_output_valid(self.y[@intFromBool(!sel)], true, options.levels);
                    }
                },
                .nets_only => {
                    const sel = v.read_logic(self.sel, options.levels);
                    const a = v.read_logic(self.a, options.levels);
                    try v.drive_logic(self.y[@intFromBool(sel)], a, options.levels);

                    if (!hiz_inactive) {
                        try v.drive_logic(self.y[@intFromBool(!sel)], true, options.levels);
                    }
                },
            }
        }
    };
}

/// Single 1:2 3-state demux
pub fn x1G18(comptime options: Options) type {
    return Single_1_2_Demux("1G18", options, true);
}

/// Single 1:2 decoder
pub fn x1G19(comptime options: Options) type {
    return Single_1_2_Demux("1G19", options, false);
}

/// Single 2:3 decoder
pub fn x1G29(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G29"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        y: [3]Net_ID = @splat(.unset),
        sel: [2]Net_ID = @splat(.unset),

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a,
                2 => self.y[1],
                3 => self.sel[0],
                4 => self.pwr.gnd,
                5 => self.y[2],
                6 => self.sel[1],
                7 => self.y[0],
                8 => @field(self.pwr, @tagName(options.pwr)),
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, options.levels);
                    try v.expect_valid(self.a, options.levels);

                    const sel = v.read_bus(self.sel, options.levels);
                    const a = v.read_logic(self.a, options.levels);
                    switch (sel) {
                        0, 1 => {
                            v.expect_output_valid(self.y[0], a, options.levels);
                            v.expect_output_valid(self.y[1], true, options.levels);
                            v.expect_output_valid(self.y[2], true, options.levels);
                        },
                        2 => {
                            v.expect_output_valid(self.y[0], true, options.levels);
                            v.expect_output_valid(self.y[1], a, options.levels);
                            v.expect_output_valid(self.y[2], true, options.levels);
                        },
                        3 => {
                            v.expect_output_valid(self.y[0], true, options.levels);
                            v.expect_output_valid(self.y[1], true, options.levels);
                            v.expect_output_valid(self.y[2], a, options.levels);
                        },
                    }
                },
                .nets_only => {
                    const sel = v.read_bus(self.sel, options.levels);
                    const a = v.read_logic(self.a, options.levels);
                    switch (sel) {
                        0, 1 => {
                            v.drive_logic(self.y[0], a, options.levels);
                            v.drive_logic(self.y[1], true, options.levels);
                            v.drive_logic(self.y[2], true, options.levels);
                        },
                        2 => {
                            v.drive_logic(self.y[0], true, options.levels);
                            v.drive_logic(self.y[1], a, options.levels);
                            v.drive_logic(self.y[2], true, options.levels);
                        },
                        3 => {
                            v.drive_logic(self.y[0], true, options.levels);
                            v.drive_logic(self.y[1], true, options.levels);
                            v.drive_logic(self.y[2], a, options.levels);
                        },
                    }
                },
            }
        }
    };
}

/// Single 2:4 decoder
pub fn x1G139(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G139"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        y: [4]Net_ID = @splat(.unset),
        sel: [2]Net_ID = @splat(.unset),

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.sel[0],
                2 => self.sel[1],
                3 => self.y[3],
                4 => self.pwr.gnd,
                5 => self.y[2],
                6 => self.y[1],
                7 => self.y[0],
                8 => @field(self.pwr, @tagName(options.pwr)),
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, options.levels);
                    const sel: u2 = @truncate(v.read_bus(self.sel, options.levels));
                    const val = @as(u4, 1) << sel;
                    v.expect_output_valid(self.y, ~val, options.levels);
                },
                .nets_only => {
                    const sel: u2 = @truncate(v.read_bus(self.sel, options.levels));
                    const val = @as(u4, 1) << sel;
                    v.expect_output_valid(self.y, ~val, options.levels);
                },
            }
        }
    };
}

fn Single_Tristate_Driver_Active_Low(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        y: Net_ID = .unset,
        n_oe: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.n_oe,
                2 => self.a,
                3 => self.pwr.gnd,
                4 => self.y,
                5 => if (options.Package.data.num_pads() == 6) .no_connect else @field(self.pwr, @tagName(options.pwr)),
                6 => if (options.Package.data.num_pads() == 6) @field(self.pwr, @tagName(options.pwr)) else unreachable,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.n_oe, options.levels);
                    try v.expect_valid(self.a, options.levels);
                    if (!v.read_logic(self.n_oe, options.levels)) {
                        const a = v.read_logic(self.a, options.levels);
                        try v.expect_output_valid(self.y, if (invert) !a else a, options.levels);
                    }
                },
                .nets_only => {
                    if (!v.read_logic(self.n_oe, options.levels)) {
                        const a = v.read_logic(self.a, options.levels);
                        try v.drive_logic(self.y, if (invert) !a else a, options.levels);
                    }
                },
            }
        }
    };
}

fn Single_Tristate_Driver_Active_High(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        a: Net_ID = .unset,
        y: Net_ID = .unset,
        oe: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.oe,
                2 => self.a,
                3 => self.pwr.gnd,
                4 => self.y,
                5 => if (options.Package.data.num_pads() == 6) .no_connect else @field(self.pwr, @tagName(options.pwr)),
                6 => if (options.Package.data.num_pads() == 6) @field(self.pwr, @tagName(options.pwr)) else unreachable,
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.oe, options.levels);
                    try v.expect_valid(self.a, options.levels);
                    if (v.read_logic(self.oe, options.levels)) {
                        const a = v.read_logic(self.a, options.levels);
                        try v.expect_output_valid(self.y, if (invert) !a else a, options.levels);
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.oe, options.levels)) {
                        const a = v.read_logic(self.a, options.levels);
                        try v.drive_logic(self.y, if (invert) !a else a, options.levels);
                    }
                },
            }
        }
    };
}

fn Dual_Tristate_Driver_Active_Low(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [2]Individual_Impl,
        },
        remap: [2]u1 = .{ 0, 1 },

        const Bus_Impl = struct {
            a: [2]Net_ID = @splat(.unset),
            y: [2]Net_ID = @splat(.unset),
            n_oe: [2]Net_ID = @splat(.unset),
        };
        const Individual_Impl = struct {
            a: Net_ID = .unset,
            y: Net_ID = .unset,
            n_oe: Net_ID = .unset,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.n_oe[0],
                    2 => impl.a[0],
                    6 => impl.y[0],

                    7 => impl.n_oe[1],
                    5 => impl.a[1],
                    3 => impl.y[1],

                    else => unreachable,
                },
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[0].n_oe,
                    2 => impl[0].a,
                    6 => impl[0].y,

                    7 => impl[1].n_oe,
                    5 => impl[1].a,
                    3 => impl[1].y,
                    
                    else => unreachable,
                },
            };
        }

        pub fn check_config(self: @This()) !void {
            var mapped_logical_bufs: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_bufs[logical] = true;
            }
            for (0.., mapped_logical_bufs) |logical_buf, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical buffer assigned to logical buffer {}", .{ @typeName(@This()), logical_buf });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.n_oe, options.levels);
                        try v.expect_valid(impl.a, options.levels);
                        const oe = v.read_logic(impl.n_oe, options.levels);
                        if (0 == (oe & 1)) {
                            const a = v.read_logic(impl.a[0], options.levels);
                            try v.expect_output_valid(impl.y[0], if (invert) !a else a, options.levels);
                        }
                        if (0 == (oe & 2)) {
                            const a = v.read_logic(impl.a[1], options.levels);
                            try v.expect_output_valid(impl.y[1], if (invert) !a else a, options.levels);
                        }
                    },
                    .individual => |impl| for (impl) |buf| {
                        try v.expect_valid(buf.n_oe, options.levels);
                        try v.expect_valid(buf.a, options.levels);
                        if (!v.read_logic(buf.n_oe, options.levels)) {
                            const a = v.read_logic(buf.a, options.levels);
                            try v.expect_output_valid(buf.y, if (invert) !a else a, options.levels);
                        }
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const oe = v.read_logic(impl.n_oe, options.levels);
                        if (0 == (oe & 1)) {
                            const a = v.read_logic(impl.a[0], options.levels);
                            try v.drive_logic(impl.y[0], if (invert) !a else a, options.levels);
                        }
                        if (0 == (oe & 2)) {
                            const a = v.read_logic(impl.a[1], options.levels);
                            try v.drive_logic(impl.y[1], if (invert) !a else a, options.levels);
                        }
                    },
                    .individual => |impl| for (impl) |buf| {
                        if (!v.read_logic(buf.n_oe, options.levels)) {
                            const a = v.read_logic(buf.a, options.levels);
                            try v.drive_logic(buf.y, if (invert) !a else a, options.levels);
                        }
                    },
                },
            }
        }
    };
}

fn Dual_Tristate_Driver_Active_High(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [2]Individual_Impl,
        },
        remap: [2]u1 = .{ 0, 1 },

        const Bus_Impl = struct {
            a: [2]Net_ID = @splat(.unset),
            y: [2]Net_ID = @splat(.unset),
            oe: [2]Net_ID = @splat(.unset),
        };
        const Individual_Impl = struct {
            a: Net_ID = .unset,
            y: Net_ID = .unset,
            oe: Net_ID = .unset,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.oe[0],
                    2 => impl.a[0],
                    6 => impl.y[0],

                    7 => impl.oe[1],
                    5 => impl.a[1],
                    3 => impl.y[1],

                    else => unreachable,
                },
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[0].oe,
                    2 => impl[0].a,
                    6 => impl[0].y,

                    7 => impl[1].oe,
                    5 => impl[1].a,
                    3 => impl[1].y,
                    
                    else => unreachable,
                },
            };
        }

        pub fn check_config(self: @This()) !void {
            var mapped_logical_bufs: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_bufs[logical] = true;
            }
            for (0.., mapped_logical_bufs) |logical_buf, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical buffer assigned to logical buffer {}", .{ @typeName(@This()), logical_buf });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.oe, options.levels);
                        try v.expect_valid(impl.a, options.levels);
                        const oe = v.read_logic(impl.oe, options.levels);
                        if (0 != (oe & 1)) {
                            const a = v.read_logic(impl.a[0], options.levels);
                            try v.expect_output_valid(impl.y[0], if (invert) !a else a, options.levels);
                        }
                        if (0 != (oe & 2)) {
                            const a = v.read_logic(impl.a[1], options.levels);
                            try v.expect_output_valid(impl.y[1], if (invert) !a else a, options.levels);
                        }
                    },
                    .individual => |impl| for (impl) |buf| {
                        try v.expect_valid(buf.oe, options.levels);
                        try v.expect_valid(buf.a, options.levels);
                        if (v.read_logic(buf.oe, options.levels)) {
                            const a = v.read_logic(buf.a, options.levels);
                            try v.expect_output_valid(buf.y, if (invert) !a else a, options.levels);
                        }
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const oe = v.read_logic(impl.oe, options.levels);
                        if (0 != (oe & 1)) {
                            const a = v.read_logic(impl.a[0], options.levels);
                            try v.drive_logic(impl.y[0], if (invert) !a else a, options.levels);
                        }
                        if (0 != (oe & 2)) {
                            const a = v.read_logic(impl.a[1], options.levels);
                            try v.drive_logic(impl.y[1], if (invert) !a else a, options.levels);
                        }
                    },
                    .individual => |impl| for (impl) |buf| {
                        if (v.read_logic(buf.oe, options.levels)) {
                            const a = v.read_logic(buf.a, options.levels);
                            try v.drive_logic(buf.y, if (invert) !a else a, options.levels);
                        }
                    },
                },
            }
        }
    };
}

pub fn x1G125(comptime options: Options) type {
    return Single_Tristate_Driver_Active_Low("1G125", options, false);
}
pub fn x2G125(comptime options: Options) type {
    return Dual_Tristate_Driver_Active_Low("2G125", options, false);
}
pub fn x1G126(comptime options: Options) type {
    return Single_Tristate_Driver_Active_High("1G126", options, false);
}
pub fn x2G126(comptime options: Options) type {
    return Dual_Tristate_Driver_Active_High("2G126", options, false);
}
pub fn x1G240(comptime options: Options) type {
    return Single_Tristate_Driver_Active_Low("1G240", options, true);
}

/// a.k.a. x2G74
pub fn x1G74(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G74"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        clk: Net_ID = .unset,
        d: Net_ID = .unset,
        q: Net_ID = .unset,
        n_q: Net_ID = .unset,
        n_async_set: Net_ID = .unset,
        n_async_clr: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.clk,
                2 => self.d,
                3 => self.n_q,
                4 => self.pwr.gnd,
                5 => self.q,
                6 => self.n_async_clr,
                7 => self.n_async_set,
                8 => @field(self.pwr, @tagName(options.pwr)),
                else => unreachable,
            };
        }

        const Validator_State = struct {
            clk: bool,
            q: bool,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = false;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_async_clr, options.levels);
                    try v.expect_valid(self.n_async_set, options.levels);

                    try v.expect_output_valid(self.q, state.q, options.levels);
                    try v.expect_output_valid(self.n_q, !state.q, options.levels);

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        state.q = v.read_logic(self.d, options.levels);
                    }
                    state.clk = new_clk;

                    const ac = !v.read_logic(self.n_async_clr, options.levels);
                    const as = !v.read_logic(self.n_async_set, options.levels);

                    if (ac and !as) {
                        state.q = false;
                    } else if (as and !ac) {
                        state.q = true;
                    }
                },
                .nets_only => {
                    const ac = !v.read_logic(self.n_async_clr, options.levels);
                    const as = !v.read_logic(self.n_async_set, options.levels);

                    if (ac) {
                        if (as) {
                            try v.drive_logic(self.q, true, options.levels);
                            try v.drive_logic(self.n_q, true, options.levels);
                        } else {
                            try v.drive_logic(self.q, false, options.levels);
                            try v.drive_logic(self.n_q, true, options.levels);
                        }
                    } else if (as) {
                        try v.drive_logic(self.q, true, options.levels);
                        try v.drive_logic(self.n_q, false, options.levels);
                    } else {
                        try v.drive_logic(self.q, state.q, options.levels);
                        try v.drive_logic(self.n_q, !state.q, options.levels);
                    }
                },
            }
        }
    };
}

fn Single_DFF(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        clk: Net_ID = .unset,
        d: Net_ID = .unset,
        q: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.d,
                2 => self.clk,
                3 => self.pwr.gnd,
                4 => self.q,
                5 => if (options.Package.data.num_pads() == 6) .no_connect else @field(self.pwr, @tagName(options.pwr)),
                6 => if (options.Package.data.num_pads() == 6) @field(self.pwr, @tagName(options.pwr)) else unreachable,
                else => unreachable,
            };
        }

        const Validator_State = struct {
            clk: bool,
            q: bool,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = false;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_output_valid(self.q, state.q, options.levels);

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        const d = v.read_logic(self.d, options.levels);
                        state.q = if (invert) !d else d;
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    try v.drive_logic(self.q, state.q, options.levels);
                },
            }
        }
    };
}

fn Dual_DFF(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        logic: union (enum) {
            bus: Bus_Impl,
            individual: [2]Individual_Impl,
        },
        remap: [2]u1 = .{ 0, 1 },

        const Bus_Impl = struct {
            clk: [2]Net_ID = @splat(.unset),
            d: [2]Net_ID = @splat(.unset),
            q: [2]Net_ID = @splat(.unset),
        };

        const Individual_Impl = struct {
            clk: Net_ID = .unset,
            d: Net_ID = .unset,
            q: Net_ID = .unset,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .individual => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl[0].clk,
                    2 => impl[0].d,
                    7 => impl[0].q,

                    5 => impl[1].clk,
                    6 => impl[1].d,
                    3 => impl[1].q,

                    else => unreachable,
                },
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    4 => self.pwr.gnd,
                    8 => @field(self.pwr, @tagName(options.pwr)),

                    1 => impl.clk[0],
                    2 => impl.d[0],
                    7 => impl.q[0],

                    5 => impl.clk[1],
                    6 => impl.d[1],
                    3 => impl.q[1],

                    else => unreachable,
                },
            };
        }
        
        pub fn check_config(self: @This()) !void {
            var mapped_logical_gates: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_logical_gates[logical] = true;
            }
            for (0.., mapped_logical_gates) |logical_gate, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical register assigned to logical register {}", .{ @typeName(@This()), logical_gate });
                    return error.InvalidRemap;
                }
            }
        }

        const Validator_State = struct {
            clk: [2]bool,
            q: [2]bool,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = @splat(false);
                    state.clk = @splat(true);
                },
                .commit => switch (self.logic) {
                    .individual => |impl| for (0.., impl) |n, reg| {
                        try v.expect_valid(reg.d, options.levels);
                        try v.expect_valid(reg.clk, options.levels);
                        try v.expect_output_valid(reg.q, state.q[n], options.levels);

                        const new_clk = v.read_logic(reg.clk, options.levels);
                        if (new_clk and !state.clk[n]) {
                            const d = v.read_logic(reg.d, options.levels);
                            state.q[n] = if (invert) !d else d;
                        }
                        state.clk[n] = new_clk;
                    },
                    .bus => |impl| {
                        try v.expect_valid(impl.d, options.levels);
                        try v.expect_valid(impl.clk, options.levels);
                        for (0..2) |n| {
                            try v.expect_output_valid(impl.q[n], state.q[n], options.levels);
                            const new_clk = v.read_logic(impl.clk[n], options.levels);
                            if (new_clk and !state.clk[n]) {
                                const d = v.read_logic(impl.d[n], options.levels);
                                state.q[n] = if (invert) !d else d;
                            }
                            state.clk[n] = new_clk;
                        }
                    },
                },
                .nets_only => switch (self.logic) {
                    .individual => |impl| for (0.., impl) |n, reg| {
                        try v.drive_logic(reg.q, state.q[n], options.levels);
                    },
                    .bus => |impl| for (0..2) |n| {
                        try v.drive_logic(impl.q[n], state.q[n], options.levels);
                    },
                },
            }
        }
    };
}

pub fn x1G79(comptime options: Options) type {
    return Single_DFF("1G79", options, false);
}
pub fn x2G79(comptime options: Options) type {
    return Dual_DFF("2G79", options, false);
}
pub fn x1G80(comptime options: Options) type {
    return Single_DFF("1G80", options, true);
}
pub fn x2G80(comptime options: Options) type {
    return Dual_DFF("2G80", options, true);
}

/// Single DFF with async clear
pub fn x1G175(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G175"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        clk: Net_ID = .unset,
        d: Net_ID = .unset,
        q: Net_ID = .unset,
        n_async_clr: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.clk,
                2 => self.pwr.gnd,
                3 => self.d,
                4 => self.q,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.n_async_clr,
                else => unreachable,
            };
        }

        const Validator_State = struct {
            clk: bool,
            q: bool,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = false;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_async_clr, options.levels);

                    try v.expect_output_valid(self.q, state.q, options.levels);

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        state.q = v.read_logic(self.d, options.levels);
                    }
                    state.clk = new_clk;

                    if (!v.read_logic(self.n_async_clr, options.levels)) {
                        state.q = false;
                    }
                },
                .nets_only => {
                    if (!v.read_logic(self.n_async_clr, options.levels)) {
                        try v.drive_logic(self.q, false, options.levels);
                    } else {
                        try v.drive_logic(self.q, state.q, options.levels);
                    }
                },
            }
        }
    };
}

/// Single DFF with OE
pub fn x1G374(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G374"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        clk: Net_ID = .unset,
        d: Net_ID = .unset,
        q: Net_ID = .unset,
        n_oe: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.clk,
                2 => self.pwr.gnd,
                3 => self.d,
                4 => self.q,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.n_oe,
                else => unreachable,
            };
        }

        const Validator_State = struct {
            clk: bool,
            q: bool,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = false;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);

                    if (!v.read_logic(self.n_oe, options.levels)) {
                        try v.drive_logic(self.q, state.q, options.levels);
                    }

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        state.q = v.read_logic(self.d, options.levels);
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    if (!v.read_logic(self.n_oe, options.levels)) {
                        try v.drive_logic(self.q, state.q, options.levels);
                    }
                },
            }
        }
    };
}

pub fn x1G373(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("1G373"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        transparent: Net_ID = .unset,
        d: Net_ID = .unset,
        q: Net_ID = .unset,
        n_oe: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.transparent,
                2 => self.pwr.gnd,
                3 => self.d,
                4 => self.q,
                5 => @field(self.pwr, @tagName(options.pwr)),
                6 => self.n_oe,
                else => unreachable,
            };
        }

        const Validator_State = struct {
            q: bool,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.q = false;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.transparent, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);
                    if (v.read_logic(self.transparent, options.levels)) {
                        state.q = v.read_logic(self.d, options.levels);
                    }
                    if (!v.read_logic(self.n_oe, options.levels)) {
                        try v.expect_output_valid(self.q, state.q, options.levels);
                    }
                },
                .nets_only => {
                    if (!v.read_logic(self.n_oe, options.levels)) {
                        const le = v.read_logic(self.transparent, options.levels);
                        const q = if (le) v.read_logic(self.d, options.levels) else state.q;
                        try v.drive_bus(self.q, q, options.levels);
                    }
                },
            }
        }
    };
}

// TODO x2G100
// TODO x2G101
// TODO x2G157
// TODO x2G241

// 3:8 decoder/demux
pub fn x138(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("138"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        sel: [3]Net_ID = @splat(.unset),
        y: [8]Net_ID = @splat(.unset),
        enable: Net_ID = .unset,
        n_enable: [2]Net_ID = @splat(.unset),

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.sel[0],
                2 => self.sel[1],
                3 => self.sel[2],
                4 => self.n_enable[0],
                5 => self.n_enable[1],
                6 => self.enable,
                7 => self.y[7],
                8 => self.pwr.gnd,
                9 => self.y[6],
                10 => self.y[5],
                11 => self.y[4],
                12 => self.y[3],
                13 => self.y[2],
                14 => self.y[1],
                15 => self.y[0],
                16 => @field(self.pwr, @tagName(options.pwr)),
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, options.levels);
                    try v.expect_valid(self.enable, options.levels);
                    try v.expect_valid(self.n_enable, options.levels);
                    var out: u8 = 0;
                    if (v.read_logic(self.enable, options.levels) and v.read_bus(self.n_enable, options.levels) == 0) {
                        const index: u3 = @truncate(v.read_bus(self.sel, options.levels));
                        out = @as(u8, 1) << index;
                    }
                    try v.expect_output_valid(self.y, ~out, options.levels);
                },
                .nets_only => {
                    var out: u8 = 0;
                    if (v.read_logic(self.enable, options.levels) and v.read_bus(self.n_enable, options.levels) == 0) {
                        const index: u3 = @truncate(v.read_bus(self.sel, options.levels));
                        out = @as(u8, 1) << index;
                    }
                    try v.drive_bus(self.y, ~out, options.levels);
                },
            }
        }

    };
}

// Dual 2:4 decoder/demux
pub fn x139(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("139"),

        u: [2]Unit = @splat(.{}),
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [2]u1 = .{ 0, 1 },

        pub const Unit = struct {
            sel: [2]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
            n_enable: Net_ID = .unset,
        };

        pub fn check_config(self: @This()) !void {
            var mapped_units: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_units[logical] = true;
            }
            for (0.., mapped_units) |logical_unit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical unit assigned to logical unit {}", .{ @typeName(@This()), logical_unit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                8 => self.pwr.gnd,
                16 => @field(self.pwr, @tagName(options.pwr)),

                1 => self.u[self.remap[0]].n_enable,
                2 => self.u[self.remap[0]].sel[0],
                3 => self.u[self.remap[0]].sel[1],
                4 => self.u[self.remap[0]].y[0],
                5 => self.u[self.remap[0]].y[1],
                6 => self.u[self.remap[0]].y[2],
                7 => self.u[self.remap[0]].y[3],

                15 => self.u[self.remap[1]].n_enable,
                14 => self.u[self.remap[1]].sel[0],
                13 => self.u[self.remap[1]].sel[1],
                12 => self.u[self.remap[1]].y[0],
                11 => self.u[self.remap[1]].y[1],
                10 => self.u[self.remap[1]].y[2],
                9 => self.u[self.remap[1]].y[3],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => for (self.u) |unit| {
                    try v.expect_valid(unit.n_enable, options.levels);
                    try v.expect_valid(unit.sel, options.levels);
                    var out: u4 = 0;
                    if (!v.read_logic(unit.n_enable, options.levels)) {
                        const index: u2 = @truncate(v.read_bus(unit.sel, options.levels));
                        out = @as(u4, 1) << index;
                    }
                    try v.expect_output_valid(unit.y, ~out, options.levels);
                },
                .nets_only => for (self.u) |unit| {
                    var out: u4 = 0;
                    if (!v.read_logic(unit.n_enable, options.levels)) {
                        const index: u2 = @truncate(v.read_bus(unit.sel, options.levels));
                        out = @as(u4, 1) << index;
                    }
                    try v.drive_bus(unit.y, ~out, options.levels);
                },
            }
        }
    };
}

// TODO x1G123
// TODO x151
// TODO x153
// TODO x157
// TODO x251
// TODO x253
// TODO x257
// TODO x3251
// TODO x3253
// TODO x3257
// TODO x823
// TODO x161

pub fn x163(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("163"),

        pwr: power.Single(options.pwr, options.Decoupler) = .{},

        d: [4]Net_ID = @splat(.unset),
        q: [4]Net_ID = @splat(.unset),
        c: Net_ID = .unset, // ripple carry out

        clk: Net_ID = .unset,

        // operation enables, from highest to lowest priority:
        n_clear_enable: Net_ID = .unset,
        n_load_enable: Net_ID = .unset,
        count_enable: Net_ID = .unset, // does not affect `c`
        count_enable_ripple: Net_ID = .unset, // affects `c` asynchronously

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.n_clear_enable,
                2 => self.clk,
                3 => self.d[0],
                4 => self.d[1],
                5 => self.d[2],
                6 => self.d[3],
                7 => self.count_enable,

                9 => self.n_load_enable,
                10 => self.count_enable_ripple,
                11 => self.q[3],
                12 => self.q[2],
                13 => self.q[1],
                14 => self.q[0],
                15 => self.c,

                8 => self.pwr.gnd,
                16 => @field(self.pwr, @tagName(options.pwr)),

                else => unreachable,
            };
        }

        const Validate_State = struct {
            data: u4,
            clk: bool,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.data = 0xA;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_clear_enable, options.levels);
                    try v.expect_valid(self.n_load_enable, options.levels);
                    try v.expect_valid(self.count_enable, options.levels);
                    try v.expect_valid(self.count_enable_ripple, options.levels);

                    const count_enable_ripple = v.read_logic(self.count_enable_ripple, options.levels);

                    try v.expect_output_valid(self.q, state.data, options.levels);
                    try v.expect_output_valid(self.c, state.data == 0xF and count_enable_ripple, options.levels);

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        if (!v.read_logic(self.n_clear_enable, options.levels)) {
                            state.data = 0;
                        } else if (!v.read_logic(self.n_load_enable, options.levels)) {
                            state.data = @truncate(v.read_bus(self.d, options.levels));
                        } else if (count_enable_ripple and v.read_logic(self.count_enable, options.levels)) {
                            state.data +%= 1;
                        }
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    try v.drive_bus(self.q, state.data, options.levels);
                    try v.drive_logic(self.c, state.data == 0xF and v.read_logic(self.count_enable_ripple, options.levels), options.levels);
                },
            }
        }
    };
}

fn Dual_4b_Tristate_Buffer(comptime value_suffix: []const u8, comptime options: Options, comptime invert_outputs: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        u: [2]Unit = @splat(.{}),
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [2]u1 = .{ 0, 1 },

        pub const Unit = struct {
            a: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            remap: [4]u2 = .{ 0, 1, 2, 3 },

            fn logical_a_bit(self: Unit, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }

            fn logical_y_bit(self: Unit, physical_bit: usize) usize {
                return self.y[self.remap[physical_bit]];
            }
        };

        pub fn check_config(self: @This()) !void {
            var mapped_units: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_units[logical] = true;
            }
            for (0.., mapped_units) |logical_unit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical unit assigned to logical unit {}", .{ @typeName(@This()), logical_unit });
                    return error.InvalidRemap;
                }
            }

            for (0.., self.u) |unit_idx, unit| {
                var mapped_bits: [4]bool = @splat(false);
                for (unit.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit {}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), unit_idx, logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u[self.remap[0]].n_oe,
                19 => self.u[self.remap[1]].n_oe,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.u[self.remap[0]].logical_a_bit(0),
                4 => self.u[self.remap[0]].logical_a_bit(1),
                6 => self.u[self.remap[0]].logical_a_bit(2),
                8 => self.u[self.remap[0]].logical_a_bit(3),

                17 => self.u[self.remap[1]].logical_a_bit(0),
                15 => self.u[self.remap[1]].logical_a_bit(1),
                13 => self.u[self.remap[1]].logical_a_bit(2),
                11 => self.u[self.remap[1]].logical_a_bit(3),

                18 => self.u[self.remap[0]].logical_y_bit(0),
                16 => self.u[self.remap[0]].logical_y_bit(1),
                14 => self.u[self.remap[0]].logical_y_bit(2),
                12 => self.u[self.remap[0]].logical_y_bit(3),

                3 => self.u[self.remap[1]].logical_y_bit(0),
                5 => self.u[self.remap[1]].logical_y_bit(1),
                7 => self.u[self.remap[1]].logical_y_bit(2),
                9 => self.u[self.remap[1]].logical_y_bit(3),

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => for (self.u) |unit| {
                    try v.expect_valid(unit.a, options.levels);
                    try v.expect_valid(unit.n_oe, options.levels);
                    if (v.read_logic(unit.n_oe, options.levels) == false) {
                        var data = v.read_bus(unit.a, options.levels);
                        if (invert_outputs) {
                            data = ~data;
                        }
                        try v.expect_output_valid(unit.y, data, options.levels);
                    }
                },
                .nets_only => for (self.u) |unit| {
                    if (v.read_logic(unit.n_oe, options.levels) == false) {
                        var data = v.read_bus(unit.a, options.levels);
                        if (invert_outputs) {
                            data = ~data;
                        }
                        try v.drive_bus(unit.y, data, options.levels);
                    }
                },
            }
        }
    };
}

/// Dual 4b inverter, tri-state
pub fn x240(comptime options: Options) type {
    return Dual_4b_Tristate_Buffer("240", options, .{ true, true });
}

/// Dual 4b buffer, tri-state (one active low and one active high OE)
pub fn x241(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("241"),

        u0: Unit_Active_Low_OE = .{},
        u1: Unit_Active_High_OE = .{},
        pwr: power.Single(options.pwr, options.Decoupler) = .{},

        pub const Unit_Active_Low_OE = struct {
            a: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            remap: [4]u2 = .{ 0, 1, 2, 3 },

            fn logical_a_bit(self: Unit_Active_Low_OE, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }
            fn logical_y_bit(self: Unit_Active_Low_OE, physical_bit: usize) usize {
                return self.y[self.remap[physical_bit]];
            }
        };
        pub const Unit_Active_High_OE = struct {
            a: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
            oe: Net_ID = .unset,
            remap: [4]u2 = .{ 0, 1, 2, 3 },

            fn logical_a_bit(self: Unit_Active_High_OE, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }
            fn logical_y_bit(self: Unit_Active_High_OE, physical_bit: usize) usize {
                return self.y[self.remap[physical_bit]];
            }
        };

        pub fn check_config(self: @This()) !void {
            {
                var mapped_bits: [4]bool = @splat(false);
                for (self.u0.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit 0: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
            {
                var mapped_bits: [4]bool = @splat(false);
                for (self.u1.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit 1: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u0.n_oe,
                19 => self.u1.oe,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.u0.logical_a_bit(0),
                4 => self.u0.logical_a_bit(1),
                6 => self.u0.logical_a_bit(2),
                8 => self.u0.logical_a_bit(3),

                17 => self.u1.logical_a_bit(0),
                15 => self.u1.logical_a_bit(1),
                13 => self.u1.logical_a_bit(2),
                11 => self.u1.logical_a_bit(3),

                18 => self.u0.logical_y_bit(0),
                16 => self.u0.logical_y_bit(1),
                14 => self.u0.logical_y_bit(2),
                12 => self.u0.logical_y_bit(3),

                3 => self.u1.logical_y_bit(0),
                5 => self.u1.logical_y_bit(1),
                7 => self.u1.logical_y_bit(2),
                9 => self.u1.logical_y_bit(3),

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.u0.a, options.levels);
                    try v.expect_valid(self.u0.n_oe, options.levels);
                    try v.expect_valid(self.u1.a, options.levels);
                    try v.expect_valid(self.u1.oe, options.levels);
                    if (v.read_logic(self.u0.n_oe, options.levels) == false) {
                        const data = v.read_bus(self.u0.a, options.levels);
                        try v.expect_output_valid(self.u0.y, data, options.levels);
                    }
                    if (v.read_logic(self.u1.oe, options.levels) == true) {
                        const data = v.read_bus(self.u1.a, options.levels);
                        try v.expect_output_valid(self.u1.y, data, options.levels);
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.u0.n_oe, options.levels) == false) {
                        const data = v.read_bus(self.u0.a, options.levels);
                        try v.drive_bus(self.u0.y, data, options.levels);
                    }
                    if (v.read_logic(self.u1.oe, options.levels) == true) {
                        const data = v.read_bus(self.u1.a, options.levels);
                        try v.drive_bus(self.u1.y, data, options.levels);
                    }
                },
            }
        }
    };
}

/// Dual 4b buffer, tri-state
pub fn x244(comptime options: Options) type {
    return Dual_4b_Tristate_Buffer("244", options, .{ false, false });
}

/// 8b bus transceiver
pub fn x245(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("245"),

        a: [8]Net_ID = @splat(.unset),
        b: [8]Net_ID = @splat(.unset),
        n_oe: Net_ID = .unset,
        a_to_b: Net_ID = .unset, // B to A when low
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [8]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.a_to_b,
                19 => self.n_oe,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.a[self.remap[0]],
                3 => self.a[self.remap[1]],
                4 => self.a[self.remap[2]],
                5 => self.a[self.remap[3]],
                6 => self.a[self.remap[4]],
                7 => self.a[self.remap[5]],
                8 => self.a[self.remap[6]],
                9 => self.a[self.remap[7]],

                18 => self.b[self.remap[0]],
                17 => self.b[self.remap[1]],
                16 => self.b[self.remap[2]],
                15 => self.b[self.remap[3]],
                14 => self.b[self.remap[4]],
                13 => self.b[self.remap[5]],
                12 => self.b[self.remap[6]],
                11 => self.b[self.remap[7]],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.n_oe, options.levels);
                    try v.expect_valid(self.a_to_b, options.levels);
                    if (v.read_logic(self.a_to_b, options.levels)) {
                        try v.expect_valid(self.a, options.levels);
                        if (v.read_logic(self.n_oe, options.levels) == false) {
                            const data = v.read_bus(self.a, options.levels);
                            try v.expect_output_valid(self.b, data, options.levels);
                        }
                    } else {
                        try v.expect_valid(self.b, options.levels);
                        if (v.read_logic(self.n_oe, options.levels) == false) {
                            const data = v.read_bus(self.b, options.levels);
                            try v.expect_output_valid(self.a, data, options.levels);
                        }
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.n_oe, options.levels) == false) {
                        if (v.read_logic(self.a_to_b, options.levels)) {
                            const data = v.read_bus(self.a, options.levels);
                            try v.drive_bus(self.b, data, options.levels);
                        } else {
                            const data = v.read_bus(self.b, options.levels);
                            try v.drive_bus(self.a, data, options.levels);
                        }
                    }
                },
            }
        }
    };
}

pub fn Octal_Line_Driver(comptime value_suffix: []const u8, comptime options: Options, comptime invert: bool) type {
    return struct {
        base: Part.Base = options.base(value_suffix),

        a: [8]Net_ID = @splat(.unset),
        y: [8]Net_ID = @splat(.unset),
        n_oe: [2]Net_ID = @splat(.unset),
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [8]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.n_oe[0],
                19 => self.n_oe[1],

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.a[self.remap[0]],
                3 => self.a[self.remap[1]],
                4 => self.a[self.remap[2]],
                5 => self.a[self.remap[3]],
                6 => self.a[self.remap[4]],
                7 => self.a[self.remap[5]],
                8 => self.a[self.remap[6]],
                9 => self.a[self.remap[7]],

                18 => self.y[self.remap[0]],
                17 => self.y[self.remap[1]],
                16 => self.y[self.remap[2]],
                15 => self.y[self.remap[3]],
                14 => self.y[self.remap[4]],
                13 => self.y[self.remap[5]],
                12 => self.y[self.remap[6]],
                11 => self.y[self.remap[7]],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);
                    const oe = v.read_bus(self.n_oe, options.levels);
                    if (oe == 0) {
                        var a = v.read_bus(self.a, options.levels);
                        if (invert) a = a ^ 0xFF;
                        try v.expect_output_valid(self.y, a, options.levels);
                    }
                },
                .nets_only => {
                    const oe = v.read_bus(self.n_oe, options.levels);
                    if (oe == 0) {
                        var a = v.read_bus(self.a, options.levels);
                        if (invert) a = a ^ 0xFF;
                        try v.drive_bus(self.y, a, options.levels);
                    }
                },
            }
        }
    };
}

/// 8b inverter, tri-state (dual OE)
pub fn x540(comptime options: Options) type {
    return Octal_Line_Driver("540", options, true);
}
/// 8b buffer, tri-state (dual OE)
pub fn x541(comptime options: Options) type {
    return Octal_Line_Driver("541", options, false);
}

/// 8b transparent latch, tri-state
pub fn x573(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("573"),

        d: [8]Net_ID = @splat(.unset),
        q: [8]Net_ID = @splat(.unset),
        transparent: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [8]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.n_oe,
                11 => self.transparent,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.d[self.remap[0]],
                3 => self.d[self.remap[1]],
                4 => self.d[self.remap[2]],
                5 => self.d[self.remap[3]],
                6 => self.d[self.remap[4]],
                7 => self.d[self.remap[5]],
                8 => self.d[self.remap[6]],
                9 => self.d[self.remap[7]],

                19 => self.q[self.remap[0]],
                18 => self.q[self.remap[1]],
                17 => self.q[self.remap[2]],
                16 => self.q[self.remap[3]],
                15 => self.q[self.remap[4]],
                14 => self.q[self.remap[5]],
                13 => self.q[self.remap[6]],
                12 => self.q[self.remap[7]],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            data: u8,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.data = 0xAA;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.transparent, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);
                    const le = v.read_logic(self.transparent, options.levels);
                    if (le == true) {
                        state.data = @truncate(v.read_bus(self.d, options.levels));
                    }
                    const oe = v.read_logic(self.n_oe, options.levels);
                    if (oe == false) {
                        try v.expect_output_valid(self.q, state.data, options.levels);
                    }
                },
                .nets_only => {
                    const oe = v.read_logic(self.n_oe, options.levels);
                    if (oe == false) {
                        const le = v.read_logic(self.transparent, options.levels);
                        const data = if (le == true) v.read_bus(self.d, options.levels) else state.data;
                        try v.drive_bus(self.q, data, options.levels);
                    }
                },
            }
        }
    };
}

/// 8b positive-edge-triggered D register, tri-state
pub fn x574(comptime options: Options) type {
    return struct {
        base: Part.Base = options.base("574"),

        d: [8]Net_ID = @splat(.unset),
        q: [8]Net_ID = @splat(.unset),
        clk: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Single(options.pwr, options.Decoupler) = .{},
        remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [8]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.n_oe,
                11 => self.clk,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(options.pwr)),

                2 => self.d[self.remap[0]],
                3 => self.d[self.remap[1]],
                4 => self.d[self.remap[2]],
                5 => self.d[self.remap[3]],
                6 => self.d[self.remap[4]],
                7 => self.d[self.remap[5]],
                8 => self.d[self.remap[6]],
                9 => self.d[self.remap[7]],

                19 => self.q[self.remap[0]],
                18 => self.q[self.remap[1]],
                17 => self.q[self.remap[2]],
                16 => self.q[self.remap[3]],
                15 => self.q[self.remap[4]],
                14 => self.q[self.remap[5]],
                13 => self.q[self.remap[6]],
                12 => self.q[self.remap[7]],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            data: u8,
            clk: bool,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.data = 0xAA;
                    state.clk = true;
                },
                .commit => {
                    try v.expect_valid(self.d, options.levels);
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);
                    const oe = v.read_logic(self.n_oe, options.levels);
                    if (oe == false) {
                        try v.expect_output_valid(self.q, state.data, options.levels);
                    }
                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk) {
                        state.data = @truncate(v.read_bus(self.d, options.levels));
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    const oe = v.read_logic(self.n_oe, options.levels);
                    if (oe == false) {
                        try v.drive_bus(self.q, state.data, options.levels);
                    }
                },
            }
        }
    };
}

/// 4x 4b buffer, tri-state
pub fn x16244(comptime options: Options, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = options.base(if (bus_hold) "H16244" else "16244"),

        u: [4]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, options.pwr, options.Decoupler) = .{},
        remap: [4]u2 = .{ 0, 1, 2, 3 },

        pub const Unit = struct {
            a: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            remap: [4]u2 = .{ 0, 1, 2, 3 },

            fn logical_a_bit(self: Unit, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }

            fn logical_y_bit(self: Unit, physical_bit: usize) usize {
                return self.y[self.remap[physical_bit]];
            }
        };

        pub fn check_config(self: @This()) !void {
            var mapped_units: [4]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_units[logical] = true;
            }
            for (0.., mapped_units) |logical_unit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical unit assigned to logical unit {}", .{ @typeName(@This()), logical_unit });
                    return error.InvalidRemap;
                }
            }

            for (0.., self.u) |unit_idx, unit| {
                var mapped_bits: [4]bool = @splat(false);
                for (unit.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit {}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), unit_idx, logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u[self.remap[0]].n_oe,
                48 => self.u[self.remap[1]].n_oe,
                25 => self.u[self.remap[2]].n_oe,
                24 => self.u[self.remap[3]].n_oe,

                47 => self.u[self.remap[0]].logical_a_bit(0),
                46 => self.u[self.remap[0]].logical_a_bit(1),
                44 => self.u[self.remap[0]].logical_a_bit(2),
                43 => self.u[self.remap[0]].logical_a_bit(3),

                41 => self.u[self.remap[1]].logical_a_bit(0),
                40 => self.u[self.remap[1]].logical_a_bit(1),
                38 => self.u[self.remap[1]].logical_a_bit(2),
                37 => self.u[self.remap[1]].logical_a_bit(3),

                36 => self.u[self.remap[2]].logical_a_bit(0),
                35 => self.u[self.remap[2]].logical_a_bit(1),
                33 => self.u[self.remap[2]].logical_a_bit(2),
                32 => self.u[self.remap[2]].logical_a_bit(3),

                30 => self.u[self.remap[3]].logical_a_bit(0),
                29 => self.u[self.remap[3]].logical_a_bit(1),
                27 => self.u[self.remap[3]].logical_a_bit(2),
                26 => self.u[self.remap[3]].logical_a_bit(3),

                2 => self.u[self.remap[0]].logical_y_bit(0),
                3 => self.u[self.remap[0]].logical_y_bit(1),
                5 => self.u[self.remap[0]].logical_y_bit(2),
                6 => self.u[self.remap[0]].logical_y_bit(3),

                8 => self.u[self.remap[1]].logical_y_bit(0),
                9 => self.u[self.remap[1]].logical_y_bit(1),
                11 => self.u[self.remap[1]].logical_y_bit(2),
                12 => self.u[self.remap[1]].logical_y_bit(3),

                13 => self.u[self.remap[2]].logical_y_bit(0),
                14 => self.u[self.remap[2]].logical_y_bit(1),
                16 => self.u[self.remap[2]].logical_y_bit(2),
                17 => self.u[self.remap[2]].logical_y_bit(3),

                19 => self.u[self.remap[3]].logical_y_bit(0),
                20 => self.u[self.remap[3]].logical_y_bit(1),
                22 => self.u[self.remap[3]].logical_y_bit(2),
                23 => self.u[self.remap[3]].logical_y_bit(3),

                4 => self.pwr.gnd[0],
                10 => self.pwr.gnd[1],
                15 => self.pwr.gnd[2],
                21 => self.pwr.gnd[3],
                28 => self.pwr.gnd[4],
                34 => self.pwr.gnd[5],
                39 => self.pwr.gnd[6],
                45 => self.pwr.gnd[7],

                7 => @field(self.pwr, @tagName(options.pwr))[0],
                18 => @field(self.pwr, @tagName(options.pwr))[1],
                31 => @field(self.pwr, @tagName(options.pwr))[2],
                42 => @field(self.pwr, @tagName(options.pwr))[3],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            bus_hold: if (bus_hold) u4 else void,
        };

        pub fn validate(self: @This(), v: *Validator, state: *[4]Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => if (bus_hold) {
                    state[0].bus_hold = 0;
                    state[1].bus_hold = 0;
                    state[2].bus_hold = 0;
                    state[3].bus_hold = 0;
                },
                .commit => for (self.u, state) |unit, *unit_state| {
                    if (bus_hold) {
                        try v.expect_valid_or_unconnected(unit.a, options.levels);
                    } else {
                        try v.expect_valid(unit.a, options.levels);
                    }
                    try v.expect_valid(unit.n_oe, options.levels);
                    if (v.read_logic(unit.n_oe, options.levels) == false) {
                        const data = read_a(unit, v, unit_state);
                        try v.expect_output_valid(unit.y, data, options.levels);
                    }
                },
                .nets_only => {
                    if (bus_hold) {
                        for (self.u, state) |unit, *unit_state| {
                            unit_state.bus_hold = @truncate(try v.pull_and_read_bus(unit.a, options.levels, unit_state.bus_hold));
                        }
                    }
                    for (self.u, state) |unit, *unit_state| {
                        if (v.read_logic(unit.n_oe, options.levels) == false) {
                            const data = read_a(unit, v, unit_state);
                            try v.drive_bus(unit.y, data, options.levels);
                        }
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State) u16 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, options.levels, state.bus_hold));
            } else {
                return @truncate(v.read_bus(unit.a, options.levels));
            }
        }
    };
}

/// 4x 4b buffer, tri-state
pub fn x16245(comptime options: Options, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = options.base(if (bus_hold) "H16245" else "16245"),

        u: [2]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, options.pwr, options.Decoupler) = .{},
        remap: [2]u1 = .{ 0, 1 },

        pub const Unit = struct {
            a: [8]Net_ID = @splat(.unset),
            b: [8]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            a_to_b: Net_ID = .unset, // B to A when low
            remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },

            fn logical_a_bit(self: Unit, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }

            fn logical_b_bit(self: Unit, physical_bit: usize) usize {
                return self.b[self.remap[physical_bit]];
            }
        };

        pub fn check_config(self: @This()) !void {
            var mapped_units: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_units[logical] = true;
            }
            for (0.., mapped_units) |logical_unit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical unit assigned to logical unit {}", .{ @typeName(@This()), logical_unit });
                    return error.InvalidRemap;
                }
            }

            for (0.., self.u) |unit_idx, unit| {
                var mapped_bits: [8]bool = @splat(false);
                for (unit.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit {}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), unit_idx, logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u[self.remap[0]].a_to_b,
                48 => self.u[self.remap[0]].n_oe,
                25 => self.u[self.remap[1]].n_oe,
                24 => self.u[self.remap[1]].a_to_b,

                47 => self.u[self.remap[0]].logical_a_bit(0),
                46 => self.u[self.remap[0]].logical_a_bit(1),
                44 => self.u[self.remap[0]].logical_a_bit(2),
                43 => self.u[self.remap[0]].logical_a_bit(3),
                41 => self.u[self.remap[0]].logical_a_bit(4),
                40 => self.u[self.remap[0]].logical_a_bit(5),
                38 => self.u[self.remap[0]].logical_a_bit(6),
                37 => self.u[self.remap[0]].logical_a_bit(7),

                36 => self.u[self.remap[1]].logical_a_bit(0),
                35 => self.u[self.remap[1]].logical_a_bit(1),
                33 => self.u[self.remap[1]].logical_a_bit(2),
                32 => self.u[self.remap[1]].logical_a_bit(3),
                30 => self.u[self.remap[1]].logical_a_bit(4),
                29 => self.u[self.remap[1]].logical_a_bit(5),
                27 => self.u[self.remap[1]].logical_a_bit(6),
                26 => self.u[self.remap[1]].logical_a_bit(7),

                2 => self.u[self.remap[0]].logical_b_bit(0),
                3 => self.u[self.remap[0]].logical_b_bit(1),
                5 => self.u[self.remap[0]].logical_b_bit(2),
                6 => self.u[self.remap[0]].logical_b_bit(3),
                8 => self.u[self.remap[0]].logical_b_bit(4),
                9 => self.u[self.remap[0]].logical_b_bit(5),
                11 => self.u[self.remap[0]].logical_b_bit(6),
                12 => self.u[self.remap[0]].logical_b_bit(7),

                13 => self.u[self.remap[1]].logical_b_bit(0),
                14 => self.u[self.remap[1]].logical_b_bit(1),
                16 => self.u[self.remap[1]].logical_b_bit(2),
                17 => self.u[self.remap[1]].logical_b_bit(3),
                19 => self.u[self.remap[1]].logical_b_bit(4),
                20 => self.u[self.remap[1]].logical_b_bit(5),
                22 => self.u[self.remap[1]].logical_b_bit(6),
                23 => self.u[self.remap[1]].logical_b_bit(7),
                
                4 => self.pwr.gnd[0],
                10 => self.pwr.gnd[1],
                15 => self.pwr.gnd[2],
                21 => self.pwr.gnd[3],
                28 => self.pwr.gnd[4],
                34 => self.pwr.gnd[5],
                39 => self.pwr.gnd[6],
                45 => self.pwr.gnd[7],

                7 => @field(self.pwr, @tagName(options.pwr))[0],
                18 => @field(self.pwr, @tagName(options.pwr))[1],
                31 => @field(self.pwr, @tagName(options.pwr))[2],
                42 => @field(self.pwr, @tagName(options.pwr))[3],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            a_hold: if (bus_hold) u8 else void,
            b_hold: if (bus_hold) u8 else void,
        };

        pub fn validate(self: @This(), v: *Validator, state: *[2]Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => if (bus_hold) {
                    state[0].a_hold = 0;
                    state[0].b_hold = 0;
                    state[1].a_hold = 0;
                    state[1].b_hold = 0;
                },
                .commit => for (self.u, state) |unit, *unit_state| {
                    try v.expect_valid(unit.n_oe, options.levels);
                    try v.expect_valid(unit.a_to_b, options.levels);
                    if (v.read_logic(unit.a_to_b, options.levels)) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.a, options.levels) else try v.expect_valid(unit.a, options.levels);
                    } else {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.b, options.levels) else try v.expect_valid(unit.b, options.levels);
                    }
                    if (v.read_logic(unit.n_oe, options.levels) == false) {
                        if (v.read_logic(unit.a_to_b, options.levels)) {
                            const data = read_a(unit, v, unit_state);
                            try v.expect_output_valid(unit.b, data, options.levels);
                        } else {
                            const data = read_b(unit, v, unit_state);
                            try v.expect_output_valid(unit.a, data, options.levels);
                        }
                    }
                },
                .nets_only => for (self.u, state) |unit, *unit_state| {
                    if (bus_hold) {
                        unit_state.a_hold = @truncate(try v.pull_and_read_bus(unit.a, options.levels, unit_state.a_hold));
                        unit_state.b_hold = @truncate(try v.pull_and_read_bus(unit.b, options.levels, unit_state.b_hold));
                    }
                    if (v.read_logic(unit.n_oe, options.levels) == false) {
                        if (v.read_logic(unit.a_to_b, options.levels)) {
                            try v.drive_bus(unit.b, read_a(unit, v, unit_state), options.levels);
                        } else {
                            try v.drive_bus(unit.a, read_b(unit, v, unit_state), options.levels);
                        }
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State) u8 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, options.levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(unit.a, options.levels));
            }
        }

        fn read_b(unit: Unit, v: *Validator, state: *Validate_State) u8 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.b, options.levels, state.b_hold));
            } else {
                return @truncate(v.read_bus(unit.b, options.levels));
            }
        }
    };
}

/// 2x12b bus exchange switch
pub fn CBT16212(comptime options: Options) type {
    std.debug.assert(options.logic_family == .CBT or options.logic_family == .CBTLV);
    return struct {
        base: Part.Base = options.base("16212"),

        pwr: power.Multi(1, 4, options.pwr, options.Decoupler) = .{},
        left: [2][12]Net_ID = @splat(@splat(.unset)),
        right: [2][12]Net_ID = @splat(@splat(.unset)),
        op_sel: [3]Net_ID = @splat(.unset),
        remap: [12]u4 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
        r_on: f32 = 3,

        pub const Op = enum (u3) {
            disconnect = 0,
            l0_r0 = 1, // l1, r1 Hi-Z
            l0_r1 = 2, // l1, r0 Hi-Z
            l1_r0 = 3, // l0, r1 Hi-Z
            l1_r1 = 4, // l0, r0 Hi-Z
            disconnect_alt = 5,
            passthrough = 6, // l0 <=> r0, l1 <=> r1
            exchange = 7,    // l0 <=> r1, l1 <=> r0
        };

        fn logical_l_net(self: @This(), bus: u1, physical_bit: usize) Net_ID {
            return self.left[bus][self.remap[physical_bit]];
        }

        fn logical_r_net(self: @This(), bus: u1, physical_bit: usize) Net_ID {
            return self.right[bus][self.remap[physical_bit]];
        }

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [12]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd[0] else unreachable,

                1 => self.op_sel[0],
                56 => self.op_sel[1],
                55 => self.op_sel[2],

                2  => self.logical_l_net(0, 0),
                3  => self.logical_l_net(1, 0),
                4  => self.logical_l_net(0, 1),
                5  => self.logical_l_net(1, 1),
                6  => self.logical_l_net(0, 2),
                7  => self.logical_l_net(1, 2),
                9  => self.logical_l_net(0, 3),
                10 => self.logical_l_net(1, 3),
                11 => self.logical_l_net(0, 4),
                12 => self.logical_l_net(1, 4),
                13 => self.logical_l_net(0, 5),
                14 => self.logical_l_net(1, 5),
                15 => self.logical_l_net(0, 6),
                16 => self.logical_l_net(1, 6),
                18 => self.logical_l_net(0, 7),
                20 => self.logical_l_net(1, 7),
                21 => self.logical_l_net(0, 8),
                22 => self.logical_l_net(1, 8),
                23 => self.logical_l_net(0, 9),
                24 => self.logical_l_net(1, 9),
                25 => self.logical_l_net(0, 10),
                26 => self.logical_l_net(1, 10),
                27 => self.logical_l_net(0, 11),
                28 => self.logical_l_net(1, 11),

                54 => self.logical_r_net(0, 0),
                53 => self.logical_r_net(1, 0),
                52 => self.logical_r_net(0, 1),
                51 => self.logical_r_net(1, 1),
                50 => self.logical_r_net(0, 2),
                48 => self.logical_r_net(1, 2),
                47 => self.logical_r_net(0, 3),
                46 => self.logical_r_net(1, 3),
                45 => self.logical_r_net(0, 4),
                44 => self.logical_r_net(1, 4),
                43 => self.logical_r_net(0, 5),
                42 => self.logical_r_net(1, 5),
                41 => self.logical_r_net(0, 6),
                40 => self.logical_r_net(1, 6),
                39 => self.logical_r_net(0, 7),
                37 => self.logical_r_net(1, 7),
                36 => self.logical_r_net(0, 8),
                35 => self.logical_r_net(1, 8),
                34 => self.logical_r_net(0, 9),
                33 => self.logical_r_net(1, 9),
                32 => self.logical_r_net(0, 10),
                31 => self.logical_r_net(1, 10),
                30 => self.logical_r_net(0, 11),
                29 => self.logical_r_net(1, 11),

                8 => self.pwr.gnd[0],
                19 => self.pwr.gnd[1],
                38 => self.pwr.gnd[2],
                49 => self.pwr.gnd[3],

                17 => @field(self.pwr, @tagName(options.pwr))[0],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.op_sel, options.levels);
                    try v.expect_below(self.left[0], options.levels.Vclamp);
                    try v.expect_below(self.left[1], options.levels.Vclamp);
                    try v.expect_below(self.right[0], options.levels.Vclamp);
                    try v.expect_below(self.right[1], options.levels.Vclamp);

                    const power_limit = 0.016384 * self.r_on;
                    switch (self.read_op(v)) {
                        .disconnect, .disconnect_alt => {},
                        .l0_r0 => try v.verify_power_limit(self.left[0], self.right[0], self.r_on, power_limit),
                        .l0_r1 => try v.verify_power_limit(self.left[0], self.right[1], self.r_on, power_limit),
                        .l1_r0 => try v.verify_power_limit(self.left[1], self.right[0], self.r_on, power_limit),
                        .l1_r1 => try v.verify_power_limit(self.left[1], self.right[1], self.r_on, power_limit),
                        .passthrough => {
                            try v.verify_power_limit(self.left[0], self.right[0], self.r_on, power_limit);
                            try v.verify_power_limit(self.left[1], self.right[1], self.r_on, power_limit);
                        },
                        .exchange => {
                            try v.verify_power_limit(self.left[0], self.right[1], self.r_on, power_limit);
                            try v.verify_power_limit(self.left[1], self.right[0], self.r_on, power_limit);
                        },
                    }
                },
                .nets_only => {
                    switch (self.read_op(v)) {
                        .disconnect, .disconnect_alt => {},
                        .l0_r0 => try v.connect_buses(self.left[0], self.right[0], self.r_on),
                        .l0_r1 => try v.connect_buses(self.left[0], self.right[1], self.r_on),
                        .l1_r0 => try v.connect_buses(self.left[1], self.right[0], self.r_on),
                        .l1_r1 => try v.connect_buses(self.left[1], self.right[1], self.r_on),
                        .passthrough => {
                            try v.connect_buses(self.left[0], self.right[0], self.r_on);
                            try v.connect_buses(self.left[1], self.right[1], self.r_on);
                        },
                        .exchange => {
                            try v.connect_buses(self.left[0], self.right[1], self.r_on);
                            try v.connect_buses(self.left[1], self.right[0], self.r_on);
                        },
                    }
                },
            }
        }

        fn read_op(self: @This(), v: *Validator) Op {
            return @enumFromInt(v.read_bus(self.op_sel, options.levels));
        }
    };
}

/// 12x 2:1 mux/demux, latched, tri-state
pub fn x16260(comptime options: Options, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = options.base(if (bus_hold) "H16260" else "16260"),

        a: Port_A = .{},
        bx: Port_B = .{},
        by: Port_B = .{},
        pwr: power.Multi(4, 8, options.pwr, options.Decoupler) = .{},
        remap: [12]u4 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },

        pub const Port_A = struct {
            data: [12]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            enable_bx: Net_ID = .unset, // when low, output comes from by instead
        };

        pub const Port_B = struct {
            data: [12]Net_ID = @splat(.unset),
            n_oe: Net_ID = .unset,
            latch_input_data: Net_ID = .unset, // latch data from B side; transparent when high
            latch_output_data: Net_ID = .unset, // latch data from A side; transparent when high
        };

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [12]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.a.n_oe,
                28 => self.a.enable_bx,
                8 => self.a.data[self.remap[0]],
                9 => self.a.data[self.remap[1]],
                10 => self.a.data[self.remap[2]],
                12 => self.a.data[self.remap[3]],
                13 => self.a.data[self.remap[4]],
                14 => self.a.data[self.remap[5]],
                15 => self.a.data[self.remap[6]],
                16 => self.a.data[self.remap[7]],
                17 => self.a.data[self.remap[8]],
                19 => self.a.data[self.remap[9]],
                20 => self.a.data[self.remap[10]],
                21 => self.a.data[self.remap[11]],

                2 => self.bx.latch_input_data,
                30 => self.bx.latch_output_data,
                29 => self.bx.n_oe,
                23 => self.bx.data[self.remap[0]],
                24 => self.bx.data[self.remap[1]],
                26 => self.bx.data[self.remap[2]],
                31 => self.bx.data[self.remap[3]],
                33 => self.bx.data[self.remap[4]],
                34 => self.bx.data[self.remap[5]],
                36 => self.bx.data[self.remap[6]],
                37 => self.bx.data[self.remap[7]],
                38 => self.bx.data[self.remap[8]],
                40 => self.bx.data[self.remap[9]],
                41 => self.bx.data[self.remap[10]],
                42 => self.bx.data[self.remap[11]],

                27 => self.by.latch_input_data,
                55 => self.by.latch_output_data,
                56 => self.by.n_oe,
                52 => self.by.data[self.remap[0]],
                5 => self.by.data[self.remap[1]],
                3 => self.by.data[self.remap[2]],
                54 => self.by.data[self.remap[3]],
                6 => self.by.data[self.remap[4]],
                51 => self.by.data[self.remap[5]],
                49 => self.by.data[self.remap[6]],
                48 => self.by.data[self.remap[7]],
                47 => self.by.data[self.remap[8]],
                45 => self.by.data[self.remap[9]],
                44 => self.by.data[self.remap[10]],
                43 => self.by.data[self.remap[11]],

                4 => self.pwr.gnd[0],
                11 => self.pwr.gnd[1],
                18 => self.pwr.gnd[2],
                25 => self.pwr.gnd[3],
                32 => self.pwr.gnd[4],
                39 => self.pwr.gnd[5],
                46 => self.pwr.gnd[6],
                53 => self.pwr.gnd[7],

                7 => @field(self.pwr, @tagName(options.pwr))[0],
                22 => @field(self.pwr, @tagName(options.pwr))[1],
                35 => @field(self.pwr, @tagName(options.pwr))[2],
                50 => @field(self.pwr, @tagName(options.pwr))[3],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            bx_to_a: u12,
            by_to_a: u12,
            a_to_bx: u12,
            a_to_by: u12,
            a_hold: if (bus_hold) u12 else void,
            bx_hold: if (bus_hold) u12 else void,
            by_hold: if (bus_hold) u12 else void,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.bx_to_a = 0xAAA;
                    state.by_to_a = 0xAAA;
                    state.a_to_bx = 0xAAA;
                    state.a_to_by = 0xAAA;
                    if (bus_hold) {
                        state.a_hold = 0;
                        state.bx_hold = 0;
                        state.by_hold = 0;
                    }
                },
                .commit => {
                    if (bus_hold) {
                        try v.expect_valid_or_unconnected(self.a.data, options.levels);
                        try v.expect_valid_or_unconnected(self.bx.data, options.levels);
                        try v.expect_valid_or_unconnected(self.by.data, options.levels);
                    } else {
                        try v.expect_valid(self.a.data, options.levels);
                        try v.expect_valid(self.bx.data, options.levels);
                        try v.expect_valid(self.by.data, options.levels);
                    }

                    try v.expect_valid(self.a.n_oe, options.levels);
                    try v.expect_valid(self.a.enable_bx, options.levels);
                    try v.expect_valid(self.bx.n_oe, options.levels);
                    try v.expect_valid(self.by.n_oe, options.levels);

                    try v.expect_valid(self.bx.latch_input_data, options.levels);
                    try v.expect_valid(self.by.latch_input_data, options.levels);
                    try v.expect_valid(self.bx.latch_output_data, options.levels);
                    try v.expect_valid(self.by.latch_output_data, options.levels);

                    if (v.read_logic(self.bx.latch_input_data, options.levels)) state.bx_to_a = self.read_bx(v, state);
                    if (v.read_logic(self.bx.latch_output_data, options.levels)) state.a_to_bx = self.read_a(v, state);

                    if (v.read_logic(self.by.latch_input_data, options.levels)) state.by_to_a = self.read_by(v, state);
                    if (v.read_logic(self.by.latch_output_data, options.levels)) state.a_to_by = self.read_a(v, state);

                    if (v.read_logic(self.a.n_oe, options.levels) == false) {
                        const data = switch (v.read_logic(self.a.enable_bx, options.levels)) {
                            true => if (v.read_logic(self.bx.latch_input_data, options.levels)) self.read_bx(v, state) else state.bx_to_a,
                            false => if (v.read_logic(self.by.latch_input_data, options.levels)) self.read_by(v, state) else state.by_to_a,
                        };
                        try v.expect_output_valid(self.a.data, data, options.levels);
                    }

                    if (v.read_logic(self.bx.n_oe, options.levels) == false) {
                        const data = if (v.read_logic(self.bx.latch_output_data, options.levels)) self.read_a(v, state) else state.a_to_bx;
                        try v.expect_output_valid(self.bx.data, data, options.levels);
                    }

                    if (v.read_logic(self.by.n_oe, options.levels) == false) {
                        const data = if (v.read_logic(self.by.latch_output_data, options.levels)) self.read_a(v, state) else state.a_to_by;
                        try v.expect_output_valid(self.by.data, data, options.levels);
                    }
                },
                .nets_only => {
                    if (bus_hold) {
                        state.a_hold = @truncate(try v.pull_and_read_bus(self.a.data, options.levels, state.a_hold));
                        state.bx_hold = @truncate(try v.pull_and_read_bus(self.bx.data, options.levels, state.bx_hold));
                        state.by_hold = @truncate(try v.pull_and_read_bus(self.by.data, options.levels, state.by_hold));
                    }

                    if (v.read_logic(self.a.n_oe, options.levels) == false) {
                        const data = switch (v.read_logic(self.a.enable_bx, options.levels)) {
                            true => if (v.read_logic(self.bx.latch_input_data, options.levels)) self.read_bx(v, state) else state.bx_to_a,
                            false => if (v.read_logic(self.by.latch_input_data, options.levels)) self.read_by(v, state) else state.by_to_a,
                        };
                        try v.drive_bus(self.a.data, data, options.levels);
                    }

                    if (v.read_logic(self.bx.n_oe, options.levels) == false) {
                        const data = if (v.read_logic(self.bx.latch_output_data, options.levels)) self.read_a(v, state) else state.a_to_bx;
                        try v.drive_bus(self.bx.data, data, options.levels);
                    }

                    if (v.read_logic(self.by.n_oe, options.levels) == false) {
                        const data = if (v.read_logic(self.by.latch_output_data, options.levels)) self.read_a(v, state) else state.a_to_by;
                        try v.drive_bus(self.by.data, data, options.levels);
                    }
                },
            }
        }

        fn read_a(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.a.data, options.levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(self.a.data, options.levels));
            }
        }

        fn read_bx(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.bx.data, options.levels, state.bx_hold));
            } else {
                return @truncate(v.read_bus(self.bx.data, options.levels));
            }
        }

        fn read_by(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.by.data, options.levels, state.by_hold));
            } else {
                return @truncate(v.read_bus(self.by.data, options.levels));
            }
        }
    };
}

/// 2x 8b bus transceiver and bidirectional positive-edge-triggered register, tri-state
pub fn x16652(comptime options: Options, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = options.base(if (bus_hold) "H16652" else "16652"),

        u: [2]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, options.pwr, options.Decoupler) = .{},
        remap: [2]u1 = .{ 0, 1 },

        pub const Unit = struct {
            a: [8]Net_ID = @splat(.unset),
            b: [8]Net_ID = @splat(.unset),
            a_to_b: struct {
                oe: Net_ID = .unset,
                output_register: Net_ID = .unset, // when low, output data will come from register input instead
                clk: Net_ID = .unset,
            } = .{},
            b_to_a: struct {
                n_oe: Net_ID = .unset,
                output_register: Net_ID = .unset, // when low, output data will come from register input instead
                clk: Net_ID = .unset,
            } = .{},
            remap: [8]u3 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },
            
            fn logical_a_bit(self: Unit, physical_bit: usize) usize {
                return self.a[self.remap[physical_bit]];
            }

            fn logical_b_bit(self: Unit, physical_bit: usize) usize {
                return self.b[self.remap[physical_bit]];
            }
        };

        pub fn check_config(self: @This()) !void {
            var mapped_units: [2]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_units[logical] = true;
            }
            for (0.., mapped_units) |logical_unit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical unit assigned to logical unit {}", .{ @typeName(@This()), logical_unit });
                    return error.InvalidRemap;
                }
            }

            for (0.., self.u) |unit_idx, unit| {
                var mapped_bits: [8]bool = @splat(false);
                for (unit.remap) |logical| {
                    mapped_bits[logical] = true;
                }
                for (0.., mapped_bits) |logical_bit, mapped| {
                    if (!mapped) {
                        log.err("{s} unit {}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), unit_idx, logical_bit });
                        return error.InvalidRemap;
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u[self.remap[0]].a_to_b.oe,
                2 => self.u[self.remap[0]].a_to_b.clk,
                3 => self.u[self.remap[0]].a_to_b.output_register,
                56 => self.u[self.remap[0]].b_to_a.n_oe,
                55 => self.u[self.remap[0]].b_to_a.clk,
                54 => self.u[self.remap[0]].b_to_a.output_register,

                28 => self.u[self.remap[1]].a_to_b.oe,
                29 => self.u[self.remap[1]].a_to_b.clk,
                27 => self.u[self.remap[1]].a_to_b.output_register,
                30 => self.u[self.remap[1]].b_to_a.n_oe,
                26 => self.u[self.remap[1]].b_to_a.clk,
                31 => self.u[self.remap[1]].b_to_a.output_register,

                5 => self.u[self.remap[0]].logical_a_bit(0),
                6 => self.u[self.remap[0]].logical_a_bit(1),
                8 => self.u[self.remap[0]].logical_a_bit(2),
                9 => self.u[self.remap[0]].logical_a_bit(3),
                10 => self.u[self.remap[0]].logical_a_bit(4),
                12 => self.u[self.remap[0]].logical_a_bit(5),
                13 => self.u[self.remap[0]].logical_a_bit(6),
                14 => self.u[self.remap[0]].logical_a_bit(7),

                15 => self.u[self.remap[1]].logical_a_bit(0),
                16 => self.u[self.remap[1]].logical_a_bit(1),
                17 => self.u[self.remap[1]].logical_a_bit(2),
                19 => self.u[self.remap[1]].logical_a_bit(3),
                20 => self.u[self.remap[1]].logical_a_bit(4),
                21 => self.u[self.remap[1]].logical_a_bit(5),
                23 => self.u[self.remap[1]].logical_a_bit(6),
                24 => self.u[self.remap[1]].logical_a_bit(7),

                52 => self.u[self.remap[0]].logical_b_bit(0),
                51 => self.u[self.remap[0]].logical_b_bit(1),
                49 => self.u[self.remap[0]].logical_b_bit(2),
                48 => self.u[self.remap[0]].logical_b_bit(3),
                47 => self.u[self.remap[0]].logical_b_bit(4),
                45 => self.u[self.remap[0]].logical_b_bit(5),
                44 => self.u[self.remap[0]].logical_b_bit(6),
                43 => self.u[self.remap[0]].logical_b_bit(7),

                42 => self.u[self.remap[1]].logical_b_bit(0),
                41 => self.u[self.remap[1]].logical_b_bit(1),
                40 => self.u[self.remap[1]].logical_b_bit(2),
                38 => self.u[self.remap[1]].logical_b_bit(3),
                37 => self.u[self.remap[1]].logical_b_bit(4),
                36 => self.u[self.remap[1]].logical_b_bit(5),
                34 => self.u[self.remap[1]].logical_b_bit(6),
                33 => self.u[self.remap[1]].logical_b_bit(7),
                
                4 => self.pwr.gnd[0],
                11 => self.pwr.gnd[1],
                18 => self.pwr.gnd[2],
                25 => self.pwr.gnd[3],
                32 => self.pwr.gnd[4],
                39 => self.pwr.gnd[5],
                46 => self.pwr.gnd[6],
                53 => self.pwr.gnd[7],

                7 => @field(self.pwr, @tagName(options.pwr))[0],
                22 => @field(self.pwr, @tagName(options.pwr))[1],
                35 => @field(self.pwr, @tagName(options.pwr))[2],
                50 => @field(self.pwr, @tagName(options.pwr))[3],

                else => unreachable,
            };
        }

        const Validate_State = struct {
            a_to_b: u8,
            b_to_a: u8,
            a_to_b_clk: bool,
            b_to_a_clk: bool,
            a_hold: if (bus_hold) u8 else void,
            b_hold: if (bus_hold) u8 else void,
        };

        pub fn validate(self: @This(), v: *Validator, state: *[2]Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => for (state) |*unit_state| {
                    unit_state.a_to_b = 0xAA;
                    unit_state.b_to_a = 0xAA;
                    unit_state.a_to_b_clk = true;
                    unit_state.b_to_a_clk = true;
                    if (bus_hold) {
                        unit_state.a_hold = 0;
                        unit_state.b_hold = 0;
                    }
                },
                .commit => for (self.u, state) |unit, *unit_state| {
                    try v.expect_valid(unit.a_to_b.oe, options.levels);
                    try v.expect_valid(unit.b_to_a.n_oe, options.levels);

                    try v.expect_valid(unit.a_to_b.output_register, options.levels);
                    try v.expect_valid(unit.b_to_a.output_register, options.levels);

                    try v.expect_valid(unit.a_to_b.clk, options.levels);
                    try v.expect_valid(unit.b_to_a.clk, options.levels);

                    if (v.read_logic(unit.b_to_a.n_oe, options.levels) == true) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.a, options.levels) else try v.expect_valid(unit.a, options.levels);
                    }
                    if (v.read_logic(unit.a_to_b.oe, options.levels) == false) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.b, options.levels) else try v.expect_valid(unit.b, options.levels);
                    }

                    {
                        const new_a_to_b_clk = v.read_logic(unit.a_to_b.clk, options.levels);
                        if (new_a_to_b_clk and !unit_state.a_to_b_clk) {
                            unit_state.a_to_b = read_a(unit, v, unit_state, 2);
                        }
                        unit_state.a_to_b_clk = new_a_to_b_clk;
                    }
                    {
                        const new_b_to_a_clk = v.read_logic(unit.b_to_a.clk, options.levels);
                        if (new_b_to_a_clk and !unit_state.b_to_a_clk) {
                            unit_state.b_to_a = read_b(unit, v, unit_state, 2);
                        }
                        unit_state.b_to_a_clk = new_b_to_a_clk;
                    }
                },
                .nets_only => for (self.u, state) |unit, *unit_state| {
                    if (bus_hold) {
                        unit_state.a_hold = @truncate(try v.pull_and_read_bus(unit.a, options.levels, unit_state.a_hold));
                        unit_state.b_hold = @truncate(try v.pull_and_read_bus(unit.b, options.levels, unit_state.b_hold));
                    }

                    if (v.read_logic(unit.b_to_a.n_oe, options.levels) == false) {
                        const data = read_a(unit, v, unit_state, 2);
                        try v.drive_bus(unit.a, data, options.levels);
                        if (bus_hold) unit_state.a_hold = data;
                    }
                    if (v.read_logic(unit.a_to_b.oe, options.levels) == true) {
                        const data = read_b(unit, v, unit_state, 2);
                        try v.drive_bus(unit.b, data, options.levels);
                        if (bus_hold) unit_state.b_hold = data;
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State, limit: usize) u8 {
            if (limit > 0 and v.read_logic(unit.b_to_a.n_oe, options.levels) == false) {
                if (v.read_logic(unit.b_to_a.output_register, options.levels)) {
                    return state.b_to_a;
                } else {
                    return read_b(unit, v, state, limit - 1);
                }
            } else if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, options.levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(unit.a, options.levels));
            }
        }

        fn read_b(unit: Unit, v: *Validator, state: *Validate_State, limit: usize) u8 {
            if (limit > 0 and v.read_logic(unit.a_to_b.oe, options.levels) == true) {
                if (v.read_logic(unit.a_to_b.output_register, options.levels)) {
                    return state.a_to_b;
                } else {
                    return read_a(unit, v, state, limit - 1);
                }
            } else if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.b, options.levels, state.b_hold));
            } else {
                return @truncate(v.read_bus(unit.b, options.levels));
            }
        }
    };
}

/// 20b positive-edge-triggered D register, qualified storage, tri-state
pub fn x16721(comptime options: Options, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = options.base(if (bus_hold) "H16721" else "16721"),

        d: [20]Net_ID = @splat(.unset),
        q: [20]Net_ID = @splat(.unset),
        clk: Net_ID = .unset,
        n_ce: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Multi(4, 8, options.pwr, options.Decoupler) = .{},
        remap: [20]u5 = .{ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 },

        pub fn check_config(self: @This()) !void {
            var mapped_bits: [20]bool = @splat(false);
            for (self.remap) |logical| {
                mapped_bits[logical] = true;
            }
            for (0.., mapped_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.n_oe,
                56 => self.clk,
                29 => self.n_ce,

                55 => self.d[self.remap[0]],
                54 => self.d[self.remap[1]],
                52 => self.d[self.remap[2]],
                51 => self.d[self.remap[3]],
                49 => self.d[self.remap[4]],
                48 => self.d[self.remap[5]],
                47 => self.d[self.remap[6]],
                45 => self.d[self.remap[7]],
                44 => self.d[self.remap[8]],
                43 => self.d[self.remap[9]],
                42 => self.d[self.remap[10]],
                41 => self.d[self.remap[11]],
                40 => self.d[self.remap[12]],
                38 => self.d[self.remap[13]],
                37 => self.d[self.remap[14]],
                36 => self.d[self.remap[15]],
                34 => self.d[self.remap[16]],
                33 => self.d[self.remap[17]],
                31 => self.d[self.remap[18]],
                30 => self.d[self.remap[19]],

                2 => self.q[self.remap[0]],
                3 => self.q[self.remap[1]],
                5 => self.q[self.remap[2]],
                6 => self.q[self.remap[3]],
                8 => self.q[self.remap[4]],
                9 => self.q[self.remap[5]],
                10 => self.q[self.remap[6]],
                12 => self.q[self.remap[7]],
                13 => self.q[self.remap[8]],
                14 => self.q[self.remap[9]],
                15 => self.q[self.remap[10]],
                16 => self.q[self.remap[11]],
                17 => self.q[self.remap[12]],
                19 => self.q[self.remap[13]],
                20 => self.q[self.remap[14]],
                21 => self.q[self.remap[15]],
                23 => self.q[self.remap[16]],
                24 => self.q[self.remap[17]],
                26 => self.q[self.remap[18]],
                27 => self.q[self.remap[19]],

                4 => self.pwr.gnd[0],
                11 => self.pwr.gnd[1],
                18 => self.pwr.gnd[2],
                25 => self.pwr.gnd[3],
                32 => self.pwr.gnd[4],
                39 => self.pwr.gnd[5],
                46 => self.pwr.gnd[6],
                53 => self.pwr.gnd[7],

                7 => @field(self.pwr, @tagName(options.pwr))[0],
                22 => @field(self.pwr, @tagName(options.pwr))[1],
                35 => @field(self.pwr, @tagName(options.pwr))[2],
                50 => @field(self.pwr, @tagName(options.pwr))[3],

                28 => .no_connect,

                else => unreachable,
            };
        }

        const Validate_State = struct {
            data: u20,
            bus_hold: if (bus_hold) u20 else void,
            clk: bool,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.clk = true;
                    state.data = 0xAAAAA;
                    if (bus_hold) {
                        state.bus_hold = 0xAAAAA;
                    }
                },
                .commit => {
                    if (bus_hold) {
                        try v.expect_valid_or_unconnected(self.d, options.levels);
                    } else {
                        try v.expect_valid(self.d, options.levels);
                    }
                    try v.expect_valid(self.clk, options.levels);
                    try v.expect_valid(self.n_ce, options.levels);
                    try v.expect_valid(self.n_oe, options.levels);
                    if (v.read_logic(self.n_oe, options.levels) == false) {
                        try v.expect_output_valid(self.q, state.data, options.levels);
                    }

                    const new_clk = v.read_logic(self.clk, options.levels);
                    if (new_clk and !state.clk and v.read_logic(self.n_ce, options.levels) == false) {
                        state.data = self.read_d(v, state);
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    if (v.read_logic(self.n_oe, options.levels) == false) {
                        try v.drive_bus(self.q, state.data, options.levels);
                    }
                    
                    if (bus_hold) {
                        state.bus_hold = self.read_d(v, state);
                    }
                },
            }
        }

        fn read_d(self: @This(), v: *Validator, state: *Validate_State) u20 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.d, options.levels, state.bus_hold));
            } else {
                return @truncate(v.read_bus(self.d, options.levels));
            }
        }
    };
}

const log = std.log.scoped(.zoink);

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Voltage = enums.Voltage;
const enums = @import("../enums.zig");
const parts = @import("../parts.zig");
const power = @import("../power.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
const std = @import("std");
