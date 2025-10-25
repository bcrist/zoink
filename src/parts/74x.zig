fn Quad_Gate(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, func: *const fn(a: usize, b: usize) usize) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: power.Single(pwr, Decoupler) = .{},
        logic: union (enum) {
            bus: Quad_Gate2_Impl,
            gates: [4]Gate2_Impl,
        } = .{ .bus = .{} },
        remap: [4]u2 = .{ 0, 1, 2, 3 },

        const Quad_Gate2_Impl = struct {
            a: [4]Net_ID = @splat(.unset),
            b: [4]Net_ID = @splat(.unset),
            y: [4]Net_ID = @splat(.unset),
        };

        const Gate2_Impl = struct {
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
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(pwr)),

                    1 => impl.a[self.remap[0]],
                    2 => impl.b[self.remap[0]],
                    3 => impl.y[self.remap[0]],

                    4 => impl.a[self.remap[1]],
                    5 => impl.b[self.remap[1]],
                    6 => impl.y[self.remap[1]],

                    10 => impl.a[self.remap[2]],
                    9 => impl.b[self.remap[2]],
                    8 => impl.y[self.remap[2]],

                    13 => impl.a[self.remap[3]],
                    12 => impl.b[self.remap[3]],
                    11 => impl.y[self.remap[3]],

                    else => unreachable,
                },
                .gates => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(pwr)),

                    1 => impl[self.remap[0]].a,
                    2 => impl[self.remap[0]].b,
                    3 => impl[self.remap[0]].y,

                    4 => impl[self.remap[1]].a,
                    5 => impl[self.remap[1]].b,
                    6 => impl[self.remap[1]].y,

                    10 => impl[self.remap[2]].a,
                    9 => impl[self.remap[2]].b,
                    8 => impl[self.remap[2]].y,

                    13 => impl[self.remap[3]].a,
                    12 => impl[self.remap[3]].b,
                    11 => impl[self.remap[3]].y,

                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => switch (self.logic) {
                    .bus => |impl| {
                        try v.expect_valid(impl.a, levels);
                        try v.expect_valid(impl.b, levels);
                        const a = v.read_bus(impl.a, levels);
                        const b = v.read_bus(impl.b, levels);
                        try v.expect_output_valid(impl.y, func(a, b), levels);
                    },
                    .gates => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, levels);
                        try v.expect_valid(gate.b, levels);
                        const a = @intFromBool(v.read_logic(gate.a, levels));
                        const b = @intFromBool(v.read_logic(gate.b, levels));
                        try v.expect_output_valid(gate.y, func(a, b) != 0, levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        const a = v.read_bus(impl.a, levels);
                        const b = v.read_bus(impl.b, levels);
                        try v.drive_bus(impl.y, func(a, b), levels);
                    },
                    .gates => |impl| for (impl) |gate| {
                        const a = @intFromBool(v.read_logic(gate.a, levels));
                        const b = @intFromBool(v.read_logic(gate.b, levels));
                        try v.drive_logic(gate.y, func(a, b) != 0, levels);
                    },
                },
            }
        }

    };
}

fn Hex_Buf(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, invert: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: power.Single(pwr, Decoupler) = .{},
        logic: union (enum) {
            bus: Hex_Buf_Impl,
            gates: [6]Buf_Impl,
        } = .{ .bus = .{} },
        remap: [6]u3 = .{ 0, 1, 2, 3, 4, 5 },

        const Hex_Buf_Impl = struct {
            a: [6]Net_ID = @splat(.unset),
            y: [6]Net_ID = @splat(.unset),
        };

        const Buf_Impl = struct {
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
                    14 => @field(self.pwr, @tagName(pwr)),

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
                .gates => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(pwr)),

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
                        try v.expect_valid(impl.a, levels);
                        var a = v.read_bus(impl.a, levels);
                        if (invert) a = ~a;
                        try v.expect_output_valid(impl.y, a, levels);
                    },
                    .gates => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, levels);
                        const a = @intFromBool(v.read_logic(gate.a, levels));
                        if (invert) a = !a;
                        try v.expect_output_valid(gate.y, a, levels);
                    },
                },
                .nets_only => switch (self.logic) {
                    .bus => |impl| {
                        var a = v.read_bus(impl.a, levels);
                        if (invert) a = ~a;
                        try v.drive_bus(impl.y, a, levels);
                    },
                    .gates => |impl| for (impl) |gate| {
                        const a = @intFromBool(v.read_logic(gate.a, levels));
                        if (invert) a = !a;
                        try v.drive_logic(gate.y, a, levels);
                    },
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

/// Quad 2-in NAND
pub fn x00(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, nand_gate);
}

