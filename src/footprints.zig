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
    north_middle, // PLCC; for even number of pins, round to the west
};

/// Rectangular SMD package, with square leads/pads on the edges of 2 or 4 sides.
/// The same number of pins are placed on opposite sides.
/// There may be a different number of pins on vertical vs. horizontal sides
/// Pin 1 is either the westmost pin on the south side, or the center pin on the west side.
/// The southwest, northwest corner or west side of the body may have a notch to indicate pin 1.
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
    body: Rect,
    overall: Rect, // includes pins
    max_z: Dim,

    // Note this also includes any omitted pins, so the actual physical number of pins (and logical max pin number) may be less.
    total_pins: usize,
    pin1: Pin1 = .south_westmost,

    // The number of pins on the side that contains pin 1, which is always the north/south sides
    // The number of pins on each of the west/east sides is (total_pins - 2 * pins_on_first_side) / 2
    pins_on_first_side: usize,

    pin_pitch: Dim,
    pin_width: Dim,

    // Length of pin that lies flat against the seating plane
    // For SOJ, the diameter of the curved J lead
    pin_seating: Dim,

    // Optional exposed pad / thermal pad / heatsink
    heat_slug: ?Rect = null,
    heat_slug_paste_area: usize = 80, // % of the head slug to cover with solder paste

    // Pin numbers (as they would be defined for a variant with no omitted pins) that do not physically exist.
    // Parts cann't reference omitted pins; they are not assigned pin numbers or Pin_IDs
    // This feature is used for SOT-23, some SOJ DRAM chips, etc.
    omitted_pins: []const usize = &.{},
};
pub fn SMD(comptime data: SMD_Data, comptime density: Density) type {
    _ = data;
    _ = density;
    return struct {
        pub const fp: Footprint = .{
        };
    };
}

/// Rectangular SMD package with a small number of non-uniform square leads/pads, e.g. SOT-143, SOT-223, DPAK
pub const SOT_Data = struct {
    body: Rect,
    max_z: Dim,
    pins: []const struct {
        side: Side,
        position_um: isize, // negative values mean to the left or down; positive values mean to the right or up.
        width: Dim,
        length: Dim,
        seating: Dim, // portion of length that lies flat against the seating plane
    },
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
    body: Rect,
    ball_diameter: Dim,
    rows: usize, // Lettered, from top to bottom (when viewed from above)
    cols: usize, // Numbered, from left to right (when viewed from above)
    row_pitch: Dim,
    col_pitch: Dim,

    include_balls: []const Grid_Region = &.{ .all },
    exclude_balls: []const Grid_Region = &.{},
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

const Footprint = @import("Footprint.zig");

