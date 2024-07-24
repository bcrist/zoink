const Quad_Gate2_Impl = struct {
    a: [4]Net_ID = .{ .unset } ** 4,
    b: [4]Net_ID = .{ .unset } ** 4,
    y: [4]Net_ID = .{ .unset } ** 4,
};

pub const Gate2_Impl = struct {
    a: Net_ID = .unset,
    b: Net_ID = .unset,
    y: Net_ID = .unset,
};

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

        fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (self.logic) {
                .bus => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(pwr)),

                    1 => impl.a[0],
                    2 => impl.b[0],
                    3 => impl.y[0],

                    4 => impl.a[1],
                    5 => impl.b[1],
                    6 => impl.y[1],

                    10 => impl.a[2],
                    9 => impl.b[2],
                    8 => impl.y[2],

                    13 => impl.a[3],
                    12 => impl.b[3],
                    11 => impl.y[3],

                    else => unreachable,
                },
                .gates => |impl| switch (@intFromEnum(pin_id)) {
                    0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                    7 => self.pwr.gnd,
                    14 => @field(self.pwr, @tagName(pwr)),

                    1 => impl[0].a,
                    2 => impl[0].b,
                    3 => impl[0].y,

                    4 => impl[1].a,
                    5 => impl[1].b,
                    6 => impl[1].y,

                    10 => impl[2].a,
                    9 => impl[2].b,
                    8 => impl[2].y,

                    13 => impl[3].a,
                    12 => impl[3].b,
                    11 => impl[3].y,

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
                    },
                    .gates => |impl| for (impl) |gate| {
                        try v.expect_valid(gate.a, levels);
                        try v.expect_valid(gate.b, levels);
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

/// Quad 2-in AND
pub fn x08(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, and_gate);
}

/// Quad 2-in OR
pub fn x32(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, or_gate);
}

/// Quad 2-in XOR
pub fn x86(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return Quad_Gate(pwr, Decoupler, levels, Pkg, xor_gate);
}

