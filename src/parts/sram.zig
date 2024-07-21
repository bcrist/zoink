pub fn Pins_8b_Alliance(comptime Self: type, comptime Pkg: type) type {
    if (Pkg == packages.TSOP_II_32 or Pkg == packages.SOJ_32) return struct {
        pub fn pin(self: Self, pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                28 => self.outpue_enable_low,
                5 => self.chip_enable_low,
                12 => self.write_enable_low,

                1 => self.addr[0],
                2 => self.addr[1],
                3 => self.addr[2],
                4 => self.addr[3],
                13 => self.addr[4],
                14 => self.addr[5],
                15 => self.addr[6],
                16 => self.addr[7],
                17 => self.addr[8],
                18 => self.addr[9],
                19 => self.addr[10],
                20 => self.addr[11],
                21 => self.addr[12],
                29 => self.addr[13],
                30 => self.addr[14],
                31 => self.addr[15],
                32 => self.addr[16],

                6 => self.data[0],
                7 => self.data[1],
                10 => self.data[2],
                11 => self.data[3],
                22 => self.data[4],
                23 => self.data[5],
                26 => self.data[6],
                27 => self.data[7],

                9 => self.pwr.gnd[0],
                8 => self.pwr.p3v3[0],
                25 => self.pwr.gnd[1],
                24 => self.pwr.p3v3[1],

                else => unreachable,
            };
        }
    };
}

pub fn Pins_16b_GSI(comptime Self: type, comptime Pkg: type) type {
    if (Pkg == packages.FBGA_48) return struct {
        pub fn pin(self: Self, pin_id: Pin_ID) Net_ID {
            return switch (packages.FBGA_48.Pin_ID.from_generic(pin_id)) {
                .A1 => self.lower_byte_enable_low,
                .B2 => self.upper_byte_enable_low,

                .A2 => self.outpue_enable_low,
                .B5 => self.chip_enable_low,
                .G5 => self.write_enable_low,

                .A3 => self.addr[0],
                .A4 => self.addr[1],
                .A5 => self.addr[2],
                .B3 => self.addr[3],
                .B4 => self.addr[4],
                .C3 => self.addr[5],
                .C4 => self.addr[6],
                .D4 => self.addr[7],
                .F3 => self.addr[8],
                .F4 => self.addr[9],
                .G3 => self.addr[10],
                .G4 => self.addr[11],
                .H2 => self.addr[12],
                .H3 => self.addr[13],
                .H4 => self.addr[14],
                .H5 => self.addr[15],
                .E4 => if (self.addr.len > 16) self.addr[16] else .no_connect,

                .G1 => self.upper_data[0],
                .F2 => self.upper_data[1],
                .F1 => self.upper_data[2],
                .E2 => self.upper_data[3],
                .D2 => self.upper_data[4],
                .C1 => self.upper_data[5],
                .C2 => self.upper_data[6],
                .B1 => self.upper_data[7],

                .B6 => self.lower_data[0],
                .C5 => self.lower_data[1],
                .C6 => self.lower_data[2],
                .D5 => self.lower_data[3],
                .E5 => self.lower_data[4],
                .F6 => self.lower_data[5],
                .F5 => self.lower_data[6],
                .G6 => self.lower_data[7],

                .E6 => self.pwr.gnd[0],
                .D6 => self.pwr.p3v3[0],
                .D1 => self.pwr.gnd[1],
                .E1 => self.pwr.p3v3[1],

                .A6, .D3, .E3, .G2, .H1, .H6 => .no_connect,
            };
        }
    };

    if (Pkg == packages.SOJ_44 or Pkg == packages.TSOP_II_44) return struct {
        pub fn pin(self: Self, pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                39 => self.lower_byte_enable_low,
                40 => self.upper_byte_enable_low,

                41 => self.outpue_enable_low,
                6 => self.chip_enable_low,
                17 => self.write_enable_low,

                5 => self.addr[0],
                4 => self.addr[1],
                3 => self.addr[2],
                2 => self.addr[3],
                1 => self.addr[4],
                44 => self.addr[5],
                43 => self.addr[6],
                42 => self.addr[7],
                27 => self.addr[8],
                26 => self.addr[9],
                25 => self.addr[10],
                24 => self.addr[11],
                21 => self.addr[12],
                20 => self.addr[13],
                19 => self.addr[14],
                18 => self.addr[15],

                29 => self.upper_data[0],
                30 => self.upper_data[1],
                31 => self.upper_data[2],
                32 => self.upper_data[3],
                35 => self.upper_data[4],
                36 => self.upper_data[5],
                37 => self.upper_data[6],
                38 => self.upper_data[7],

                7 => self.lower_data[0],
                8 => self.lower_data[1],
                9 => self.lower_data[2],
                10 => self.lower_data[3],
                13 => self.lower_data[4],
                14 => self.lower_data[5],
                15 => self.lower_data[6],
                16 => self.lower_data[7],

                12 => self.pwr.gnd[0],
                11 => self.pwr.p3v3[0],
                34 => self.pwr.gnd[1],
                33 => self.pwr.p3v3[1],

                22 => if (self.addr.len > 16) self.addr[16] else .no_connect,
                23, 28 => .no_connect,
                else => unreachable,
            };
        }
    };

    @compileError("GSI 16b SRAM pinout is not known for " ++ @typeName(Pkg));
}


