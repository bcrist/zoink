pub const Footprint = @import("kicad/Footprint.zig");
pub const Location = @import("kicad/Location.zig");
pub const Micron = @import("kicad/Micron.zig");
pub const Model = @import("kicad/Model.zig");
pub const Pad = @import("kicad/Pad.zig");
pub const Polygon = @import("kicad/Polygon.zig");
pub const Rect = @import("kicad/Rect.zig");
pub const Line = @import("kicad/Line.zig");
pub const Circle = @import("kicad/Circle.zig");
pub const Arc = @import("kicad/Arc.zig");
pub const Stroke_Style = @import("kicad/Stroke_Style.zig");
pub const Property = @import("kicad/Property.zig");
pub const Ratio = @import("kicad/Ratio.zig");
pub const Rotation = @import("kicad/Rotation.zig");
pub const Text = @import("kicad/Text.zig");
pub const Text_Box = @import("kicad/Text_Box.zig");
pub const Text_Style = @import("kicad/Text_Style.zig");
pub const Writer_Options = @import("kicad/Writer_Options.zig");

pub const Pin_Name_Format_Func = *const fn (pin: Pin_ID, writer: *std.io.Writer) std.io.Writer.Error!void;
pub fn format_pin_name(comptime E: type) Pin_Name_Format_Func {
    return struct {
        pub fn func(pin: Pin_ID, writer: *std.io.Writer) std.io.Writer.Error!void {
            try writer.writeAll(@tagName(E.from_generic(pin)));
        }
    }.func;
}

pub fn default_format_pin_name(pin: Pin_ID, writer: *std.io.Writer) std.io.Writer.Error!void {
    if (pin == .heatsink) {
        try writer.writeAll("EP");
    } else {
        try writer.print("{}", .{ @intFromEnum(pin) });
    }
}

