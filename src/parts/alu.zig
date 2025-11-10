// LOGIC L4C381 16b ALU
// Package = packages.PLCC_68M or packages.PLCC_68M_PGA
pub fn L4C381(comptime Decoupler: type, comptime Package: type) type {
    return struct {
        base: Part.Base = .{
            .prefix = .U,
            .package = &Package.pkg,
        },

        pwr: power.Single(.p5v, Decoupler) = .{},

        a: [16]Net_ID = @splat(.unset),
        b: [16]Net_ID = @splat(.unset),
        f: [16]Net_ID = @splat(.unset),

        operation: [3]Net_ID = @splat(.unset),
        operand_select: [2]Net_ID = @splat(.unset),
        carry_in: Net_ID = .unset,
        carry_out: Net_ID = .unset,
        n_carry_propagate: Net_ID = .unset,
        n_carry_generate: Net_ID = .unset,
        zero: Net_ID = .unset,
        overflow: Net_ID = .unset,
        flowthrough_ab: Net_ID = .unset,
        flowthrough_f: Net_ID = .unset,
        n_oe: Net_ID = .unset,
        n_ce_a: Net_ID = .unset,
        n_ce_b: Net_ID = .unset,
        n_ce_f: Net_ID = .unset,
        clk: Net_ID = .unset,

        pub const Operation = enum (u3) {
            zeroes = 0,
            nadd = 1,
            sub = 2,
            add = 3,
            xor = 4,
            @"or" = 5,
            @"and" = 6,
            ones = 7,
        };

        pub const Operand_Select = enum(u2) {
            a_f = 0,
            a_zero = 1,
            zero_b = 2,
            a_b = 3,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.a[0],
                2 => self.a[1],
                3 => self.a[2],
                4 => self.a[3],
                5 => self.a[4],
                6 => self.a[5],
                7 => self.a[6],
                8 => self.a[7],
                9 => self.a[8],
                10 => self.a[9],
                11 => self.a[10],
                12 => self.a[11],
                13 => self.a[12],
                14 => self.a[13],
                15 => self.a[14],
                16 => self.a[15],
                17 => self.clk,
                18 => self.pwr.p5v,
                19 => self.pwr.gnd,
                20 => self.carry_out,
                21 => self.n_carry_propagate,
                22 => self.n_carry_generate,
                23 => self.zero,
                24 => self.overflow,
                25 => self.n_ce_f,
                26 => self.flowthrough_f,
                27 => self.n_oe,
                28 => self.f[15],
                29 => self.f[14],
                30 => self.f[13],
                31 => self.f[12],
                32 => self.f[11],
                33 => self.f[10],
                34 => self.f[9],
                35 => self.f[8],
                36 => self.f[7],
                37 => self.f[6],
                38 => self.f[5],
                39 => self.f[4],
                40 => self.f[3],
                41 => self.f[2],
                42 => self.f[1],
                43 => self.f[0],
                44 => self.carry_in,
                45 => self.operation[0],
                46 => self.operation[1],
                47 => self.operation[2],
                48 => self.operand_select[0],
                49 => self.operand_select[1],
                50 => self.flowthrough_ab,
                51 => self.n_ce_b,
                52 => self.n_ce_a,
                53 => self.b[0],
                54 => self.b[1],
                55 => self.b[2],
                56 => self.b[3],
                57 => self.b[4],
                58 => self.b[5],
                59 => self.b[6],
                60 => self.b[7],
                61 => self.b[8],
                62 => self.b[9],
                63 => self.b[10],
                64 => self.b[11],
                65 => self.b[12],
                66 => self.b[13],
                67 => self.b[14],
                68 => self.b[15],
                else => std.debug.panic("Invalid pin: {} for L4C381", .{ @intFromEnum(pin_id) }),
            };
        }

        const levels = Voltage.TTL;

        const Validator_State = struct {
            clk: bool,
            a: u16,
            b: u16,
            f: u16,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.* = std.mem.zeroes(Validator_State);
                },
                .commit => {
                    try v.expect_valid(self.clk, levels);
                    try v.expect_valid(self.n_oe, levels);
                    try v.expect_valid(self.carry_in, levels);
                    try v.expect_valid(self.operation, levels);
                    try v.expect_valid(self.operand_select, levels);
                    try v.expect_valid(self.flowthrough_ab, levels);
                    try v.expect_valid(self.flowthrough_f, levels);

                    const result = self.compute_result(v, state.*);
                    try v.expect_output_valid(self.carry_out, result.carry, levels);
                    try v.expect_output_valid(self.overflow, result.overflow, levels);
                    try v.expect_output_valid(self.n_carry_generate, !result.generate, levels);
                    try v.expect_output_valid(self.n_carry_propagate, !result.propagate, levels);
                    try v.expect_output_valid(self.zero, result.zero, levels);

                    if (!v.read_logic(self.n_oe, levels)) {
                        if (v.read_logic(self.flowthrough_f, levels)) {
                            // flow through F
                            try v.expect_output_valid(&self.f, result.f, levels);
                        } else {
                            // registered F
                            try v.expect_output_valid(&self.f, state.f, levels);
                        }
                    }

                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk) {
                        try v.expect_valid(self.n_ce_a, levels);
                        try v.expect_valid(self.n_ce_b, levels);
                        try v.expect_valid(self.n_ce_f, levels);

                        if (!v.read_logic(self.n_ce_f, levels)) {
                            state.f = result.f;
                        }
                        if (!v.read_logic(self.n_ce_a, levels)) {
                            try v.expect_valid(self.a, levels);
                            state.a = @truncate(v.read_bus(self.a, levels));
                        }
                        if (!v.read_logic(self.n_ce_b, levels)) {
                            try v.expect_valid(self.b, levels);
                            state.b = @truncate(v.read_bus(self.b, levels));
                        }
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    const result = self.compute_result(v, state.*);
                    try v.drive_logic(self.carry_out, result.carry, levels);
                    try v.drive_logic(self.overflow, result.overflow, levels);
                    try v.drive_logic(self.n_carry_generate, !result.generate, levels);
                    try v.drive_logic(self.n_carry_propagate, !result.propagate, levels);
                    try v.drive_logic(self.zero, result.zero, levels);

                    if (!v.read_logic(self.n_oe, levels)) {
                        if (v.read_logic(self.flowthrough_f, levels)) {
                            // flow through F
                            try v.drive_bus(&self.f, result.f, levels);
                        } else {
                            // registered F
                            try v.drive_bus(&self.f, state.f, levels);
                        }
                    }
                },
            }
        }

        const Result = struct {
            f: u16,
            carry: bool = false,
            generate: bool = false,
            propagate: bool = false,
            overflow: bool = false,
            zero: bool,
        };

        fn compute_result(self: @This(), v: *Validator, state: Validator_State) Result {
            const operand_select = self.read_operand_select(v);
            const flowthrough_ab = v.read_logic(self.flowthrough_ab, levels);

            const a: u16 = switch (operand_select) {
                .zero_b => 0,
                .a_f, .a_zero, .a_b => switch (flowthrough_ab) {
                    false => state.a,
                    true => @intCast(v.read_bus(self.a, levels)),
                },
            };

            const b: u16 = switch (operand_select) {
                .a_f => state.f,
                .a_zero => 0,
                .a_b, .zero_b => switch (flowthrough_ab) {
                    false => state.b,
                    true => @intCast(v.read_bus(self.b, levels)),
                },
            };

            const ua: u16, const ub: u16 = switch (self.read_operation(v)) {
                .zeroes => return .{
                    .f = 0,
                    .zero = true,
                },
                .nadd => .{ ~a, b },
                .sub => .{ a, ~b },
                .add => .{ a, b },
                .xor => return .{
                    .f = a ^ b,
                    .zero = a == b,
                },
                .@"or" => return .{
                    .f = a | b,
                    .zero = (a | b) == 0,
                },
                .@"and" => return .{
                    .f = a & b,
                    .zero = (a & b) == 0,
                },
                .ones => return .{
                    .f = 0xFFFF,
                    .zero = false,
                },
            };

            const sa: i16 = @bitCast(ua);
            const sb: i16 = @bitCast(ub);

            const ua32: u32 = ua;
            const ub32: u32 = ub;

            const sa32: i32 = sa;
            const sb32: i32 = sb;

            const carry_in = v.read_logic(self.carry_in, levels);

            const unsigned_sum = ua32 + ub32 + @intFromBool(carry_in);
            const signed_sum = sa32 + sb32 + @intFromBool(carry_in);

            return .{
                .f = @truncate(unsigned_sum),
                .carry = (unsigned_sum & 0x10000) != 0,
                .generate = ((ua32 + ub32) & 0x10000) != 0,
                .propagate = (ua32 | ub32) == 0xFFFF,
                .overflow = signed_sum > std.math.maxInt(i16) or signed_sum < std.math.minInt(i16),
                .zero = (unsigned_sum & 0xFFFF) == 0,
            };
        }
        
        fn read_operand_select(self: @This(), v: *Validator) Operand_Select {
            return @enumFromInt(v.read_bus(self.operand_select, levels));
        }

        fn read_operation(self: @This(), v: *Validator) Operation {
            return @enumFromInt(v.read_bus(self.operation, levels));
        }

    };
}