/// 8b buffer, tri-state (dual OE)
pub fn x541(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        a: [8]Net_ID = .{ .unset } ** 8,
        y: [8]Net_ID = .{ .unset } ** 8,
        output_enable_low: [2]Net_ID = .{ .unset } ** 2,
        pwr: power.Single(pwr, Decoupler) = .{},

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.output_enable_low[0],
                19 => self.output_enable_low[1],

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(pwr)),

                2 => self.a[0],
                3 => self.a[1],
                4 => self.a[2],
                5 => self.a[3],
                6 => self.a[4],
                7 => self.a[5],
                8 => self.a[6],
                9 => self.a[7],

                18 => self.y[0],
                17 => self.y[1],
                16 => self.y[2],
                15 => self.y[3],
                14 => self.y[4],
                13 => self.y[5],
                12 => self.y[6],
                11 => self.y[7],

                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_valid(self.a, levels);
                    try v.expect_valid(self.output_enable_low, levels);
                },
                .nets_only => {
                    const oe = v.read_bus(self.output_enable_low, levels);
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

        d: [8]Net_ID = .{ .unset } ** 8,
        q: [8]Net_ID = .{ .unset } ** 8,
        transparent: Net_ID = .unset,
        output_enable_low: Net_ID = .unset,
        pwr: power.Single(pwr, Decoupler) = .{},

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.output_enable_low,
                11 => self.transparent,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(pwr)),

                2 => self.d[0],
                3 => self.d[1],
                4 => self.d[2],
                5 => self.d[3],
                6 => self.d[4],
                7 => self.d[5],
                8 => self.d[6],
                9 => self.d[7],

                19 => self.q[0],
                18 => self.q[1],
                17 => self.q[2],
                16 => self.q[3],
                15 => self.q[4],
                14 => self.q[5],
                13 => self.q[6],
                12 => self.q[7],

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
                    try v.expect_valid(self.output_enable_low, levels);
                    const le = v.read_logic(self.transparent, levels);
                    if (le == true) {
                        state.data = @truncate(v.read_bus(self.d, levels));
                    }
                },
                .nets_only => {
                    const oe = v.read_logic(self.output_enable_low, levels);
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

        d: [8]Net_ID = .{ .unset } ** 8,
        q: [8]Net_ID = .{ .unset } ** 8,
        clk: Net_ID = .unset,
        output_enable_low: Net_ID = .unset,
        pwr: power.Single(pwr, Decoupler) = .{},

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.output_enable_low,
                11 => self.clk,

                10 => self.pwr.gnd,
                20 => @field(self.pwr, @tagName(pwr)),

                2 => self.d[0],
                3 => self.d[1],
                4 => self.d[2],
                5 => self.d[3],
                6 => self.d[4],
                7 => self.d[5],
                8 => self.d[6],
                9 => self.d[7],

                19 => self.q[0],
                18 => self.q[1],
                17 => self.q[2],
                16 => self.q[3],
                15 => self.q[4],
                14 => self.q[5],
                13 => self.q[6],
                12 => self.q[7],

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
                    try v.expect_valid(self.output_enable_low, levels);
                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk) {
                        state.data = @truncate(v.read_bus(self.d, levels));
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    const oe = v.read_logic(self.output_enable_low, levels);
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

        u: [4]Unit = .{ .{} } ** 4,
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},

        pub const Unit = struct {
            a: [4]Net_ID = .{ .unset } ** 4,
            y: [4]Net_ID = .{ .unset } ** 4,
            output_enable_low: Net_ID = .unset,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.u[0].output_enable_low,
                48 => self.u[1].output_enable_low,
                25 => self.u[2].output_enable_low,
                24 => self.u[3].output_enable_low,

                47 => self.u[0].a[0],
                46 => self.u[0].a[1],
                44 => self.u[0].a[2],
                43 => self.u[0].a[3],

                41 => self.u[1].a[0],
                40 => self.u[1].a[1],
                38 => self.u[1].a[2],
                37 => self.u[1].a[3],

                36 => self.u[2].a[0],
                35 => self.u[2].a[1],
                33 => self.u[2].a[2],
                32 => self.u[2].a[3],

                30 => self.u[3].a[0],
                29 => self.u[3].a[1],
                27 => self.u[3].a[2],
                26 => self.u[3].a[3],

                2 => self.u[0].y[0],
                3 => self.u[0].y[1],
                5 => self.u[0].y[2],
                6 => self.u[0].y[3],

                8 => self.u[1].y[0],
                9 => self.u[1].y[1],
                11 => self.u[1].y[2],
                12 => self.u[1].y[3],

                13 => self.u[2].y[0],
                14 => self.u[2].y[1],
                16 => self.u[2].y[2],
                17 => self.u[2].y[3],

                19 => self.u[3].y[0],
                20 => self.u[3].y[1],
                22 => self.u[3].y[2],
                23 => self.u[3].y[3],

                
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
            bus_hold: u16,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => for (self.u) |unit| {
                    if (bus_hold) {
                        try v.expect_valid_or_nc(unit.a, levels);
                    } else {
                        try v.expect_valid(unit.a, levels);
                    }
                    try v.expect_valid(unit.output_enable_low, levels);
                },
                .nets_only => {
                    for (self.u) |unit| {
                        if (v.read_logic(unit.output_enable_low, levels) == false) {
                            const data = v.read_bus(unit.a, levels);
                            try v.drive_bus(unit.y, data, levels);
                        }
                    }

                    if (bus_hold) {
                        const a = self.u[0].a ++ self.u[1].a ++ self.u[2].a ++ self.u[3].a;
                        try v.drive_bus_weak(a, state.bus_hold, levels);
                        state.bus_hold = @truncate(v.read_bus_fallback(a, levels, state.bus_hold));
                    }
                },
            }
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

        pub const Port_A = struct {
            data: [12]Net_ID = .{ .unset } ** 12,
            output_enable_low: Net_ID = .unset,
            enable_bx: Net_ID = .unset, // when low, output comes from by instead
        };

        pub const Port_B = struct {
            data: [12]Net_ID = .{ .unset } ** 12,
            output_enable_low: Net_ID = .unset,
            latch_input_data: Net_ID = .unset, // latch data from B side; transparent when high
            latch_output_data: Net_ID = .unset, // latch data from A side; transparent when high
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.a.output_enable_low,
                28 => self.a.enable_bx,
                8 => self.a.data[0],
                9 => self.a.data[1],
                10 => self.a.data[2],
                12 => self.a.data[3],
                13 => self.a.data[4],
                14 => self.a.data[5],
                15 => self.a.data[6],
                16 => self.a.data[7],
                17 => self.a.data[8],
                19 => self.a.data[9],
                20 => self.a.data[10],
                21 => self.a.data[11],

                2 => self.bx.latch_input_data,
                30 => self.bx.latch_output_data,
                29 => self.bx.output_enable_low,
                23 => self.bx.data[0],
                24 => self.bx.data[1],
                26 => self.bx.data[2],
                31 => self.bx.data[3],
                33 => self.bx.data[4],
                34 => self.bx.data[5],
                36 => self.bx.data[6],
                37 => self.bx.data[7],
                38 => self.bx.data[8],
                40 => self.bx.data[9],
                41 => self.bx.data[10],
                42 => self.bx.data[11],

                27 => self.by.latch_input_data,
                55 => self.by.latch_output_data,
                56 => self.by.output_enable_low,
                52 => self.by.data[0],
                5 => self.by.data[1],
                3 => self.by.data[2],
                54 => self.by.data[3],
                6 => self.by.data[4],
                51 => self.by.data[5],
                49 => self.by.data[6],
                48 => self.by.data[7],
                47 => self.by.data[8],
                45 => self.by.data[9],
                44 => self.by.data[10],
                43 => self.by.data[11],

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
            a_hold: u12,
            bx_hold: u12,
            by_hold: u12,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.bx_to_a = 0xAAA;
                    state.by_to_a = 0xAAA;
                    state.a_to_bx = 0xAAA;
                    state.a_to_by = 0xAAA;
                },
                .commit => {
                    if (bus_hold) {
                        try v.expect_valid_or_nc(self.a.data, levels);
                        try v.expect_valid_or_nc(self.bx.data, levels);
                        try v.expect_valid_or_nc(self.by.data, levels);
                    } else {
                        try v.expect_valid(self.a.data, levels);
                        try v.expect_valid(self.bx.data, levels);
                        try v.expect_valid(self.by.data, levels);
                    }

                    try v.expect_valid(self.a.output_enable_low, levels);
                    try v.expect_valid(self.a.enable_bx, levels);
                    try v.expect_valid(self.bx.output_enable_low, levels);
                    try v.expect_valid(self.by.output_enable_low, levels);

                    try v.expect_valid(self.bx.latch_input_data, levels);
                    try v.expect_valid(self.by.latch_input_data, levels);
                    try v.expect_valid(self.bx.latch_output_data, levels);
                    try v.expect_valid(self.by.latch_output_data, levels);

                    if (v.read_logic(self.bx.latch_input_data, levels)) state.bx_to_a = self.read_bx(v, state);
                    if (v.read_logic(self.bx.latch_output_data, levels)) state.a_to_bx = self.read_a(v, state);

                    if (v.read_logic(self.by.latch_input_data, levels)) state.by_to_a = self.read_by(v, state);
                    if (v.read_logic(self.by.latch_output_data, levels)) state.a_to_by = self.read_a(v, state);
                },
                .nets_only => {
                    if (v.read_logic(self.a.output_enable_low, levels) == false) {
                        if (v.read_logic(self.a.enable_bx, levels)) {
                            state.a_hold = if (v.read_logic(self.bx.latch_input_data, levels)) self.read_bx(v, state) else state.bx_to_a;
                            try v.drive_bus(self.a.data, state.a_hold, levels);
                        } else {
                            state.a_hold = if (v.read_logic(self.by.latch_input_data, levels)) self.read_by(v, state) else state.by_to_a;
                            try v.drive_bus(self.a.data, state.a_hold, levels);
                        }
                    } else if (bus_hold) {
                        try v.drive_bus_weak(self.a.data, state.a_hold, levels);
                        state.a_hold = @truncate(v.read_bus_fallback(self.a.data, levels, state.a_hold));
                    }

                    if (v.read_logic(self.bx.output_enable_low, levels) == false) {
                        state.bx_hold = if (v.read_logic(self.bx.latch_output_data, levels)) self.read_a(v, state) else state.a_to_bx;
                        try v.drive_bus(self.bx.data, state.bx_hold, levels);
                    } else if (bus_hold) {
                        try v.drive_bus_weak(self.bx.data, state.bx_hold, levels);
                        state.bx_hold = @truncate(v.read_bus_fallback(self.bx.data, levels, state.bx_hold));
                    }

                    if (v.read_logic(self.by.output_enable_low, levels) == false) {
                        state.by_hold = if (v.read_logic(self.by.latch_output_data, levels)) self.read_a(v, state) else state.a_to_by;
                        try v.drive_bus(self.by.data, state.by_hold, levels);
                    } else if (bus_hold) {
                        try v.drive_bus_weak(self.by.data, state.by_hold, levels);
                        state.by_hold = @truncate(v.read_bus_fallback(self.by.data, levels, state.by_hold));
                    }
                },
            }
        }

        fn read_a(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_fallback(self.a.data, levels, state.a_hold));
            } else {
                return @truncate(v.read_bus(self.a.data, levels));
            }
        }

        fn read_bx(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_fallback(self.bx.data, levels, state.bx_hold));
            } else {
                return @truncate(v.read_bus(self.bx.data, levels));
            }
        }

        fn read_by(self: @This(), v: *Validator, state: *Validate_State) u12 {
            if (bus_hold) {
                return @truncate(v.read_bus_fallback(self.by.data, levels, state.by_hold));
            } else {
                return @truncate(v.read_bus(self.by.data, levels));
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

        d: [20]Net_ID = .{ .unset } ** 20,
        q: [20]Net_ID = .{ .unset } ** 20,
        clk: Net_ID = .unset,
        enable_clk_low: Net_ID = .unset,
        output_enable_low: Net_ID = .unset,
        pwr: power.Multi(4, 8, pwr, Decoupler) = .{},

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                0 => if (self.base.package.has_pin(.heatsink)) self.pwr.gnd else unreachable,

                1 => self.output_enable_low,
                56 => self.clk,
                29 => self.enable_clk_low,

                55 => self.d[0],
                54 => self.d[1],
                52 => self.d[2],
                51 => self.d[3],
                49 => self.d[4],
                48 => self.d[5],
                47 => self.d[6],
                45 => self.d[7],
                44 => self.d[8],
                43 => self.d[9],
                42 => self.d[10],
                41 => self.d[11],
                40 => self.d[12],
                38 => self.d[13],
                37 => self.d[14],
                36 => self.d[15],
                34 => self.d[16],
                33 => self.d[17],
                31 => self.d[18],
                30 => self.d[19],

                2 => self.q[0],
                3 => self.q[1],
                5 => self.q[2],
                6 => self.q[3],
                8 => self.q[4],
                9 => self.q[5],
                10 => self.q[6],
                12 => self.q[7],
                13 => self.q[8],
                14 => self.q[9],
                15 => self.q[10],
                16 => self.q[11],
                17 => self.q[12],
                19 => self.q[13],
                20 => self.q[14],
                21 => self.q[15],
                23 => self.q[16],
                24 => self.q[17],
                26 => self.q[18],
                27 => self.q[19],

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
            bus_hold: u20,
            clk: bool,
        };
        
        pub fn validate(self: @This(), v: *Validator, state: *Validate_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.data = 0xAAAAA;
                    state.bus_hold = 0xAAAAA;
                    state.clk = true;
                },
                .commit => {
                    if (bus_hold) {
                        try v.expect_valid_or_nc(self.d, levels);
                    } else {
                        try v.expect_valid(self.d, levels);
                    }
                    try v.expect_valid(self.clk, levels);
                    try v.expect_valid(self.enable_clk_low, levels);
                    try v.expect_valid(self.output_enable_low, levels);

                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk and v.read_logic(self.enable_clk_low, levels) == false) {
                        state.data = self.read_d(v, state);
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    if (v.read_logic(self.output_enable_low, levels) == false) {
                        try v.drive_bus(self.q, state.data, levels);
                    }
                    
                    if (bus_hold) {
                        try v.drive_bus_weak(self.d, state.bus_hold, levels);
                        state.bus_hold = @truncate(v.read_bus_fallback(self.d, levels, state.bus_hold));
                    }
                },
            }
        }

        fn read_d(self: @This(), v: *Validator, state: *Validate_State) u20 {
            if (bus_hold) {
                return @truncate(v.read_bus_fallback(self.d, levels, state.bus_hold));
            } else {
                return @truncate(v.read_bus(self.d, levels));
            }
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
