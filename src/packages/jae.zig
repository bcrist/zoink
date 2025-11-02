pub const Mating_Type = enum {
    plug,
    plug_right_angle,
    receptacle,
    receptacle_right_angle,
};

pub fn TX24_TX25(comptime total_pins: usize, comptime mating_type: Mating_Type) type {
    @setEvalBranchQuota(100_000);
    var result: Footprint = .{
        .kind = .through_hole,
        .name = std.fmt.comptimePrint("{s}-{}{s}-{s}-H1E", .{
            switch (mating_type) {
                .plug, .plug_right_angle => "TX25",
                .receptacle, .receptacle_right_angle => "TX24",
            },
            total_pins,
            switch (mating_type) {
                .plug, .plug_right_angle => "P",
                .receptacle, .receptacle_right_angle => "R",
            },
            switch (mating_type) {
                .plug, .receptacle => "6ST",
                .plug_right_angle, .receptacle_right_angle => "LT",
            },
        }),
    };

    const pin_pitch_um: f64 = 1270;
    const row_spacing_um: f64 = 1905;

    const hole_diameter_mm: f64 = 0.8;
    const pad_diameter_mm = 1.2;

    const mounting_hole_diameter_mm: f64 = 2.2;
    const mounting_pad_diameter_mm: f64 = 3.2;
    
    const overall_width_mm: f64 = 0.4 + switch (total_pins) {
        30 => 31.7,
        40 => 38,
        50 => 44.4,
        60 => 50.7,
        80 => 63.4,
        100 => 76.1,
        120 => 88.8,
        else => unreachable,
    };
    const overall_height_mm: f64 = switch (mating_type) {
        .plug, .receptacle => 8.2,
        .plug_right_angle => 16,
        .receptacle_right_angle => 9.6,
    };
    const min_y_mm: f64 = switch (mating_type) {
        .plug, .receptacle => -4.1,
        .plug_right_angle => -9.5,
        .receptacle_right_angle => -3.1,
    };
    const max_y_mm: f64 = min_y_mm + overall_height_mm;
    const courtyard_expansion_mm: f64 = 1;
    const mounting_hole_width_mm: f64 = switch (total_pins) {
        30 => 27.94,
        40 => 34.29,
        50 => 40.64,
        60 => 46.99,
        80 => 59.69,
        100 => 72.39,
        120 => 85.09,
        else => unreachable,
    };

    result.pads = result.pads ++ .{
        kicad.Pad {
            .pin = @enumFromInt(0),
            .kind = .through_hole,
            .location = .init_mm(-mounting_hole_width_mm / 2, 0),
            .w = .init_mm(mounting_pad_diameter_mm),
            .h = .init_mm(mounting_pad_diameter_mm),
            .hole_w = .init_mm(mounting_hole_diameter_mm),
            .hole_h = .init_mm(mounting_hole_diameter_mm),
            .shape = .oval,
            .layers = footprints.through_hole_layers,
            .copper_layers = .all,
            .teardrops = .{},
        },
        kicad.Pad {
            .pin = @enumFromInt(0),
            .kind = .through_hole,
            .location = .init_mm(mounting_hole_width_mm / 2, 0),
            .w = .init_mm(mounting_pad_diameter_mm),
            .h = .init_mm(mounting_pad_diameter_mm),
            .hole_w = .init_mm(mounting_hole_diameter_mm),
            .hole_h = .init_mm(mounting_hole_diameter_mm),
            .shape = .oval,
            .layers = footprints.through_hole_layers,
            .copper_layers = .all,
            .teardrops = .{},
        },
    };

    result.rects = result.rects ++ .{
        kicad.Rect {
            .start = .init_mm(-overall_width_mm / 2 - courtyard_expansion_mm, min_y_mm - courtyard_expansion_mm),
            .end = .init_mm(overall_width_mm / 2 + courtyard_expansion_mm, max_y_mm + courtyard_expansion_mm),
            .layer = .courtyard_front,
            .stroke = .{
                .width = .init_mm(0.01),
            },
        },
        kicad.Rect {
            .start = .init_mm(-overall_width_mm / 2, min_y_mm),
            .end = .init_mm(overall_width_mm / 2, max_y_mm),
            .layer = .fab_front,
            .stroke = .{
                .width = .init_mm(0.1),
            },
        },
    };

    if (mating_type == .receptacle_right_angle) {
        result.rects = result.rects ++ .{
            kicad.Rect {
                .start = .init_mm(-mounting_hole_width_mm / 2, min_y_mm - 7.5),
                .end = .init_mm(mounting_hole_width_mm / 2, min_y_mm),
                .layer = .fab_front,
                .stroke = .{
                    .width = .init_mm(0.1),
                },
            },
        }; 
    }

    const xf_base: zm.Mat3 = .translation(-pin_pitch_um * @as(f64, @floatFromInt(total_pins / 2 - 1)) / 2, switch (mating_type) {
        .plug, .receptacle => -row_spacing_um * 1.5,
        .plug_right_angle, .receptacle_right_angle => 0,
    });

    for (0 .. total_pins / 2) |raw_pin| {
        const y_offset: f64 = if (raw_pin % 2 == 0) row_spacing_um else 0;
        const xf: zm.Mat3 = xf_base.multiply(.translation(pin_pitch_um * @as(f64, @floatFromInt(raw_pin)), y_offset));

        if (raw_pin == 0) {
            footprints.generate_pin1_mark(&result, .arrow, .{
                .pad_origin = xf.multiply(.translation(0, 2 * row_spacing_um)),
                .pin_pitch = pin_pitch_um,
                .pad_width = pad_diameter_mm * 1000,
                .pad_length = pad_diameter_mm * 1000,
                .is_first_pin_on_side = false,
                .is_last_pin_on_side = false,
            });
        }

        result.pads = result.pads ++ .{
            kicad.Pad {
                .pin = @enumFromInt(raw_pin + 1),
                .kind = .through_hole,
                .location = .init_um_transformed(xf, 0, 2 * row_spacing_um),
                .w = .init_mm(pad_diameter_mm),
                .h = .init_mm(pad_diameter_mm),
                .hole_w = .init_mm(hole_diameter_mm),
                .hole_h = .init_mm(hole_diameter_mm),
                .shape = if (raw_pin == 0) .default_chamfered else .oval,
                .layers = footprints.through_hole_layers,
                .copper_layers = .connected_and_outside_only,
                .teardrops = .{},
            },
            kicad.Pad {
                .pin = @enumFromInt(raw_pin + 61),
                .kind = .through_hole,
                .location = .init_um_transformed(xf, 0, 0),
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

    const final_footprint = result;
    
    return struct {
        pub const pkg: Package = .{
            .default_footprint = &final_footprint,
            .has_pin = has_pin,
        };

        pub fn has_pin(pin: Pin_ID) bool {
            return switch (@intFromEnum(pin)) {
                0...total_pins => true,
                else => false,
            };
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