pub const Layer = enum (u8) {
    copper_front = 0,
    soldermask_front = 1,
    copper_back = 2,
    soldermask_back = 3,
    copper_internal_1 = 4,
    silkscreen_front = 5,
    copper_internal_2 = 6,
    silkscreen_back = 7,
    copper_internal_3 = 8,
    adhesive_front = 9,
    copper_internal_4 = 10,
    adhesive_back = 11,
    copper_internal_5 = 12,
    paste_front = 13,
    copper_internal_6 = 14,
    paste_back = 15,
    copper_internal_7 = 16,
    user_drawings = 17,
    copper_internal_8 = 18,
    user_comments = 19,
    copper_internal_9 = 20,
    user_eco_1 = 21,
    copper_internal_10 = 22,
    user_eco_2 = 23,
    copper_internal_11 = 24,
    edges = 25,
    copper_internal_12 = 26,
    margins = 27,
    copper_internal_13 = 28,
    courtyard_back = 29,
    copper_internal_14 = 30,
    courtyard_front = 31,
    copper_internal_15 = 32,
    fab_back = 33,
    copper_internal_16 = 34,
    fab_front = 35,
    copper_internal_17 = 36,

    copper_internal_18 = 38,
    names = 39,
    copper_internal_19 = 40,
    values = 41,
    copper_internal_20 = 42,
    designators = 43,
    copper_internal_21 = 44,
    // user_4 = 45,
    copper_internal_22 = 46,
    // user_5 = 47,
    copper_internal_23 = 48,
    // user_6 = 49,
    copper_internal_24 = 50,
    // user_7 = 51,
    copper_internal_25 = 52,
    // user_8 = 53,
    copper_internal_26 = 54,
    // user_9 = 55,
    copper_internal_27 = 56,
    // user_10 = 57,
    copper_internal_28 = 58,
    // user_11 = 59,
    copper_internal_29 = 60,
    // user_12 = 61,
    copper_internal_30 = 62,
    // user_13 = 63,
    // user_14 = 65,
    // user_15 = 67,
    // user_16 = 69,
    // user_17 = 71,
    // user_18 = 73,
    // user_19 = 75,
    // user_20 = 77,
    // user_21 = 79,
    // user_22 = 81,
    // user_23 = 83,
    // user_24 = 85,
    // user_25 = 87,
    // user_26 = 89,
    // user_27 = 91,
    // user_28 = 93,
    // user_29 = 95,
    // user_30 = 97,
    // user_31 = 99,
    // user_32 = 101,
    // user_33 = 103,
    // user_34 = 105,
    // user_35 = 107,
    // user_36 = 109,
    // user_37 = 111,
    // user_38 = 113,
    // user_39 = 115,
    // user_40 = 117,
    // user_41 = 119,
    // user_42 = 121,
    // user_43 = 123,
    // user_44 = 125,
    // user_45 = 127,

    pub fn is_copper(self: Layer) bool {
        return switch (self) {
            .copper_front, .copper_back,
            .copper_internal_1,
            .copper_internal_2,
            .copper_internal_3,
            .copper_internal_4,
            .copper_internal_5,
            .copper_internal_6,
            .copper_internal_7,
            .copper_internal_8,
            .copper_internal_9,
            .copper_internal_10,
            .copper_internal_11,
            .copper_internal_12,
            .copper_internal_13,
            .copper_internal_14,
            .copper_internal_15,
            .copper_internal_16,
            .copper_internal_17,
            .copper_internal_18,
            .copper_internal_19,
            .copper_internal_20,
            .copper_internal_21,
            .copper_internal_22,
            .copper_internal_23,
            .copper_internal_24,
            .copper_internal_25,
            .copper_internal_26,
            .copper_internal_27,
            .copper_internal_28,
            .copper_internal_29,
            .copper_internal_30,
            => true,
            else => false,
        };
    }

    pub fn flip_sides(self: Layer) Layer {
        return switch (self) {
            .copper_front => .copper_back,
            .copper_back => .copper_front,
            .adhesive_back => .adhesive_front,
            .adhesive_front => .adhesive_back,
            .paste_back => .paste_front,
            .paste_front => .paste_back,
            .silkscreen_back => .silkscreen_front,
            .silkscreen_front => .silkscreen_back,
            .soldermask_back => .soldermask_front,
            .soldermask_front => .soldermask_back,
            .courtyard_back => .courtyard_front,
            .courtyard_front => .courtyard_back,
            .fab_back => .fab_front,
            .fab_front => .fab_back,
            else => self,
        };
    }

    pub fn flip_sides_set(set: std.EnumSet(Layer)) std.EnumSet(Layer) {
        var new_set: std.EnumSet(Layer) = .initEmpty();
        var iter = set.iterator();
        while (iter.next()) |layer| {
            new_set.insert(layer.flip_sides());
        }
        return new_set;
    }

    const name_lookup = std.StaticStringMap(Layer).initComptime(.{
        .{ "F.Cu", .copper_front },
        .{ "In1.Cu", .copper_internal_1 },
        .{ "In2.Cu", .copper_internal_2 },
        .{ "In3.Cu", .copper_internal_3 },
        .{ "In4.Cu", .copper_internal_4 },
        .{ "In5.Cu", .copper_internal_5 },
        .{ "In6.Cu", .copper_internal_6 },
        .{ "In7.Cu", .copper_internal_7 },
        .{ "In8.Cu", .copper_internal_8 },
        .{ "In9.Cu", .copper_internal_9 },
        .{ "In10.Cu", .copper_internal_10 },
        .{ "In11.Cu", .copper_internal_11 },
        .{ "In12.Cu", .copper_internal_12 },
        .{ "In13.Cu", .copper_internal_13 },
        .{ "In14.Cu", .copper_internal_14 },
        .{ "In15.Cu", .copper_internal_15 },
        .{ "In16.Cu", .copper_internal_16 },
        .{ "In17.Cu", .copper_internal_17 },
        .{ "In18.Cu", .copper_internal_18 },
        .{ "In19.Cu", .copper_internal_19 },
        .{ "In20.Cu", .copper_internal_20 },
        .{ "In21.Cu", .copper_internal_21 },
        .{ "In22.Cu", .copper_internal_22 },
        .{ "In23.Cu", .copper_internal_23 },
        .{ "In24.Cu", .copper_internal_24 },
        .{ "In25.Cu", .copper_internal_25 },
        .{ "In26.Cu", .copper_internal_26 },
        .{ "In27.Cu", .copper_internal_27 },
        .{ "In28.Cu", .copper_internal_28 },
        .{ "In29.Cu", .copper_internal_29 },
        .{ "In30.Cu", .copper_internal_30 },
        .{ "B.Cu", .copper_back },
        .{ "B.Adhesive", .adhesive_back },
        .{ "B.Adhes", .adhesive_back },
        .{ "F.Adhesive", .adhesive_front },
        .{ "F.Adhes", .adhesive_front },
        .{ "B.Paste", .paste_back },
        .{ "F.Paste", .paste_front },
        .{ "B.Silkscreen", .silkscreen_back },
        .{ "B.SilkS", .silkscreen_back },
        .{ "F.Silkscreen", .silkscreen_front },
        .{ "F.SilkS", .silkscreen_front },
        .{ "B.Mask", .soldermask_back },
        .{ "F.Mask", .soldermask_front },
        .{ "User.Drawings", .user_drawings },
        .{ "Dwgs.User", .user_drawings },
        .{ "User.Comments", .user_comments },
        .{ "Cmts.User", .user_comments },
        .{ "User.Eco1", .user_eco_1 },
        .{ "Eco1.User", .user_eco_1 },
        .{ "User.Eco2", .user_eco_2 },
        .{ "Eco2.User", .user_eco_2 },
        .{ "Edge.Cuts", .edges },
        .{ "Margin", .margins },
        .{ "B.Courtyard", .courtyard_back },
        .{ "B.CrtYd", .courtyard_back },
        .{ "F.Courtyard", .courtyard_front },
        .{ "F.CrtYd", .courtyard_front },
        .{ "B.Fab", .fab_back },
        .{ "F.Fab", .fab_front },
        .{ "Names", .names },
        .{ "User.1", .names },
        .{ "Values", .values },
        .{ "User.2", .values },
        .{ "Designators", .designators },
        .{ "User.3", .designators },
    });

    pub fn from_kicad_name(name: []const u8) ?Layer {
        return name_lookup.get(name);
    }

    pub fn parse_set(name: []const u8) std.EnumSet(Layer) {
        if (std.mem.eql(u8, name, "*.Cu")) {
            var result: std.EnumSet(Layer) = .initEmpty();
            inline for (comptime std.enums.values(Layer)) |layer| {
                if (comptime layer.is_copper()) result.insert(layer);
            }
            return result;
        } else if (std.mem.startsWith(u8, name, "*.")) {
            var buf: [64]u8 = undefined;
            var w = std.io.Writer.fixed(&buf);
            w.print("F.{s}", .{ name["*.".len ..] }) catch return .initEmpty();
            if (from_kicad_name(w.buffered())) |layer| {
                return .initMany(&.{ layer, layer.flip_sides() });
            } else {
                return .initEmpty();
            }
        } else if (std.mem.startsWith(u8, name, "F&B.")) {
            var buf: [64]u8 = undefined;
            var w = std.io.Writer.fixed(&buf);
            w.print("F.{s}", .{ name["F&B.".len ..] }) catch return .initEmpty();
            if (from_kicad_name(w.buffered())) |layer| {
                return .initMany(&.{ layer, layer.flip_sides() });
            } else {
                return .initEmpty();
            }
        } else {
            return if (from_kicad_name(name)) |layer| .initOne(layer) else .initEmpty();
        }
    }

    const Kicad_Name_Options = struct {
        long_form: bool = false,
    };
    pub fn get_kicad_name(self: Layer, options: Kicad_Name_Options) []const u8 {
        return switch (self) {
            .copper_front => "F.Cu",
            .copper_internal_1 => "In1.Cu",
            .copper_internal_2 => "In2.Cu",
            .copper_internal_3 => "In3.Cu",
            .copper_internal_4 => "In4.Cu",
            .copper_internal_5 => "In5.Cu",
            .copper_internal_6 => "In6.Cu",
            .copper_internal_7 => "In7.Cu",
            .copper_internal_8 => "In8.Cu",
            .copper_internal_9 => "In9.Cu",
            .copper_internal_10 => "In10.Cu",
            .copper_internal_11 => "In11.Cu",
            .copper_internal_12 => "In12.Cu",
            .copper_internal_13 => "In13.Cu",
            .copper_internal_14 => "In14.Cu",
            .copper_internal_15 => "In15.Cu",
            .copper_internal_16 => "In16.Cu",
            .copper_internal_17 => "In17.Cu",
            .copper_internal_18 => "In18.Cu",
            .copper_internal_19 => "In19.Cu",
            .copper_internal_20 => "In20.Cu",
            .copper_internal_21 => "In21.Cu",
            .copper_internal_22 => "In22.Cu",
            .copper_internal_23 => "In23.Cu",
            .copper_internal_24 => "In24.Cu",
            .copper_internal_25 => "In25.Cu",
            .copper_internal_26 => "In26.Cu",
            .copper_internal_27 => "In27.Cu",
            .copper_internal_28 => "In28.Cu",
            .copper_internal_29 => "In29.Cu",
            .copper_internal_30 => "In30.Cu",
            .copper_back => "B.Cu",
            .adhesive_back => if (options.long_form) "B.Adhesive" else "B.Adhes",
            .adhesive_front => if (options.long_form) "F.Adhesive" else "F.Adhes",
            .paste_back => "B.Paste",
            .paste_front => "F.Paste",
            .silkscreen_back => if (options.long_form) "B.Silkscreen" else "B.SilkS",
            .silkscreen_front => if (options.long_form) "F.Silkscreen" else "F.SilkS",
            .soldermask_back => "B.Mask",
            .soldermask_front => "F.Mask",
            .user_drawings => if (options.long_form) "User.Drawings" else "Dwgs.User",
            .user_comments => if (options.long_form) "User.Comments" else "Cmts.User",
            .user_eco_1 => if (options.long_form) "User.Eco1" else "Eco1.User",
            .user_eco_2 => if (options.long_form) "User.Eco2" else "Eco2.User",
            .edges => "Edge.Cuts",
            .margins => "Margin",
            .courtyard_back => if (options.long_form) "B.Courtyard" else "B.CrtYd",
            .courtyard_front => if (options.long_form) "F.Courtyard" else "F.CrtYd",
            .fab_back => "B.Fab",
            .fab_front => "F.Fab",
            .names => if (options.long_form) "Names" else "User.1",
            .values => if (options.long_form) "Values" else "User.2",
            .designators => if (options.long_form) "Designators" else "User.3",
        };
    }

    pub fn write_layers(layers: std.EnumSet(Layer), w: *sx.Writer) !void {
        var fb_copper = true;
        var all_copper = true;
        var fb_adhesive = true;
        var fb_paste = true;
        var fb_silkscreen = true;
        var fb_soldermask = true;
        var fb_courtyard = true;
        var fb_fab = true;

        var unselected_layer_iter = layers.complement().iterator();
        while (unselected_layer_iter.next()) |layer| {
            if (all_copper and layer.is_copper()) all_copper = false;
            if (fb_copper and (layer == .copper_front or layer == .copper_back)) fb_copper = false;
            if (fb_adhesive and (layer == .adhesive_front or layer == .adhesive_back)) fb_adhesive = false;
            if (fb_paste and (layer == .paste_front or layer == .paste_back)) fb_paste = false;
            if (fb_silkscreen and (layer == .silkscreen_front or layer == .silkscreen_back)) fb_silkscreen = false;
            if (fb_soldermask and (layer == .soldermask_front or layer == .soldermask_back)) fb_soldermask = false;
            if (fb_courtyard and (layer == .courtyard_front or layer == .courtyard_back)) fb_courtyard = false;
            if (fb_fab and (layer == .fab_front or layer == .fab_back)) fb_fab = false;
        }

        try w.expression("layers");
        if (all_copper) {
            try w.string_quoted("*.Cu");
        } else if (fb_copper) {
            try w.string_quoted("F&B.Cu");
        }
        if (fb_adhesive) try w.string_quoted("*.Adhes");
        if (fb_paste) try w.string_quoted("*.Paste");
        if (fb_silkscreen) try w.string_quoted("*.SilkS");
        if (fb_soldermask) try w.string_quoted("*.Mask");
        if (fb_courtyard) try w.string_quoted("*.CrtYd");
        if (fb_fab) try w.string_quoted("*.Fab");
        var layer_iter = layers.iterator();
        while (layer_iter.next()) |layer| {
            if (layer.is_copper()) {
                if (all_copper) continue;
                if (fb_copper and (layer == .copper_front or layer == .copper_back)) continue;
                try w.string_quoted(layer.get_kicad_name(.{}));
            } else switch (layer) {
                .adhesive_back, .adhesive_front => if (!fb_adhesive) try w.string_quoted(layer.get_kicad_name(.{})),
                .paste_back, .paste_front => if (!fb_paste) try w.string_quoted(layer.get_kicad_name(.{})),
                .silkscreen_back, .silkscreen_front => if (!fb_silkscreen) try w.string_quoted(layer.get_kicad_name(.{})),
                .soldermask_back, .soldermask_front => if (!fb_soldermask) try w.string_quoted(layer.get_kicad_name(.{})),
                .courtyard_back, .courtyard_front => if (!fb_courtyard) try w.string_quoted(layer.get_kicad_name(.{})),
                .fab_back, .fab_front => if (!fb_fab) try w.string_quoted(layer.get_kicad_name(.{})),
                else => try w.string_quoted(layer.get_kicad_name(.{})),
            }
        }
        try w.close();
    }
};

const log = std.log.scoped(.zoink);

const Net_ID = enums.Net_ID;
const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const Board = @import("Board.zig");
const sx = @import("sx");
const std = @import("std");
