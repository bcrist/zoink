pub const Density = enum {
    loose,
    normal,
    dense,
};

pub const Dim = struct {
    nominal_um: usize, // dimension in micrometers
    tolerance_um: usize, // measured dimension may be +/- this much
};

pub const Rect = struct {
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

fn mils_to_microns(mils: isize) isize {
    return ((mils * 254) + 6) / 10;
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
    heat_slug_paste_area: ?Rect = null,

    // Pin numbers (as they would be defined for a variant with no omitted pins) that do not physically exist.
    // Parts cann't reference omitted pins; they are not assigned pin numbers or Pin_IDs
    // This feature is used for SOT-23, some SOJ DRAM chips, etc.
    omitted_pins: []const usize = &.{},

    pub fn format(self: SMD_Data, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.package_name);
    }
};
pub fn SMD(comptime data: SMD_Data, comptime density: Density) type {
    var pads: []Footprint.Pad = &.{};

    const pins_on_second_side = (data.total_pins / 2) - data.pins_on_first_side;

    switch (data.pin1) {
        .south_westmost => {
            var pin: usize = 1;
            pads = add_smd_pads(pads, data, .south, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            pads = add_smd_pads(pads, data, .east, pin, pins_on_second_side, density);
            pin += pins_on_second_side;
            pads = add_smd_pads(pads, data, .north, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            pads = add_smd_pads(pads, data, .west, pin, pins_on_second_side, density);
        },
        .west_middle => {
            var pin: usize = 1 + data.total_pins - data.pins_on_first_side / 2;
            pads = add_smd_pads(data, .west, pin, data.pins_on_first_side, density);
            pin = 1 + (data.pins_on_first_side + 1) / 2;
            pads = add_smd_pads(data, .south, pin, pins_on_second_side, density);
            pin += pins_on_second_side;
            pads = add_smd_pads(data, .east, pin, data.pins_on_first_side, density);
            pin += data.pins_on_first_side;
            pads = add_smd_pads(data, .north, pin, pins_on_second_side, density);
        },
    }

    return struct {
        pub const fp: Footprint = .{
            .name = "SMD",
        };
    };
}
fn add_smd_pads(
    comptime pads: []Footprint.Pad,
    comptime data: SMD_Data,
    comptime side: Side,
    comptime first_pin: usize,
    comptime pins_on_side: usize,
    comptime density: Density,
) []Footprint.Pad {
    _ = data;
    _ = side;
    _ = first_pin;
    _ = density;

    if (pins_on_side == 0) return pads;
    const new_pads: []Footprint.Pad = &.{};
    comptime {

    // switch (side) {
    //     .west => zgp.rotate(std.math.pi * 3.0 / 2.0),
    //     .east => zgp.rotate(std.math.pi / 2.0),
    //     .north => zgp.rotate(std.math.pi),
    //     .south => {},
    // }

        // const is_west_east = switch (side) {
        //     .west, .east => true,
        //     .north, .south => false,
        // };

        // const overall_dim: isize = @intCast(if (is_west_east) data.overall.width.nominal_um else data.overall.height.nominal_um);
        // const seating: isize = @intCast(data.pin_seating.nominal_um);
        // const pin_pitch: isize = @intCast(data.pin_pitch.nominal_um);
        // const max_pin_width: isize = @intCast(data.pin_width.nominal_um + data.pin_width.tolerance_um);
        // const pins_on_side_i: isize = @intCast(pins_on_side);

        // const pad_width = switch (density) {
        //     .dense => max_pin_width,
        // };

        // var pin_offset = -pin_pitch * (pins_on_side_i - 1) / 2;
        // const side_origin = (seating - overall_dim) / 2;

        // for (0..pins_on_side) |po| {
        //     var pad: Footprint.Pad = .{
        //         .pin = @enumFromInt(pads.len + po + 1),
        //         .kind = .smd,
        //         .x = x,
        //         .y = y,
        //         .rot = switch (side) {
        //             .west => Rotation.cw,
        //             .east => Rotation.ccw,
        //             .north => Rotation.flip,
        //             .south => .{},
        //         },
        //         .w = w,
        //         .h = h,
        //         .shape = .{ .rect = .{
        //             .round_amount = .{ .numer = 1, .denom = 4 },
        //             .chamfer_amount = .{},
        //             .top_left = .rounded,
        //             .top_right = .rounded,
        //             .bottom_left = .rounded,
        //             .bottom_right = .rounded,
        //         }},
        //         .shape_offset_x = .{ .um = 0 },
        //         .shape_offset_y = .{ .um = @intCast((seating - data.pin_width.nominal_um) / 2) },
        //         .hole_w = .{ .um = 0 },
        //         .hole_h = .{ .um = 0 },
        //         .pad_to_die_length = .{ .um = 0 },
        //         .layers = std.EnumSet(Layer).initMany(&.{
        //             .copper_front,
        //             .paste_front,
        //             .soldermask_front,
        //         }),
        //         .copper_layers = .all,
        //         .teardrops = .{},
        //     };

            //defer zgp.translate(pin_pitch_mm, 0);

            // var pin = first_pin + po;
            // if (pin > data.total_pins) pin -= data.total_pins;
            // if (pin == 1) {
            //     try zgp.push_transform();
            //     zgp.translate(0, -(seating_mm + pin_pitch_mm * 1.5) / 2);

            //     zgp.set_color_rgb(0.85, 0.85, 0.85);

            //     try zgp.draw_triangle(
            //         .{ .x = 0,               .y = pin_pitch_mm/2 },
            //         .{ .x = -pin_pitch_mm/2, .y = -pin_pitch_mm/2 },
            //         .{ .x = pin_pitch_mm/2,  .y = -pin_pitch_mm/2 }
            //     );

            //     try zgp.pop_transform();
            // }
            // if (std.mem.indexOfScalar(usize, data.omitted_pins, pin)) |_| {
            //     continue;
            // }

            // try draw_rect(.{
            //     .width = data.pin_width,
            //     .height = .{
            //         .nominal_um = data.pin_seating.nominal_um,
            //         .tolerance_um = data.pin_seating.tolerance_um + switch (side) {
            //             .east, .west => data.overall.width.tolerance_um,
            //             .north, .south => data.overall.height.tolerance_um,
            //         },
            //     },
            // }, pin_color, pin_tol_color);
        // }
    }
    return pads ++ new_pads;
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

    pub fn format(self: SOT_Data, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.package_name);
    }
};
pub fn SOT(comptime data: SOT_Data, comptime density: Density) type {
    _ = data;
    _ = density;
    return struct {
        pub const fp: Footprint = .{
        };
    };
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
    
    pub fn format(self: BGA_Data, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.package_name);
    }
};
pub fn BGA(comptime data: BGA_Data, comptime density: Density) type {
    _ = data;
    _ = density;
    return struct {
        pub const fp: Footprint = .{
        };
    };
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

const Rotation = @import("Rotation.zig");
const Footprint = @import("Footprint.zig");
const Layer = enums.Layer;
const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const std = @import("std");
