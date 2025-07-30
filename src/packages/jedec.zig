pub const MS_026D_Variant = enum {
    thin, // up to 1.0mm thick
    low_profile, // up to 1.4mm thick
};
/// TQFP/LQFP
pub fn MS_026D(comptime lead_count: comptime_int, comptime width_mm: comptime_int, comptime height_mm: comptime_int, comptime variant: MS_026D_Variant, comptime package_name: []const u8) type {
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
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = width_mm * 1000, .tolerance_um = 50 },
                .height = .{ .nominal_um = height_mm * 1000, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = (width_mm + 2) * 1000, .tolerance_um = 250 },
                .height = .{ .nominal_um = (height_mm + 2) * 1000, .tolerance_um = 250 },
            },
            .max_z = .{ .nominal_um = max_z, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = pins_first_side,
            .pin_pitch = .{ .nominal_um = pitch_um, .tolerance_um = 0 },
            .pin_width = .{
                .nominal_um = switch (pitch_um) {
                    1000 => 425,
                    800 => 375,
                    650 => 320,
                    500 => 220,
                    400 => 180,
                    else => unreachable,
                },
                .tolerance_um = switch (pitch_um) {
                    800, 1000 => 75,
                    650 => 60,
                    400, 500 => 50,
                    else => unreachable,
                },
            },
            .pin_seating = .{ .nominal_um = 600, .tolerance_um = 150 },
        };
    };
}

/// TSOP II (400mil)
pub fn MS_024H(comptime lead_count: comptime_int, comptime pitch_um: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (pitch_um) {
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
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 50 },
                .height = .{ .nominal_um = 10160, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 250 },
                .height = .{ .nominal_um = 11760, .tolerance_um = 250 },
            },
            .max_z = .{ .nominal_um = 1200, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = pitch_um, .tolerance_um = 0 },
            .pin_width = .{
                .nominal_um = switch (pitch_um) {
                    1270 => 410,
                    800 => 375,
                    650 => 300,
                    500 => 220,
                    400 => 180,
                    else => unreachable,
                },
                .tolerance_um = switch (pitch_um) {
                    1270 => 110,
                    800 => 75,
                    650 => 80,
                    400, 500 => 50,
                    else => unreachable,
                },
            },
            .pin_seating = .{ .nominal_um = 500, .tolerance_um = 100 },
        };
    };
}

/// SOJ (300mil, 400mil)
pub fn MS_027A__MO_065A_077D_088A(comptime lead_count: comptime_int, comptime body_size_mils: comptime_int, comptime package_name: []const u8) type {
    std.debug.assert(lead_count % 2 == 0);
    const body_width = (lead_count + 1) * 635;
    const body_height = switch (body_size_mils) {
        300 => 7620,
        400 => 10160,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 127 },
                .height = .{ .nominal_um = body_height, .tolerance_um = 127 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 127 },
                .height = .{ .nominal_um = body_height + 1016, .tolerance_um = 127 },
            },
            .max_z = .{ .nominal_um = 3760, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 460, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 2032, .tolerance_um = 80 },
        };
    };
}

/// PLCC (rectangular)
/// N.B. does not support the smallest "AA" variation of PLCC-18; MS_016A(18) corresponds to the "AB" variation.
pub fn MS_016A(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const pins_on_first_side = switch (lead_count) {
        18, 22 => 4,
        28 => 5,
        32 => 7,
        else => unreachable,
    };
    const overall_width = switch (lead_count) {
        18, 22 => 13395,
        28, 32 => 14985,
        else => unreachable,
    };
    const overall_height = switch (lead_count) {
        18, 22 => 8315,
        28 => 9905,
        32 => 12445,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = overall_width - 1070, .tolerance_um = 127 },
                .height = .{ .nominal_um = overall_height - 1070, .tolerance_um = 127 },
            },
            .overall = .{
                .width  = .{ .nominal_um = overall_width, .tolerance_um = 127 },
                .height = .{ .nominal_um = overall_height, .tolerance_um = 127 },
            },
            .max_z = .{ .nominal_um = 3550, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pin1 = .west_middle,
            .pins_on_first_side = pins_on_first_side,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 480, .tolerance_um = 80 },
            .pin_seating = .{ .nominal_um = 1600, .tolerance_um = 80 },
        };
    };
}

