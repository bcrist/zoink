// standard through-hole PLCC sockets and PLCC-to-PGA adapters
pub fn PLCC(comptime rows: comptime_int, comptime cols: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.PLCC_PGA(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...(2 * (rows + cols)) => true,
                else => false,
            };
        }

        pub const data: PLCC_PGA_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .init_mm(1.27 * (cols - 1) + 5.3, 0.5),
                .height = .init_mm(1.27 * (rows - 1) + 5.3, 0.5),
            },
            .max_z = .init_mm(7.7, 0.2),
            .pin_diameter = .init_inches_range(0.01, 0.02),
            .pin_length = .init_inches_range(0.1, 0.2),
            .plcc_rows = rows,
            .plcc_cols = cols,
        };
    };
}

pub const PGA68 = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.PGA(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: enums.Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...68 => true,
            else => false,
        };
    }

    pub const data: PGA_Data = .{
        .package_name = "PGA-68 (11x11)",
        .body = .{
            .width = .init_inches(1.2, 0.05),
            .height = .init_inches(1.2, 0.05),
        },
        .body_thickness = .init_inches_range(0.15, 0.25),
        .max_z = .init_inches_range(0.2, 0.3),
        .pin_diameter = .init_inches_range(0.01, 0.02),
        .pin_length = .init_inches_range(0.1, 0.2),
        .rows = 11,
        .cols = 11,
        .include_pins = &.{
            .{ .ring = .{
                .dist_from_edges = 0,
                .thickness = 2,
            }},
        },
        .exclude_pins = &.{
            .{ .corners = .{
                .width = 1,
                .height = 1,
            }},
        },
        .pin_name_format_func = kicad.format_pin_name(Pin_ID),
    };

    pub const Pin_ID = enum (u8) {
                 A2 = 1,  A3 = 2,  A4 = 3,  A5 = 4,  A6 = 5,  A7 = 6,  A8 = 7,  A9 = 8,  A10 = 9,
        B1 = 10, B2 = 11, B3 = 12, B4 = 13, B5 = 14, B6 = 15, B7 = 16, B8 = 17, B9 = 18, B10 = 19,  B11 = 20,
        C1 = 21, C2 = 22,                                                                C10 = 23,  C11 = 24,
        D1 = 25, D2 = 26,                                                                D10 = 27,  D11 = 28,
        E1 = 29, E2 = 30,                                                                E10 = 31,  E11 = 32,
        F1 = 33, F2 = 34,                                                                F10 = 35,  F11 = 36,
        G1 = 37, G2 = 38,                                                                G10 = 39,  G11 = 40,
        H1 = 41, H2 = 42,                                                                H10 = 43,  H11 = 44,
        J1 = 45, J2 = 46,                                                                J10 = 47,  J11 = 48,
        K1 = 49, K2 = 50, K3 = 51, K4 = 52, K5 = 53, K6 = 54, K7 = 55, K8 = 56, K9 = 57, K10 = 58,  K11 = 59,
                 L2 = 60, L3 = 61, L4 = 62, L5 = 63, L6 = 64, L7 = 65, L8 = 66, L9 = 67, L10 = 68,

        pub fn from_generic(id: enums.Pin_ID) Pin_ID {
            return @enumFromInt(@intFromEnum(id));
        }
        pub fn generic(self: Pin_ID) enums.Pin_ID {
            return @enumFromInt(@intFromEnum(self));
        }
    };
};

const PGA_Data = fp.PGA_Data;
const PLCC_PGA_Data = fp.PLCC_PGA_Data;
const fp = @import("../footprints.zig");
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