/// Quad 2-in NOR
pub fn x02(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, nor_gate);
}

/// Hex inverter
pub fn x04(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Hex_Buf(pwr, Decoupler, levels, Pkg, true);
}

/// Quad 2-in AND
pub fn x08(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, and_gate);
}

/// Hex inverter, ST inputs
pub fn x14(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Hex_Buf(pwr, Decoupler, levels, Pkg, true);
}

/// Quad 2-in OR
pub fn x32(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, or_gate);
}

/// Hex buffer
pub fn x34(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Hex_Buf(pwr, Decoupler, levels, Pkg, false);
}

/// Quad 2-in XOR
pub fn x86(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, xor_gate);
}

// 3:8 decoder/demux
pub fn x138(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: power.Single(pwr, Decoupler) = .{},
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
                16 => @field(self.pwr, @tagName(pwr)),
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.sel, levels);
                    try v.expect_valid(self.enable, levels);
                    try v.expect_valid(self.n_enable, levels);
                    var out: u8 = 0;
                    if (v.read_logic(self.enable, levels) and v.read_bus(self.n_enable, levels) == 0) {
                        const index: u3 = @truncate(v.read_bus(self.sel, levels));
                        out = @as(u8, 1) << index;
                    }
                    try v.expect_output_valid(self.y, ~out, levels);
                },
                .nets_only => {
                    var out: u8 = 0;
                    if (v.read_logic(self.enable, levels) and v.read_bus(self.n_enable, levels) == 0) {
                        const index: u3 = @truncate(v.read_bus(self.sel, levels));
                        out = @as(u8, 1) << index;
                    }
                    try v.drive_bus(self.y, ~out, levels);
                },
            }
        }

    };
}

// Dual 2:4 decoder/demux
pub fn x139(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u: [2]Unit = @splat(.{}),
        pwr: power.Single(pwr, Decoupler) = .{},
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
                16 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(unit.n_enable, levels);
                    try v.expect_valid(unit.sel, levels);
                    var out: u4 = 0;
                    if (!v.read_logic(unit.n_enable, levels)) {
                        const index: u2 = @truncate(v.read_bus(unit.sel, levels));
                        out = @as(u4, 1) << index;
                    }
                    try v.expect_output_valid(unit.y, ~out, levels);
                },
                .nets_only => for (self.u) |unit| {
                    var out: u4 = 0;
                    if (!v.read_logic(unit.n_enable, levels)) {
                        const index: u2 = @truncate(v.read_bus(unit.sel, levels));
                        out = @as(u4, 1) << index;
                    }
                    try v.drive_bus(unit.y, ~out, levels);
                },
            }
        }
    };
}

// TODO x161, x163

fn Dual_4b_Tristate_Buffer(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime invert_outputs: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u: [2]Unit = @splat(.{}),
        pwr: power.Single(pwr, Decoupler) = .{},
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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(unit.a, levels);
                    try v.expect_valid(unit.n_oe, levels);
                    if (v.read_logic(unit.n_oe, levels) == false) {
                        var data = v.read_bus(unit.a, levels);
                        if (invert_outputs) {
                            data = ~data;
                        }
                        try v.expect_output_valid(unit.y, data, levels);
                    }
                },
                .nets_only => for (self.u) |unit| {
                    if (v.read_logic(unit.n_oe, levels) == false) {
                        var data = v.read_bus(unit.a, levels);
                        if (invert_outputs) {
                            data = ~data;
                        }
                        try v.drive_bus(unit.y, data, levels);
                    }
                },
            }
        }
    };
}