/// PLCC (square)
pub fn MO_047B(comptime lead_count: comptime_int, comptime pin1: footprints.Pin1, comptime package_name: []const u8) type {
    const overall_dim = switch (lead_count) {
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
    const body_dim = overall_dim - switch (lead_count) {
        20, 28, 44, 52 => 988,
        68, 84, 100, 124 => 937,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_dim, .tolerance_um = 127 },
                .height = .{ .nominal_um = body_dim, .tolerance_um = 127 },
            },
            .overall = .{
                .width  = .{ .nominal_um = overall_dim, .tolerance_um = 127 },
                .height = .{ .nominal_um = overall_dim, .tolerance_um = 127 },
            },
            .max_z = .{
                .nominal_um = switch (lead_count) {
                    20, 28, 44 => 4570,
                    52, 68, 84, 100, 124 => 5080,
                    else => unreachable,
                },
                .tolerance_um = 0,
            },
            .total_pins = lead_count,
            .pin1 = pin1,
            .pins_on_first_side = lead_count / 4,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 480, .tolerance_um = 80 },
            .pin_seating = .{ .nominal_um = 1600, .tolerance_um = 80 },
        };
    };
}

/// SOIC (150mil)
pub fn MS_012G_02(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        8 => 4900,
        14 => 8650,
        16 => 9900,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 50 },
                .height = .{ .nominal_um = 3900, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 250 },
                .height = .{ .nominal_um = 6000, .tolerance_um = 250 },
            },
            .max_z = .{ .nominal_um = 1250, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 410, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 835, .tolerance_um = 435 },
        };
    };
}

/// SOIC (200mil)
pub fn MO_046B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        14, 16 => 10300,
        20 => 12800,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 200 },
                .height = .{ .nominal_um = 5100, .tolerance_um = 200 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 400 },
                .height = .{ .nominal_um = 7800, .tolerance_um = 400 },
            },
            .max_z = .{ .nominal_um = 1800, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 430, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 500, .tolerance_um = 250 },
        };
    };
}

/// SOIC (300mil)
pub fn MS_013G(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        8 => 5850,
        14 => 9000,
        16 => 10300,
        18 => 11550,
        20 => 12800,
        24 => 15400,
        28 => 17900,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 50 },
                .height = .{ .nominal_um = 7500, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 250 },
                .height = .{ .nominal_um = 10300, .tolerance_um = 250 },
            },
            .max_z = .{ .nominal_um = 2650, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 410, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 835, .tolerance_um = 435 },
        };
    };
}

/// SOIC (330mil)
pub fn MO_059B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        24 => 15650,
        28 => 18100,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 450 },
                .height = .{ .nominal_um = 8454, .tolerance_um = 450 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 600 },
                .height = .{ .nominal_um = 12100, .tolerance_um = 600 },
            },
            .max_z = .{ .nominal_um = 3050, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 425, .tolerance_um = 75 },
            .pin_seating = .{ .nominal_um = 835, .tolerance_um = 435 },
        };
    };
}

/// SOIC (500mil)
pub fn MO_126B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        44 => 28200,
        48 => 30500,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 200 },
                .height = .{ .nominal_um = 12600, .tolerance_um = 200 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 200 },
                .height = .{ .nominal_um = 16050, .tolerance_um = 200 },
            },
            .max_z = .{ .nominal_um = 3100, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 1270, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 350, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 880, .tolerance_um = 150 },
        };
    };
}

/// SSOP (200mil)
pub fn MO_150B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        8 => 3000,
        14, 16 => 6200,
        18, 20 => 7200,
        22, 24 => 8200,
        28, 30 => 10300,
        38 => 12500,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 300 },
                .height = .{ .nominal_um = 5300, .tolerance_um = 300 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 300 },
                .height = .{ .nominal_um = 7800, .tolerance_um = 400 },
            },
            .max_z = .{ .nominal_um = 2000, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 650, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 300, .tolerance_um = 80 },
            .pin_seating = .{ .nominal_um = 750, .tolerance_um = 200 },
        };
    };
}

/// SSOP (300mil)
pub fn MO_118B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_width = switch (lead_count) {
        28 => 10300,
        48 => 16000,
        56 => 18500,
        64 => 21000,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 300 },
                .height = .{ .nominal_um = 7500, .tolerance_um = 300 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 300 },
                .height = .{ .nominal_um = 10300, .tolerance_um = 400 },
            },
            .max_z = .{ .nominal_um = 2800, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 635, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 270, .tolerance_um = 80 },
            .pin_seating = .{ .nominal_um = 750, .tolerance_um = 200 },
        };
    };
}

