pub fn CY7C0xx(
    comptime byte_bits: comptime_int,
    comptime addr_bits: comptime_int,
    comptime pwr: Net_ID,
    comptime Decoupler: type,
    comptime levels: type,
    comptime Pkg: type,
) type {
    std.debug.assert(addr_bits >= 12);
    std.debug.assert(byte_bits == 8 or byte_bits == 9);
    if (Pkg == packages.PLCC_84M) {
        std.debug.assert(byte_bits == 8);
        std.debug.assert(addr_bits <= 13);
    } else std.debug.assert(Pkg == packages.TQFP_100_14mm);
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        master: Net_ID = .unset,
        left: Port = .{},
        right: Port = .{},
        pwr: Power = .{},
        remap_lower_data: [byte_bits]u4 = Part.identity_remap(u4, byte_bits),
        remap_upper_data: [byte_bits]u4 = Part.identity_remap(u4, byte_bits),
        remap_addr: [addr_bits]u5 = Part.identity_remap(u5, addr_bits),

        pub const Port = struct {
            lower_data: [byte_bits]Net_ID = @splat(.unset),
            upper_data: [byte_bits]Net_ID = @splat(.unset),
            addr: [addr_bits]Net_ID = @splat(.unset),

            ce: if (addr_bits >= 15) Net_ID else void = if (addr_bits >= 15) .unset else {},
            n_ce: Net_ID = .unset,
            n_lower_byte_enable: Net_ID = .unset,
            n_upper_byte_enable: Net_ID = .unset,
            n_we: Net_ID = .unset,
            n_oe: Net_ID = .unset,
            n_semaphore_enable: Net_ID = .unset,
            n_interrupt: Net_ID = .unset,
            n_busy: Net_ID = .unset,
        };

        pub const Power = if (addr_bits < 15)
            power.Multi(3, 6, pwr, Decoupler)
            else switch (byte_bits) {
                8 => power.Multi(3, 8, pwr, Decoupler),
                9 => power.Multi(4, 9, pwr, Decoupler),
                else => unreachable,
            };

        pub fn check_config(self: @This()) !void {
            var mapped_lower_data_bits: [byte_bits]bool = .{ false } ** byte_bits;
            for (self.remap_lower_data) |logical| {
                mapped_lower_data_bits[logical] = true;
            }
            for (0.., mapped_lower_data_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical lower_data bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
            var mapped_upper_data_bits: [byte_bits]bool = .{ false } ** byte_bits;
            for (self.remap_upper_data) |logical| {
                mapped_upper_data_bits[logical] = true;
            }
            for (0.., mapped_upper_data_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical upper_data bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }

            var mapped_addr_bits: [addr_bits]bool = .{ false } ** addr_bits;
            for (self.remap_addr) |logical| {
                mapped_addr_bits[logical] = true;
            }
            for (0.., mapped_addr_bits) |logical_bit, mapped| {
                if (!mapped) {
                    log.err("{s}: No physical addr bit assigned to logical bit {}", .{ @typeName(@This()), logical_bit });
                    return error.InvalidRemap;
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (Pkg) {
                packages.TQFP_100 => if (addr_bits >= 15 and byte_bits == 8) switch (@intFromEnum(pin_id)) {
                    // CY7C027/CY7C028
                    87 => self.master,

                    89 => self.left.n_busy,
                    90 => self.left.n_interrupt,
                    10 => self.left.n_lower_byte_enable,
                    11 => self.left.n_upper_byte_enable,
                    12 => self.left.n_ce,
                    13 => self.left.ce,
                    14 => self.left.n_semaphore_enable,
                    16 => self.left.n_we,
                    17 => self.left.n_oe,

                    59 => self.right.n_oe,
                    60 => self.right.n_we,
                    62 => self.right.n_semaphore_enable,
                    63 => self.right.ce,
                    64 => self.right.n_ce,
                    65 => self.right.n_upper_byte_enable,
                    66 => self.right.n_lower_byte_enable,
                    85 => self.right.n_interrupt,
                    86 => self.right.n_busy,

                    92 => self.left.addr[self.remap_addr[0]],
                    93 => self.left.addr[self.remap_addr[1]],
                    94 => self.left.addr[self.remap_addr[2]],
                    95 => self.left.addr[self.remap_addr[3]],
                    96 => self.left.addr[self.remap_addr[4]],
                    97 => self.left.addr[self.remap_addr[5]],
                    98 => self.left.addr[self.remap_addr[6]],
                    99 => self.left.addr[self.remap_addr[7]],
                    100 => self.left.addr[self.remap_addr[8]],
                    1 => self.left.addr[self.remap_addr[9]],
                    2 => self.left.addr[self.remap_addr[10]],
                    3 => self.left.addr[self.remap_addr[11]],
                    4 => self.left.addr[self.remap_addr[12]],
                    5 => self.left.addr[self.remap_addr[13]],
                    6 => self.left.addr[self.remap_addr[14]],
                    7 => switch (addr_bits) {
                        15 => .no_connect,
                        16 => self.left.addr[self.remap_addr[15]],
                        else => unreachable,
                    },

                    84 => self.right.addr[self.remap_addr[0]],
                    83 => self.right.addr[self.remap_addr[1]],
                    82 => self.right.addr[self.remap_addr[2]],
                    81 => self.right.addr[self.remap_addr[3]],
                    80 => self.right.addr[self.remap_addr[4]],
                    79 => self.right.addr[self.remap_addr[5]],
                    78 => self.right.addr[self.remap_addr[6]],
                    77 => self.right.addr[self.remap_addr[7]],
                    76 => self.right.addr[self.remap_addr[8]],
                    75 => self.right.addr[self.remap_addr[9]],
                    74 => self.right.addr[self.remap_addr[10]],
                    73 => self.right.addr[self.remap_addr[11]],
                    72 => self.right.addr[self.remap_addr[12]],
                    71 => self.right.addr[self.remap_addr[13]],
                    70 => self.right.addr[self.remap_addr[14]],
                    69 => switch (addr_bits) {
                        15 => .no_connect,
                        16 => self.right.addr[self.remap_addr[15]],
                        else => unreachable,
                    },

                    37 => self.left.lower_data[self.remap_lower_data[0]],
                    36 => self.left.lower_data[self.remap_lower_data[1]],
                    34 => self.left.lower_data[self.remap_lower_data[2]],
                    33 => self.left.lower_data[self.remap_lower_data[3]],
                    32 => self.left.lower_data[self.remap_lower_data[4]],
                    31 => self.left.lower_data[self.remap_lower_data[5]],
                    30 => self.left.lower_data[self.remap_lower_data[6]],
                    29 => self.left.lower_data[self.remap_lower_data[7]],

                    27 => self.left.upper_data[self.remap_upper_data[0]],
                    26 => self.left.upper_data[self.remap_upper_data[1]],
                    25 => self.left.upper_data[self.remap_upper_data[2]],
                    24 => self.left.upper_data[self.remap_upper_data[3]],
                    23 => self.left.upper_data[self.remap_upper_data[4]],
                    22 => self.left.upper_data[self.remap_upper_data[5]],
                    21 => self.left.upper_data[self.remap_upper_data[6]],
                    20 => self.left.upper_data[self.remap_upper_data[7]],

                    39 => self.right.lower_data[self.remap_lower_data[0]],
                    40 => self.right.lower_data[self.remap_lower_data[1]],
                    41 => self.right.lower_data[self.remap_lower_data[2]],
                    42 => self.right.lower_data[self.remap_lower_data[3]],
                    43 => self.right.lower_data[self.remap_lower_data[4]],
                    44 => self.right.lower_data[self.remap_lower_data[5]],
                    45 => self.right.lower_data[self.remap_lower_data[6]],
                    47 => self.right.lower_data[self.remap_lower_data[7]],

                    48 => self.right.upper_data[self.remap_upper_data[0]],
                    49 => self.right.upper_data[self.remap_upper_data[1]],
                    51 => self.right.upper_data[self.remap_upper_data[2]],
                    52 => self.right.upper_data[self.remap_upper_data[3]],
                    53 => self.right.upper_data[self.remap_upper_data[4]],
                    54 => self.right.upper_data[self.remap_upper_data[5]],
                    55 => self.right.upper_data[self.remap_upper_data[6]],
                    56 => self.right.upper_data[self.remap_upper_data[7]],

                    18 => self.pwr.gnd[0],
                    19 => self.pwr.gnd[1],
                    35 => self.pwr.gnd[2],
                    38 => self.pwr.gnd[3],
                    57 => self.pwr.gnd[4],
                    58 => self.pwr.gnd[5],
                    61 => self.pwr.gnd[6],
                    88 => self.pwr.gnd[7],
                    
                    15 => @field(self.pwr, @tagName(pwr))[0],
                    28 => @field(self.pwr, @tagName(pwr))[1],
                    46 => @field(self.pwr, @tagName(pwr))[2],

                    8, 9, 50, 67, 68, 91 => .no_connect,
                    else => unreachable,
                } else if (addr_bits >= 15 and byte_bits == 9) switch (@intFromEnum(pin_id)) {
                    // CY7C037/CY7C038
                    86 => self.master,

                    90 => self.left.n_busy,
                    91 => self.left.n_interrupt,
                    8 => self.left.n_lower_byte_enable,
                    9 => self.left.n_upper_byte_enable,
                    10 => self.left.n_ce,
                    11 => self.left.ce,
                    12 => self.left.n_semaphore_enable,
                    13 => self.left.n_we,
                    14 => self.left.n_oe,

                    60 => self.right.n_oe,
                    62 => self.right.n_we,
                    63 => self.right.n_semaphore_enable,
                    64 => self.right.ce,
                    65 => self.right.n_ce,
                    66 => self.right.n_upper_byte_enable,
                    67 => self.right.n_lower_byte_enable,
                    84 => self.right.n_interrupt,
                    85 => self.right.n_busy,

                    92 => self.left.addr[self.remap_addr[0]],
                    93 => self.left.addr[self.remap_addr[1]],
                    94 => self.left.addr[self.remap_addr[2]],
                    95 => self.left.addr[self.remap_addr[3]],
                    96 => self.left.addr[self.remap_addr[4]],
                    97 => self.left.addr[self.remap_addr[5]],
                    98 => self.left.addr[self.remap_addr[6]],
                    99 => self.left.addr[self.remap_addr[7]],
                    100 => self.left.addr[self.remap_addr[8]],
                    1 => self.left.addr[self.remap_addr[9]],
                    2 => self.left.addr[self.remap_addr[10]],
                    3 => self.left.addr[self.remap_addr[11]],
                    4 => self.left.addr[self.remap_addr[12]],
                    5 => self.left.addr[self.remap_addr[13]],
                    6 => self.left.addr[self.remap_addr[14]],
                    7 => switch (addr_bits) {
                        15 => .no_connect,
                        16 => self.left.addr[self.remap_addr[15]],
                        else => unreachable,
                    },

                    83 => self.right.addr[self.remap_addr[0]],
                    82 => self.right.addr[self.remap_addr[1]],
                    81 => self.right.addr[self.remap_addr[2]],
                    80 => self.right.addr[self.remap_addr[3]],
                    79 => self.right.addr[self.remap_addr[4]],
                    78 => self.right.addr[self.remap_addr[5]],
                    77 => self.right.addr[self.remap_addr[6]],
                    76 => self.right.addr[self.remap_addr[7]],
                    75 => self.right.addr[self.remap_addr[8]],
                    74 => self.right.addr[self.remap_addr[9]],
                    73 => self.right.addr[self.remap_addr[10]],
                    72 => self.right.addr[self.remap_addr[11]],
                    71 => self.right.addr[self.remap_addr[12]],
                    70 => self.right.addr[self.remap_addr[13]],
                    69 => self.right.addr[self.remap_addr[14]],
                    68 => switch (addr_bits) {
                        15 => .no_connect,
                        16 => self.right.addr[self.remap_addr[15]],
                        else => unreachable,
                    },

                    37 => self.left.lower_data[self.remap_lower_data[0]],
                    36 => self.left.lower_data[self.remap_lower_data[1]],
                    34 => self.left.lower_data[self.remap_lower_data[2]],
                    33 => self.left.lower_data[self.remap_lower_data[3]],
                    32 => self.left.lower_data[self.remap_lower_data[4]],
                    31 => self.left.lower_data[self.remap_lower_data[5]],
                    30 => self.left.lower_data[self.remap_lower_data[6]],
                    29 => self.left.lower_data[self.remap_lower_data[7]],
                    27 => self.left.lower_data[self.remap_lower_data[8]],

                    26 => self.left.upper_data[self.remap_upper_data[0]],
                    25 => self.left.upper_data[self.remap_upper_data[1]],
                    24 => self.left.upper_data[self.remap_upper_data[2]],
                    23 => self.left.upper_data[self.remap_upper_data[3]],
                    22 => self.left.upper_data[self.remap_upper_data[4]],
                    21 => self.left.upper_data[self.remap_upper_data[5]],
                    20 => self.left.upper_data[self.remap_upper_data[6]],
                    18 => self.left.upper_data[self.remap_upper_data[7]],
                    17 => self.left.upper_data[self.remap_upper_data[8]],

                    39 => self.right.lower_data[self.remap_lower_data[0]],
                    40 => self.right.lower_data[self.remap_lower_data[1]],
                    41 => self.right.lower_data[self.remap_lower_data[2]],
                    42 => self.right.lower_data[self.remap_lower_data[3]],
                    43 => self.right.lower_data[self.remap_lower_data[4]],
                    44 => self.right.lower_data[self.remap_lower_data[5]],
                    45 => self.right.lower_data[self.remap_lower_data[6]],
                    47 => self.right.lower_data[self.remap_lower_data[7]],
                    48 => self.right.lower_data[self.remap_lower_data[8]],

                    49 => self.right.upper_data[self.remap_upper_data[0]],
                    50 => self.right.upper_data[self.remap_upper_data[1]],
                    51 => self.right.upper_data[self.remap_upper_data[2]],
                    52 => self.right.upper_data[self.remap_upper_data[3]],
                    53 => self.right.upper_data[self.remap_upper_data[4]],
                    54 => self.right.upper_data[self.remap_upper_data[5]],
                    55 => self.right.upper_data[self.remap_upper_data[6]],
                    56 => self.right.upper_data[self.remap_upper_data[7]],
                    58 => self.right.upper_data[self.remap_upper_data[8]],

                    16 => self.pwr.gnd[0],
                    19 => self.pwr.gnd[1],
                    38 => self.pwr.gnd[2],
                    35 => self.pwr.gnd[3],
                    57 => self.pwr.gnd[4],
                    59 => self.pwr.gnd[5],
                    61 => self.pwr.gnd[6],
                    88 => self.pwr.gnd[7],
                    89 => self.pwr.gnd[8],
                    
                    15 => @field(self.pwr, @tagName(pwr))[0],
                    28 => @field(self.pwr, @tagName(pwr))[1],
                    46 => @field(self.pwr, @tagName(pwr))[2],
                    87 => @field(self.pwr, @tagName(pwr))[3],
                    else => unreachable,
                } else switch (@intFromEnum(pin_id)) {
                    // CY7C024/CY7C0241/CY7C025/CY7C0251/CY7C0246
                    62 => self.master,

                    64 => self.left.n_busy,
                    65 => self.left.n_interrupt,
                    83 => self.left.n_lower_byte_enable,
                    84 => self.left.n_upper_byte_enable,
                    85 => self.left.n_ce,
                    86 => self.left.n_semaphore_enable,
                    87 => self.left.n_we,
                    89 => self.left.n_oe,

                    36 => self.right.n_oe,
                    37 => self.right.n_we,
                    39 => self.right.n_semaphore_enable,
                    40 => self.right.n_ce,
                    41 => self.right.n_upper_byte_enable,
                    42 => self.right.n_lower_byte_enable,
                    60 => self.right.n_interrupt,
                    61 => self.right.n_busy,

                    66 => self.left.addr[self.remap_addr[0]],
                    67 => self.left.addr[self.remap_addr[1]],
                    68 => self.left.addr[self.remap_addr[2]],
                    69 => self.left.addr[self.remap_addr[3]],
                    70 => self.left.addr[self.remap_addr[4]],
                    71 => self.left.addr[self.remap_addr[5]],
                    72 => if (addr_bits == 14) self.left.addr[self.remap_addr[6]] else .no_connect,
                    76 => self.left.addr[self.remap_addr[if (addr_bits == 14) 7 else 6]],
                    77 => self.left.addr[self.remap_addr[if (addr_bits == 14) 8 else 7]],
                    78 => self.left.addr[self.remap_addr[if (addr_bits == 14) 9 else 8]],
                    79 => self.left.addr[self.remap_addr[if (addr_bits == 14) 10 else 9]],
                    80 => self.left.addr[self.remap_addr[if (addr_bits == 14) 11 else 10]],
                    81 => self.left.addr[self.remap_addr[if (addr_bits == 14) 12 else 11]],
                    82 => switch (addr_bits) {
                        12 => .no_connect,
                        13 => self.left.addr[self.remap_addr[12]],
                        14 => self.left.addr[self.remap_addr[13]],
                        else => unreachable,
                    },

                    59 => self.right.addr[self.remap_addr[0]],
                    58 => self.right.addr[self.remap_addr[1]],
                    57 => self.right.addr[self.remap_addr[2]],
                    56 => self.right.addr[self.remap_addr[3]],
                    55 => self.right.addr[self.remap_addr[4]],
                    54 => if (addr_bits == 14) self.right.addr[self.remap_addr[5]] else .no_connect,
                    50 => self.right.addr[self.remap_addr[if (addr_bits == 14) 6 else 5]],
                    49 => self.right.addr[self.remap_addr[if (addr_bits == 14) 7 else 6]],
                    48 => self.right.addr[self.remap_addr[if (addr_bits == 14) 8 else 7]],
                    47 => self.right.addr[self.remap_addr[if (addr_bits == 14) 9 else 8]],
                    46 => self.right.addr[self.remap_addr[if (addr_bits == 14) 10 else 9]],
                    45 => self.right.addr[self.remap_addr[if (addr_bits == 14) 11 else 10]],
                    44 => self.right.addr[self.remap_addr[if (addr_bits == 14) 12 else 11]],
                    43 => switch (addr_bits) {
                        12 => .no_connect,
                        13 => self.right.addr[self.remap_addr[12]],
                        14 => self.right.addr[self.remap_addr[13]],
                        else => unreachable,
                    },

                    90 => self.left.lower_data[self.remap_lower_data[0]],
                    91 => self.left.lower_data[self.remap_lower_data[1]],
                    93 => self.left.lower_data[self.remap_lower_data[2]],
                    94 => self.left.lower_data[self.remap_lower_data[3]],
                    95 => self.left.lower_data[self.remap_lower_data[4]],
                    96 => self.left.lower_data[self.remap_lower_data[5]],
                    97 => self.left.lower_data[self.remap_lower_data[6]],
                    98 => self.left.lower_data[self.remap_lower_data[7]],
                    3 => if (byte_bits == 9) self.left.lower_data[self.remap_lower_data[8]] else .no_connect,

                    99 => self.left.upper_data[self.remap_upper_data[0]],
                    100 => self.left.upper_data[self.remap_upper_data[1]],
                    5 => self.left.upper_data[self.remap_upper_data[2]],
                    6 => self.left.upper_data[self.remap_upper_data[3]],
                    7 => self.left.upper_data[self.remap_upper_data[4]],
                    8 => self.left.upper_data[self.remap_upper_data[5]],
                    10 => self.left.upper_data[self.remap_upper_data[6]],
                    11 => self.left.upper_data[self.remap_upper_data[7]],
                    4 => if (byte_bits == 9) self.left.upper_data[self.remap_upper_data[8]] else .no_connect,

                    14 => self.right.lower_data[self.remap_lower_data[0]],
                    15 => self.right.lower_data[self.remap_lower_data[1]],
                    16 => self.right.lower_data[self.remap_lower_data[2]],
                    18 => self.right.lower_data[self.remap_lower_data[3]],
                    19 => self.right.lower_data[self.remap_lower_data[4]],
                    20 => self.right.lower_data[self.remap_lower_data[5]],
                    21 => self.right.lower_data[self.remap_lower_data[6]],
                    26 => self.right.lower_data[self.remap_lower_data[7]],
                    22 => if (byte_bits == 9) self.right.lower_data[self.remap_lower_data[8]] else .no_connect,

                    27 => self.right.upper_data[self.remap_upper_data[0]],
                    28 => self.right.upper_data[self.remap_upper_data[1]],
                    29 => self.right.upper_data[self.remap_upper_data[2]],
                    30 => self.right.upper_data[self.remap_upper_data[3]],
                    31 => self.right.upper_data[self.remap_upper_data[4]],
                    32 => self.right.upper_data[self.remap_upper_data[5]],
                    33 => self.right.upper_data[self.remap_upper_data[6]],
                    35 => self.right.upper_data[self.remap_upper_data[7]],
                    23 => if (byte_bits == 9) self.right.upper_data[self.remap_upper_data[8]] else .no_connect,

                    9 => self.pwr.gnd[0],
                    13 => self.pwr.gnd[1],
                    34 => self.pwr.gnd[2],
                    38 => self.pwr.gnd[3],
                    63 => self.pwr.gnd[4],
                    92 => self.pwr.gnd[5],
                    
                    12 => @field(self.pwr, @tagName(pwr))[0],
                    17 => @field(self.pwr, @tagName(pwr))[1],
                    88 => @field(self.pwr, @tagName(pwr))[2],

                    1, 2, 24, 25, 51, 52, 53, 73, 74, 75 => .no_connect,
                },
                packages.PLCC_84 => switch (@intFromEnum(pin_id)) {
                    // CY7C024/CY7C025
                    63 => self.master,

                    65 => self.left.n_busy,
                    66 => self.left.n_interrupt,
                    80 => self.left.n_lower_byte_enable,
                    81 => self.left.n_upper_byte_enable,
                    82 => self.left.n_ce,
                    83 => self.left.n_semaphore_enable,
                    84 => self.left.n_we,
                    2 => self.left.n_oe,

                    41 => self.right.n_oe,
                    42 => self.right.n_we,
                    44 => self.right.n_semaphore_enable,
                    45 => self.right.n_ce,
                    46 => self.right.n_upper_byte_enable,
                    47 => self.right.n_lower_byte_enable,
                    61 => self.right.n_interrupt,
                    62 => self.right.n_busy,

                    67 => self.left.addr[self.remap_addr[0]],
                    68 => self.left.addr[self.remap_addr[1]],
                    69 => self.left.addr[self.remap_addr[2]],
                    70 => self.left.addr[self.remap_addr[3]],
                    71 => self.left.addr[self.remap_addr[4]],
                    72 => self.left.addr[self.remap_addr[5]],
                    73 => self.left.addr[self.remap_addr[6]],
                    74 => self.left.addr[self.remap_addr[7]],
                    75 => self.left.addr[self.remap_addr[8]],
                    76 => self.left.addr[self.remap_addr[9]],
                    77 => self.left.addr[self.remap_addr[10]],
                    78 => self.left.addr[self.remap_addr[11]],
                    79 => if (addr_bits > 12) self.left.addr[self.remap_addr[12]] else .no_connect,

                    60 => self.right.addr[self.remap_addr[0]],
                    59 => self.right.addr[self.remap_addr[1]],
                    58 => self.right.addr[self.remap_addr[2]],
                    57 => self.right.addr[self.remap_addr[3]],
                    56 => self.right.addr[self.remap_addr[4]],
                    55 => self.right.addr[self.remap_addr[5]],
                    54 => self.right.addr[self.remap_addr[6]],
                    53 => self.right.addr[self.remap_addr[7]],
                    52 => self.right.addr[self.remap_addr[8]],
                    51 => self.right.addr[self.remap_addr[9]],
                    50 => self.right.addr[self.remap_addr[10]],
                    49 => self.right.addr[self.remap_addr[11]],
                    48 => if (addr_bits > 12) self.right.addr[self.remap_addr[12]] else .no_connect,

                    3 => self.left.lower_data[self.remap_lower_data[0]],
                    4 => self.left.lower_data[self.remap_lower_data[1]],
                    6 => self.left.lower_data[self.remap_lower_data[2]],
                    7 => self.left.lower_data[self.remap_lower_data[3]],
                    8 => self.left.lower_data[self.remap_lower_data[4]],
                    9 => self.left.lower_data[self.remap_lower_data[5]],
                    10 => self.left.lower_data[self.remap_lower_data[6]],
                    11 => self.left.lower_data[self.remap_lower_data[7]],

                    12 => self.left.upper_data[self.remap_upper_data[0]],
                    13 => self.left.upper_data[self.remap_upper_data[1]],
                    14 => self.left.upper_data[self.remap_upper_data[2]],
                    15 => self.left.upper_data[self.remap_upper_data[3]],
                    16 => self.left.upper_data[self.remap_upper_data[4]],
                    17 => self.left.upper_data[self.remap_upper_data[5]],
                    19 => self.left.upper_data[self.remap_upper_data[6]],
                    20 => self.left.upper_data[self.remap_upper_data[7]],

                    23 => self.right.lower_data[self.remap_lower_data[0]],
                    24 => self.right.lower_data[self.remap_lower_data[1]],
                    25 => self.right.lower_data[self.remap_lower_data[2]],
                    27 => self.right.lower_data[self.remap_lower_data[3]],
                    28 => self.right.lower_data[self.remap_lower_data[4]],
                    29 => self.right.lower_data[self.remap_lower_data[5]],
                    30 => self.right.lower_data[self.remap_lower_data[6]],
                    31 => self.right.lower_data[self.remap_lower_data[7]],

                    32 => self.right.upper_data[self.remap_upper_data[0]],
                    33 => self.right.upper_data[self.remap_upper_data[1]],
                    34 => self.right.upper_data[self.remap_upper_data[2]],
                    35 => self.right.upper_data[self.remap_upper_data[3]],
                    36 => self.right.upper_data[self.remap_upper_data[4]],
                    37 => self.right.upper_data[self.remap_upper_data[5]],
                    38 => self.right.upper_data[self.remap_upper_data[6]],
                    40 => self.right.upper_data[self.remap_upper_data[7]],

                    5 => self.pwr.gnd[0],
                    18 => self.pwr.gnd[1],
                    22 => self.pwr.gnd[2],
                    39 => self.pwr.gnd[3],
                    43 => self.pwr.gnd[4],
                    64 => self.pwr.gnd[5],
                    1 => @field(self.pwr, @tagName(pwr))[0],
                    21 => @field(self.pwr, @tagName(pwr))[1],
                    26 => @field(self.pwr, @tagName(pwr))[2],
                },
            };
        }

        const Validator_State = struct {
            left_mutex_addr: usize,
            right_mutex_addr: usize,
            left_interrupt: bool,
            right_interrupt: bool,
            left_semaphores: [8]Semaphore_State,
            right_semaphores: [8]Semaphore_State,
            left_busy: bool,  // not really state; just a copy of the busy signal we're
            right_busy: bool, // outputting in case it's assigned to .no_connect
            mem: [1 << addr_bits]Word,

            const Word = packed struct {
                lower: Byte,
                upper: Byte,
            };
            const Byte = switch (byte_bits) {
                8 => u8,
                9 => u9,
                else => unreachable,
            };
            const Semaphore_State = enum {
                idle,
                pending,
                owned_masked, // was pending when the current read cycle began, but the other side released it during the read and it is now owned by this side
                owned,
            };
        };

        pub fn validate(self: @This(), v: *Validator, state: *Validator_State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    @memset(&state.mem, .{ .lower = 0xAA, .upper = 0xAA });
                    state.left_mutex_addr = std.math.maxInt(usize);
                    state.right_mutex_addr = std.math.maxInt(usize);
                    state.left_interrupt = false;
                    state.right_interrupt = false;
                    @memset(&state.left_semaphores, .idle);
                    @memset(&state.right_semaphores, .idle);
                },
                .commit => {
                    try v.expect_valid(self.master, levels);
                    if (v.read_logic(self.master, levels) == false) {
                        try v.expect_valid(self.left.n_busy, levels);
                        try v.expect_valid(self.right.n_busy, levels);
                    }

                    try write_port(self.left, v, .{
                        .busy = state.left_busy,
                        .mutex_addr = &state.left_mutex_addr,
                        .interrupt_addr = state.mem.len - 2,
                        .other_interrupt_addr = state.mem.len - 1,
                        .interrupt_flag = &state.left_interrupt,
                        .other_interrupt_flag = &state.right_interrupt,
                        .semaphores = &state.left_semaphores,
                        .other_semaphores = &state.right_semaphores,
                        .mem = &state.mem,
                    });

                    try write_port(self.right, v, .{
                        .busy = state.right_busy,
                        .mutex_addr = &state.right_mutex_addr,
                        .interrupt_addr = state.mem.len - 1,
                        .other_interrupt_addr = state.mem.len - 2,
                        .interrupt_flag = &state.right_interrupt,
                        .other_interrupt_flag = &state.left_interrupt,
                        .semaphores = &state.right_semaphores,
                        .other_semaphores = &state.left_semaphores,
                        .mem = &state.mem,
                    });
                
                    try finalize_semaphores(self.left, v, &state.left_semaphores);
                    try finalize_semaphores(self.right, v, &state.right_semaphores);

                    const left_ce = read_port_ce(self.left, v);
                    const right_ce = read_port_ce(self.right, v);

                    _ = try read_port(mode, self.left, v, left_ce, &state.mem, state.left_semaphores);
                    _ = try read_port(mode, self.right, v, right_ce, &state.mem, state.right_semaphores);

                    if (v.read_logic(self.master, levels)) {
                        try v.expect_output_valid(self.left.n_busy, !state.left_busy, levels);
                        try v.expect_output_valid(self.right.n_busy, !state.right_busy, levels);
                    }

                    try v.expect_output_valid(self.left.n_interrupt, !state.left_interrupt, levels);
                    try v.expect_output_valid(self.right.n_interrupt, !state.right_interrupt, levels);
                },
                .nets_only => {
                    const left_ce = read_port_ce(self.left, v);
                    const right_ce = read_port_ce(self.right, v);

                    const maybe_left_addr = try read_port(mode, self.left, v, left_ce, &state.mem, state.left_semaphores);
                    const maybe_right_addr = try read_port(mode, self.right, v, right_ce, &state.mem, state.right_semaphores);

                    if (v.read_logic(self.master, levels)) {
                        state.left_busy = false;
                        state.right_busy = false;
                        if (left_ce and right_ce) {
                            const left_a = maybe_left_addr orelse v.read_bus(self.left.addr, levels);
                            const right_a = maybe_right_addr orelse v.read_bus(self.right.addr, levels);

                            if (left_a == right_a) {
                                if (state.right_mutex_addr == right_a) {
                                    state.left_busy = true;
                                } else {
                                    state.right_busy = true;
                                }
                            }
                        }
                        try v.drive_logic(self.left.n_busy, !state.left_busy, levels);
                        try v.drive_logic(self.right.n_busy, !state.right_busy, levels);
                    }

                    try v.drive_logic(self.left.n_interrupt, !state.left_interrupt, levels);
                    try v.drive_logic(self.right.n_interrupt, !state.right_interrupt, levels);
                },
            }
        }

        fn read_port_ce(port: Port, v: *Validator) bool {
            return v.read_logic(port.n_ce, levels) == false and (@TypeOf(port.ce) == void or v.read_logic(port.ce, levels) == true);
        }

        fn read_port(mode: Validator.Update_Mode, port: Port, v: *Validator, ce: bool, mem: *const [1 << addr_bits]Validator_State.Word, semaphores: [8]Validator_State.Semaphore_State) !?usize {
            var addr: ?usize = null;
            if (ce
                and v.read_logic(port.n_oe, levels) == false
                and v.read_logic(port.n_we, levels) == true
            ) {
                addr = v.read_bus(port.addr, levels);
                const word = mem[addr.?];

                if (v.read_logic(port.n_lower_byte_enable, levels) == false) {
                    switch (mode) {
                        .commit => try v.expect_output_valid(port.lower_data, word.lower, levels),
                        else => try v.drive_bus(port.lower_data, word.lower, levels),
                    }
                }
                if (v.read_logic(port.n_upper_byte_enable, levels) == false) {
                    switch (mode) {
                        .commit => try v.expect_output_valid(port.upper_data, word.upper, levels),
                        else => try v.drive_bus(port.upper_data, word.upper, levels),
                    }
                }
            } else if (v.read_logic(port.n_ce, levels) == true
                and v.read_logic(port.n_semaphore_enable, levels) == false
                and v.read_logic(port.n_oe, levels) == false
                and v.read_logic(port.n_we, levels) == true
            ) {
                const sem_addr = v.read_bus(port.addr[0..2], levels);
                const sem = semaphores[sem_addr];

                if (v.read_logic(port.n_lower_byte_enable, levels) == false) {
                    const value: u16 = if (sem == .owned) 0 else 0x1FF;
                    switch (mode) {
                        .commit => try v.expect_output_valid(port.lower_data, value, levels),
                        else => try v.drive_bus(port.lower_data, value, levels),
                    }
                }
                if (v.read_logic(port.n_upper_byte_enable, levels) == false) {
                    const value: u16 = if (sem == .owned) 0 else 0x1FF;
                    switch (mode) {
                        .commit => try v.expect_output_valid(port.upper_data, value, levels),
                        else => try v.drive_bus(port.upper_data, value, levels),
                    }
                }
            }

            return addr;
        }

        fn is_busy(port: Port, v: *Validator, internal: bool) bool {
            if (port.n_busy == .no_connect or port.n_busy == .unset) return internal;
            return v.read_logic(port.n_busy, levels) == false;
        }

        const Write_Port_Params = struct {
            busy: bool,
            mutex_addr: *usize,
            interrupt_addr: usize,
            other_interrupt_addr: usize,
            interrupt_flag: *bool,
            other_interrupt_flag: *bool,
            semaphores: *[8]Validator_State.Semaphore_State,
            other_semaphores: *[8]Validator_State.Semaphore_State,
            mem: *[1 << addr_bits]Validator_State.Word
        };
        fn write_port(port: Port, v: *Validator, p: Write_Port_Params) !void {
            if (@TypeOf(port.ce) != void) {
                try v.expect_valid(port.ce, levels);
            }
            try v.expect_valid(port.n_ce, levels);
            try v.expect_valid(port.n_lower_byte_enable, levels);
            try v.expect_valid(port.n_upper_byte_enable, levels);
            try v.expect_valid(port.n_we, levels);
            try v.expect_valid(port.n_oe, levels);
            try v.expect_valid(port.n_semaphore_enable, levels);

            var new_mutex_addr: usize = std.math.maxInt(usize);

            if (read_port_ce(port, v)) {
                try v.expect_valid(port.addr, levels);

                const lb = v.read_logic(port.n_lower_byte_enable, levels) == false;
                const ub = v.read_logic(port.n_upper_byte_enable, levels) == false;

                if (lb) try v.expect_valid(port.lower_data, levels);
                if (ub) try v.expect_valid(port.upper_data, levels);

                if (!is_busy(port, v, p.busy)) {
                    if (v.read_logic(port.n_we, levels) == false) {
                        new_mutex_addr = v.read_bus(port.addr, levels);

                        if (lb) {
                            const data = v.read_bus(port.lower_data, levels);
                            p.mem[new_mutex_addr].lower = @intCast(data);
                        }
                        if (ub) {
                            const data = v.read_bus(port.upper_data, levels);
                            p.mem[new_mutex_addr].upper = @intCast(data);
                        }

                        if (new_mutex_addr == p.other_interrupt_addr and !p.other_interrupt_flag.*) {
                            p.other_interrupt_flag.* = true;
                        }
                    } else if (v.read_logic(port.n_oe, levels) == false) {
                        const addr = v.read_bus(port.addr, levels);
                        if (addr == p.interrupt_addr and p.interrupt_flag.*) {
                            p.interrupt_flag.* = false;
                        }
                    }
                }
            } else if (v.read_logic(port.n_ce, levels) == true
                and v.read_logic(port.n_semaphore_enable, levels) == false
                and v.read_logic(port.n_we, levels) == false
            ) {
                try v.expect_valid(port.addr[0..2], levels);
                try v.expect_valid(port.lower_data[0], levels);

                const sem_addr = v.read_bus(port.addr[0..2], levels);
                const sem = v.read_logic(port.lower_data[0], levels);

                if (sem) {
                    // releasing
                    const prev = p.semaphores[sem_addr];
                    p.semaphores[sem_addr] = .idle;
                    if (p.other_semaphores[sem_addr] == .pending) switch (prev) {
                        .owned, .owned_masked => p.other_semaphores[sem_addr] = .owned_masked,
                        .idle, .pending => {},
                    };
                } else if (p.semaphores[sem_addr] == .idle) {
                    // acquiring
                    p.semaphores[sem_addr] = switch (p.other_semaphores[sem_addr]) {
                        .idle, .pending => .owned,
                        .owned, .owned_masked => .pending,
                    };
                }
            }

            p.mutex_addr.* = new_mutex_addr;
        }

        fn finalize_semaphores(port: Port, v: *Validator, semaphores: *[8]Validator_State.Semaphore_State) !void {
            for (semaphores) |*sem| {
                if (sem.* != .owned_masked) continue;
                if (v.read_logic(port.n_ce, levels) == false
                    or v.read_logic(port.n_semaphore_enable, levels) == true
                    or v.read_logic(port.n_oe, levels) == true
                    or v.read_logic(port.n_we, levels) == false
                ) sem.* = .owned;
            }
        }
    };
}

const log = std.log.scoped(.zoink);

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const packages = @import("../packages.zig");
const Part = @import("../Part.zig");
const Package = @import("../Package.zig");
const Validator = @import("../Validator.zig");
const std = @import("std");
