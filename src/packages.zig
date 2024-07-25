// TODO alias namespaces - jedec, jeita/eiaj, SOT codes, etc.

pub const jedec = @import("packages/jedec.zig");

pub const TQFP_100_14mm = jedec.MS_026D(100, 14, 14, .thin);

pub const TSOP_II_32 = jedec.MS_024H(32, 1270);
pub const TSOP_II_44 = jedec.MS_024H(44, 800);

pub const SOJ_14 = jedec.MS_027A__MO_065A_077D_088A(14, 300);
pub const SOJ_16 = jedec.MS_027A__MO_065A_077D_088A(16, 300);
pub const SOJ_18 = jedec.MS_027A__MO_065A_077D_088A(18, 300);
pub const SOJ_20 = jedec.MS_027A__MO_065A_077D_088A(20, 300);
pub const SOJ_24 = jedec.MS_027A__MO_065A_077D_088A(24, 300);
pub const SOJ_26 = jedec.MS_027A__MO_065A_077D_088A(26, 300);
pub const SOJ_28_300 = jedec.MS_027A__MO_065A_077D_088A(28, 300);
pub const SOJ_32_300 = jedec.MS_027A__MO_065A_077D_088A(32, 300);
pub const SOJ_42_300 = jedec.MS_027A__MO_065A_077D_088A(42, 300);

pub const SOJ_28_400 = jedec.MS_027A__MO_065A_077D_088A(28, 400);
pub const SOJ_32_400 = jedec.MS_027A__MO_065A_077D_088A(32, 400);
pub const SOJ_34_400 = jedec.MS_027A__MO_065A_077D_088A(34, 400);
pub const SOJ_36_400 = jedec.MS_027A__MO_065A_077D_088A(36, 400);
pub const SOJ_40_400 = jedec.MS_027A__MO_065A_077D_088A(40, 400);
pub const SOJ_42_400 = jedec.MS_027A__MO_065A_077D_088A(42, 400);
pub const SOJ_44 = jedec.MS_027A__MO_065A_077D_088A(44, 400);

pub const PLCC_18 = jedec.MS_016A(18); // 5x4
pub const PLCC_22 = jedec.MS_016A(18); // 7x4
pub const PLCC_28_9x5 = jedec.MS_016A(18); // 9x5
pub const PLCC_32 = jedec.MS_016A(18); // 9x7

pub const PLCC_20 = jedec.MO_047B(20);
pub const PLCC_28_7x7 = jedec.MO_047B(28);
pub const PLCC_44 = jedec.MO_047B(44);
pub const PLCC_52 = jedec.MO_047B(52);
pub const PLCC_68 = jedec.MO_047B(68);
pub const PLCC_84 = jedec.MO_047B(84);
pub const PLCC_100 = jedec.MO_047B(100);
pub const PLCC_124 = jedec.MO_047B(124);

pub fn SOIC(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };
    };
}
pub const SOIC_14 = SOIC(14);
pub const SOIC_20 = SOIC(20);

pub fn SSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };
    };
}
pub const SSOP_14 = SSOP(14);
pub const SSOP_20 = SSOP(20);
pub const SSOP_48 = SSOP(48);
pub const SSOP_56 = SSOP(56);

pub fn TSSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };
    };
}
pub const TSSOP_14 = TSSOP(14);
pub const TSSOP_20 = TSSOP(20);
pub const TSSOP_48 = TSSOP(48);
pub const TSSOP_56 = TSSOP(56);

pub fn VQFN(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SQ(@This()).fp,
        };
    };
}
pub const VQFN_14 = VQFN(14);
pub const VQFN_20 = VQFN(20);

pub fn TVSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };
    };
}
pub const TVSOP_20 = TVSOP(20);
pub const TVSOP_48 = TVSOP(48);

/// 6 x 8 mm body
/// 6 x 8 ball grid
/// 0.75mm ball pitch
/// Common package for parallel interface memories
pub const FBGA_48 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.BGA_Full(@This()).fp,
    };

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

pub const R1206 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.R(@This()).fp,
    };
};

pub const R0805 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.R(@This()).fp,
    };
};

pub const R0603 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.R(@This()).fp,
    };
};

pub const R0402 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.R(@This()).fp,
    };
};

pub const R0201 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.R(@This()).fp,
    };
};

pub const C1206 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.C(@This()).fp,
    };
};

pub const C0805 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.C(@This()).fp,
    };
};

pub const C0603 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.C(@This()).fp,
    };
};

pub const C0402 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.C(@This()).fp,
    };
};

pub const C0201 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.C(@This()).fp,
    };
};

const fp = @import("footprints.zig").normal;
const enums = @import("enums.zig");
const Package = @import("Package.zig");
const std = @import("std");