// 16b x 16b => 32b signed/unsigned multipliers based on the TRW MPY016H pinout
// Manufactured by various companies
// - IDT 7216
// - Cypress CY7C516
// - AMD Am29516, Am29C516
// - LOGIC LMU16, LMU216
// - TRW MPY016H
pub fn M16(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime package_type: Multiplier_Package_Type) type {
    return struct {
        base: Part.Base = .{
            .prefix = .U,
            .package = switch (package_type) {
                .dip64 => &packages.DIP64.pkg,
                .plcc68 => &packages.PLCC_68M.pkg,
                .plcc68_pga68 => &packages.PLCC_68M_PGA.pkg,
                .pga68 => &packages.PGA68.pkg,
                .flatpack64 => @compileError("not currently supported"),
            },
        },

        pwr: power.Multi(2, 2, pwr, Decoupler) = .{},

        // input multiplicand
        x: [16]Net_ID = @splat(.unset),

        // input multiplicand & optional LSP output operand, controlled by n_oe_y
        y: [16]Net_ID = @splat(.unset),

        // dedicated product output bus; selectable between MSP or LSP
        p: [16]Net_ID = @splat(.unset),

        // "x input mode" - when high, interpret as 2's complement signed; when low, interpret as unsigned
        xm: Net_ID = .unset,

        // "y input mode" - when high, interpret as 2's complement signed; when low, interpret as unsigned
        ym: Net_ID = .unset,

        // "flowthrough" - when high, MSP and LSP output registers are bypassed
        ft: Net_ID = .unset,

        // "format adjust" - when low, shifts MSP and MSB of LSB one bit left, then copies new MSP MSB to LSP MSB.
        // When multiplying two signed, fractional values in the range (-1,1), the result will also be in the range (-1,1), but the normal output format supports a range of [-2,2).
        // This means the two MSBs are always identical, and it may be more useful to put one in each half of the result in some cases?
        // Rarely used, so defauled to high for the normal format.
        fa: Net_ID = pwr,

        // When high, a 1 is added to the MSB of the LSP (when FA == 0, this is bit 14 instead of bit 15)
        // This is intended to be used to avoid systematic biases, but must be used carefully, and most applications don't need it, so defaulted to off.
        rnd: Net_ID = .gnd,

        // When low, output LSP on `y`
        n_oe_y: Net_ID = pwr,

        // When low, output LSP or MSP on `p`
        n_oe_p: Net_ID = .unset,

        // When high, select LSP for `p` output buffer; when low, select MSP
        lsp_sel: Net_ID = .unset,

        clk_x: Net_ID = .unset,
        clk_y: Net_ID = .unset,
        clk_msp: Net_ID = .unset,
        clk_lsp: Net_ID = .unset,


        pub const Input_Format = enum (u1) {
            unsigned = 0,
            signed = 1,
        };

        pub const Output_Format = enum (u1) {
            adjusted = 0,
            normal = 1,
        };

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (package_type) {
                .dip64 => switch (@intFromEnum(pin_id)) {
                    1 => self.x[4],
                    2 => self.x[3],
                    3 => self.x[2],
                    4 => self.x[1],
                    5 => self.x[0],
                    6 => self.n_oe_y,
                    7 => self.clk_lsp,
                    8 => self.clk_y,
                    9 => self.y[0],
                    10 => self.y[1],
                    11 => self.y[2],
                    12 => self.y[3],
                    13 => self.y[4],
                    14 => self.y[5],
                    15 => self.y[6],
                    16 => self.y[7],
                    17 => self.y[8],
                    18 => self.y[9],
                    19 => self.y[10],
                    20 => self.y[11],
                    21 => self.y[12],
                    22 => self.y[13],
                    23 => self.y[14],
                    24 => self.y[15],
                    25 => self.p[0],
                    26 => self.p[1],
                    27 => self.p[2],
                    28 => self.p[3],
                    29 => self.p[4],
                    30 => self.p[5],
                    31 => self.p[6],
                    32 => self.p[7],
                    33 => self.p[8],
                    34 => self.p[9],
                    35 => self.p[10],
                    36 => self.p[11],
                    37 => self.p[12],
                    38 => self.p[13],
                    39 => self.p[14],
                    40 => self.p[15],
                    41 => self.clk_msp,
                    42 => self.n_oe_p,
                    43 => self.fa,
                    44 => self.ft,
                    45 => self.lsp_sel,
                    46 => self.pwr.gnd[0],
                    47 => self.pwr.gnd[1],
                    48 => @field(self.pwr, @tagName(pwr))[1],
                    49 => @field(self.pwr, @tagName(pwr))[0],
                    50 => self.ym,
                    51 => self.xm,
                    52 => self.rnd,
                    53 => self.clk_x,
                    54 => self.x[15],
                    55 => self.x[14],
                    56 => self.x[13],
                    57 => self.x[12],
                    58 => self.x[11],
                    59 => self.x[10],
                    60 => self.x[9],
                    61 => self.x[8],
                    62 => self.x[7],
                    63 => self.x[6],
                    64 => self.x[5],
                    else => unreachable,
                },
                .plcc68, .plcc68_pga68 => switch (@intFromEnum(pin_id)) {
                    68 => @field(self.pwr, @tagName(pwr))[0],
                    67 => self.ym,
                    66 => self.xm,
                    65 => self.rnd,
                    64 => self.clk_x,
                    63 => self.x[15],
                    62 => self.x[14],
                    61 => self.x[13],
                    60 => .no_connect,
                    59 => self.x[12],
                    58 => self.x[11],
                    57 => self.x[10],
                    56 => self.x[9],
                    55 => self.x[8],
                    54 => self.x[7],
                    53 => self.x[6],
                    52 => self.x[5],
                    51 => self.x[4],
                    50 => self.x[3],
                    49 => self.x[2],
                    48 => self.x[1],
                    47 => self.x[0],
                    46 => self.n_oe_y,
                    45 => self.clk_lsp,
                    44 => self.clk_y,
                    43 => .no_connect,
                    42 => self.y[0],
                    41 => self.y[1],
                    40 => self.y[2],
                    39 => self.y[3],
                    38 => self.y[4],
                    37 => self.y[5],
                    36 => self.y[6],
                    35 => self.y[7],
                    34 => self.y[8],
                    33 => self.y[9],
                    32 => self.y[10],
                    31 => self.y[11],
                    30 => self.y[12],
                    29 => self.y[13],
                    28 => self.y[14],
                    27 => self.y[15],
                    26 => .no_connect,
                    25 => self.p[0],
                    24 => self.p[1],
                    23 => self.p[2],
                    22 => self.p[3],
                    21 => self.p[4],
                    20 => self.p[5],
                    19 => self.p[6],
                    18 => self.p[7],
                    17 => self.p[8],
                    16 => self.p[9],
                    15 => self.p[10],
                    14 => self.p[11],
                    13 => self.p[12],
                    12 => self.p[13],
                    11 => self.p[14],
                    10 => self.p[15],
                    9 => .no_connect,
                    8 => self.clk_msp,
                    7 => self.n_oe_p,
                    6 => self.fa,
                    5 => self.ft,
                    4 => self.lsp_sel,
                    3 => self.pwr.gnd[0],
                    2 => self.pwr.gnd[1],
                    1 => @field(self.pwr, @tagName(pwr))[1],
                    else => unreachable,
                },
                .pga68 => switch (packages.PGA68.Pin_ID.from_generic(pin_id)) {
                    .B2 => self.y[0],
                    .B1 => self.y[1],
                    .C2 => self.y[2],
                    .C1 => self.y[3],
                    .D2 => self.y[4],
                    .D1 => self.y[5],
                    .E2 => self.y[6],
                    .E1 => self.y[7],
                    .F2 => self.y[8],
                    .F1 => self.y[9],
                    .G2 => self.y[10],
                    .G1 => self.y[11],
                    .H2 => self.y[12],
                    .H1 => self.y[13],
                    .J2 => self.y[14],
                    .J1 => self.y[15],
                    .K2 => self.p[0],
                    .L2 => self.p[1],
                    .K3 => self.p[2],
                    .L3 => self.p[3],
                    .K4 => self.p[4],
                    .L4 => self.p[5],
                    .K5 => self.p[6],
                    .L5 => self.p[7],
                    .K6 => self.p[8],
                    .L6 => self.p[9],
                    .K7 => self.p[10],
                    .L7 => self.p[11],
                    .K8 => self.p[12],
                    .L8 => self.p[13],
                    .K9 => self.p[14],
                    .L9 => self.p[15],
                    .K10 => self.clk_msp,
                    .K11 => self.n_oe_p,
                    .J10 => self.fa,
                    .J11 => self.ft,
                    .H10 => self.lsp_sel,
                    .H11 => self.pwr.gnd[0],
                    .G10 => self.pwr.gnd[1],
                    .G11 => @field(self.pwr, @tagName(pwr))[1],
                    .F10 => @field(self.pwr, @tagName(pwr))[0],
                    .F11 => self.ym,
                    .E10 => self.xm,
                    .E11 => self.rnd,
                    .D10 => self.clk_x,
                    .D11 => self.x[15],
                    .C10 => self.x[14],
                    .C11 => self.x[13],
                    .B10 => self.x[12],
                    .A10 => self.x[11],
                    .B9 => self.x[10],
                    .A9 => self.x[9],
                    .B8 => self.x[8],
                    .A8 => self.x[7],
                    .B7 => self.x[6],
                    .A7 => self.x[5],
                    .B6 => self.x[4],
                    .A6 => self.x[3],
                    .B5 => self.x[2],
                    .A5 => self.x[1],
                    .B4 => self.x[0],
                    .A4 => self.n_oe_y,
                    .B3 => self.clk_lsp,
                    .A3 => self.clk_y,

                    .A2 => .no_connect,
                    .B11 => .no_connect,
                    .L10 => .no_connect,
                    .K1 => .no_connect,
                },
                .flatpack64 => switch (@intFromEnum(pin_id)) {
                    64 => self.clk_msp,
                    63 => self.n_oe_p,
                    62 => self.fa,
                    61 => self.ft,
                    60 => self.lsp_sel,
                    59 => self.pwr.gnd[0],
                    58 => self.pwr.gnd[1],
                    57 => @field(self.pwr, @tagName(pwr))[1],
                    56 => @field(self.pwr, @tagName(pwr))[0],
                    55 => self.ym,
                    54 => self.xm,
                    53 => self.rnd,
                    52 => self.clk_x,
                    51 => self.x[15],
                    50 => self.x[14],
                    49 => self.x[13],
                    48 => self.x[12],
                    47 => self.x[11],
                    46 => self.x[10],
                    45 => self.x[9],
                    44 => self.x[8],
                    43 => self.x[7],
                    42 => self.x[6],
                    41 => self.x[5],
                    40 => self.x[4],
                    39 => self.x[3],
                    38 => self.x[2],
                    37 => self.x[1],
                    36 => self.x[0],
                    35 => self.n_oe_y,
                    34 => self.clk_lsp,
                    33 => self.clk_y,
                    32 => self.y[0],
                    31 => self.y[1],
                    30 => self.y[2],
                    29 => self.y[3],
                    28 => self.y[4],
                    27 => self.y[5],
                    26 => self.y[6],
                    25 => self.y[7],
                    24 => self.y[8],
                    23 => self.y[9],
                    22 => self.y[10],
                    21 => self.y[11],
                    20 => self.y[12],
                    19 => self.y[13],
                    18 => self.y[14],
                    17 => self.y[15],
                    16 => self.p[0],
                    15 => self.p[1],
                    14 => self.p[2],
                    13 => self.p[3],
                    12 => self.p[4],
                    11 => self.p[5],
                    10 => self.p[6],
                    9 => self.p[7],
                    8 => self.p[8],
                    7 => self.p[9],
                    6 => self.p[10],
                    5 => self.p[11],
                    4 => self.p[12],
                    3 => self.p[13],
                    2 => self.p[14],
                    1 => self.p[15],
                    else => unreachable,
                },
            };
        }

        const Validator_State = struct {
            xm: Input_Format,
            ym: Input_Format,
            rnd: bool,
            clk_x: bool,
            clk_y: bool,
            clk_msp: bool,
            clk_lsp: bool,
            x: u16,
            y: u16,
            lsp: u16,
            msp: u16,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.* = std.mem.zeroes(Validator_State);
                },
                .commit => {
                    try v.expect_valid(self.clk_x, levels);
                    try v.expect_valid(self.clk_y, levels);
                    try v.expect_valid(self.clk_msp, levels);
                    try v.expect_valid(self.clk_lsp, levels);
                    try v.expect_valid(self.n_oe_p, levels);
                    try v.expect_valid(self.n_oe_y, levels);
                    try v.expect_valid(self.ft, levels);
                    try v.expect_valid(self.fa, levels);
                    try v.expect_valid(self.xm, levels);
                    try v.expect_valid(self.ym, levels);
                    try v.expect_valid(self.x, levels);

                    if (v.read_logic(self.ft, levels)) {
                        // flowthrough mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.expect_valid(self.lsp_sel, levels);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.expect_output_valid(&self.p, product & 0xFFFF, levels);
                            } else {
                                try v.expect_output_valid(&self.p, product >> 16, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.expect_output_valid(&self.y, product & 0xFFFF, levels);
                        }
                    } else {
                        // registered mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            try v.expect_valid(self.lsp_sel, levels);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.expect_output_valid(&self.p, state.lsp, levels);
                            } else {
                                try v.expect_output_valid(&self.p, state.msp, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            try v.expect_output_valid(&self.y, state.lsp, levels);
                        }
                    }

                    const new_clk_lsp = v.read_logic(self.clk_lsp, levels);
                    const new_clk_msp = v.read_logic(self.clk_msp, levels);
                    if (new_clk_lsp and !state.clk_lsp or new_clk_msp and !state.clk_msp) {
                        const product = self.compute_product(v, state.*);
                        if (new_clk_lsp and !state.clk_lsp) {
                            state.lsp = @truncate(product);
                        }
                        if (new_clk_msp and !state.clk_msp) {
                            state.msp = @truncate(product >> 16);
                        }
                    }

                    const new_clk_x = v.read_logic(self.clk_x, levels);
                    if (new_clk_x and !state.clk_x) {
                        state.x = @truncate(v.read_bus(self.x, levels));
                        state.rnd = v.read_logic(self.rnd, levels);
                        try v.expect_valid(self.rnd, levels);
                    }

                    const new_clk_y = v.read_logic(self.clk_y, levels);
                    if (new_clk_y and !state.clk_y) {
                        state.y = @truncate(v.read_bus(self.y, levels));
                        try v.expect_valid(self.y, levels);
                        state.rnd = v.read_logic(self.rnd, levels);
                        try v.expect_valid(self.rnd, levels);
                    }

                    state.clk_x = new_clk_x;
                    state.clk_y = new_clk_y;
                    state.clk_lsp = new_clk_lsp;
                    state.clk_msp = new_clk_msp;
                },
                .nets_only => {
                    if (v.read_logic(self.ft, levels)) {
                        // flowthrough mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            const product = self.compute_product(v, state.*);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.drive_bus(&self.p, product & 0xFFFF, levels);
                            } else {
                                try v.drive_bus(&self.p, product >> 16, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.drive_bus(&self.y, product & 0xFFFF, levels);
                        }
                    } else {
                        // registered mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.drive_bus(&self.p, state.lsp, levels);
                            } else {
                                try v.drive_bus(&self.p, state.msp, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            try v.drive_bus(&self.y, state.lsp, levels);
                        }
                    }
                },
            }
        }

        fn compute_product(self: @This(), v: *Validator, state: Validator_State) u32 {
            const x: u32 = switch (state.xm) {
                .unsigned => state.x,
                .signed => bits.sx(u32, state.x),
            };
            const y: u32 = switch (state.ym) {
                .unsigned => state.y,
                .signed => bits.sx(u32, state.y),
            };
            var product = x *% y;

            const output_format = self.read_output_format(v);

            if (state.rnd) {
                product +%= switch (output_format) {
                    .normal => 0x8000,
                    .adjusted => 0x4000,
                };
            }

            return switch (output_format) {
                .normal => product,
                .adjusted => result: {
                    const shifted = (product & 0x7FFF) | ((product & 0x7FFF_8000) << 1);
                    break :result shifted | ((shifted >> 16) & 0x8000);
                },
            };
        }

        fn read_input_format(v: *Validator, signal: Net_ID) Input_Format {
            return @enumFromInt(@intFromBool(v.read_logic(signal, levels)));
        }

        fn read_output_format(self: @This(), v: *Validator) Output_Format {
            return @enumFromInt(@intFromBool(v.read_logic(self.fa, levels)));
        }
    };
}