/// Dual 4b inverter, tri-state
pub fn x240(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Dual_4b_Tristate_Buffer(pwr, Decoupler, levels, Pkg, .{ true, true });
}

/// Dual 4b buffer, tri-state (one active low and one active high OE)
pub fn x241(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u0: Unit_Active_Low_OE = .{},
        u1: Unit_Active_High_OE = .{},
        pwr: power.Single(pwr, Decoupler) = .{},

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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(self.u0.a, levels);
                    try v.expect_valid(self.u0.n_oe, levels);
                    try v.expect_valid(self.u1.a, levels);
                    try v.expect_valid(self.u1.oe, levels);
                    if (v.read_logic(self.u0.n_oe, levels) == false) {
                        const data = v.read_bus(self.u0.a, levels);
                        try v.expect_output_valid(self.u0.y, data, levels);
                    }
                    if (v.read_logic(self.u1.oe, levels) == true) {
                        const data = v.read_bus(self.u1.a, levels);
                        try v.expect_output_valid(self.u1.y, data, levels);
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.u0.n_oe, levels) == false) {
                        const data = v.read_bus(self.u0.a, levels);
                        try v.drive_bus(self.u0.y, data, levels);
                    }
                    if (v.read_logic(self.u1.oe, levels) == true) {
                        const data = v.read_bus(self.u1.a, levels);
                        try v.drive_bus(self.u1.y, data, levels);
                    }
                },
            }
        }
    };
}

/// Dual 4b buffer, tri-state
pub fn x244(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Dual_4b_Tristate_Buffer(pwr, Decoupler, levels, Pkg, .{ false, false });
}

/// 8b bus transceiver
pub fn x245(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        a: [8]Net_ID = @splat(.unset),
        b: [8]Net_ID = @splat(.unset),
        n_oe: Net_ID = .unset,
        a_to_b: Net_ID = .unset, // B to A when low
        pwr: power.Single(pwr, Decoupler) = .{},
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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(self.n_oe, levels);
                    try v.expect_valid(self.a_to_b, levels);
                    if (v.read_logic(self.a_to_b, levels)) {
                        try v.expect_valid(self.a, levels);
                        if (v.read_logic(self.n_oe, levels) == false) {
                            const data = v.read_bus(self.a, levels);
                            try v.expect_output_valid(self.b, data, levels);
                        }
                    } else {
                        try v.expect_valid(self.b, levels);
                        if (v.read_logic(self.n_oe, levels) == false) {
                            const data = v.read_bus(self.b, levels);
                            try v.expect_output_valid(self.a, data, levels);
                        }
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.n_oe, levels) == false) {
                        if (v.read_logic(self.a_to_b, levels)) {
                            const data = v.read_bus(self.a, levels);
                            try v.drive_bus(self.b, data, levels);
                        } else {
                            const data = v.read_bus(self.b, levels);
                            try v.drive_bus(self.a, data, levels);
                        }
                    }
                },
            }
        }
    };
}

/// 8b buffer, tri-state (dual OE)
pub fn x541(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        a: [8]Net_ID = @splat(.unset),
        y: [8]Net_ID = @splat(.unset),
        n_oe: [2]Net_ID = @splat(.unset),
        pwr: power.Single(pwr, Decoupler) = .{},
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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(self.a, levels);
                    try v.expect_valid(self.n_oe, levels);
                    const oe = v.read_bus(self.n_oe, levels);
                    if (oe == 0) {
                        const a = v.read_bus(self.a, levels);
                        try v.expect_output_valid(self.y, a, levels);
                    }
                },
                .nets_only => {
                    const oe = v.read_bus(self.n_oe, levels);
                    if (oe == 0) {
                        const a = v.read_bus(self.a, levels);
                        try v.drive_bus(self.y, a, levels);
                    }
                },
            }
        }
    };
}

