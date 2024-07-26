pub fn _1206(comptime max_z_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: fp.SMD_Data = .{
            .body = .{
                .width  = .{ .nominal_um = 1600, .tolerance_um = 150 },
                .height = .{ .nominal_um = 3200, .tolerance_um = 150 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 1600, .tolerance_um = 150 },
                .height = .{ .nominal_um = 3200, .tolerance_um = 150 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 1600, .tolerance_um = 150 },
            .pin_seating = .{ .nominal_um = 500, .tolerance_um = 250 },
        };
    };
}

pub fn _0805(comptime max_z_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: fp.SMD_Data = .{
            .body = .{
                .width  = .{ .nominal_um = 1250, .tolerance_um = 100 },
                .height = .{ .nominal_um = 2000, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 1250, .tolerance_um = 100 },
                .height = .{ .nominal_um = 2000, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 1250, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 400, .tolerance_um = 200 },
        };
    };
}

pub fn _0603(comptime max_z_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: fp.SMD_Data = .{
            .body = .{
                .width  = .{ .nominal_um = 800, .tolerance_um = 100 },
                .height = .{ .nominal_um = 1600, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 800, .tolerance_um = 100 },
                .height = .{ .nominal_um = 1600, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 800, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 300, .tolerance_um = 150 },
        };
    };
}

pub fn _0402(comptime max_z_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };

        pub const data: fp.SMD_Data = .{
            .body = .{
                .width  = .{ .nominal_um = 500, .tolerance_um = 50 },
                .height = .{ .nominal_um = 1000, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 500, .tolerance_um = 50 },
                .height = .{ .nominal_um = 1000, .tolerance_um = 50 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 500, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 250, .tolerance_um = 100 },
        };
    };
}

pub fn _0201(comptime max_z_um: comptime_int) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &fp.SMD(data, .normal).fp,
        };
        
        pub const data: fp.SMD_Data = .{
            .body = .{
                .width  = .{ .nominal_um = 300, .tolerance_um = 30 },
                .height = .{ .nominal_um = 600, .tolerance_um = 30 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 300, .tolerance_um = 30 },
                .height = .{ .nominal_um = 600, .tolerance_um = 30 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 300, .tolerance_um = 30 },
            .pin_seating = .{ .nominal_um = 150, .tolerance_um = 50 },
        };
    };
}

const SOT_Data = footprints.SOT_Data;
const SMD_Data = footprints.SMD_Data;
const fp = footprints;
const footprints = @import("../footprints.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");