pub fn Async_8b(
    comptime addr_bits: comptime_int,
    comptime Power: type,
    comptime levels: type,
    comptime Pins_Provider: fn(comptime Self: type, comptime Pkg: type) type,
    comptime Pkg: type,
) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: Power = .{},
        data: [8]Net_ID = .{ .unset } ** 8,
        addr: [addr_bits]Net_ID = .{ .unset } ** addr_bits,
        chip_enable_low: Net_ID = .unset,
        write_enable_low: Net_ID = .unset,
        output_enable_low: Net_ID = .unset,

        pub const pin = Pins_Provider(@This(), Pkg).pin;

        const Validator_State = struct {
            mem: [1 << addr_bits]u8,
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    @memset(&state.mem, 0xAA);
                },
                .commit => {
                    try v.expect_valid(self.chip_enable_low, levels);
                    try v.expect_valid(self.write_enable_low, levels);
                    try v.expect_valid(self.output_enable_low, levels);

                    if (v.read_logic(self.chip_enable_low, levels) == false) {
                        try v.expect_valid(self.addr, levels);
                        try v.expect_valid(self.data, levels);

                        if (v.read_logic(self.write_enable_low, levels) == false) {
                            const addr = v.read_bus(self.addr, levels);
                            state.mem[addr] = @intCast(v.read_bus(self.data, levels));
                        }
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.chip_enable_low, levels) == false 
                        and v.read_logic(self.output_enable_low, levels) == false
                        and v.read_logic(self.write_enable_low, levels) == true
                    ) {
                        const addr = v.read_bus(self.addr, levels);
                        try v.drive_bus(self.data, state.mem[addr], levels);
                    }
                },
            }
        }
    };
}

pub fn Async_16b(
    comptime addr_bits: comptime_int,
    comptime Power: type,
    comptime levels: type,
    comptime Pins_Provider: fn(comptime Self: type, comptime Pkg: type) type,
    comptime Pkg: type,
) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        pwr: Power = .{},
        lower_data: [8]Net_ID = .{ .unset } ** 8,
        upper_data: [8]Net_ID = .{ .unset } ** 8,
        addr: [addr_bits]Net_ID = .{ .unset } ** addr_bits,
        chip_enable_low: Net_ID = .unset,
        lower_byte_enable_low: Net_ID = .unset,
        upper_byte_enable_low: Net_ID = .unset,
        write_enable_low: Net_ID = .unset,
        output_enable_low: Net_ID = .unset,

        pub const pin = Pins_Provider(@This(), Pkg).pin;

        const Validator_State = struct {
            mem: [1 << addr_bits]Word,

            const Word = struct {
                lower: u8,
                upper: u8,
            };
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    @memset(&state.mem, .{ .lower = 0xAA, .upper = 0xAA });
                },
                .commit => {
                    try v.expect_valid(self.chip_enable_low, levels);
                    try v.expect_valid(self.lower_byte_enable_low, levels);
                    try v.expect_valid(self.upper_byte_enable_low, levels);
                    try v.expect_valid(self.write_enable_low, levels);
                    try v.expect_valid(self.output_enable_low, levels);

                    if (v.read_logic(self.chip_enable_low, levels) == false) {
                        try v.expect_valid(self.addr, levels);

                        const lb = v.read_logic(self.lower_byte_enable_low, levels) == false;
                        const ub = v.read_logic(self.upper_byte_enable_low, levels) == false;

                        if (lb) try v.expect_valid(self.lower_data, levels);
                        if (ub) try v.expect_valid(self.upper_data, levels);

                        if (v.read_logic(self.write_enable_low, levels) == false) {
                            const addr = v.read_bus(self.addr, levels);
                            if (lb) state.mem[addr].lower = @intCast(v.read_bus(self.lower_data, levels));
                            if (ub) state.mem[addr].upper = @intCast(v.read_bus(self.upper_data, levels));
                        }
                    }
                },
                .nets_only => {
                    if (v.read_logic(self.chip_enable_low, levels) == false 
                        and v.read_logic(self.output_enable_low, levels) == false
                        and v.read_logic(self.write_enable_low, levels) == true
                    ) {
                        const addr = v.read_bus(self.addr, levels);
                        const word = state.mem[addr];

                        if (v.read_logic(self.lower_byte_enable_low, levels) == false) {
                            try v.drive_bus(self.lower_data, word.lower, levels);
                        }
                        if (v.read_logic(self.upper_byte_enable_low, levels) == false) {
                            try v.drive_bus(self.upper_data, word.upper, levels);
                        }
                    }
                },
            }
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const packages = @import("../packages.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