/// 8b transparent latch, tri-state
pub fn x573(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        d: [8]Net_ID = @splat(.unset),
        q: [8]Net_ID = @splat(.unset),
        transparent: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Single(pwr, Decoupler) = .{},
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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(self.d, levels);
                    try v.expect_valid(self.transparent, levels);
                    try v.expect_valid(self.n_oe, levels);
                    const le = v.read_logic(self.transparent, levels);
                    if (le == true) {
                        state.data = @truncate(v.read_bus(self.d, levels));
                    }
                    const oe = v.read_logic(self.n_oe, levels);
                    if (oe == false) {
                        try v.expect_output_valid(self.q, state.data, levels);
                    }
                },
                .nets_only => {
                    const oe = v.read_logic(self.n_oe, levels);
                    if (oe == false) {
                        const le = v.read_logic(self.transparent, levels);
                        const data = if (le == true) v.read_bus(self.d, levels) else state.data;
                        try v.drive_bus(self.q, data, levels);
                    }
                },
            }
        }
    };
}

/// 8b positive-edge-triggered D register, tri-state
pub fn x574(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        d: [8]Net_ID = @splat(.unset),
        q: [8]Net_ID = @splat(.unset),
        clk: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Single(pwr, Decoupler) = .{},
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
                20 => @field(self.pwr, @tagName(pwr)),

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
                    try v.expect_valid(self.d, levels);
                    try v.expect_valid(self.clk, levels);
                    try v.expect_valid(self.n_oe, levels);
                    const oe = v.read_logic(self.n_oe, levels);
                    if (oe == false) {
                        try v.expect_output_valid(self.q, state.data, levels);
                    }
                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk) {
                        state.data = @truncate(v.read_bus(self.d, levels));
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    const oe = v.read_logic(self.n_oe, levels);
                    if (oe == false) {
                        try v.drive_bus(self.q, state.data, levels);
                    }
                },
            }
        }
    };
}

/// 4x 4b buffer, tri-state
pub fn x16244(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u: [4]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},
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

                7 => @field(self.pwr, @tagName(pwr))[0],
                18 => @field(self.pwr, @tagName(pwr))[1],
                31 => @field(self.pwr, @tagName(pwr))[2],
                42 => @field(self.pwr, @tagName(pwr))[3],

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
                        try v.expect_valid_or_unconnected(unit.a, levels);
                    } else {
                        try v.expect_valid(unit.a, levels);
                    }
                    try v.expect_valid(unit.n_oe, levels);
                    if (v.read_logic(unit.n_oe, levels) == false) {
                        const data = read_a(unit, v, unit_state);
                        try v.expect_output_valid(unit.y, data, levels);
                    }
                },
                .nets_only => {
                    if (bus_hold) {
                        for (self.u, state) |unit, *unit_state| {
                            unit_state.bus_hold = @truncate(try v.pull_and_read_bus(unit.a, levels, unit_state.bus_hold));
                        }
                    }
                    for (self.u, state) |unit, *unit_state| {
                        if (v.read_logic(unit.n_oe, levels) == false) {
                            const data = read_a(unit, v, unit_state);
                            try v.drive_bus(unit.y, data, levels);
                        }
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State) u16 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, levels, state.bus_hold));
            } else {
                return @truncate(v.read_bus(unit.a, levels));
            }
        }
    };
}

