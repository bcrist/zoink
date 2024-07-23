// TODO alias namespaces - jedec, jeita/eiaj, SOT codes, etc.

pub const jedec = struct {

    pub const MS_026D_Variant = enum {
        thin, // up to 1.0mm thick
        low_profile, // up to 1.4mm thick
    };
    pub fn MS_026D(comptime lead_count: comptime_int, comptime width_mm: comptime_int, comptime height_mm: comptime_int, comptime variant: MS_026D_Variant) type {
        comptime var pins_first_side = lead_count / 4;

        if (width_mm == 20) {
            if (height_mm == 14) {
                pins_first_side = switch (lead_count) {
                    100 => 30,
                    128 => 38,
                    else => unreachable,
                };
            } else if (height_mm == 20) {
                std.debug.assert(lead_count == 112 or lead_count == 144 or lead_count == 176);
            } else unreachable;
        } else {
            std.debug.assert(height_mm == width_mm);
        }
        
        if (width_mm == 28.0) {
            std.debug.assert(variant == .low_profile);
        }

        const max_z = switch (variant) {
            .thin => 1200,
            .low_profile => 1600,
        };

        const pitch_um = switch (width_mm) {
            4 => switch (lead_count) {
                20 => 650,
                24 => 500,
                32 => 400,
                else => unreachable,
            },
            5 => switch (lead_count) {
                32 => 500,
                40 => 400,
                else => unreachable,
            },
            7 => switch (lead_count) {
                32 => 800,
                40 => 650,
                48 => 500,
                64 => 400,
                else => unreachable,
            },
            10 => switch (lead_count) {
                36 => 1000,
                44 => 800,
                52 => 650,
                64 => 500,
                80 => 400,
                else => unreachable,
            },
            12 => switch (lead_count) {
                44 => 1000,
                52 => 800,
                64 => 650,
                80 => 500,
                100 => 400,
                else => unreachable,
            },
            14 => switch (lead_count) {
                52 => 1000,
                64 => 800,
                80 => 650,
                100 => 500,
                120 => 400,
                else => unreachable,
            },
            20 => switch (lead_count) {
                100, 112 => 650,
                128, 144 => 500,
                176 => 400,
                else => unreachable,
            },
            24 => switch (lead_count) {
                176 => 500,
                216 => 400,
                else => unreachable,
            },
            28 => switch (lead_count) {
                160 => 650,
                208 => 500,
                256 => 400,
                else => unreachable,
            },
            else => unreachable,
        };

        return struct {
            pub const pkg: Package = .{
                .default_footprint = &fp.QFP(@This()).fp,
            };

            pub const pins = lead_count;

            // pin 1 is the leftmost pin on the bottom side (when viewed from top)
            pub const pins_on_first_side = pins_first_side;

            pub const pin_pitch_um = pitch_um;

            pub const pin_width_um = switch (pitch_um) {
                1000 => 425,
                800 => 375,
                650 => 320,
                500 => 220,
                400 => 180,
                else => unreachable,
            };
            pub const pin_width_tolerance_um = switch (pitch_um) {
                800, 1000 => 75,
                650 => 60,
                400, 500 => 50,
                else => unreachable,
            };

            pub const pin_seating_um = 600; // length of pin that lies flat against the seating plane
            pub const pin_seating_tolerance_um = 150;

            pub const body_width_um = width_mm * 1000;
            pub const body_height_um = height_mm * 1000;
            pub const body_dim_tolerance_um = 0.05;

            pub const overall_width_um = (width_mm + 2) * 1000;
            pub const overall_height_um = (height_mm + 2) * 1000;
            pub const overall_dim_tolerance_um = 0.25;

            pub const max_z_um = max_z;
        };
    }
};

pub const TQFP_100_14mm = jedec.MS_026D(100, 14, 14, .thin);

pub const TSOP_II_32 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.SO(@This()).fp,
    };
};
pub const TSOP_II_44 = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.SO(@This()).fp,
    };
};

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

pub fn PLCC(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.PLCC(@This()).fp,
        };
    };
}
pub const PLCC_84 = PLCC(84);

pub fn SOJ(comptime pin_count: comptime_int, comptime width_mils: comptime_int) type {
    _ = pin_count;
    _ = width_mils;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SOJ(@This()).fp,
        };
    };
}
pub const SOJ_32_300 = SOJ(32, 300);
pub const SOJ_32_400 = SOJ(32, 400);
pub const SOJ_44 = SOJ(44, 400);

pub fn SOIC(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SO(@This()).fp,
        };
    };
}
pub const SOIC_14 = SOIC(14);
pub const SOIC_20 = SOIC(20);

pub fn SSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SO(@This()).fp,
        };
    };
}
pub const SSOP_14 = SSOP(14);
pub const SSOP_20 = SSOP(20);
pub const SSOP_56 = SSOP(56);

pub fn TSSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SO(@This()).fp,
        };
    };
}
pub const TSSOP_14 = TSSOP(14);
pub const TSSOP_20 = TSSOP(20);
pub const TSSOP_56 = TSSOP(56);

pub fn VQFN(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.QFN(@This()).fp,
        };
    };
}
pub const VQFN_14 = VQFN(14);
pub const VQFN_20 = VQFN(20);

pub fn TVSOP(comptime pin_count: comptime_int) type {
    _ = pin_count;
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SO(@This()).fp,
        };
    };
}
pub const TVSOP_20 = TVSOP(20);



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