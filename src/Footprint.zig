kind: Kind = .unspecified,
exclude_from_position_files: bool = false,
exclude_from_bom: bool = false,
ignore_courtyard: bool = false,
do_not_populate: bool = false,
name: []const u8 = "",
desc: []const u8 = "",
keywords: []const u8 = "",
properties: []const Property = &.{},
model: ?Model = null,
format_pin_name: *const fn (pin: Pin_ID, writer: std.io.AnyWriter) anyerror!void = default_format_pin_name,
pads: []const Pad = &.{},
// lines: []const Line,
// polygons: []const Polygon,
// circles: []const Circle,
// arcs: []const Arc,
// rects: []const Rect,
texts: []const Text = &.{},
// text_boxes: []const Text_Box,

const Footprint = @This();

pub const Kind = enum {
    unspecified,
    through_hole,
    smd,
};

pub const Property = struct {
    name: []const u8,
    text: Text,
};

pub const Text = struct {
    content: []const u8,
    x: Micron,
    y: Micron,
    rot: Rotation = .{},
    style: Text_Style = .{},
};

pub const Model = struct {
    path: []const u8,
    scale_x: Ratio = .{},
    scale_y: Ratio = .{},
    scale_z: Ratio = .{},
    rot_x: Rotation = .{},
    rot_y: Rotation = .{},
    rot_z: Rotation = .{},
    offset_x: Micron = .{ .um = 0 },
    offset_y: Micron = .{ .um = 0 },
    offset_z: Micron = .{ .um = 0 },
    opacity: Ratio = .{},
};

pub const Pad = struct {
    pin: Pin_ID,
    kind: Pad.Kind,
    x: Micron,
    y: Micron,
    rot: Rotation = .{},
    w: Micron,
    h: Micron,
    shape: Shape,
    shape_offset_x: Micron,
    shape_offset_y: Micron,
    hole_w: Micron,
    hole_h: Micron,
    pad_to_die_length: Micron,
    layers: std.EnumSet(Layer),
    copper_layers: enum {
        all,
        connected_only,
        connected_and_outside_only,
    } = .all,
    teardrops: ?Teardrops,

    pub const Kind = enum {
        through_hole, // N.B. kicad uses "thru_hole"
        non_plated_through_hole,
        smd,
        edge_connector,
        stencil_aperture,
    };

    pub const Fab_Note = enum {
        none,
        bga,
        fiducial_local,
        fiducial_global,
        test_point,
        heatsink,
        castellated,
    };

    pub const Shape = union (enum) {
        oval, // circle if w == h
        rect: struct {
            chamfer_amount: Ratio,
            round_amount: Ratio,
            top_left: Corner_Shape = .normal,
            top_right: Corner_Shape = .normal,
            bottom_left: Corner_Shape = .normal,
            bottom_right: Corner_Shape = .normal,
        },
        trapezoid: struct {
            ratio: Ratio,
            symetry_axis: enum { x, y },
        },
    };

    pub const Corner_Shape = enum {
        normal,
        chamfered,
        rounded,
    };

    pub const Teardrops = struct {
        max_track_width: Ratio = .{},
        target_length: Ratio = .{ .numer = 1, .denom = 2 },
        target_width: Ratio = .{},
        max_length: Micron = .{ .um = 2000 },
        max_width: Micron = .{ .um = 4000 },
        curve_subdivs: usize = 5,
        allow_two_segments: bool = true,
        prefer_zone_connections: bool = true,
    };
};

pub fn write_sx(self: Footprint, writer: sx.Writer) !void {
    _ = self;
    _ = writer;
}


pub fn default_format_pin_name(pin: Pin_ID, writer: std.io.AnyWriter) anyerror!void {
    if (pin == .heatsink) {
        try writer.writeAll("EP");
    } else {
        try writer.print("{}", .{ @intFromEnum(pin) });
    }
}

const Text_Style = @import("Text_Style.zig");
const Rotation = @import("Rotation.zig");
const Micron = @import("Micron.zig");
const Ratio = @import("Ratio.zig");
const Layer = enums.Layer;
const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const sx = @import("sx");
const std = @import("std");