/// 4x 4b buffer, tri-state
pub fn x16245(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u: [2]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},
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

                7 => @field(self.pwr, @tagName(pwr))[0],
                18 => @field(self.pwr, @tagName(pwr))[1],
                31 => @field(self.pwr, @tagName(pwr))[2],
                42 => @field(self.pwr, @tagName(pwr))[3],

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
                    try v.expect_valid(unit.n_oe, levels);
                    try v.expect_valid(unit.a_to_b, levels);
                    if (v.read_logic(unit.a_to_b, levels)) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.a, levels) else try v.expect_valid(unit.a, levels);
                    } else {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.b, levels) else try v.expect_valid(unit.b, levels);
                    }
                    if (v.read_logic(unit.n_oe, levels) == false) {
                        if (v.read_logic(unit.a_to_b, levels)) {
                            const data = read_a(unit, v, unit_state);
                            try v.expect_output_valid(unit.b, data, levels);
                        } else {
                            const data = read_b(unit, v, unit_state);
                            try v.expect_output_valid(unit.a, data, levels);
                        }
                    }
                },
                .nets_only => for (self.u, state) |unit, *unit_state| {
                    if (bus_hold) {
                        unit_state.a_hold = @truncate(try v.pull_and_read_bus(unit.a, levels, unit_state.a_hold));
                        unit_state.b_hold = @truncate(try v.pull_and_read_bus(unit.b, levels, unit_state.b_hold));
                    }
                    if (v.read_logic(unit.n_oe, levels) == false) {
                        if (v.read_logic(unit.a_to_b, levels)) {
                            try v.drive_bus(unit.b, read_a(unit, v, unit_state), levels);
                        } else {
                            try v.drive_bus(unit.a, read_b(unit, v, unit_state), levels);
                        }
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State) u8 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(unit.a, levels));
            }
        }

        fn read_b(unit: Unit, v: *Validator, state: *Validate_State) u8 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.b, levels, state.b_hold));
            } else {
                return @truncate(v.read_bus(unit.b, levels));
            }
        }
    };
}

/// 2x12b bus exchange switch
pub fn CBT16212(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: power.Multi(1, 4, pwr, Decoupler) = .{},
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

        fn logical_l_net(self: @This(), bus: u1, physical_bit: usize) usize {
            return self.left[bus][self.remap[physical_bit]];
        }

        fn logical_r_net(self: @This(), bus: u1, physical_bit: usize) usize {
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
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

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

                17 => @field(self.pwr, @tagName(pwr))[0],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.op_sel, levels);
                    try v.expect_below(self.left[0], levels.Vclamp);
                    try v.expect_below(self.left[1], levels.Vclamp);
                    try v.expect_below(self.right[0], levels.Vclamp);
                    try v.expect_below(self.right[1], levels.Vclamp);

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
            return @enumFromInt(v.read_bus(self.op_sel, levels));
        }
    };
}