/// Corresponds to E1 nominal dimension
pub const MO_153_Body_Size = enum {
    a, // 2.8mm
    b, // 4.4mm
    c, // 6.1mm
    d, // 8mm
};
/// TSSOP
pub fn MO_153H(comptime lead_count: comptime_int, comptime pitch_um: comptime_int, comptime body: MO_153_Body_Size, comptime package_name: []const u8) type {
    const pin_width = switch (pitch_um) {
        400 => 180,
        500 => 220,
        650 => 250,
        else => unreachable,
    };
    
    const body_height = switch (body) {
        .a => 2800,
        .b => 4400,
        .c => 6100,
        .d => 8000,
    };

    const body_width = switch (pitch_um) {
        400 => switch (body) {
            .a => unreachable,
            .b => switch (lead_count) {
                24 => 5000,
                32 => 6500,
                36 => 7800,
                48 => 9700,
                else => unreachable,
            },
            .c => switch (lead_count) {
                36 => 7800,
                48 => 9700,
                52 => 11000,
                56 => 12500,
                64 => 14000,
                80 => 17000,
                else => unreachable,
            },
            .d => switch (lead_count) {
                48 => 9700,
                52 => 11000,
                56, 60 => 12500,
                64, 68 => 14000,
                else => unreachable,
            },
        },
        500 => switch (body) {
            .a => switch (lead_count) {
                16 => 4400,
                else => unreachable,
            },
            .b => switch (lead_count) {
                20 => 5000,
                24 => 6500,
                28, 30 => 7800,
                36, 38 => 9700,
                44 => 11000,
                50 => 12500,
                else => unreachable,
            },
            .c => switch (lead_count) {
                28 => 7800,
                36 => 9700,
                40, 44 => 11000,
                48 => 12500,
                56 => 14000,
                64 => 17000,
                else => unreachable,
            },
            .d => switch (lead_count) {
                8 => 3000,
                14, 16 => 5000,
                20 => 6500,
                24 => 7800,
                28 => 9700,
                else => unreachable,
            },
        },
        650 => switch (body) {
            .a => unreachable,
            .b => switch (lead_count) {
                8 => 3000,
                14, 16 => 5000,
                20 => 6500,
                24 => 7800,
                28 => 9700,
                else => unreachable,
            },
            .c => switch (lead_count) {
                24 => 7800,
                28, 30 => 9700,
                32 => 11000,
                36, 38 => 12500,
                40 => 14000,
                else => unreachable,
            },
            .d => switch (lead_count) {
                28 => 9700,
                32 => 11000,
                36 => 12500,
                40 => 14000,
                else => unreachable,
            },
        },
        else => unreachable,
    };
        
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 100 },
                .height = .{ .nominal_um = body_height, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 100 },
                .height = .{ .nominal_um = body_height + 2000, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = 1200, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = pitch_um, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = pin_width, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 600, .tolerance_um = 150 },
        };
    };
}

/// TVSOP
pub fn MO_194B(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const body_height = switch (lead_count) {
        14, 16, 20, 24, 48, 56 => 4400,
        80, 100 => 6100,
        else => unreachable,
    };
    const body_width = switch (lead_count) {
        14, 16 => 3600,
        20, 24 => 5000,
        48 => 9800,
        56 => 11300,
        80 => 17000,
        100 => 20800,
        else => unreachable,
    };
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 100 },
                .height = .{ .nominal_um = body_height, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = body_width, .tolerance_um = 100 },
                .height = .{ .nominal_um = body_height + 2000, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = 1200, .tolerance_um = 0 },
            .total_pins = lead_count,
            .pins_on_first_side = lead_count / 2,
            .pin_pitch = .{ .nominal_um = 400, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 180, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 600, .tolerance_um = 150 },
        };
    };
}

/// SOT-23-3/5/6/8
pub fn TO_236H__MO_193G(comptime lead_count: comptime_int, comptime package_name: []const u8) type {
    const pins = switch (lead_count) {
        3, 5, 6 => 6,
        8 => 8,
        else => unreachable,
    };
    const omitted_pins = switch (lead_count) {
        3 => &.{ 2, 4, 6 },
        5 => &.{ 5 },
        6, 8 => &.{},
        else => unreachable,
    };
    const pitch = switch (lead_count) {
        3, 5, 6 => 950,
        8 => 650,
        else => unreachable,
    };
    const pin_width = switch (lead_count) {
        3, 5, 6 => 400,
        8 => 300,
        else => unreachable,
    };

    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 2900, .tolerance_um = 100 },
                .height = .{ .nominal_um = 1600, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 2900, .tolerance_um = 150 },
                .height = .{ .nominal_um = 2800, .tolerance_um = 150 },
            },
            .max_z = .{ .nominal_um = 1170, .tolerance_um = 0 },
            .total_pins = pins,
            .pins_on_first_side = pins / 2,
            .omitted_pins = omitted_pins,
            .pin_pitch = .{ .nominal_um = pitch, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = pin_width, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 450, .tolerance_um = 150 },
        };
    };
}

