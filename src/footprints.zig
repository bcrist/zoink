pub const Density = enum {
    loose,
    normal,
    dense,
};

pub const Dim = struct {
    nominal_um: usize, // dimension in micrometers
    tolerance_um: usize, // measured dimension may be +/- this much

    pub fn init_mm(nominal: comptime_float, tolerance: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round(nominal * 1000)),
            .tolerance_um = @intFromFloat(@round(tolerance * 1000)),
        };
    }

    pub fn init_mm_range(min: comptime_float, max: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round((min + max) * 500)),
            .tolerance_um = @intFromFloat(@round(@abs(max - min) * 500)),
        };
    }

    pub fn init_mil(nominal: comptime_float, tolerance: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round(nominal * 25.4)),
            .tolerance_um = @intFromFloat(@round(tolerance * 25.4)),
        };
    }

    pub fn init_mil_range(min: comptime_float, max: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round((min + max) * 12.7)),
            .tolerance_um = @intFromFloat(@round(@abs(max - min) * 12.7)),
        };
    }

    pub fn init_inches(nominal: comptime_float, tolerance: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round(nominal * 25400)),
            .tolerance_um = @intFromFloat(@round(tolerance * 25400)),
        };
    }

    pub fn init_inches_range(min: comptime_float, max: comptime_float) Dim {
        return .{
            .nominal_um = @intFromFloat(@round((min + max) * 12700)),
            .tolerance_um = @intFromFloat(@round(@abs(max - min) * 12700)),
        };
    }

    pub fn min_um(self: Dim) usize {
        return self.nominal_um - self.tolerance_um;
    }

    pub fn max_um(self: Dim) usize {
        return self.nominal_um + self.tolerance_um;
    }
};

pub const Rect = struct {
    width: Dim,
    height: Dim,
};

pub const Offset_Rect = struct {
    x_um: isize,
    y_um: isize,
    width: Dim,
    height: Dim,
};

pub const Side = enum {
    north,
    south,
    west,
    east,
};

pub const Pin1 = enum {
    south_westmost,
    west_middle, // PLCC; for even number of pins, round to the south
};

pub const Pin1_Mark_Type = enum {
    none,
    arrow,
    line,
};