/// 12x 2:1 mux/demux, latched, tri-state
pub fn x16260(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        a: Port_A = .{},
        bx: Port_B = .{},
        by: Port_B = .{},
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},
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

                7 => @field(self.pwr, @tagName(pwr))[0],
                22 => @field(self.pwr, @tagName(pwr))[1],
                35 => @field(self.pwr, @tagName(pwr))[2],
                50 => @field(self.pwr, @tagName(pwr))[3],

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
                        try v.expect_valid_or_unconnected(self.a.data, levels);
                        try v.expect_valid_or_unconnected(self.bx.data, levels);
                        try v.expect_valid_or_unconnected(self.by.data, levels);
                    } else {
                        try v.expect_valid(self.a.data, levels);
                        try v.expect_valid(self.bx.data, levels);
                        try v.expect_valid(self.by.data, levels);
                    }

                    try v.expect_valid(self.a.n_oe, levels);
                    try v.expect_valid(self.a.enable_bx, levels);
                    try v.expect_valid(self.bx.n_oe, levels);
                    try v.expect_valid(self.by.n_oe, levels);

                    try v.expect_valid(self.bx.latch_input_data, levels);
                    try v.expect_valid(self.by.latch_input_data, levels);
                    try v.expect_valid(self.bx.latch_output_data, levels);
                    try v.expect_valid(self.by.latch_output_data, levels);

                    if (v.read_logic(self.bx.latch_input_data, levels)) state.bx_to_a = self.read_bx(v, state);
                    if (v.read_logic(self.bx.latch_output_data, levels)) state.a_to_bx = self.read_a(v, state);

                    if (v.read_logic(self.by.latch_input_data, levels)) state.by_to_a = self.read_by(v, state);
                    if (v.read_logic(self.by.latch_output_data, levels)) state.a_to_by = self.read_a(v, state);

                    if (v.read_logic(self.a.n_oe, levels) == false) {
                        const data = switch (v.read_logic(self.a.enable_bx, levels)) {
                            true => if (v.read_logic(self.bx.latch_input_data, levels)) self.read_bx(v, state) else state.bx_to_a,
                            false => if (v.read_logic(self.by.latch_input_data, levels)) self.read_by(v, state) else state.by_to_a,
                        };
                        try v.expect_output_valid(self.a.data, data, levels);
                    }

                    if (v.read_logic(self.bx.n_oe, levels) == false) {
                        const data = if (v.read_logic(self.bx.latch_output_data, levels)) self.read_a(v, state) else state.a_to_bx;
                        try v.expect_output_valid(self.bx.data, data, levels);
                    }

                    if (v.read_logic(self.by.n_oe, levels) == false) {
                        const data = if (v.read_logic(self.by.latch_output_data, levels)) self.read_a(v, state) else state.a_to_by;
                        try v.expect_output_valid(self.by.data, data, levels);
                    }
                },
                .nets_only => {
                    if (bus_hold) {
                        state.a_hold = @truncate(try v.pull_and_read_bus(self.a.data, levels, state.a_hold));
                        state.bx_hold = @truncate(try v.pull_and_read_bus(self.bx.data, levels, state.bx_hold));
                        state.by_hold = @truncate(try v.pull_and_read_bus(self.by.data, levels, state.by_hold));
                    }

                    if (v.read_logic(self.a.n_oe, levels) == false) {
                        const data = switch (v.read_logic(self.a.enable_bx, levels)) {
                            true => if (v.read_logic(self.bx.latch_input_data, levels)) self.read_bx(v, state) else state.bx_to_a,
                            false => if (v.read_logic(self.by.latch_input_data, levels)) self.read_by(v, state) else state.by_to_a,
                        };
                        try v.drive_bus(self.a.data, data, levels);
                    }

                    if (v.read_logic(self.bx.n_oe, levels) == false) {
                        const data = if (v.read_logic(self.bx.latch_output_data, levels)) self.read_a(v, state) else state.a_to_bx;
                        try v.drive_bus(self.bx.data, data, levels);
                    }

                    if (v.read_logic(self.by.n_oe, levels) == false) {
                        const data = if (v.read_logic(self.by.latch_output_data, levels)) self.read_a(v, state) else state.a_to_by;
                        try v.drive_bus(self.by.data, data, levels);
                    }
                },
            }
        }

        fn read_a(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.a.data, levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(self.a.data, levels));
            }
        }

        fn read_bx(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.bx.data, levels, state.bx_hold));
            } else {
                return @truncate(v.read_bus(self.bx.data, levels));
            }
        }

        fn read_by(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.by.data, levels, state.by_hold));
            } else {
                return @truncate(v.read_bus(self.by.data, levels));
            }
        }
    };
}

