fn mm(um: usize) f32 {
    const umf: f32 = @floatFromInt(um);
    return umf / 1000;
}

fn draw_rect(rect: zoink.footprints.Rect, color: zgp.Color_UB4, border_color: zgp.Color_UB4) !void {
    const width = mm(rect.width.nominal_um);
    const width_tolerance = mm(rect.width.tolerance_um);
    const width_min = width - width_tolerance;

    const height = mm(rect.height.nominal_um);
    const height_tolerance = mm(rect.height.tolerance_um);
    const height_min = height - height_tolerance;

    zgp.set_color_unorm(color);
    try zgp.draw_bordered_rect(-width_min/2, -height_min/2, width_min, height_min, width_tolerance/2, height_tolerance/2, border_color);
}


const body_color: zgp.Color_UB4 = .{ .r = 40, .g = 40, .b = 40 };
const body_tol_color: zgp.Color_UB4 = .{ .r = 0, .g = 0, .b = 0 };

const pin_color: zgp.Color_UB4 = .{ .r = 195, .g = 144, .b = 60 };
const pin_tol_color: zgp.Color_UB4 = .{ .r = 240, .g = 200, .b = 160 };

pub fn draw_smd(data: zoink.footprints.SMD_Data) !void {
    draw_rect(data.body, body_color, body_tol_color) catch unreachable;

    const pins_on_second_side = (data.total_pins / 2) - data.pins_on_first_side;

    switch (data.pin1) {
        .south_westmost => {
            var pin: usize = 1;
            try draw_smd_pins(data, .south, pin, data.pins_on_first_side);
            pin += data.pins_on_first_side;
            try draw_smd_pins(data, .east, pin, pins_on_second_side);
            pin += pins_on_second_side;
            try draw_smd_pins(data, .north, pin, data.pins_on_first_side);
            pin += data.pins_on_first_side;
            try draw_smd_pins(data, .west, pin, pins_on_second_side);
        },
        .west_middle => {
            var pin: usize = 1 + data.total_pins - data.pins_on_first_side / 2;
            try draw_smd_pins(data, .west, pin, data.pins_on_first_side);
            pin = 1 + (data.pins_on_first_side + 1) / 2;
            try draw_smd_pins(data, .south, pin, pins_on_second_side);
            pin += pins_on_second_side;
            try draw_smd_pins(data, .east, pin, data.pins_on_first_side);
            pin += data.pins_on_first_side;
            try draw_smd_pins(data, .north, pin, pins_on_second_side);
        },
    }

    if (data.heat_slug) |heat_slug| {
        try draw_rect(heat_slug, pin_color, pin_tol_color);
    }
}

fn draw_smd_pins(data: zoink.footprints.SMD_Data, side: zoink.footprints.Side, first_pin: usize, pins_on_side: usize) !void {
    if (pins_on_side == 0) return;

    try zgp.push_transform();

    switch (side) {
        .west => zgp.rotate(std.math.pi * 3.0 / 2.0),
        .east => zgp.rotate(std.math.pi / 2.0),
        .north => zgp.rotate(std.math.pi),
        .south => {},
    }

    const overall_dim = switch (side) {
        .east, .west => mm(data.overall.width.nominal_um),
        .north, .south => mm(data.overall.height.nominal_um),
    };

    const seating_mm = mm(data.pin_seating.nominal_um);
    const pin_pitch_mm = mm(data.pin_pitch.nominal_um);
    const pins_on_side_f: f32 = @floatFromInt(pins_on_side);

    zgp.translate(-pin_pitch_mm * (pins_on_side_f - 1) / 2, (seating_mm - overall_dim) / 2);

    // zgp.set_color_rgb(0.85, 0.85, 0.85);
    // try zgp.draw_line(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = -5 });

    for (0..pins_on_side) |po| {
        defer zgp.translate(pin_pitch_mm, 0);

        var pin = first_pin + po;
        if (pin > data.total_pins) pin -= data.total_pins;
        if (pin == 1) {
            try zgp.push_transform();
            zgp.translate(0, -(seating_mm + pin_pitch_mm * 1.5) / 2);

            zgp.set_color_rgb(0.85, 0.85, 0.85);

            try zgp.draw_triangle(
                .{ .x = 0,               .y = pin_pitch_mm/2 },
                .{ .x = -pin_pitch_mm/2, .y = -pin_pitch_mm/2 },
                .{ .x = pin_pitch_mm/2,  .y = -pin_pitch_mm/2 }
            );

            try zgp.pop_transform();
        }
        if (std.mem.indexOfScalar(usize, data.omitted_pins, pin)) |_| {
            continue;
        }

        try draw_rect(.{
            .width = data.pin_width,
            .height = .{
                .nominal_um = data.pin_seating.nominal_um,
                .tolerance_um = data.pin_seating.tolerance_um + switch (side) {
                    .east, .west => data.overall.width.tolerance_um,
                    .north, .south => data.overall.height.tolerance_um,
                },
            },
        }, pin_color, pin_tol_color);
    }

    try zgp.pop_transform();
}

const zoink = @import("zoink");
const zgp = @import("zokol_gp.zig");
const std = @import("std");