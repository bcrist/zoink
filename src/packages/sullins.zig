// dual row female header, 2.54mm pitch
// https://s3.amazonaws.com/catalogspreads-pdf/PAGE123%20.100%20SFH11%20SERIES%20FEMALE%20HDR%20ST%20RA.pdf
pub const SFH11 = struct {
    // straight
    // https://drawings-pdf.s3.amazonaws.com/11160.pdf
    pub fn ST(comptime pins: comptime_int) type {
        if ((pins & 1) != 0) @compileError("Expected even number of pins");

        var result: Footprint = .{
            .kind = .through_hole,
            .name = std.fmt.comptimePrint("SFH11-PBPC-D{d:0>2}-ST-BK", .{ pins }),
        };

        const pin_pitch_mm: f64 = 2.54;

        const hole_diameter_mm: f64 = 1.02;
        const pad_diameter_mm: f64 = 1.8;

        const courtyard_expansion_mm: f64 = 1.3;

        const x_origin_mm: f64 = pin_pitch_mm * (pins/2 - 1) * -0.5;
        const x_left_mm: f64 = x_origin_mm - 3.81;
        const x_right_mm: f64 = x_origin_mm + pin_pitch_mm * (pins/2 - 1) + 3.81;

        const overall_height: f64 = 6;
        const overall_width = x_right_mm - x_left_mm;

        const y_top_mm: f64 = -overall_height / 2;
        const y_bottom_mm: f64 = overall_height / 2;

        const key_width_mm: f64 = 3.7;
        const key_height_mm: f64 = 1.0;

        for (0..pins/2) |col| {
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 1),
                    .kind = .through_hole,
                    .location = .init_mm(x_origin_mm + pin_pitch_mm * col, -pin_pitch_mm / 2),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = if (col == 0) .square else .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 2),
                    .kind = .through_hole,
                    .location = .init_mm(x_origin_mm + pin_pitch_mm * col, pin_pitch_mm / 2),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
            };
        }

        result.rects = &.{
            kicad.Rect {
                .start = .init_mm(x_left_mm - courtyard_expansion_mm, y_top_mm - courtyard_expansion_mm),
                .end = .init_mm(x_right_mm + courtyard_expansion_mm, y_bottom_mm + courtyard_expansion_mm),
                .layer = .courtyard_front,
                .stroke = .{ .width = .init_mm(0.01) },
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_right_mm, y_bottom_mm),
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm + overall_width / 2 - key_width_mm / 2, y_top_mm),
                .end = .init_mm(x_left_mm + overall_width / 2 + key_width_mm / 2, y_top_mm - key_height_mm),
            },
            kicad.Rect {
                .start = .init_mm(x_origin_mm + pin_pitch_mm * -0.5, 0),
                .end = .init_mm(x_origin_mm + pin_pitch_mm * 0.5, -pin_pitch_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
            },
        };

        const final_footprint = result;

        return struct {
            pub const pkg: Package = .{
                .default_footprint = &final_footprint,
                .has_pin = has_pin,
            };

            pub fn has_pin(pin: Pin_ID) bool {
                return switch (@intFromEnum(pin)) {
                    1...pins => true,
                    else => false,
                };
            }
        };
    }

    // right angle
    // https://drawings-pdf.s3.amazonaws.com/11161.pdf
    pub fn RA(comptime pins: comptime_int) type {
        if ((pins & 1) != 0) @compileError("Expected even number of pins");

        var result: Footprint = .{
            .kind = .through_hole,
            .name = std.fmt.comptimePrint("SFH11-PBPC-D{d:0>2}-RA-BK", .{ pins }),
        };

        const pin_pitch_mm: f64 = 2.54;

        const hole_diameter_mm: f64 = 1.02;
        const pad_diameter_mm: f64 = 1.8;

        const courtyard_expansion_mm: f64 = 1;

        const x_origin_mm: f64 = pin_pitch_mm * (pins/2 - 1) * -0.5;
        const x_left_mm: f64 = x_origin_mm - 3.81;
        const x_right_mm: f64 = x_origin_mm + pin_pitch_mm * (pins/2 - 1) + 3.81;

        const body_height: f64 = 8.5;
        const body_width = x_right_mm - x_left_mm;

        const y_bottom_mm: f64 = 10.1 + pin_pitch_mm / 2;
        const y_top_mm: f64 = y_bottom_mm - body_height;

        const key_width_mm: f64 = 3.7;

        for (0..pins/2) |col| {
            result.rects = result.rects ++ .{
                kicad.Rect {
                    .start = .init_mm(x_origin_mm + pin_pitch_mm * col - 0.3, pin_pitch_mm * -0.5),
                    .end = .init_mm(x_origin_mm + pin_pitch_mm * col + 0.3, y_top_mm),
                    .stroke = .{ .width = .init_mm(0) },
                    .fill = true,
                    .layer = .fab_front,
                },
            };
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 1),
                    .kind = .through_hole,
                    .location = .init_mm(x_origin_mm + pin_pitch_mm * col, pin_pitch_mm * -0.5),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = if (col == 0) .square else .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 2),
                    .kind = .through_hole,
                    .location = .init_mm(x_origin_mm + pin_pitch_mm * col, pin_pitch_mm * 0.5),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
            };
        }

        result.rects = result.rects ++ .{
            kicad.Rect {
                .start = .init_mm(x_left_mm - courtyard_expansion_mm, pin_pitch_mm * -0.5 - courtyard_expansion_mm),
                .end = .init_mm(x_right_mm + courtyard_expansion_mm, y_bottom_mm + courtyard_expansion_mm),
                .layer = .courtyard_front,
                .stroke = .{ .width = .init_mm(0.01) },
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_right_mm, y_bottom_mm),
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm + body_width / 2 - key_width_mm / 2, y_top_mm),
                .end = .init_mm(x_left_mm + body_width / 2 + key_width_mm / 2, y_bottom_mm),
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_origin_mm + pin_pitch_mm * -0.5, 0),
                .end = .init_mm(x_origin_mm + pin_pitch_mm * 0.5, -pin_pitch_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
            },
        };

        const final_footprint = result;

        return struct {
            pub const pkg: Package = .{
                .default_footprint = &final_footprint,
                .has_pin = has_pin,
            };

            pub fn has_pin(pin: Pin_ID) bool {
                return switch (@intFromEnum(pin)) {
                    1...pins => true,
                    else => false,
                };
            }
        };
    }
};

const Pin_ID = enums.Pin_ID;
const Footprint = kicad.Footprint;
const Package = @import("../Package.zig");
const footprints = @import("../footprints.zig");
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const zm = @import("zm");
const std = @import("std");
