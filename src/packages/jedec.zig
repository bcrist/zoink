pub const MS_026D_Variant = enum {
    thin, // up to 1.0mm thick
    low_profile, // up to 1.4mm thick
};
/// TQFP/LQFP
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
    
    if (width_mm == 28) {
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
            .default_footprint = &fp.SQ(@This()).fp,
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
        pub const body_dim_tolerance_um = 50;

        pub const overall_width_um = (width_mm + 2) * 1000;
        pub const overall_height_um = (height_mm + 2) * 1000;
        pub const overall_dim_tolerance_um = 250;

        pub const max_z_um = max_z;
    };
}

/// TSOP II (400mil)
pub fn MS_024H(comptime lead_count: comptime_int, comptime pitch_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };

        pub const pins = lead_count;

        // pin 1 is the leftmost pin on the bottom side (when viewed from top)
        pub const pins_on_first_side = lead_count / 2;

        pub const pin_pitch_um = pitch_um;

        pub const pin_width_um = switch (pitch_um) {
            1270 => 410,
            800 => 375,
            650 => 300,
            500 => 220,
            400 => 180,
            else => unreachable,
        };
        pub const pin_width_tolerance_um = switch (pitch_um) {
            1270 => 110,
            800 => 75,
            650 => 80,
            400, 500 => 50,
            else => unreachable,
        };

        pub const pin_seating_um = 500; // length of pin that lies flat against the seating plane
        pub const pin_seating_tolerance_um = 100;

        pub const body_width_um = switch (pitch_um) {
            1270 => switch (lead_count) {
                28 => 18410,
                32 => 20950,
                36 => 23490,
                40 => 26030,
                else => unreachable,
            },
            800 => switch (lead_count) {
                44 => 18410,
                50 => 20950,
                54 => 22220,
                70 => 28570,
                else => unreachable,
            },
            650 => switch (lead_count) {
                66 => 22220,
                70 => 23490,
                else => unreachable,
            },
            500 => switch (lead_count) {
                80 => 20950,
                86 => 22220,
                else => unreachable,
            },
            400 => switch (lead_count) {
                54 => 11200,
                else => unreachable,
            },
        };
        pub const body_height_um = 10160;
        pub const body_dim_tolerance_um = 50;

        pub const overall_width_um = body_width_um;
        pub const overall_height_um = 11760;
        pub const overall_dim_tolerance_um = 250;

        pub const max_z_um = 1200;
    };
}

/// SOJ (300mil, 400mil)
pub fn MS_027A__MO_065A_077D_088A(comptime lead_count: comptime_int, comptime body_size_mils: comptime_int) type {
    std.debug.assert(lead_count % 2 == 0);
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SD(@This()).fp,
        };

        pub const pins = lead_count;

        // pin 1 is the leftmost pin on the bottom side (when viewed from top)
        pub const pins_on_first_side = lead_count / 2;

        pub const pin_pitch_um = 1270;

        pub const pin_width_um = 460;
        pub const pin_width_tolerance_um = 50;

        pub const pin_seating_um = 2032; // diameter of lower half circle of J leads
        pub const pin_seating_tolerance_um = 80;

        pub const body_width_um = (lead_count + 1) * 635;
        pub const body_height_um = switch (body_size_mils) {
            300 => 7620,
            400 => 10160,
            else => unreachable,
        };
        pub const body_dim_tolerance_um = 127;

        pub const overall_width_um = body_width_um;
        pub const overall_height_um = body_height_um + 1016;
        pub const overall_dim_tolerance_um = 127;

        pub const max_z_um = 3760;
    };
}

/// PLCC (rectangular)
/// N.B. does not support the smallest "AA" variation of PLCC-18; MS_016A(18) corresponds to the "AB" variation.
pub fn MS_016A(comptime lead_count: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SQ(@This()).fp,
        };

        pub const pins = lead_count;

        // pin 1 is the leftmost pin on the bottom side (when viewed from top)
        pub const pins_on_first_side = switch (lead_count) {
            18 => 5,
            22 => 7,
            28, 32 => 9,
            else => unreachable,
        };
        pub const pins_on_second_side = switch (lead_count) {
            18, 22 => 4,
            28 => 5,
            32 => 7,
            else => unreachable,
        };

        pub const pin_pitch_um = 1270;

        pub const pin_width_um = 480;
        pub const pin_width_tolerance_um = 80;

        pub const pin_seating_um = 2032; // diameter of lower half circle of J leads
        pub const pin_seating_tolerance_um = 80;

        pub const body_width_um = overall_width_um - 1070;
        pub const body_height_um = overall_height_um - 1070;
        pub const body_dim_tolerance_um = 127;

        pub const overall_width_um = switch (lead_count) {
            18, 22 => 13395,
            28, 32 => 14985,
            else => unreachable,
        };
        pub const overall_height_um = switch (lead_count) {
            18, 22 => 8315,
            28 => 9905,
            32 => 12445,
            else => unreachable,
        };
        pub const overall_dim_tolerance_um = 127;

        pub const max_z_um = 3550;
    };
}

/// PLCC (square)
pub fn MO_047B(comptime lead_count: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SQ(@This()).fp,
        };

        pub const pins = lead_count;

        // pin 1 is the leftmost pin on the bottom side (when viewed from top)
        pub const pins_on_first_side = lead_count / 4;

        pub const pin_pitch_um = 1270;

        pub const pin_width_um = 480;
        pub const pin_width_tolerance_um = 80;

        pub const pin_seating_um = 2032; // diameter of lower half circle of J leads
        pub const pin_seating_tolerance_um = 80;

        pub const body_width_um = overall_width_um - switch (lead_count) {
            20, 28, 44, 52 => 988,
            68, 84, 100, 124 => 937,
            else => unreachable,
        };
        pub const body_height_um = body_width_um;
        pub const body_dim_tolerance_um = 127;

        pub const overall_width_um = switch (lead_count) {
            20 => 9905,
            28 => 12445,
            44 => 17525,
            52 => 20065,
            68 => 25145,
            84 => 30225,
            100 => 35305,
            124 => 42925,
            else => unreachable,
        };
        pub const overall_height_um = overall_width_um;
        pub const overall_dim_tolerance_um = 127;

        pub const max_z_um = switch (lead_count) {
            20, 28, 44 => 4570,
            52, 68, 84, 100, 124 => 5080,
        };
    };
}


const fp = @import("../footprints.zig").normal;
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");