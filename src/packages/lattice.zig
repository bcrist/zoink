// Based on FPGA-DS-02053-8.4 "Package Diagrams"
// https://www.latticesemi.com/view_document?document_id=213

// 35. 56-Ball csBGA Package
// 6mm square body
// 1.23mm nominal height from board (1.1 ~ 1.35)
// 0.15mm min. displacement from seating plane
// 0.3mm nominal ball diameter (+/- 0.05mm)
// 10x10 grid, 0.5mm pitch
// Inner ring of 20 balls
// Outer ring of 36 balls
pub const csBGA56 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...56 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "csBGA-56",
        .body = .{
            .width  = .{ .nominal_um = 6000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 6000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1230, .tolerance_um = 130 },
        .ball_diameter = .{ .nominal_um = 300, .tolerance_um = 50 },
        .rows = 10,
        .cols = 10,
        .row_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .include_balls = &.{
            .{ .ring = .{
                .dist_from_edges = 0,
                .thickness = 1,
            }},
            .{ .ring = .{
                .dist_from_edges = 2,
                .thickness = 1,
            }},
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,  A9 = 9,  A10 = 10,
        B1 = 11,                                                                         B10 = 12,
        C1 = 13,          C3 = 14, C4 = 15, C5 = 16, C6 = 17, C7 = 18, C8 = 19,          C10 = 20,
        D1 = 21,          D3 = 22,                                     D8 = 23,          D10 = 24,
        E1 = 25,          E3 = 26,                                     E8 = 27,          E10 = 28,
        F1 = 29,          F3 = 30,                                     F8 = 31,          F10 = 32,
        G1 = 33,          G3 = 34,                                     G8 = 35,          G10 = 36,
        H1 = 37,          H3 = 38, H4 = 39, H5 = 40, H6 = 41, H7 = 42, H8 = 43,          H10 = 44,
        J1 = 45,                                                                         J10 = 46,
        K1 = 47, K2 = 48, K3 = 49, K4 = 50, K5 = 51, K6 = 52, K7 = 53, K8 = 54, K9 = 55, K10 = 56,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

// 36. 64-Ball csBGA Package
// 5mm square body
// 1mm nominal height from board (0.9 ~ 1.1)
// 0.15mm min. displacement from seating plane
// 0.3mm nominal ball diameter (+/- 0.05mm)
// 8x8 grid, 0.5mm pitch
pub const csBGA64 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...64 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "csBGA-64",
        .body = .{
            .width  = .{ .nominal_um = 5000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 5000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1000, .tolerance_um = 100 },
        .ball_diameter = .{ .nominal_um = 300, .tolerance_um = 50 },
        .rows = 8,
        .cols = 8,
        .row_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,
        B1 = 9,  B2 = 10, B3 = 11, B4 = 12, B5 = 13, B6 = 14, B7 = 15, B8 = 16,
        C1 = 17, C2 = 18, C3 = 19, C4 = 20, C5 = 21, C6 = 22, C7 = 23, C8 = 24,
        D1 = 25, D2 = 26, D3 = 27, D4 = 28, D5 = 29, D6 = 30, D7 = 31, D8 = 32,
        E1 = 33, E2 = 34, E3 = 35, E4 = 36, E5 = 37, E6 = 38, E7 = 39, E8 = 40,
        F1 = 41, F2 = 42, F3 = 43, F4 = 44, F5 = 45, F6 = 46, F7 = 47, F8 = 48,
        G1 = 49, G2 = 50, G3 = 51, G4 = 52, G5 = 53, G6 = 54, G7 = 55, G8 = 56,
        H1 = 57, H2 = 58, H3 = 59, H4 = 60, H5 = 61, H6 = 62, H7 = 63, H8 = 64,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

// 38. 64-Ball ucBGA Package
// 4mm square body
// 1mm max height from board
// 0.1mm min. displacement from seating plane
// 0.25mm nominal ball diameter (+/- 0.05mm)
// 8x8 grid, 0.4mm pitch
pub const ucBGA64 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...64 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "ucBGA-64",
        .body = .{
            .width  = .{ .nominal_um = 4000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 4000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 900, .tolerance_um = 100 },
        .ball_diameter = .{ .nominal_um = 250, .tolerance_um = 50 },
        .rows = 8,
        .cols = 8,
        .row_pitch = .{ .nominal_um = 400, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 400, .tolerance_um = 0 },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,
        B1 = 9,  B2 = 10, B3 = 11, B4 = 12, B5 = 13, B6 = 14, B7 = 15, B8 = 16,
        C1 = 17, C2 = 18, C3 = 19, C4 = 20, C5 = 21, C6 = 22, C7 = 23, C8 = 24,
        D1 = 25, D2 = 26, D3 = 27, D4 = 28, D5 = 29, D6 = 30, D7 = 31, D8 = 32,
        E1 = 33, E2 = 34, E3 = 35, E4 = 36, E5 = 37, E6 = 38, E7 = 39, E8 = 40,
        F1 = 41, F2 = 42, F3 = 43, F4 = 44, F5 = 45, F6 = 46, F7 = 47, F8 = 48,
        G1 = 49, G2 = 50, G3 = 51, G4 = 52, G5 = 53, G6 = 54, G7 = 55, G8 = 56,
        H1 = 57, H2 = 58, H3 = 59, H4 = 60, H5 = 61, H6 = 62, H7 = 63, H8 = 64,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

// 73. 132-Ball csBGA Package Option 1
// 8mm square body
// 1.23mm nominal height from board (0.9 ~ 1.35)
// 0.15mm min. displacement from seating plane
// 0.3mm nominal ball diameter (+/- 0.05mm)
// 14x14 grid, 0.5mm pitch
// Inner 8x8 grid unpopulated
pub const csBGA132 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...132 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "csBGA-132",
        .body = .{
            .width  = .{ .nominal_um = 8000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 8000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1230, .tolerance_um = 130 },
        .ball_diameter = .{ .nominal_um = 300, .tolerance_um = 50 },
        .rows = 14,
        .cols = 14,
        .row_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .include_balls = &.{
            .{ .ring = .{
                .dist_from_edges = 0,
                .thickness = 3,
            }},
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,  A9 = 9,  A10 = 10, A11 = 11, A12 = 12, A13 = 13, A14 = 14,
        B1 = 15, B2 = 16, B3 = 17, B4 = 18, B5 = 19, B6 = 20, B7 = 21, B8 = 22, B9 = 23, B10 = 24, B11 = 25, B12 = 26, B13 = 27, B14 = 28,
        C1 = 29, C2 = 30, C3 = 31, C4 = 32, C5 = 33, C6 = 34, C7 = 35, C8 = 36, C9 = 37, C10 = 38, C11 = 39, C12 = 40, C13 = 41, C14 = 42,
        D1 = 43, D2 = 44, D3 = 45,                                                                           D12 = 46, D13 = 47, D14 = 48,
        E1 = 49, E2 = 50, E3 = 51,                                                                           E12 = 52, E13 = 53, E14 = 54,
        F1 = 55, F2 = 56, F3 = 57,                                                                           F12 = 58, F13 = 59, F14 = 60,
        G1 = 61, G2 = 62, G3 = 63,                                                                           G12 = 64, G13 = 65, G14 = 66,
        H1 = 67, H2 = 68, H3 = 69,                                                                           H12 = 70, H13 = 71, H14 = 72,
        J1 = 73, J2 = 74, J3 = 75,                                                                           J12 = 76, J13 = 77, J14 = 78,
        K1 = 79, K2 = 80, K3 = 81,                                                                           K12 = 82, K13 = 83, K14 = 84,
        L1 = 85, L2 = 86, L3 = 87,                                                                           L12 = 88, L13 = 89, L14 = 90,
        M1 = 91, M2 = 92, M3 = 93, M4 = 94, M5 = 95, M6 = 96, M7 = 97, M8 = 98, M9 = 99, M10 =100, M11 =101, M12 =102, M13 =103, M14 =104,
        N1 =105, N2 =106, N3 =107, N4 =108, N5 =109, N6 =110, N7 =111, N8 =112, N9 =113, N10 =114, N11 =115, N12 =116, N13 =117, N14 =118,
        P1 =119, P2 =120, P3 =121, P4 =122, P5 =123, P6 =124, P7 =125, P8 =126, P9 =127, P10 =128, P11 =129, P12 =130, P13 =131, P14 =132,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

// 76. 132-Ball ucBGA Package
// 6mm square body
// 1mm max height from board
// 0.1mm min. displacement from seating plane
// 0.25mm nominal ball diameter (+/- 0.05mm)
// 12x12 grid, 0.4mm pitch
// Inner diamond unpopulated
pub const ucBGA132 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...132 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "ucBGA-132",
        .body = .{
            .width  = .{ .nominal_um = 6000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 6000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 900, .tolerance_um = 100 },
        .ball_diameter = .{ .nominal_um = 250, .tolerance_um = 50 },
        .rows = 12,
        .cols = 12,
        .row_pitch = .{ .nominal_um = 400, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 400, .tolerance_um = 0 },
        .exclude_balls = &.{
            .{ .individual = .{
                .row = 4,
                .col = 5,
                .mirror = .all,
            }},
            .{ .individual = .{
                .row = 5,
                .col = 5,
                .mirror = .all,
            }},
            .{ .individual = .{
                .row = 5,
                .col = 4,
                .mirror = .all,
            }},
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,  A9 = 9,  A10 = 10, A11 = 11, A12 = 12,
        B1 = 13, B2 = 14, B3 = 15, B4 = 16, B5 = 17, B6 = 18, B7 = 19, B8 = 20, B9 = 21, B10 = 22, B11 = 23, B12 = 24,
        C1 = 25, C2 = 26, C3 = 27, C4 = 28, C5 = 29, C6 = 30, C7 = 31, C8 = 32, C9 = 33, C10 = 34, C11 = 35, C12 = 36,
        D1 = 37, D2 = 38, D3 = 39, D4 = 40, D5 = 41, D6 = 42, D7 = 43, D8 = 44, D9 = 45, D10 = 46, D11 = 47, D12 = 48,
        E1 = 49, E2 = 50, E3 = 51, E4 = 52, E5 = 53,                   E8 = 54, E9 = 55, E10 = 56, E11 = 57, E12 = 58,
        F1 = 59, F2 = 60, F3 = 61, F4 = 62,                                     F9 = 63, F10 = 64, F11 = 65, F12 = 66,
        G1 = 67, G2 = 68, G3 = 69, G4 = 70,                                     G9 = 71, G10 = 72, G11 = 73, G12 = 74,
        H1 = 75, H2 = 76, H3 = 77, H4 = 78, H5 = 79,                   H8 = 80, H9 = 81, H10 = 82, H11 = 83, H12 = 84,
        J1 = 85, J2 = 86, J3 = 87, J4 = 88, J5 = 89, J6 = 90, J7 = 91, J8 = 92, J9 = 93, J10 = 94, J11 = 95, J12 = 96,
        K1 = 97, K2 = 98, K3 = 99, K4 =100, K5 =101, K6 =102, K7 =103, K8 =104, K9 =105, K10 =106, K11 =107, K12 =108,
        L1 =109, L2 =110, L3 =111, L4 =112, L5 =113, L6 =114, L7 =115, L8 =116, L9 =117, L10 =118, L11 =119, L12 =120,
        M1 =121, M2 =122, M3 =123, M4 =124, M5 =125, M6 =126, M7 =127, M8 =128, M9 =129, M10 =130, M11 =131, M12 =132,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

// 78. 144-Ball csBGA Package
// 7mm square body
// 1mm nominal height from board (0.9 ~ 1.1)
// 0.15mm min. displacement from seating plane
// 0.3mm nominal ball diameter (+/- 0.05mm)
// 12x12 grid, 0.5mm pitch
pub const csBGA144 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.BGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...144 => true,
            else => false,
        };
    }

    pub const data: BGA_Data = .{
        .package_name = "csBGA-144",
        .body = .{
            .width  = .{ .nominal_um = 7000, .tolerance_um = 100 },
            .height = .{ .nominal_um = 7000, .tolerance_um = 100 },
        },
        .max_z = .{ .nominal_um = 1000, .tolerance_um = 100 },
        .ball_diameter = .{ .nominal_um = 300, .tolerance_um = 50 },
        .rows = 12,
        .cols = 12,
        .row_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .col_pitch = .{ .nominal_um = 500, .tolerance_um = 0 },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
        A1 = 1,  A2 = 2,  A3 = 3,  A4 = 4,  A5 = 5,  A6 = 6,  A7 = 7,  A8 = 8,  A9 = 9,  A10 = 10, A11 = 11, A12 = 12,
        B1 = 13, B2 = 14, B3 = 15, B4 = 16, B5 = 17, B6 = 18, B7 = 19, B8 = 20, B9 = 21, B10 = 22, B11 = 23, B12 = 24,
        C1 = 25, C2 = 26, C3 = 27, C4 = 28, C5 = 29, C6 = 30, C7 = 31, C8 = 32, C9 = 33, C10 = 34, C11 = 35, C12 = 36,
        D1 = 37, D2 = 38, D3 = 39, D4 = 40, D5 = 41, D6 = 42, D7 = 43, D8 = 44, D9 = 45, D10 = 46, D11 = 47, D12 = 48,
        E1 = 49, E2 = 50, E3 = 51, E4 = 52, E5 = 53, E6 = 54, E7 = 55, E8 = 56, E9 = 57, E10 = 58, E11 = 59, E12 = 60,
        F1 = 61, F2 = 62, F3 = 63, F4 = 64, F5 = 65, F6 = 66, F7 = 67, F8 = 68, F9 = 69, F10 = 70, F11 = 71, F12 = 72,
        G1 = 73, G2 = 74, G3 = 75, G4 = 76, G5 = 77, G6 = 78, G7 = 79, G8 = 80, G9 = 81, G10 = 82, G11 = 83, G12 = 84,
        H1 = 85, H2 = 86, H3 = 87, H4 = 88, H5 = 89, H6 = 90, H7 = 91, H8 = 92, H9 = 93, H10 = 94, H11 = 95, H12 = 96,
        J1 = 97, J2 = 98, J3 = 99, J4 =100, J5 =101, J6 =102, J7 =103, J8 =104, J9 =105, J10 =106, J11 =107, J12 =108,
        K1 =109, K2 =110, K3 =111, K4 =112, K5 =113, K6 =114, K7 =115, K8 =116, K9 =117, K10 =118, K11 =119, K12 =120,
        L1 =121, L2 =122, L3 =123, L4 =124, L5 =125, L6 =126, L7 =127, L8 =128, L9 =129, L10 =130, L11 =131, L12 =132,
        M1 =133, M2 =134, M3 =135, M4 =136, M5 =137, M6 =138, M7 =139, M8 =140, M9 =141, M10 =142, M11 =143, M12 =144,

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
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");
