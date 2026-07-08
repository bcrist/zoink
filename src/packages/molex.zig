pub const CGrid = struct {
    // generic dual row breakaway male header, 2.54mm pitch
    // https://www.molex.com/content/dam/molex/molex-dot-com/products/automated/en-us/salesdrawingpdf/702/70280/010897200_sd.pdf
    pub fn @"70280"(comptime pins: comptime_int) type {
        if ((pins & 1) != 0) @compileError("Expected even number of pins");

        var result: Footprint = .{
            .kind = .through_hole,
            .name = std.fmt.comptimePrint("70280-{d}", .{ pins }),
        };

        const pin_pitch_mm: f64 = 2.54;

        const hole_diameter_mm: f64 = 1.02;
        const pad_diameter_mm: f64 = 1.8;

        const courtyard_expansion_mm: f64 = 1;

        const x_left_mm: f64 = -pin_pitch_mm / 2;
        const x_right_mm: f64 = pin_pitch_mm * pins/2 - pin_pitch_mm / 2;

        for (0..pins/2) |col| {
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 1),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * col, 0),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 2),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * col, -pin_pitch_mm),
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
                .start = .init_mm(x_left_mm - courtyard_expansion_mm, pin_pitch_mm * -1.5 - courtyard_expansion_mm),
                .end = .init_mm(x_right_mm + courtyard_expansion_mm, pin_pitch_mm * 0.5 + courtyard_expansion_mm),
                .layer = .courtyard_front,
                .stroke = .{ .width = .init_mm(0.01) },
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, pin_pitch_mm * -1.5),
                .end = .init_mm(x_right_mm, pin_pitch_mm * 0.5),
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, pin_pitch_mm * -0.5),
                .end = .init_mm(x_left_mm + pin_pitch_mm, pin_pitch_mm * 0.5),
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

    // generic dual row male header, 2.54mm pitch, shrouded
    // https://www.molex.com/content/dam/molex/molex-dot-com/products/automated/en-us/salesdrawingpdf/702/70246/702461004_sd.pdf
    pub fn @"70246"(comptime pins: comptime_int) type {
        if ((pins & 1) != 0) @compileError("Expected even number of pins");

        var result: Footprint = .{
            .kind = .through_hole,
            .name = std.fmt.comptimePrint("70246-{d}", .{ pins }),
        };

        const pin_pitch_mm: f64 = 2.54;

        const hole_diameter_mm: f64 = 1.02;
        const pad_diameter_mm: f64 = 1.8;

        const courtyard_expansion_mm: f64 = 0.1;

        const x_left_mm: f64 = -5.08;
        const x_right_mm: f64 = pin_pitch_mm * (pins/2 - 1) + 5.08;

        const overall_height: f64 = 8.89;
        const overall_width = x_right_mm - x_left_mm;

        const y_top_mm: f64 = -overall_height / 2 - pin_pitch_mm / 2;
        const y_bottom_mm: f64 = y_top_mm + overall_height;

        const shroud_thickness_mm: f64 = 1.25;

        for (0..pins/2) |col| {
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 1),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * col, 0),
                    .w = .init_mm(pad_diameter_mm),
                    .h = .init_mm(pad_diameter_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .connected_and_outside_only,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(col * 2 + 2),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * col, -pin_pitch_mm),
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

        result.lines = &.{
            kicad.Line {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_right_mm, y_top_mm),
            },
            kicad.Line {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_left_mm, y_bottom_mm),
            },
            kicad.Line {
                .start = .init_mm(x_right_mm, y_top_mm),
                .end = .init_mm(x_right_mm, y_bottom_mm),
            },
            kicad.Line {
                .start = .init_mm(x_left_mm, y_bottom_mm),
                .end = .init_mm(x_left_mm + overall_width / 2 - 2.055, y_bottom_mm),
            },
            kicad.Line {
                .start = .init_mm(x_right_mm, y_bottom_mm),
                .end = .init_mm(x_right_mm - overall_width / 2 + 2.055, y_bottom_mm),
            },
        };

        result.rects = &.{
            kicad.Rect {
                .start = .init_mm(x_left_mm - courtyard_expansion_mm, y_top_mm - courtyard_expansion_mm),
                .end = .init_mm(x_right_mm + courtyard_expansion_mm, y_bottom_mm + courtyard_expansion_mm),
                .layer = .courtyard_front,
                .stroke = .{ .width = .init_mm(0.01) },
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_left_mm + shroud_thickness_mm, y_bottom_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_right_mm, y_top_mm),
                .end = .init_mm(x_right_mm - shroud_thickness_mm, y_bottom_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, y_top_mm),
                .end = .init_mm(x_right_mm, y_top_mm + shroud_thickness_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, y_bottom_mm),
                .end = .init_mm(x_left_mm + overall_width / 2 - 2.055, y_bottom_mm - shroud_thickness_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(x_right_mm, y_bottom_mm),
                .end = .init_mm(x_right_mm - overall_width / 2 + 2.055, y_bottom_mm - shroud_thickness_mm),
                .stroke = .{ .width = .init_mm(0) },
                .fill = true,
                .layer = .fab_front,
            },
            kicad.Rect {
                .start = .init_mm(pin_pitch_mm * -0.5, pin_pitch_mm * -0.5),
                .end = .init_mm(pin_pitch_mm * 0.5, pin_pitch_mm * 0.5),
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

pub const KK254 = struct {
    // generic single row breakaway male header, 2.54mm pitch
    // https://www.molex.com/content/dam/molex/molex-dot-com/products/automated/en-us/salesdrawingpdf/423/42375/022285034_sd.pdf
    pub fn @"42375"(comptime pins: comptime_int) type {
        var result: Footprint = .{
            .kind = .through_hole,
            .name = std.fmt.comptimePrint("42375-{d}", .{ pins }),
        };

        const pin_pitch_mm: f64 = 2.54;

        const hole_diameter_mm: f64 = 1.02;
        const pad_width_mm: f64 = 1.8;
        const pad_height_mm: f64 = 2.6;

        const courtyard_expansion_mm: f64 = 1;

        const overall_height: f64 = 2.49;

        const x_left_mm: f64 = -pin_pitch_mm / 2;
        const x_right_mm: f64 = pin_pitch_mm * pins - pin_pitch_mm / 2;

        for (0..pins) |i| {
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(1 + i),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * i, 0),
                    .w = .init_mm(pad_width_mm),
                    .h = .init_mm(pad_height_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
            };
        }

        result.rects = &.{
            kicad.Rect {
                .start = .init_mm(x_left_mm - courtyard_expansion_mm, -overall_height / 2 - courtyard_expansion_mm),
                .end = .init_mm(x_right_mm + courtyard_expansion_mm, overall_height / 2 + courtyard_expansion_mm),
                .layer = .courtyard_front,
                .stroke = .{ .width = .init_mm(0.01) },
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, -overall_height / 2),
                .end = .init_mm(x_right_mm, overall_height / 2),
            },
            kicad.Rect {
                .start = .init_mm(x_left_mm, -overall_height / 2),
                .end = .init_mm(x_left_mm + pin_pitch_mm, overall_height / 2),
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

    // 4-pin computer fan header (3 pins shrouded)
    // https://www.molex.com/en-us/products/part-detail/470531000?display=pdf
    pub const @"47053" = struct {
        pub const pkg: Package = .{
            .default_footprint = &footprint(),
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                1...4 => true,
                else => false,
            };
        }

        // https://www.molex.com/content/dam/molex/molex-dot-com/products/automated/en-us/salesdrawingpdf/470/47053/470531000_sd.pdf
        fn footprint() Footprint {
            var result: Footprint = .{
                .kind = .through_hole,
                .name = "47053",
            };

            const pin_pitch_mm: f64 = 2.54;

            const hole_diameter_mm: f64 = 1.02;
            const pad_width_mm: f64 = 1.8;
            const pad_height_mm: f64 = 2.6;

            const mounting_hole_diameter_mm: f64 = 1.25;
            
            const courtyard_expansion_mm: f64 = 1;

            const y_top_mm: f64 = -2.54;
            const y_bottom_mm: f64 = y_top_mm + 5.84;

            const x_left_mm: f64 = (10.2 - 7.62) / -2.0;
            const x_right_mm: f64 = x_left_mm + 10.2;

            result.pads = &.{
                kicad.Pad {
                    .pin = @enumFromInt(0),
                    .kind = .non_plated_through_hole,
                    .location = .init_mm(pin_pitch_mm * 2, -2.16),
                    .w = .init_mm(mounting_hole_diameter_mm),
                    .h = .init_mm(mounting_hole_diameter_mm),
                    .hole_w = .init_mm(mounting_hole_diameter_mm),
                    .hole_h = .init_mm(mounting_hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.npth_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(1),
                    .kind = .through_hole,
                    .location = .init_mm(0, 0),
                    .w = .init_mm(pad_width_mm),
                    .h = .init_mm(pad_height_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(2),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm, 0),
                    .w = .init_mm(pad_width_mm),
                    .h = .init_mm(pad_height_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(3),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * 2, 0),
                    .w = .init_mm(pad_width_mm),
                    .h = .init_mm(pad_height_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
                kicad.Pad {
                    .pin = @enumFromInt(4),
                    .kind = .through_hole,
                    .location = .init_mm(pin_pitch_mm * 3, 0),
                    .w = .init_mm(pad_width_mm),
                    .h = .init_mm(pad_height_mm),
                    .hole_w = .init_mm(hole_diameter_mm),
                    .hole_h = .init_mm(hole_diameter_mm),
                    .shape = .oval,
                    .layers = footprints.through_hole_layers,
                    .copper_layers = .all,
                    .teardrops = .{},
                },
            };

            // footprints.generate_pin1_mark(&result, .arrow, .{
            //     .pad_origin = .identity(),
            //     .pin_pitch = pin_pitch_mm * 1000,
            //     .pad_width = pad_diameter_mm * 1000,
            //     .pad_length = pad_diameter_mm * 1000,
            //     .is_first_pin_on_side = true,
            //     .is_last_pin_on_side = false,
            // });

            result.rects = &.{
                kicad.Rect {
                    .start = .init_mm(x_left_mm - courtyard_expansion_mm, y_top_mm - courtyard_expansion_mm),
                    .end = .init_mm(x_right_mm + courtyard_expansion_mm, y_bottom_mm + courtyard_expansion_mm),
                    .layer = .courtyard_front,
                    .stroke = .{ .width = .init_mm(0.01) },
                },
                kicad.Rect {
                    .start = .init_mm(x_left_mm, y_bottom_mm),
                    .end = .init_mm(x_right_mm, y_top_mm),
                },
                kicad.Rect {
                    .start = .init_mm(0, y_bottom_mm),
                    .end = .init_mm(pin_pitch_mm * 2, y_bottom_mm - 1),
                    .stroke = .{ .width = .init_mm(0) },
                    .fill = true,
                },
            };

            return result;
        }
    };
};

const Pin_ID = enums.Pin_ID;
const Footprint = kicad.Footprint;
const Package = @import("../Package.zig");
const footprints = @import("../footprints.zig");
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const zm = @import("zm");
const std = @import("std");