/// Single inline packages, with pins extending directly beneath center of body.
/// Pin 1 is the westmost pin.
/// The west/southwest/south side of the body may have a notch to indicate pin 1.
/// All pins have the same dimensions and pitch.
/// Some pins may be omitted.
///
/// This footprint type is suitable for:
///   * through-hole transistors
///   * through-hole voltage regulators
///   * some delay lines
///   * some reed relays
pub const SIL_Data = struct {
    package_name: []const u8,

    body: Rect,
    max_z: Dim,
    body_thickness: Dim, // leadframe assumed to be placed half thickness from top of body (max_z)

    // Note this also includes any omitted pins, so the actual physical number of pins (and logical max pin number) may be less.
    total_pins: usize,

    pin_pitch: Dim, // typically 100mil; distance between adjacent pin centers
    pin_width: Dim, // typically ~18mil; hole diameter must be at least sqrt(pin_width^2 + pin_thickness^2)
    pin_thickness: Dim, // typically ~10mil, a.k.a. leadframe thickness
    pin_width_above_seating: Dim, // sometimes there is a "bulge" in leads from how leadframe is trimmed
    pin_length: Dim, // typically ~150mil; max excursion below the seating plane

    // Pin numbers (as they would be defined for a variant with no omitted pins) that do not physically exist.
    // Parts cann't reference omitted pins; they are not assigned pin numbers or Pin_IDs
    // This feature is mainly used for delay lines and transformers.
    omitted_pins: []const usize = &.{},

    pub fn format(self: SIL_Data, writer: *std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn SIL(comptime data: SIL_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .through_hole,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}

/// Rectangular dual inline packages, with square leads/pads on the edges of 2 sides.
/// The same number of pins are placed on opposite sides.
/// Pin 1 is the westmost pin on the south side.
/// The southwest corner or west side of the body may have a notch to indicate pin 1.
/// All pins have the same dimensions and pitch.
/// Some pins may be omitted.
///
/// This footprint type is suitable for most through-hole ICs and some analog delay lines and transformers
/// It could be used for 4-pin hermetically sealed oscillator/SAW filter cans, but is not recommended.
/// This footprint is not usable for:
///  - SMD/BGA packages
///  - PGA packages
///  - SIP/SIL packages
///  - ZIP/ZIL packages
///  - DZIP/DZIL packages
///  - through hole transistor/passive packages
pub const DIL_Data = struct {
    package_name: []const u8,

    body: Rect,
    overall: Rect, // includes pins
    max_z: Dim,
    body_thickness: Dim, // leadframe assumed to be placed half thickness from top of body (max_z)

    // Note this also includes any omitted pins, so the actual physical number of pins (and logical max pin number) may be less.
    total_pins: usize,

    pin_pitch: Dim, // typically 100mil; distance between adjacent pin centers
    row_spacing: Dim, // typically 300mil, 400mil, 600mil, or 900mil; distance between centers of two rows of pins
    pin_width: Dim, // typically ~18mil; hole diameter must be at least sqrt(pin_width^2 + pin_thickness^2)
    pin_thickness: Dim, // typically ~10mil, a.k.a. leadframe thickness
    pin_width_above_seating: Dim, // typically ~50mil
    pin_length: Dim, // typically ~150mil; max excursion below the seating plane

    // Pin numbers (as they would be defined for a variant with no omitted pins) that do not physically exist.
    // Parts cann't reference omitted pins; they are not assigned pin numbers or Pin_IDs
    // This feature is mainly used for delay lines and transformers.
    omitted_pins: []const usize = &.{},

    pub fn format(self: DIL_Data, writer: *std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn DIL(comptime data: DIL_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .through_hole,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}


/// Rectangular SMD package, with square leads/pads on the edges of 2 or 4 sides.
/// The same number of pins are placed on opposite sides.
/// There may be a different number of pins on vertical vs. horizontal sides
/// Pin 1 is either the westmost pin on the south side, or the center pin on the west side.
/// The southwest corner or west side of the body may have a notch to indicate pin 1.
/// All pins have the same dimensions and pitch.
/// Some pins may be omitted.
/// May include a single centered heat slug with arbitrary dimensions, which is always Pin_ID 0.
/// 
/// This footprint type is suitable for most SMD semiconductor packages, e.g.
/// 2-pin passive SMD components, SOT-23, SOT-323, SOIC, SSOP, TSSOP, SOJ, PLCC, QFP, QFN, DFN
/// It is not usable for:
///  - Through hole packages
///  - BGA packages
///  - SOT packages with non-uniform pin size (e.g. SOT-143, SOT-223)
///  - packages with offset pins
pub const SMD_Data = struct {
    package_name: []const u8,

    body: Rect,
    overall: Rect, // includes pins
    max_z: Dim,

    // Note this also includes any omitted pins, so the actual physical number of pins (and logical max pin number) may be less.
    total_pins: usize,
    pin1: Pin1 = .south_westmost,

    // The number of pins on the side that contains pin 1, which is either the south or west side
    // The number of pins on each of the other sides is (total_pins - 2 * pins_on_first_side) / 2
    pins_on_first_side: usize,

    pin_pitch: Dim,
    pin_width: Dim,

    // Length of pin that lies flat against the seating plane
    // For SOJ, the diameter of the curved J lead
    pin_seating: Dim,

    // Optional exposed pad / thermal pad / heatsink
    heat_slug: ?Rect = null,
    heat_slug_paste_areas: []const Offset_Rect = &.{},

    // Pin numbers (as they would be defined for a variant with no omitted pins) that do not physically exist.
    // Parts cann't reference omitted pins; they are not assigned pin numbers or Pin_IDs
    // This feature is used for SOT-23, some SOJ DRAM chips, etc.
    omitted_pins: []const usize = &.{},

    pin_1_mark: Pin1_Mark_Type = .arrow,

    pub fn format(self: SMD_Data, writer: *std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn SMD(comptime data: SMD_Data, comptime density: Density) *const Footprint {
    @setEvalBranchQuota(100_000);
    var result: Footprint = .{
        .kind = .smd,
        .name = data.package_name,
    };

    const body_w: f64 = @floatFromInt(data.body.width.nominal_um);
    const body_h: f64 = @floatFromInt(data.body.height.nominal_um);
    result.rects = &.{
        .{
            .start = .init_um(-body_w / 2, -body_h / 2),
            .end = .init_um(body_w / 2, body_h / 2),
            .layer = .fab_front,
            .stroke = .{
                .width = .init_mm(0.1),
            },
        },
    };

    const pins_on_second_side = (data.total_pins / 2) - data.pins_on_first_side;

    if (data.heat_slug) |heat_slug| {
        result.pads = result.pads ++ .{
            kicad.Pad {
                .pin = @enumFromInt(0),
                .kind = .smd,
                .location = .origin,
                .w = .{ .um = @intCast(heat_slug.width.nominal_um) },
                .h = .{ .um = @intCast(heat_slug.height.nominal_um) },
                .shape = .{ .rect = .{
                    .round_amount = .{ .numer = 1, .denom = 4 },
                    .chamfer_amount = .{},
                    .top_left = .rounded,
                    .top_right = .rounded,
                    .bottom_left = .rounded,
                    .bottom_right = .rounded,
                }},
                .layers = .initMany(if (data.heat_slug_paste_areas.len == 0) &.{
                    .copper_front,
                    .paste_front,
                    .soldermask_front,
                } else &.{
                    .copper_front,
                    .soldermask_front,
                }),
                .copper_layers = .all,
                .teardrops = .{},
            },
        };

        for (data.heat_slug_paste_areas) |area| {
            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(0),
                    .kind = .stencil_aperture,
                    .location = .{
                        .x = .{ .um = area.x_um },
                        .y = .{ .um = area.y_um },
                    },
                    .w = .{ .um = @intCast(area.width.nominal_um) },
                    .h = .{ .um = @intCast(area.height.nominal_um) },
                    .shape = .{ .rect = .{
                        .round_amount = .{},
                        .chamfer_amount = .{},
                    }},
                    .layers = .initOne(.paste_front),
                    .copper_layers = .all,
                    .teardrops = .{},
                },
            };
        }
    }

    switch (data.pin1) {
        .south_westmost => {
            var pin: usize = 1;
            add_smd_pads(&result, data, .south, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            add_smd_pads(&result, data, .east, pin, pins_on_second_side, density);
            pin += pins_on_second_side;
            add_smd_pads(&result, data, .north, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            add_smd_pads(&result, data, .west, pin, pins_on_second_side, density);
        },
        .west_middle => {
            var pin: usize = 1 + data.total_pins - data.pins_on_first_side / 2;
            add_smd_pads(&result, data, .west, pin, data.pins_on_first_side, density);
            pin = 1 + (data.pins_on_first_side + 1) / 2;
            add_smd_pads(&result, data, .south, pin, pins_on_second_side, density);
            pin += pins_on_second_side;
            add_smd_pads(&result, data, .east, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            add_smd_pads(&result, data, .north, pin, pins_on_second_side, density);
        },
    }

    const final_result = comptime result;
    return &final_result;
}
fn add_smd_pads(
    comptime result: *Footprint,
    comptime data: SMD_Data,
    comptime side: Side,
    comptime first_pin: usize,
    comptime pins_on_side: usize,
    comptime density: Density,
) void {
    if (pins_on_side == 0) return;
    comptime {
        var xf: zm.Mat3 = switch (side) {
            .west => rotate_90,
            .east => rotate_270,
            .north => rotate_180,
            .south => .identity(),
        };

        const is_west_east = switch (side) {
            .west, .east => true,
            .north, .south => false,
        };

        const body_dim: f64 = @floatFromInt(if (is_west_east) data.body.width.nominal_um else data.body.height.nominal_um);
        const overall_dim: f64 = @floatFromInt(if (is_west_east) data.overall.width.nominal_um else data.overall.height.nominal_um);
        const overall_dim_max: f64 = @floatFromInt(if (is_west_east) data.overall.width.max_um() else data.overall.height.max_um());
        const seating: f64 = @floatFromInt(data.pin_seating.nominal_um);
        const pin_pitch: f64 = @floatFromInt(data.pin_pitch.nominal_um);
        const max_pin_width: f64 = @floatFromInt(data.pin_width.max_um());
        const pins_on_side_f: f64 = @floatFromInt(pins_on_side);

        const pin_length = @max(seating, (overall_dim - body_dim) / 2);

        var pad_width = switch (density) {
            .dense => max_pin_width,
            .normal => max_pin_width * 9 / 8,
            .loose => max_pin_width * 5 / 4,
        };
        if (pin_pitch > 200 and pad_width > pin_pitch - 100) {
            pad_width = pin_pitch - 100;
        }

        const pad_length = switch (density) {
            .dense => seating + (overall_dim_max - overall_dim) / 2,
            .normal => seating + (overall_dim_max - overall_dim) / 2 + if (pins_on_side_f > 1 and pin_pitch > 0) 500 else 250,
            .loose => seating + (overall_dim_max - overall_dim) / 2 + if (pins_on_side_f > 1 and pin_pitch > 0) 1500 else 500,
        };

        const pin_offset = -pin_pitch * (pins_on_side_f - 1) / 2;
        const side_origin = overall_dim / 2;

        xf = xf.multiply(.translation(pin_offset, side_origin));

        for (0..pins_on_side) |po| {
            var pin = first_pin + po;
            if (pin > data.total_pins) pin -= data.total_pins;
            defer xf = xf.multiply(.translation(pin_pitch, 0));

            if (std.mem.indexOfScalar(usize, data.omitted_pins, pin)) |_| {
                continue;
            }

            result.rects = result.rects ++ .{
                kicad.Rect {
                    .start = .init_um_transformed(xf, -max_pin_width / 2, -pin_length ),
                    .end = .init_um_transformed(xf, max_pin_width / 2, (overall_dim_max - overall_dim) / 2),
                    .stroke = .{ .width = .zero },
                    .fill =  true,
                    .layer = .fab_front,
                },
            };

            const xf2 = xf.multiply(.translation(0, pad_length - seating - @min(pad_width, pad_length) / 2));

            result.pads = result.pads ++ .{
                kicad.Pad {
                    .pin = @enumFromInt(pin),
                    .kind = .smd,
                    .location = .init_um_transformed(xf2, 0, 0),
                    .rotation = switch (side) {
                        .west => kicad.Rotation.cw,
                        .east => kicad.Rotation.ccw,
                        .north => kicad.Rotation.flip,
                        .south => .{},
                    },
                    .w = .init_um(pad_width),
                    .h = .init_um(pad_length),
                    .shape = .{ .rect = .{
                        .round_amount = .{ .numer = 1, .denom = 4 },
                        .chamfer_amount = .{},
                        .top_left = .rounded,
                        .top_right = .rounded,
                        .bottom_left = .rounded,
                        .bottom_right = .rounded,
                    }},
                    .shape_offset = .{
                        .x = .zero,
                        .y = .init_um(-(pad_length - @min(pad_width, pad_length)) / 2),
                    },
                    .layers = std.EnumSet(Layer).initMany(&.{
                        .copper_front,
                        .paste_front,
                        .soldermask_front,
                    }),
                    .copper_layers = .all,
                    .teardrops = .{},
                },
            };
            
            if (pin == 1) switch (data.pin_1_mark) {
                .none => {},
                .arrow => {
                    const scale = if (pin_pitch == 0) @min(1000, pad_width) else pin_pitch;

                    const xf3 = xf2.multiply(.rotation(@as(f64, std.math.pi) / 5));
                    const xf4 = xf3.multiply(.translation(0, @min(pad_width, pad_length) * 0.75 + @min(500, scale * 0.25)));

                    result.polygons = result.polygons ++ .{
                        kicad.Polygon {
                            .points = &.{
                                .init_um_transformed(xf4, 0,             0),
                                .init_um_transformed(xf4, -scale * 0.4, scale),
                                .init_um_transformed(xf4, scale * 0.4,  scale),
                            },
                            .stroke = .{
                                .width = .init_mm(0.1),
                            },
                            .fill = true,
                        },
                    };
                },
                .line => {
                    const scale_x = pad_width / 2 + 400;
                    const scale_y = @min(pad_width, pad_length) / 2 + 400;

                    if (pin_pitch == 0 or po == 0) {
                        result.lines = result.lines ++ .{
                            kicad.Line {
                                .start = .init_um_transformed(xf2, -scale_x, -scale_y * 0.5),
                                .end = .init_um_transformed(xf2, -scale_x, scale_y)
                            },
                        };
                    }
                    result.lines = result.lines ++ .{
                        kicad.Line {
                            .start = .init_um_transformed(xf2, -scale_x, scale_y),
                            .end = .init_um_transformed(xf2, scale_x, scale_y)
                        },
                    };
                    if (pin_pitch == 0 or po == pins_on_side - 1) {
                        result.lines = result.lines ++ .{
                            kicad.Line {
                                .start = .init_um_transformed(xf2, scale_x, scale_y),
                                .end = .init_um_transformed(xf2, scale_x, -scale_y * 0.5)
                            },
                        };
                    }
                },
            };
        }
    }
}

/// Rectangular SMD package with a small number of non-uniform square leads/pads, e.g. SOT-143, SOT-223, DPAK
pub const SOT_Data = struct {
    package_name: []const u8,
    body: Rect,
    max_z: Dim,
    pins: []const struct {
        side: Side,
        position_um: isize, // negative values mean to the left or down; positive values mean to the right or up.
        width: Dim,
        length: Dim,
        seating: Dim, // portion of length that lies flat against the seating plane
    },

    pub fn format(self: SOT_Data, writer: *std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn SOT(comptime data: SOT_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .smd,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}

/// Rectangular PGA package with pins in a grid as used by PLCC-to-PGA adapters.
/// Only the two rows/columns nearest the edges are used.
/// The four corners of the grid are not populated.
/// Pin_ID assignment:
///     * Pin 1 is always on the west side, in the middle row, or the row above it.
///         * If `(plcc_rows + plcc_cols + 2) * 2` is divisible by 16, then pin 1 is in the row above it, and is in the "inner ring"
///         * Otherwise pin 1 is in the middle row, and part of the "outer ring"
///     * Assignment proceeds counter-clockwise, visiting the pin in the outer ring before the inner one.
///     * When reaching a corner, *both* outer pins is visited before the inner one
pub const PLCC_PGA_Data = struct {
    package_name: []const u8,
    body: Rect,
    max_z: Dim,
    pin_diameter: Dim,
    pin_length: Dim,
    plcc_rows: usize,
    plcc_cols: usize,
    
    pub fn format(self: PLCC_PGA_Data, writer: std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn PLCC_PGA(comptime data: PLCC_PGA_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .through_hole,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}

/// Rectangular PGA package with pins in a grid with uniform X/Y pitch
/// Pin_IDs are assigned left-to-right, then top-to-bottom
pub const PGA_Data = struct {
    package_name: []const u8,
    body: Rect,
    body_thickness: Dim,
    max_z: Dim,
    pin_diameter: Dim,
    pin_length: Dim,
    rows: usize, // Lettered, from top to bottom (when viewed from above)
    cols: usize, // Numbered, from left to right (when viewed from above)
    row_pitch: Dim = .init_mil(100, 0),
    col_pitch: Dim = .init_mil(100, 0),

    include_pins: []const Grid_Region = &.{ .all },
    exclude_pins: []const Grid_Region = &.{},

    pin_name_format_func: kicad.Pin_Name_Format_Func,
    
    pub fn format(self: PGA_Data, writer: std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn PGA(comptime data: PGA_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .through_hole,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}

/// Rectangular BGA package with balls in a grid with uniform X/Y pitch
/// Pin_IDs are assigned left-to-right, then top-to-bottom
pub const BGA_Data = struct {
    package_name: []const u8,
    body: Rect,
    max_z: Dim,
    ball_diameter: Dim,
    rows: usize, // Lettered, from top to bottom (when viewed from above)
    cols: usize, // Numbered, from left to right (when viewed from above)
    row_pitch: Dim,
    col_pitch: Dim,

    include_balls: []const Grid_Region = &.{ .all },
    exclude_balls: []const Grid_Region = &.{},

    pin_name_format_func: kicad.Pin_Name_Format_Func,
    
    pub fn format(self: BGA_Data, writer: std.io.Writer) !void {
        try writer.writeAll(self.package_name);
    }
};
pub fn BGA(comptime data: BGA_Data, comptime density: Density) *const Footprint {
    _ = density;

    var result: Footprint = .{
        .kind = .smd,
        .name = data.package_name,
    };

    _ = &result;
    
    const final_result = comptime result;
    return &final_result;
}

pub const Grid_Region = union (enum) {
    all,
    ring: struct {
        dist_from_edges: u32,
        thickness: u32,
    },
    rows: struct {
        dist_from_top: u32,
        row_count: u32,
        mirror: Mirror,
    },
    cols: struct {
        dist_from_left: u32,
        col_count: u32,
        mirror: Mirror,
    },
    corners: struct {
        width: u32,
        height: u32,
    },
    individual: struct {
        row: u32,
        col: u32,
        mirror: Mirror,
    },

    const Mirror = enum {
        none,
        ns,
        we,
        both, // opposite corner
        all, // all corners
    };

    pub fn apply(self: Grid_Region, comptime Width: usize, comptime Height: usize, mask: *[Height][Width]bool, set: bool) void {
        switch (self) {
            .all => for (mask) |*row| for (row) |*ball| {
                ball.* = set;
            },
            .ring => |info| for (0.., mask) |y, *row| for (0.., row) |x, *ball| {
                if (y < info.dist_from_edges) continue;
                if (x < info.dist_from_edges) continue;
                if (y + info.dist_from_edges >= Height) continue;
                if (x + info.dist_from_edges >= Width) continue;

                if (y >= info.dist_from_edges + info.thickness
                    and y + info.dist_from_edges + info.thickness < Height
                    and x >= info.dist_from_edges + info.thickness
                    and x + info.dist_from_edges + info.thickness < Width
                ) continue;

                ball.* = set;
            },
            .rows => |info| {
                for (info.dist_from_top .. info.dist_from_top + info.row_count) |y| {
                    for (&mask[y]) |*ball| ball.* = set;
                    switch (info.mirror) {
                        .none, .we => {},
                        .ns, .both, .all => {
                            for (&mask[Height - y - 1]) |*ball| ball.* = set;
                        },
                    }
                }
            },
            .cols => |info| {
                for (info.dist_from_left .. info.dist_from_left + info.col_count) |x| {
                    for (mask) |*row| {
                        row[x] = set;
                        switch (info.mirror) {
                            .none, .ns => {},
                            .we, .both, .all => {
                                row[Width - x - 1] = set;
                            },
                        }
                    }
                }
            },
            .corners => |info| {
                for (0..info.height) |y| for (0..info.width) |x| {
                    mask[y][x] = set;
                    mask[y][Width - x - 1] = set;
                    mask[Height - y - 1][x] = set;
                    mask[Height - y - 1][Width - x - 1] = set;
                };
            },
            .individual => |info| {
                mask[info.row][info.col] = set;
                const mirror_row = Height - info.row - 1;
                const mirror_col = Width - info.col - 1;
                switch (info.mirror) {
                    .none => {},
                    .ns => mask[mirror_row][info.col] = set,
                    .we => mask[info.row][mirror_col] = set,
                    .both => mask[mirror_row][mirror_col] = set,
                    .all => {
                        mask[mirror_row][info.col] = set;
                        mask[info.row][mirror_col] = set;
                        mask[mirror_row][mirror_col] = set;
                    },
                }
            },
        }
    }
};

const rotate_90: zm.Mat3 = .{
    .data = .{
        0, -1, 0,
        1,  0, 0,
        0,  0, 1,
    },
};

const rotate_180: zm.Mat3 = .{
    .data = .{
        -1,  0, 0,
         0, -1, 0,
         0,  0, 1,
    },
};

const rotate_270: zm.Mat3 = .{
    .data = .{
         0, 1, 0,
        -1, 0, 0,
         0, 0, 1,
    },
};

const Footprint = kicad.Footprint;
const Layer = kicad.Layer;
const kicad = @import("kicad.zig");
const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const zm = @import("zm");
const std = @import("std");