// 16b x 16b => 32b signed/unsigned multipliers with single clock
// Manufactured by various companies
// - IDT 7217
// - Cypress CY7C517
// - AMD Am29517, Am29C517
// - LOGIC LMU217
pub fn M17(comptime pwr: Net_ID, comptime Decoupler: type, comptime levels: type, comptime package_type: Multiplier_Package_Type) type {
    return struct {
        base: Part.Base = .{
            .prefix = .U,
            .package = switch (package_type) {
                .dip64 => &packages.DIP64.pkg,
                .plcc68 => &packages.PLCC_68M.pkg,
                .plcc68_pga68 => &packages.PLCC_68M_PGA.pkg,
                .pga68 => &packages.PGA68.pkg,
                .flatpack64 => @compileError("not currently supported"),
            },
        },

        pwr: power.Multi(2, 2, pwr, Decoupler) = .{},

        // input multiplicand
        x: [16]Net_ID = @splat(.unset),

        // input multiplicand & optional LSP output operand, controlled by n_oe_y
        y: [16]Net_ID = @splat(.unset),

        // dedicated product output bus; selectable between MSP or LSP
        p: [16]Net_ID = @splat(.unset),

        // "x input mode" - when high, interpret as 2's complement signed; when low, interpret as unsigned
        xm: Net_ID = .unset,

        // "y input mode" - when high, interpret as 2's complement signed; when low, interpret as unsigned
        ym: Net_ID = .unset,

        // "flowthrough" - when high, MSP and LSP output registers are bypassed
        ft: Net_ID = .unset,

        // "format adjust" - when low, shifts MSP and MSB of LSB one bit left, then copies new MSP MSB to LSP MSB.
        // When multiplying two signed, fractional values in the range (-1,1), the result will also be in the range (-1,1), but the normal output format supports a range of [-2,2).
        // This means the two MSBs are always identical, and it may be more useful to put one in each half of the result in some cases?
        // Rarely used, so defauled to high for the normal format.
        fa: Net_ID = pwr,

        // When high, a 1 is added to the MSB of the LSP (when FA == 0, this is bit 14 instead of bit 15)
        // This is intended to be used to avoid systematic biases, but must be used carefully, and most applications don't need it, so defaulted to off.
        rnd: Net_ID = .gnd,

        // When low, output LSP on `y`
        n_oe_y: Net_ID = pwr,

        // When low, output LSP or MSP on `p`
        n_oe_p: Net_ID = .unset,

        // When high, select LSP for `p` output buffer; when low, select MSP
        lsp_sel: Net_ID = .unset,

        clk: Net_ID = .unset,
        n_ce_x: Net_ID = .unset,
        n_ce_y: Net_ID = .unset,
        n_ce_p: Net_ID = .unset,

        pub const Input_Format = M16(pwr, Decoupler, levels, package_type).Input_Format;
        pub const Output_Format = M16(pwr, Decoupler, levels, package_type).Output_Format;

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (package_type) {
                .dip64 => switch (@intFromEnum(pin_id)) {
                    1 => self.x[4],
                    2 => self.x[3],
                    3 => self.x[2],
                    4 => self.x[1],
                    5 => self.x[0],
                    6 => self.n_oe_y,
                    7 => self.clk,
                    8 => self.n_ce_y,
                    9 => self.y[0],
                    10 => self.y[1],
                    11 => self.y[2],
                    12 => self.y[3],
                    13 => self.y[4],
                    14 => self.y[5],
                    15 => self.y[6],
                    16 => self.y[7],
                    17 => self.y[8],
                    18 => self.y[9],
                    19 => self.y[10],
                    20 => self.y[11],
                    21 => self.y[12],
                    22 => self.y[13],
                    23 => self.y[14],
                    24 => self.y[15],
                    25 => self.p[0],
                    26 => self.p[1],
                    27 => self.p[2],
                    28 => self.p[3],
                    29 => self.p[4],
                    30 => self.p[5],
                    31 => self.p[6],
                    32 => self.p[7],
                    33 => self.p[8],
                    34 => self.p[9],
                    35 => self.p[10],
                    36 => self.p[11],
                    37 => self.p[12],
                    38 => self.p[13],
                    39 => self.p[14],
                    40 => self.p[15],
                    41 => self.n_ce_p,
                    42 => self.n_oe_p,
                    43 => self.fa,
                    44 => self.ft,
                    45 => self.lsp_sel,
                    46 => self.pwr.gnd[0],
                    47 => self.pwr.gnd[1],
                    48 => @field(self.pwr, @tagName(pwr))[1],
                    49 => @field(self.pwr, @tagName(pwr))[0],
                    50 => self.ym,
                    51 => self.xm,
                    52 => self.rnd,
                    53 => self.n_ce_x,
                    54 => self.x[15],
                    55 => self.x[14],
                    56 => self.x[13],
                    57 => self.x[12],
                    58 => self.x[11],
                    59 => self.x[10],
                    60 => self.x[9],
                    61 => self.x[8],
                    62 => self.x[7],
                    63 => self.x[6],
                    64 => self.x[5],
                    else => unreachable,
                },
                .plcc68, .plcc68_pga68 => switch (@intFromEnum(pin_id)) {
                    68 => @field(self.pwr, @tagName(pwr))[0],
                    67 => self.ym,
                    66 => self.xm,
                    65 => self.rnd,
                    64 => self.n_ce_x,
                    63 => self.x[15],
                    62 => self.x[14],
                    61 => self.x[13],
                    60 => .no_connect,
                    59 => self.x[12],
                    58 => self.x[11],
                    57 => self.x[10],
                    56 => self.x[9],
                    55 => self.x[8],
                    54 => self.x[7],
                    53 => self.x[6],
                    52 => self.x[5],
                    51 => self.x[4],
                    50 => self.x[3],
                    49 => self.x[2],
                    48 => self.x[1],
                    47 => self.x[0],
                    46 => self.n_oe_y,
                    45 => self.clk,
                    44 => self.n_ce_y,
                    43 => .no_connect,
                    42 => self.y[0],
                    41 => self.y[1],
                    40 => self.y[2],
                    39 => self.y[3],
                    38 => self.y[4],
                    37 => self.y[5],
                    36 => self.y[6],
                    35 => self.y[7],
                    34 => self.y[8],
                    33 => self.y[9],
                    32 => self.y[10],
                    31 => self.y[11],
                    30 => self.y[12],
                    29 => self.y[13],
                    28 => self.y[14],
                    27 => self.y[15],
                    26 => .no_connect,
                    25 => self.p[0],
                    24 => self.p[1],
                    23 => self.p[2],
                    22 => self.p[3],
                    21 => self.p[4],
                    20 => self.p[5],
                    19 => self.p[6],
                    18 => self.p[7],
                    17 => self.p[8],
                    16 => self.p[9],
                    15 => self.p[10],
                    14 => self.p[11],
                    13 => self.p[12],
                    12 => self.p[13],
                    11 => self.p[14],
                    10 => self.p[15],
                    9 => .no_connect,
                    8 => self.n_ce_p,
                    7 => self.n_oe_p,
                    6 => self.fa,
                    5 => self.ft,
                    4 => self.lsp_sel,
                    3 => self.pwr.gnd[0],
                    2 => self.pwr.gnd[1],
                    1 => @field(self.pwr, @tagName(pwr))[1],
                    else => unreachable,
                },
                .pga68 => switch (packages.PGA68.Pin_ID.from_generic(pin_id)) {
                    .B2 => self.y[0],
                    .B1 => self.y[1],
                    .C2 => self.y[2],
                    .C1 => self.y[3],
                    .D2 => self.y[4],
                    .D1 => self.y[5],
                    .E2 => self.y[6],
                    .E1 => self.y[7],
                    .F2 => self.y[8],
                    .F1 => self.y[9],
                    .G2 => self.y[10],
                    .G1 => self.y[11],
                    .H2 => self.y[12],
                    .H1 => self.y[13],
                    .J2 => self.y[14],
                    .J1 => self.y[15],
                    .K2 => self.p[0],
                    .L2 => self.p[1],
                    .K3 => self.p[2],
                    .L3 => self.p[3],
                    .K4 => self.p[4],
                    .L4 => self.p[5],
                    .K5 => self.p[6],
                    .L5 => self.p[7],
                    .K6 => self.p[8],
                    .L6 => self.p[9],
                    .K7 => self.p[10],
                    .L7 => self.p[11],
                    .K8 => self.p[12],
                    .L8 => self.p[13],
                    .K9 => self.p[14],
                    .L9 => self.p[15],
                    .K10 => self.n_ce_p,
                    .K11 => self.n_oe_p,
                    .J10 => self.fa,
                    .J11 => self.ft,
                    .H10 => self.lsp_sel,
                    .H11 => self.pwr.gnd[0],
                    .G10 => self.pwr.gnd[1],
                    .G11 => @field(self.pwr, @tagName(pwr))[1],
                    .F10 => @field(self.pwr, @tagName(pwr))[0],
                    .F11 => self.ym,
                    .E10 => self.xm,
                    .E11 => self.rnd,
                    .D10 => self.n_ce_x,
                    .D11 => self.x[15],
                    .C10 => self.x[14],
                    .C11 => self.x[13],
                    .B10 => self.x[12],
                    .A10 => self.x[11],
                    .B9 => self.x[10],
                    .A9 => self.x[9],
                    .B8 => self.x[8],
                    .A8 => self.x[7],
                    .B7 => self.x[6],
                    .A7 => self.x[5],
                    .B6 => self.x[4],
                    .A6 => self.x[3],
                    .B5 => self.x[2],
                    .A5 => self.x[1],
                    .B4 => self.x[0],
                    .A4 => self.n_oe_y,
                    .B3 => self.clk,
                    .A3 => self.n_ce_y,

                    .A2 => .no_connect,
                    .B11 => .no_connect,
                    .L10 => .no_connect,
                    .K1 => .no_connect,
                },
                .flatpack64 => switch (@intFromEnum(pin_id)) {
                    64 => self.n_ce_p,
                    63 => self.n_oe_p,
                    62 => self.fa,
                    61 => self.ft,
                    60 => self.lsp_sel,
                    59 => self.pwr.gnd[0],
                    58 => self.pwr.gnd[1],
                    57 => @field(self.pwr, @tagName(pwr))[1],
                    56 => @field(self.pwr, @tagName(pwr))[0],
                    55 => self.ym,
                    54 => self.xm,
                    53 => self.rnd,
                    52 => self.n_ce_x,
                    51 => self.x[15],
                    50 => self.x[14],
                    49 => self.x[13],
                    48 => self.x[12],
                    47 => self.x[11],
                    46 => self.x[10],
                    45 => self.x[9],
                    44 => self.x[8],
                    43 => self.x[7],
                    42 => self.x[6],
                    41 => self.x[5],
                    40 => self.x[4],
                    39 => self.x[3],
                    38 => self.x[2],
                    37 => self.x[1],
                    36 => self.x[0],
                    35 => self.n_oe_y,
                    34 => self.clk,
                    33 => self.n_ce_y,
                    32 => self.y[0],
                    31 => self.y[1],
                    30 => self.y[2],
                    29 => self.y[3],
                    28 => self.y[4],
                    27 => self.y[5],
                    26 => self.y[6],
                    25 => self.y[7],
                    24 => self.y[8],
                    23 => self.y[9],
                    22 => self.y[10],
                    21 => self.y[11],
                    20 => self.y[12],
                    19 => self.y[13],
                    18 => self.y[14],
                    17 => self.y[15],
                    16 => self.p[0],
                    15 => self.p[1],
                    14 => self.p[2],
                    13 => self.p[3],
                    12 => self.p[4],
                    11 => self.p[5],
                    10 => self.p[6],
                    9 => self.p[7],
                    8 => self.p[8],
                    7 => self.p[9],
                    6 => self.p[10],
                    5 => self.p[11],
                    4 => self.p[12],
                    3 => self.p[13],
                    2 => self.p[14],
                    1 => self.p[15],
                    else => unreachable,
                },
            };
        }

        const Validator_State = struct {
            xm: Input_Format,
            ym: Input_Format,
            rnd: bool,
            clk: bool,
            x: u16,
            y: u16,
            lsp: u16,
            msp: u16,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.* = std.mem.zeroes(Validator_State);
                },
                .commit => {
                    try v.expect_valid(self.clk, levels);
                    try v.expect_valid(self.n_oe_p, levels);
                    try v.expect_valid(self.n_oe_y, levels);
                    try v.expect_valid(self.ft, levels);
                    try v.expect_valid(self.fa, levels);

                    if (v.read_logic(self.ft, levels)) {
                        // flowthrough mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.expect_valid(self.lsp_sel, levels);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.expect_output_valid(&self.p, product & 0xFFFF, levels);
                            } else {
                                try v.expect_output_valid(&self.p, product >> 16, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.expect_output_valid(&self.y, product & 0xFFFF, levels);
                        }
                    } else {
                        // registered mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            try v.expect_valid(self.lsp_sel, levels);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.expect_output_valid(&self.p, state.lsp, levels);
                            } else {
                                try v.expect_output_valid(&self.p, state.msp, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            try v.expect_output_valid(&self.y, state.lsp, levels);
                        }
                    }

                    const new_clk = v.read_logic(self.clk, levels);
                    if (new_clk and !state.clk) {
                        try v.expect_valid(self.x, levels);
                        try v.expect_valid(self.y, levels);
                        try v.expect_valid(self.xm, levels);
                        try v.expect_valid(self.ym, levels);
                        try v.expect_valid(self.rnd, levels);
                        try v.expect_valid(self.n_ce_x, levels);
                        try v.expect_valid(self.n_ce_y, levels);
                        try v.expect_valid(self.n_ce_p, levels);

                        if (!v.read_logic(self.n_ce_p, levels)) {
                            const product = self.compute_product(v, state.*);
                            state.lsp = @truncate(product);
                            state.msp = @truncate(product >> 16);
                        }

                        if (!v.read_logic(self.n_ce_x, levels)) {
                            state.x = @truncate(v.read_bus(self.x, levels));
                            state.rnd = v.read_logic(self.rnd, levels);
                        }
                        if (!v.read_logic(self.n_ce_y, levels)) {
                            state.y = @truncate(v.read_bus(self.y, levels));
                            state.rnd = v.read_logic(self.rnd, levels);
                        }
                    }
                    state.clk = new_clk;
                },
                .nets_only => {
                    if (v.read_logic(self.ft, levels)) {
                        // flowthrough mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            const product = self.compute_product(v, state.*);
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.drive_bus(&self.p, product & 0xFFFF, levels);
                            } else {
                                try v.drive_bus(&self.p, product >> 16, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            const product = self.compute_product(v, state.*);
                            try v.drive_bus(&self.y, product & 0xFFFF, levels);
                        }
                    } else {
                        // registered mode
                        if (!v.read_logic(self.n_oe_p, levels)) {
                            if (v.read_logic(self.lsp_sel, levels)) {
                                try v.drive_bus(&self.p, state.lsp, levels);
                            } else {
                                try v.drive_bus(&self.p, state.msp, levels);
                            }
                        }
                        if (!v.read_logic(self.n_oe_y, levels)) {
                            try v.drive_bus(&self.y, state.lsp, levels);
                        }
                    }
                },
            }
        }

        fn compute_product(self: @This(), v: *Validator, state: Validator_State) u32 {
            const x: u32 = switch (state.xm) {
                .unsigned => state.x,
                .signed => bits.sx(u32, state.x),
            };
            const y: u32 = switch (state.ym) {
                .unsigned => state.y,
                .signed => bits.sx(u32, state.y),
            };
            var product = x *% y;

            const output_format = self.read_output_format(v);

            if (state.rnd) {
                product +%= switch (output_format) {
                    .normal => 0x8000,
                    .adjusted => 0x4000,
                };
            }

            return switch (output_format) {
                .normal => product,
                .adjusted => result: {
                    const shifted = (product & 0x7FFF) | ((product & 0x7FFF_8000) << 1);
                    break :result shifted | ((shifted >> 16) & 0x8000);
                },
            };
        }

        fn read_input_format(v: *Validator, signal: Net_ID) Input_Format {
            return @enumFromInt(@intFromBool(v.read_logic(signal, levels)));
        }

        fn read_output_format(self: @This(), v: *Validator) Output_Format {
            return @enumFromInt(@intFromBool(v.read_logic(self.fa, levels)));
        }
    };
}

pub const Multiplier_Package_Type = enum {
    dip64,
    plcc68,
    plcc68_pga68, // PLCC68 in a PGA68 socket
    pga68, // warning: same physical form factor as plcc68_pga68, but different pinout!
    flatpack64,
};

const Net_ID = enums.Net_ID;
const Pin_ID = enums.Pin_ID;
const Voltage = enums.Voltage;
const enums = @import("../enums.zig");
const Validator = @import("../Validator.zig");
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const packages = @import("../packages.zig");
const bits = @import("bits");
const std = @import("std");
