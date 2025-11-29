layer: Layer = .copper_front,
location: Location = .origin,
rotation: Rotation = .none,
locked: bool = false,
do_not_populate: bool = false,
not_in_schematic: bool = true,
exclude_from_position_files: bool = false,
exclude_from_bom: bool = false,
uuid: Uuid = .nil,
properties: []const Property = &.{},

kind: Kind = .unspecified,
name: []const u8 = "",
format_pin_name: Pin_Name_Format_Func = kicad.default_format_pin_name,
pads: []const Pad = &.{},
lines: []const Line = &.{},
rects: []const Rect = &.{},
polygons: []const Polygon = &.{},
circles: []const Circle = &.{},
arcs: []const Arc = &.{},
texts: []const Text = &.{},
//model: ?Model = null,

const Footprint = @This();

pub const Kind = enum {
    unspecified,
    through_hole,
    smd,
};

pub fn read(r: *sx.Reader, arena: std.mem.Allocator) !?Footprint {
    if (!try r.expression("footprint")) return null;
    const fqn = try r.require_any_string();
    const name = if (std.mem.indexOfScalar(u8, fqn, ':')) |i| fqn[i + 1 ..] else fqn;
    var fp: Footprint = .{
        .name = try arena.dupe(u8, name),
    };

    var properties: std.ArrayList(Property) = .empty;
    var lines: std.ArrayList(Line) = .empty;
    var rects: std.ArrayList(Rect) = .empty;
    var polygons: std.ArrayList(Polygon) = .empty;
    var circles: std.ArrayList(Circle) = .empty;
    var arcs: std.ArrayList(Arc) = .empty;
    var texts: std.ArrayList(Text) = .empty;
    var pads: std.ArrayList(Pad) = .empty;

    while (true) {
        if (try r.expression("locked")) {
            fp.locked = try r.string("yes");
            try r.ignore_remaining_expression();
        } else if (try r.expression("layer")) {
            if (try r.any_string()) |layer_name| {
                if (Layer.from_kicad_name(layer_name)) |layer| {
                    fp.layer = layer;
                }
            }
            try r.ignore_remaining_expression();
        } else if (try Uuid.read(r)) |uuid| {
            fp.uuid = uuid;
        } else if (try Location.read(r, "at", &fp.rotation)) |loc| {
            fp.location = loc;
        } else if (try r.expression("attr")) {
            while (try r.any_string()) |attr| {
                if (std.mem.eql(u8, attr, "smd")) {
                    fp.kind = .smd;
                } else if (std.mem.eql(u8, attr, "through_hole")) {
                    fp.kind = .through_hole;
                } else if (std.mem.eql(u8, attr, "board_only")) {
                    fp.not_in_schematic = true;
                } else if (std.mem.eql(u8, attr, "exclude_from_pos_files")) {
                    fp.exclude_from_position_files = true;
                } else if (std.mem.eql(u8, attr, "exclude_from_bom")) {
                    fp.exclude_from_bom = true;
                } else if (std.mem.eql(u8, attr, "dnp")) {
                    fp.do_not_populate = true;
                }
            }
            try r.ignore_remaining_expression();
        } else if (try Property.read(r, arena)) |prop| {
            try properties.append(arena, prop);
        } else if (try Line.read(r, "fp_line")) |line| {
            try lines.append(arena, line);
        } else if (try Rect.read(r, "fp_rect")) |rect| {
            try rects.append(arena, rect);
        } else if (try Polygon.read(r, arena, "fp_poly")) |poly| {
            try polygons.append(arena, poly);
        } else if (try Circle.read(r, "fp_circle")) |circle| {
            try circles.append(arena, circle);
        } else if (try Arc.read(r, "fp_arc")) |arc| {
            try arcs.append(arena, arc);
        } else if (try Text.read(r, arena, "fp_text")) |text| {
            try texts.append(arena, text);
        } else if (try Pad.read(r)) |pad| {
            try pads.append(arena, pad);
        } else if (try r.any_expression()) |_| {
            try r.ignore_remaining_expression();
        } else if (try r.any_string()) |_| {
            // ignore
        } else break;
    }

    try r.require_close();

    fp.properties = properties.items;
    fp.lines = lines.items;
    fp.rects = rects.items;
    fp.polygons = polygons.items;
    fp.circles = circles.items;
    fp.arcs = arcs.items;
    fp.texts = texts.items;
    fp.pads = pads.items;

    return fp;
}

pub fn write(self: Footprint, w: *sx.Writer, b: *Board, p: Part, remap: *const Net_Remap, options: Writer_Options) !void {
    try w.expression("footprint");
    try w.print_quoted("fp:{s}", .{ self.name });
    w.set_compact(false);

    if (self.locked) {
        try w.expression("locked");
        try w.string("yes");
        try w.close();
    }

    try w.expression("layer");
    try w.string_quoted(self.layer.get_kicad_name(.{}));
    try w.close();

    try self.uuid.write(w);
    try self.location.write(w, "at", self.rotation);

    for (self.properties) |prop| try prop.write(w);

    try w.expression("attr");
    switch (self.kind) {
        .unspecified => {},
        .smd, .through_hole => {
            try w.string(@tagName(self.kind));
        },
    }
    if (self.not_in_schematic) try w.string("board_only");
    if (self.exclude_from_position_files) try w.string("exclude_from_pos_files");
    if (self.exclude_from_bom) try w.string("exclude_from_bom");
    if (!options.enable_courtyard_drc) try w.string("allow_missing_courtyard");
    if (self.do_not_populate) try w.string("dnp");
    try w.close();

    var i: u16 = 0;

    for (self.texts) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_text");
        i += 1;
    }

    for (self.lines) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_line");
        i += 1;
    }

    for (self.rects) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_rect");
        i += 1;
    }

    for (self.polygons) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_poly");
        i += 1;
    }

    for (self.circles) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_circle");
        i += 1;
    }

    for (self.arcs) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, "fp_arc");
        i += 1;
    }

    for (self.pads) |element| {
        var e = element;
        if (e.uuid.raw == Uuid.nil.raw) {
            e.uuid = self.uuid;
            e.uuid.set_mid(i);
        }
        try e.write(w, b, p, remap, self.format_pin_name);
        i += 1;
    }

    try w.expression("embedded_fonts");
    try w.string("no");
    try w.close();

    try w.close();
}

const Layer = @import("../kicad.zig").Layer;
const Uuid = @import("Uuid.zig");
const Property = @import("Property.zig");
const Location = @import("Location.zig");
const Rotation = @import("Rotation.zig");
const Model = @import("Model.zig");
const Pad = @import("Pad.zig");
const Line = @import("Line.zig");
const Rect = @import("Rect.zig");
const Polygon = @import("Polygon.zig");
const Circle = @import("Circle.zig");
const Arc = @import("Arc.zig");
const Text = @import("Text.zig");
const Writer_Options = @import("Writer_Options.zig");
const Pin_Name_Format_Func = kicad.Pin_Name_Format_Func;
const Pin_ID = enums.Pin_ID;
const kicad = @import("../kicad.zig");
const enums = @import("../enums.zig");
const Net_Remap = @import("../Net_Remap.zig");
const Part = @import("../Part.zig");
const Board = @import("../Board.zig");
const sx = @import("sx");
const std = @import("std");