pin: Pin_ID,
kind: Kind,
fab_property: Fab_Property = .none,
location: Location,
rotation: Rotation = .none,
w: Micron,
h: Micron,
shape: Shape,
shape_offset: Location = .origin,
hole_w: Micron = .zero,
hole_h: Micron = .zero,
pad_to_die_length: Micron = .zero,
layers: std.EnumSet(Layer),
copper_layers: enum {
    all,
    connected_only,
    connected_and_outside_only,
} = .all,
teardrops: ?Teardrops = null,
uuid: Uuid = .nil,

pub const Kind = enum {
    through_hole,
    non_plated_through_hole,
    smd,
    edge_connector,
    stencil_aperture,
};

pub const Fab_Property = enum {
    none,
    bga,
    fiducial_loc,
    fiducial_glob,
    testpoint,
    heatsink,
    castellated,
    mechanical,
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

    pub const square: Shape = .{ .rect = .{
        .chamfer_amount = .{},
        .round_amount = .{},
    }};

    pub const default_rounded: Shape = .{ .rect = .{
        .round_amount = .{
            .numer = 1,
            .denom = 4,
        },
        .chamfer_amount = .{},
        .top_left = .rounded,
        .top_right = .rounded,
        .bottom_left = .rounded,
        .bottom_right = .rounded,
    }};

    pub const default_chamfered: Shape = .{ .rect = .{
        .chamfer_amount = .{
            .numer = 1,
            .denom = 8,
        },
        .round_amount = .{},
        .top_left = .chamfered,
        .top_right = .chamfered,
        .bottom_left = .chamfered,
        .bottom_right = .chamfered,
    }};
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

pub const Pin_Name_Formatter = struct {
    pin: Pin_ID,
    impl: *const fn (data: Pin_ID, writer: *std.io.Writer) std.io.Writer.Error!void,

    pub inline fn format(self: @This(), writer: *std.io.Writer) std.io.Writer.Error!void {
        try self.impl(self.pin, writer);
    }
};

pub fn read(r: *sx.Reader) !?Pad {
    if (!try r.expression("pad")) return null;

    var self: Pad = .{
        .pin = Pin_ID.heatsink,
        .kind = .smd,
        .location = .origin,
        .w = .zero,
        .h = .zero,
        .shape = .oval,
        .layers = .initOne(.copper_front),
    };

    _ = try r.any_string(); // pin name

    if (try r.any_string()) |kind| {
        if (std.mem.eql(u8, kind, "thru_hole")) {
            self.kind = .through_hole;
        } else if (std.mem.eql(u8, kind, "np_through_hole")) {
            self.kind = .non_plated_through_hole;
        } else if (std.mem.eql(u8, kind, "smd")) {
            self.kind = .smd;
        } else if (std.mem.eql(u8, kind, "connect")) {
            self.kind = .edge_connector;
        }
    }

    if (try r.any_string()) |shape| {
        if (std.mem.eql(u8, shape, "circle")) {
            self.shape = .oval;
        } else if (std.mem.eql(u8, shape, "oval")) {
            self.shape = .oval;
        } else if (std.mem.eql(u8, shape, "rect")) {
            self.shape = .{ .rect = .{
                .chamfer_amount = .{ .numer = 0 },
                .round_amount = .{ .numer = 0 },
            }};
        } else if (std.mem.eql(u8, shape, "roundrect")) {
            self.shape = .{ .rect = .{
                .chamfer_amount = .{ .numer = 0 },
                .round_amount = .{ .numer = 0 },
                .top_left = .rounded,
                .top_right = .rounded,
                .bottom_left = .rounded,
                .bottom_right = .rounded,
            }};
        } else if (std.mem.eql(u8, shape, "trapezoid")) {
            self.shape = .{ .trapezoid = .{
                .ratio = .{},
                .symetry_axis = .x,
            }};
        }
    }


    while (true) {
        if (try r.expression("size")) {
            self.w = .init_mm(try r.require_any_float(f64));
            self.h = if (try r.any_float(f64)) |h| .init_mm(h) else self.w;
            try r.ignore_remaining_expression();

        } else if (try r.expression("rect_delta")) {
            const x = try r.require_any_float(f64);
            const y = try r.require_any_float(f64);
            const mag = if (x == 0) y else x;
            self.shape = .{ .trapezoid = if (x == 0) .{
                    .symetry_axis = .y,
                    .ratio = .{
                        .numer = @intCast(Micron.init_mm(mag + self.w.mm(f64)).um),
                        .denom = @intCast(self.w.um),
                    },
                } else .{
                    .symetry_axis = .x,
                    .ratio = .{
                        .numer = @intCast(Micron.init_mm(mag + self.h.mm(f64)).um),
                        .denom = @intCast(self.h.um),
                    },
                }
            };
            try r.ignore_remaining_expression();

        } else if (try r.expression("drill")) {
            if (try r.any_float(f64)) |w| {
                self.hole_w = .init_mm(w);
                self.hole_h = self.hole_w;
                if (try r.any_float(f64)) |h| {
                    self.hole_h = .init_mm(h);
                }
            }
            if (try Location.read(r, "offset", null)) |offset| {
                self.shape_offset = offset;
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("property")) {
            if (try r.any_string()) |str| {
                if (std.mem.startsWith(u8, str, "pad_prop_")) {
                    const str_without_prefix = str["pad_prop_".len ..];
                    if (std.meta.stringToEnum(Fab_Property, str_without_prefix)) |fab| {
                        self.fab_property = fab;
                    }
                }
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("layers")) {
            self.layers = .initEmpty();
            while (try r.any_string()) |layer_spec| {
                self.layers.setUnion(Layer.parse_set(layer_spec));
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("remove_unused_layers")) {
            if (self.copper_layers != .connected_and_outside_only) {
                self.copper_layers = .connected_only;
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("keep_end_layers")) {
            self.copper_layers = .connected_and_outside_only;
            try r.ignore_remaining_expression();
        
        } else if (try r.expression("die_length")) {
            self.pad_to_die_length = .init_mm(try r.require_any_float(f64));
            try r.ignore_remaining_expression();

        } else if (try r.expression("roundrect_rratio")) {
            if (self.shape == .rect) {
                self.shape.rect.round_amount = .{
                    .numer = @intCast(Micron.init_mm(try r.require_any_float(f64)).um),
                    .denom = @intCast(Micron.init_mm(1).um),
                };
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("chamfer_ratio")) {
            if (self.shape == .rect) {
                self.shape.rect.chamfer_amount = .{
                    .numer = @intCast(Micron.init_mm(try r.require_any_float(f64)).um),
                    .denom = @intCast(Micron.init_mm(1).um),
                };
            }
            try r.ignore_remaining_expression();

        } else if (try r.expression("chamfer")) {
            if (self.shape == .rect and self.shape.rect.top_left == .rounded) {
                while (try r.any_string()) |str| {
                    if (std.mem.eql(u8, str, "top_left")) {
                        self.shape.rect.top_left = .chamfered;
                    } else if (std.mem.eql(u8, str, "top_right")) {
                        self.shape.rect.top_right = .chamfered;
                    } else if (std.mem.eql(u8, str, "bottom_left")) {
                        self.shape.rect.bottom_left = .chamfered;
                    } else if (std.mem.eql(u8, str, "bottom_right")) {
                        self.shape.rect.bottom_right = .chamfered;
                    }
                }
            }
            try r.ignore_remaining_expression();

        } else if (try Location.read(r, "at", &self.rotation)) |loc| {
            self.location = loc;
        } else if (try Uuid.read(r)) |id| {
            self.uuid = id;
        } else if (try r.any_expression()) |_| {
            try r.ignore_remaining_expression();
        } else if (try r.any_string()) |_| {
            // ignore
        } else break;
    }

    try r.require_close();
    return self;
}

pub fn write(self: Pad, w: *sx.Writer, b: *Board, p: Part, remap: *const Net_Remap, format_pin_name: Pin_Name_Format_Func) !void {
    try w.expression("pad");
    try w.print_quoted("{f}", .{
        Pin_Name_Formatter{
            .pin = self.pin,
            .impl = format_pin_name,
        }
    });
    try w.string(switch (self.kind) {
        .through_hole => "thru_hole",
        .non_plated_through_hole => "np_thru_hole",
        .smd, .stencil_aperture => "smd",
        .edge_connector => "connect",
    });

    switch (self.shape) {
        .oval => {
            try w.string(if (self.w.um == self.h.um) "circle" else "oval");
        },
        .rect => |info| {
            if (info.top_left != .normal or info.top_right != .normal or info.bottom_left != .normal or info.bottom_right != .normal) {
                try w.string("roundrect");
            } else {
                try w.string("rect");
            }
        },
        .trapezoid => try w.string("trapezoid"),
    }
    w.set_compact(false);

    try self.location.write(w, "at", self.rotation);

    try w.expression("size");
    try w.float(self.w.mm(f64));
    try w.float(self.h.mm(f64));
    try w.close();

    switch(self.shape) {
        .trapezoid => |info| {
            try w.expression("rect_delta");
            try w.float(if (info.symetry_axis == .x) info.ratio.mul(self.h).mm(f64) - self.h.mm(f64) else 0);
            try w.float(if (info.symetry_axis == .y) info.ratio.mul(self.w).mm(f64) - self.w.mm(f64) else 0);
            try w.close();
        },
        else => {},
    }

    if (self.hole_h.um != 0 or self.hole_w.um != 0 or self.shape_offset.x.um != 0 or self.shape_offset.y.um != 0) {
        try w.expression("drill");
        if (self.hole_h.um != 0 or self.hole_w.um != 0) {
            try w.float(self.hole_w.mm(f64));
            if (self.hole_h.um != self.hole_w.um) {
                try w.float(self.hole_h.mm(f64));
            }
        }
        w.set_compact(false);
        if (self.shape_offset.x.um != 0 or self.shape_offset.y.um != 0) {
            try self.shape_offset.write(w, "offset", null);
        }
        try w.close();
    }

    if (self.fab_property != .none) {
        try w.expression("property");
        try w.print_value("pad_prop_{t}", .{ self.fab_property });
        try w.close();
    }

    try Layer.write_layers(self.layers, w);

    switch (self.copper_layers) {
        .all => {},
        .connected_only => {
            try w.expression("remove_unused_layers");
            try w.string("yes");
            try w.close();
            try w.expression("zone_layer_connections");
            try w.close();
        },
        .connected_and_outside_only => {
            try w.expression("remove_unused_layers");
            try w.string("yes");
            try w.close();
            try w.expression("keep_end_layers");
            try w.string("yes");
            try w.close();
            try w.expression("zone_layer_connections");
            try w.close();
        },
    }

    switch(self.shape) {
        .rect => |info| {
            if (info.top_left != .normal or info.top_right != .normal or info.bottom_left != .normal or info.bottom_right != .normal) {
                try w.expression("roundrect_rratio");
                try w.float(info.round_amount.mul(.init_mm(1)).mm(f64));
                try w.close();
                if (info.top_left == .chamfered or info.top_right == .chamfered or info.bottom_left == .chamfered or info.bottom_right == .chamfered) {
                    try w.expression("chamfer_ratio");
                    try w.float(info.chamfer_amount.mul(.init_mm(1)).mm(f64));
                    try w.close();

                    try w.expression("chamfer");
                    if (info.top_left == .chamfered) try w.string("top_left");
                    if (info.top_right == .chamfered) try w.string("top_right");
                    if (info.bottom_left == .chamfered) try w.string("bottom_left");
                    if (info.bottom_right == .chamfered) try w.string("bottom_right");
                    try w.close();
                }
            }
        },
        else => {},
    }

    const net = remap.get_merged_net(p.vt.pin_to_net(p.base, self.pin));
    const net_name = b.net_name(net);
    try w.expression("net");
    try w.int(remap.get_kicad_id_from_name(net_name), 10);
    try w.string_quoted(net_name);
    try w.close();

    if (self.pad_to_die_length.um > 0) {
        try w.expression("die_length");
        try w.float(self.pad_to_die_length.mm(f64));
        try w.close();
    }

    try self.uuid.write(w);
    try w.close();
}

const log = std.log.scoped(.zoink);

const Pad = @This();

const Layer = kicad.Layer;
const Pin_Name_Format_Func = kicad.Pin_Name_Format_Func;
const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const Net_Remap = @import("../Net_Remap.zig");
const Board = @import("../Board.zig");
const Part = @import("../Part.zig");
const Uuid = @import("Uuid.zig");
const Location = @import("Location.zig");
const Micron = @import("Micron.zig");
const Ratio = @import("Ratio.zig");
const Rotation = @import("Rotation.zig");
const sx = @import("sx");
const std = @import("std");