/// 2x 8b bus transceiver and bidirectional positive-edge-triggered register, tri-state
pub fn x16652(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        u: [2]Unit = @splat(.{}),
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},
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

                7 => @field(self.pwr, @tagName(pwr))[0],
                22 => @field(self.pwr, @tagName(pwr))[1],
                35 => @field(self.pwr, @tagName(pwr))[2],
                50 => @field(self.pwr, @tagName(pwr))[3],

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
                    try v.expect_valid(unit.a_to_b.oe, levels);
                    try v.expect_valid(unit.b_to_a.n_oe, levels);

                    try v.expect_valid(unit.a_to_b.output_register, levels);
                    try v.expect_valid(unit.b_to_a.output_register, levels);

                    try v.expect_valid(unit.a_to_b.clk, levels);
                    try v.expect_valid(unit.b_to_a.clk, levels);

                    if (v.read_logic(unit.b_to_a.n_oe, levels) == true) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.a, levels) else try v.expect_valid(unit.a, levels);
                    }
                    if (v.read_logic(unit.a_to_b.oe, levels) == false) {
                        if (bus_hold) try v.expect_valid_or_unconnected(unit.b, levels) else try v.expect_valid(unit.b, levels);
                    }

                    {
                        const new_a_to_b_clk = v.read_logic(unit.a_to_b.clk, levels);
                        if (new_a_to_b_clk and !unit_state.a_to_b_clk) {
                            unit_state.a_to_b = read_a(unit, v, unit_state, 2);
                        }
                        unit_state.a_to_b_clk = new_a_to_b_clk;
                    }
                    {
                        const new_b_to_a_clk = v.read_logic(unit.b_to_a.clk, levels);
                        if (new_b_to_a_clk and !unit_state.b_to_a_clk) {
                            unit_state.b_to_a = read_b(unit, v, unit_state, 2);
                        }
                        unit_state.b_to_a_clk = new_b_to_a_clk;
                    }
                },
                .nets_only => for (self.u, state) |unit, *unit_state| {
                    if (bus_hold) {
                        unit_state.a_hold = @truncate(try v.pull_and_read_bus(unit.a, levels, unit_state.a_hold));
                        unit_state.b_hold = @truncate(try v.pull_and_read_bus(unit.b, levels, unit_state.b_hold));
                    }

                    if (v.read_logic(unit.b_to_a.n_oe, levels) == false) {
                        const data = read_a(unit, v, unit_state, 2);
                        try v.drive_bus(unit.a, data, levels);
                        if (bus_hold) unit_state.a_hold = data;
                    }
                    if (v.read_logic(unit.a_to_b.oe, levels) == true) {
                        const data = read_b(unit, v, unit_state, 2);
                        try v.drive_bus(unit.b, data, levels);
                        if (bus_hold) unit_state.b_hold = data;
                    }
                },
            }
        }

        fn read_a(unit: Unit, v: *Validator, state: *Validate_State, limit: usize) u8 {
            if (limit > 0 and v.read_logic(unit.b_to_a.n_oe, levels) == false) {
                if (v.read_logic(unit.b_to_a.output_register, levels)) {
                    return state.b_to_a;
                } else {
                    return read_b(unit, v, state, limit - 1);
                }
            } else if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.a, levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(unit.a, levels));
            }
        }

        fn read_b(unit: Unit, v: *Validator, state: *Validate_State, limit: usize) u8 {
            if (limit > 0 and v.read_logic(unit.a_to_b.oe, levels) == true) {
                if (v.read_logic(unit.a_to_b.output_register, levels)) {
                    return state.a_to_b;
                } else {
                    return read_a(unit, v, state, limit - 1);
                }
            } else if (bus_hold) {
                return @truncate(v.read_bus_with_pull(unit.b, levels, state.b_hold));
            } else {
                return @truncate(v.read_bus(unit.b, levels));
            }
        }
    };
}

/// 20b positive-edge-triggered D register, qualified storage, tri-state
pub fn x16721(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type, comptime bus_hold: bool) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        d: [20]Net_ID = @splat(.unset),
        q: [20]Net_ID = @splat(.unset),
        clk: Net_ID = .unset,
        n_ce: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},
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

                7 => @field(self.pwr, @tagName(pwr))[0],
                22 => @field(self.pwr, @tagName(pwr))[1],
                35 => @field(self.pwr, @tagName(pwr))[2],
                50 => @field(self.pwr, @tagName(pwr))[3],

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
                        try v.expect_valid_or_unconnected(self.d, levels);
                    } else {
                        try v.expect_valid(self.d, levels);
                    }
                    try v.expect_valid(self.clk, levels);
                    try v.expect_valid(self.n_ce, levels);
                    try v.expect_valid(self.n_oe, levels);
                    if (v.read_logic(self.n_oe, levels) == false) {
                        try v.expect_output_valid(self.q, state.data, levels);
                    }

                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk and v.read_logic(self.n_ce, levels) == false) {
                        state.data = self.read_d(v, state);
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    if (v.read_logic(self.n_oe, levels) == false) {
                        try v.drive_bus(self.q, state.data, levels);
                    }
                    
                    if (bus_hold) {
                        state.bus_hold = self.read_d(v, state);
                    }
                },
            }
        }

        fn read_d(self: @This(), v: *Validator, state: *Validate_State) u20 {
            if (bus_hold) {
                return @truncate(v.read_bus_with_pull(self.d, levels, state.bus_hold));
            } else {
                return @truncate(v.read_bus(self.d, levels));
            }
        }
    };
}

const log = std.log.scoped(.zoink);

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
const std = @import("std");
