// e.g. https://www.raltron.com/webproducts/specs/CRYSTAL/RH100-12.000-12-1010-X-TR-NS2.pdf
pub const SMD_3200x2500um = struct {
    pub const pkg: Package = .{
        .default_footprint = fp.SMD_Crystal(data, .normal),
        .has_pin = has_pin,
    };

    pub fn has_pin(pin: Pin_ID) bool {
        return switch (@intFromEnum(pin)) {
            1...4 => true,
            else => false,
        };
    }

    pub const data: SMD_Crystal_Data = .{
        .package_name = "SMD Crystal (3.2mm x 2.5mm)",
        .overall = .{
            .width  = .init_mm(3.2, 0.2),
            .height = .init_mm(2.5, 0.2),
        },
        .max_z = .init_mm(0.7, 0.1),

        .land_size = .{
            .width = .init_mm(1.0, 0),
            .height = .init_mm(0.9, 0),
        },
    };
};

const SMD_Crystal_Data = footprints.SMD_Crystal_Data;
const fp = footprints;
const footprints = @import("../footprints.zig");
const Pin_ID = enums.Pin_ID;
const enums = @import("../enums.zig");
const kicad = @import("../kicad.zig");
const Package = @import("../Package.zig");
const std = @import("std");