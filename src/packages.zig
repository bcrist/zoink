pub const TQFP_100 = struct {
    pub const pkg: Package = .{};
};

pub const TSOP_II_32 = struct {
    pub const pkg: Package = .{};
};
pub const TSOP_II_44 = struct {
    pub const pkg: Package = .{};
};

/// 6 x 8 mm body
/// 6 x 8 ball grid
/// 0.75mm ball pitch
/// Common package for parallel interface memories
pub const FBGA_48 = struct {
    pub const pkg: Package = .{};

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,
        B1 = 7,  B2 = 8,  B3 = 9,  B4 = 10, B5 = 11, B6 = 12,
        C1 = 13, C2 = 14, C3 = 15, C4 = 16, C5 = 17, C6 = 18,
        D1 = 19, D2 = 20, D3 = 21, D4 = 22, D5 = 23, D6 = 24,
        E1 = 25, E2 = 26, E3 = 27, E4 = 28, E5 = 29, E6 = 30,
        F1 = 31, F2 = 32, F3 = 33, F4 = 34, F5 = 35, F6 = 36,
        G1 = 37, G2 = 38, G3 = 39, G4 = 40, G5 = 41, G6 = 42,
        H1 = 43, H2 = 44, H3 = 45, H4 = 46, H5 = 47, H6 = 48,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

pub fn PLCC(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const PLCC_84 = PLCC(84);

pub fn SOJ(comptime pin_count: comptime_int, comptime width_mils: comptime_int) type {
    _ = pin_count;
    _ = width_mils;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const SOJ_32_300 = SOJ(32, 300);
pub const SOJ_32_400 = SOJ(32, 400);
pub const SOJ_44 = SOJ(44, 400);

pub fn SOIC(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const SOIC_14 = SOIC(14);
pub const SOIC_20 = SOIC(20);

pub fn SSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const SSOP_14 = SSOP(14);
pub const SSOP_20 = SSOP(20);

pub fn TSSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const TSSOP_14 = TSSOP(14);
pub const TSSOP_20 = TSSOP(20);

pub fn VQFN(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const VQFN_14 = VQFN(14);
pub const VQFN_20 = VQFN(20);

pub fn TVSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{};
    };
}
pub const TVSOP_20 = TVSOP(20);



pub const R1206 = struct {
    pub const pkg: Package = .{};
};

pub const R0805 = struct {
    pub const pkg: Package = .{};
};

pub const R0603 = struct {
    pub const pkg: Package = .{};
};

pub const R0402 = struct {
    pub const pkg: Package = .{};
};

pub const R0201 = struct {
    pub const pkg: Package = .{};
};

pub const C1206 = struct {
    pub const pkg: Package = .{};
};

pub const C0805 = struct {
    pub const pkg: Package = .{};
};

pub const C0603 = struct {
    pub const pkg: Package = .{};
};

pub const C0402 = struct {
    pub const pkg: Package = .{};
};

pub const C0201 = struct {
    pub const pkg: Package = .{};
};

const enums = @import("enums.zig");
const Package = @import("Package.zig");
