pub fn _1206(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
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
            .pin_1_mark = .none,
        };
    };
}

pub fn _0805(comptime max_z_um: comptime_int, package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
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
            .pin_1_mark = .none,
        };
    };
}

pub fn _0603(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
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
            .pin_1_mark = .none,
        };
    };
}

pub fn _0402(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
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
            .pin_1_mark = .none,
        };
    };
}

pub fn _0201(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }
        
        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
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
            .pin_1_mark = .none,
        };
    };
}

pub fn K1206(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 1600, .tolerance_um = 150 },
                .height = .{ .nominal_um = 3200, .tolerance_um = 150 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 1600, .tolerance_um = 150 },
                .height = .{ .nominal_um = 3200, .tolerance_um = 150 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 4,
            .pins_on_first_side = 2,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 1600, .tolerance_um = 150 },
            .pin_seating = .{ .nominal_um = 500, .tolerance_um = 250 },
            .pin_1_mark = .none,
        };
    };
}

pub fn K0805(comptime max_z_um: comptime_int, package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 1250, .tolerance_um = 100 },
                .height = .{ .nominal_um = 2000, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 1250, .tolerance_um = 100 },
                .height = .{ .nominal_um = 2000, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 4,
            .pins_on_first_side = 2,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 1250, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 400, .tolerance_um = 200 },
            .pin_1_mark = .none,
        };
    };
}

pub fn K0603(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 800, .tolerance_um = 100 },
                .height = .{ .nominal_um = 1600, .tolerance_um = 100 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 800, .tolerance_um = 100 },
                .height = .{ .nominal_um = 1600, .tolerance_um = 100 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 4,
            .pins_on_first_side = 2,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 800, .tolerance_um = 100 },
            .pin_seating = .{ .nominal_um = 300, .tolerance_um = 150 },
            .pin_1_mark = .none,
        };
    };
}

pub fn K0402(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }

        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 500, .tolerance_um = 50 },
                .height = .{ .nominal_um = 1000, .tolerance_um = 50 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 500, .tolerance_um = 50 },
                .height = .{ .nominal_um = 1000, .tolerance_um = 50 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 4,
            .pins_on_first_side = 2,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 500, .tolerance_um = 50 },
            .pin_seating = .{ .nominal_um = 250, .tolerance_um = 100 },
            .pin_1_mark = .none,
        };
    };
}

pub fn K0201(comptime max_z_um: comptime_int, comptime package_name: []const u8) type {
    return struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }
        
        pub const data: fp.SMD_Data = .{
            .package_name = package_name,
            .body = .{
                .width  = .{ .nominal_um = 300, .tolerance_um = 30 },
                .height = .{ .nominal_um = 600, .tolerance_um = 30 },
            },
            .overall = .{
                .width  = .{ .nominal_um = 300, .tolerance_um = 30 },
                .height = .{ .nominal_um = 600, .tolerance_um = 30 },
            },
            .max_z = .{ .nominal_um = max_z_um, .tolerance_um = 0 },
            .total_pins = 4,
            .pins_on_first_side = 2,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .{ .nominal_um = 300, .tolerance_um = 30 },
            .pin_seating = .{ .nominal_um = 150, .tolerance_um = 50 },
            .pin_1_mark = .none,
        };
    };
}

pub const taiyo_yuden = struct {
    // NRS5040 series, 4.9mm x 4.9mm
    pub const NRS5040 = struct {
        pub const pkg: Package = .{
            .default_footprint = fp.SMD(data, .normal),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: enums.Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...2 => true,
                else => false,
            };
        }
        
        pub const data: fp.SMD_Data = .{
            .package_name = "NRS5040",
            .body = .{
                .width  = .init_mm(4.9, 0.2),
                .height = .init_mm(4.9, 0.2),
            },
            .overall = .{
                .width  = .init_mm(4.9, 0.2),
                .height = .init_mm(4.9, 0.2),
            },
            .max_z = .init_mm(4.1, 0),
            .total_pins = 2,
            .pins_on_first_side = 1,
            .pin_pitch = .{ .nominal_um = 0, .tolerance_um = 0 },
            .pin_width = .init_mm(3.8, 0.2),
            .pin_seating = .init_mm(1.4, 0.1),
            .pin_1_mark = .none,
        };
    };
};

const SOT_Data = footprints.SOT_Data;
const SMD_Data = footprints.SMD_Data;
const fp = footprints;
const footprints = @import("../footprints.zig");
const enums = @import("../enums.zig");
const Package = @import("../Package.zig");
const std = @import("std");