pub const TO_253D = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.SOT(data, .normal).fp,
    };

    pub const data: SOT_Data = .{
        .package_name = "SOT143-4",
        .body = .{
            .width  = .{ .nominal_um = 2920, .tolerance_um = 120 },
            .height = .{ .nominal_um = 1300, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1220, .tolerance_um = 0 },
        .pins = &.{
            .{
                .side = .south,
                .position_um = -760,
                .width = .{ .nominal_um = 800, .tolerance_um = 100 },
                .length = .{ .nominal_um = 535, .tolerance_um = 135 },
                .seating = .{ .nominal_um = 500, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = 960,
                .width = .{ .nominal_um = 400, .tolerance_um = 100 },
                .length = .{ .nominal_um = 535, .tolerance_um = 135 },
                .seating = .{ .nominal_um = 500, .tolerance_um = 100 },
            },
            .{
                .side = .north,
                .position_um = 960,
                .width = .{ .nominal_um = 400, .tolerance_um = 100 },
                .length = .{ .nominal_um = 535, .tolerance_um = 135 },
                .seating = .{ .nominal_um = 500, .tolerance_um = 100 },
            },
            .{
                .side = .north,
                .position_um = -960,
                .width = .{ .nominal_um = 400, .tolerance_um = 100 },
                .length = .{ .nominal_um = 535, .tolerance_um = 135 },
                .seating = .{ .nominal_um = 500, .tolerance_um = 100 },
            },
        },
    };
};

pub const TO_261AA = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.SOT(data, .normal).fp,
    };

    pub const data: SOT_Data = .{
        .package_name = "SOT223-4",
        .body = .{
            .width  = .{ .nominal_um = 6500, .tolerance_um = 200 },
            .height = .{ .nominal_um = 3500, .tolerance_um = 200 },
        },
        .max_z = .{ .nominal_um = 1800, .tolerance_um = 0 },
        .pins = &.{
            .{
                .side = .south,
                .position_um = -2300,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = 0,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = 2300,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .north,
                .position_um = 0,
                .width = .{ .nominal_um = 3000, .tolerance_um = 100 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
        },
    };
};

pub const TO_261AB = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.SOT(data, .normal).fp,
    };

    pub const data: SOT_Data = .{
        .package_name = "SOT223-5",
        .body = .{
            .width  = .{ .nominal_um = 6500, .tolerance_um = 200 },
            .height = .{ .nominal_um = 3500, .tolerance_um = 200 },
        },
        .max_z = .{ .nominal_um = 1800, .tolerance_um = 0 },
        .pins = &.{
            .{
                .side = .south,
                .position_um = -2250,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = -750,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = 750,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .south,
                .position_um = 2250,
                .width = .{ .nominal_um = 760, .tolerance_um = 80 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
            .{
                .side = .north,
                .position_um = 0,
                .width = .{ .nominal_um = 3000, .tolerance_um = 100 },
                .length = .{ .nominal_um = 1900, .tolerance_um = 200 },
                .seating = .{ .nominal_um = 850, .tolerance_um = 100 },
            },
        },
    };
};


// FBGA-48: 6x8 balls, 6x8mm, 0.75mm pitch
pub const MO_207AD = struct {
    pub const pkg: Package = .{
        .default_footprint = &fp.BGA(data, .normal).fp,
    };

    pub const data: BGA_Data = .{
        .package_name = "FBGA-48",
        .body = .{
            .width  = .{ .nominal_um = 6000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 8000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1150, .tolerance_um = 200 },
        .ball_diameter = .{ .nominal_um = 350, .tolerance_um = 50 },
        .rows = 8,
        .cols = 6,
        .row_pitch = .{ .nominal_um = 750, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 750, .tolerance_um = 0 },
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

const BGA_Data = footprints.BGA_Data;
const SOT_Data = footprints.SOT_Data;
const SMD_Data = footprints.SMD_Data;
const fp = footprints;
const footprints = @import("../footprints.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");