pub const M2_NPTH = NPTH("M2", 2400, 3800);
pub const @"M2.5_NPTH" = NPTH("M2.5", 3000, 4750);
pub const M3_NPTH = NPTH("M3", 3500, 5700);
pub const @"M3.5_NPTH" = NPTH("M3.5", 4100, 6650);
pub const M4_NPTH = NPTH("M4", 4600, 7600);
pub const M5_NPTH = NPTH("M5", 5700, 9500);

pub const M2_PTH = PTH("M2", 2400, 3800, 8, 300);
pub const @"M2.5_PTH" = PTH("M2.5", 3000, 4750, 8, 300);
pub const M3_PTH = PTH("M3", 3500, 5700, 8, 300);
pub const @"M3.5_PTH" = PTH("M3.5", 4100, 6650, 8, 300);
pub const M4_PTH = PTH("M4", 4600, 7600, 8, 500);
pub const M5_PTH = PTH("M5", 5700, 9500, 8, 500);

pub fn NPTH(comptime name: []const u8, comptime hole_diameter_um: comptime_int, comptime outer_diameter_um: comptime_int) type {
    var result: Footprint = .{
        .kind = .through_hole,
        .name = name,
        .exclude_from_position_files = true,
        .exclude_from_bom = true,
    };

    result.pads = &.{
        kicad.Pad {
            .pin = @enumFromInt(0),
            .kind = .non_plated_through_hole,
            .location = .init_mm(0, 0),
            .w = .{ .um = outer_diameter_um },
            .h = .{ .um = outer_diameter_um },
            .hole_w = .{ .um = hole_diameter_um },
            .hole_h = .{ .um = hole_diameter_um },
            .shape = .oval,
            .layers = footprints.through_hole_layers,
            .copper_layers = .all,
            .teardrops = .{},
        },
    };

    const final_footprint = result;
    
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &final_footprint,
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: Pin_ID) bool {
            return @intFromEnum(pin) == 0;
        }
    };
}


pub fn PTH(comptime name: []const u8, comptime hole_diameter_um: comptime_int, comptime pad_diameter_um: comptime_int, comptime num_vias: comptime_int, comptime via_diameter_um: comptime_int) type {
    var result: Footprint = .{
        .kind = .through_hole,
        .name = name,
        .exclude_from_position_files = true,
        .exclude_from_bom = true,
    };

    result.pads = &.{
        kicad.Pad {
            .pin = @enumFromInt(0),
            .kind = .through_hole,
            .location = .init_mm(0, 0),
            .w = .{ .um = pad_diameter_um },
            .h = .{ .um = pad_diameter_um },
            .hole_w = .{ .um = hole_diameter_um },
            .hole_h = .{ .um = hole_diameter_um },
            .shape = .oval,
            .layers = footprints.through_hole_layers,
            .copper_layers = .all,
            .teardrops = .{},
        },
    };


    for (0..num_vias) |v| {
        const xf: zm.Mat3 = footprints.rotation(@as(f64, std.math.tau) * v / num_vias);
        result.pads = result.pads ++ .{
            kicad.Pad {
                .pin = @enumFromInt(0),
                .kind = .through_hole,
                .location = .init_um_transformed(xf, 0, (hole_diameter_um + pad_diameter_um) / 4),
                .w = .{ .um = via_diameter_um + 100 },
                .h = .{ .um = via_diameter_um + 100 },
                .hole_w = .{ .um = via_diameter_um },
                .hole_h = .{ .um = via_diameter_um },
                .shape = .oval,
                .layers = footprints.through_hole_layers,
                .copper_layers = .all,
                .teardrops = .{},
            },
        };
    }

    const final_footprint = result;
    
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &final_footprint,
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: Pin_ID) bool {
            return @intFromEnum(pin) == 0;
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Footprint = kicad.Footprint;
const Package = @import("../Package.zig");
const footprints = @import("../footprints.zig");
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const zm = @import("zm");
const std = @import("std");
