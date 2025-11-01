parent: ?*const Text_Style = null,
layer: ?Layer = null,
hidden: ?bool = null,
locked: ?bool = null,
knockout: ?bool = null,
mirrored: ?bool = null,
bold: ?bool = null,
italic: ?bool = null,
font: ?[]const u8 = null,
thickness: ?Micron = null,
size_y: ?Micron = null,
aspect_ratio: ?Ratio = null,
justify: ?Justification = null,
baseline: ?Baseline = null,

pub const names_and_descriptions: Text_Style = .{
    .layer = .names,
    .thickness = .init_mm(0.025),
    .size_y = .init_mm(0.25),
    .aspect_ratio = .{},
    .justify = .center,
    .baseline = .middle,
};

pub const designators: Text_Style = .{
    .layer = .designators,
    .thickness = .init_mm(0.05),
    .size_y = .init_mm(0.5),
    .aspect_ratio = .{},
    .justify = .center,
    .baseline = .middle,
};

pub const values: Text_Style = .{
    .layer = .values,
    .thickness = .init_mm(0.05),
    .size_y = .init_mm(0.5),
    .aspect_ratio = .{},
    .justify = .center,
    .baseline = .middle,
};

const Justification = enum {
    left,
    center,
    right,
};

const Baseline = enum {
    top,
    middle,
    bottom,
};

const Text_Style = @This();

pub fn get_layer(self: Text_Style) Layer {
    return self.layer orelse if (self.parent) |parent| parent.get_layer() else .silkscreen_front;
}

pub fn is_hidden(self: Text_Style) bool {
    return self.hidden orelse if (self.parent) |parent| parent.is_hidden() else false;
}
pub fn is_locked(self: Text_Style) bool {
    return self.locked orelse if (self.parent) |parent| parent.is_locked() else false;
}
pub fn is_knockout(self: Text_Style) bool {
    return self.knockout orelse if (self.parent) |parent| parent.is_knockout() else false;
}
pub fn is_mirrored(self: Text_Style) bool {
    return self.mirrored orelse if (self.parent) |parent| parent.is_mirrored() else false;
}
pub fn is_bold(self: Text_Style) bool {
    return self.bold orelse if (self.parent) |parent| parent.is_bold() else false;
}
pub fn is_italic(self: Text_Style) bool {
    return self.italic orelse if (self.parent) |parent| parent.is_italic() else false;
}

pub fn get_font(self: Text_Style) []const u8 {
    return self.font orelse if (self.parent) |parent| parent.get_font() else "";
}

pub fn get_thickness(self: Text_Style) Micron {
    return self.thickness orelse if (self.parent) |parent| parent.get_thickness() else .{ .um = 300 };
}

pub fn get_size_y(self: Text_Style) Micron {
    return self.size_y orelse if (self.parent) |parent| parent.get_size_y() else .{ .um = 1200 };
}

pub fn get_aspect_ratio(self: Text_Style) Ratio {
    return self.aspect_ratio orelse if (self.parent) |parent| parent.get_aspect_ratio() else .{};
}

pub fn get_size_x(self: Text_Style) Micron {
    return self.get_aspect_ratio().mul(self.get_size_y());
}

pub fn get_justification(self: Text_Style) Justification {
    return self.justify orelse if (self.parent) |parent| parent.get_justification() else .center;
}

pub fn get_baseline(self: Text_Style) Baseline {
    return self.baseline orelse if (self.parent) |parent| parent.get_baseline() else .middle;
}

pub fn read_effects(self: *Text_Style, r: *sx.Reader, arena: std.mem.Allocator) !bool {
    if (!try r.expression("effects")) return false;

    while (true) {
        if (try r.expression("font")) {
            while (true) {
                if (try r.expression("face")) {
                    self.font = try arena.dupe(u8, try r.require_any_string());
                    try r.ignore_remaining_expression();
                } else if (try r.expression("size")) {
                    self.size_y = .init_mm(try r.require_any_float(f64));
                    if (try r.any_float(f64)) |size_x| {
                        self.aspect_ratio = .{
                            .numer = @intCast(Micron.init_mm(size_x).um),
                            .denom = @intCast(self.size_y.?.um),
                        };
                    }
                    try r.ignore_remaining_expression();
                } else if (try r.expression("thickness")) {
                    self.thickness = .init_mm(try r.require_any_float(f64));
                    try r.ignore_remaining_expression();
                } else if (try r.expression("bold")) {
                    self.bold = try r.string("yes");
                    try r.ignore_remaining_expression();
                } else if (try r.expression("italic")) {
                    self.italic = try r.string("yes");
                    try r.ignore_remaining_expression();
                } else if (try r.any_expression()) |_| {
                    try r.ignore_remaining_expression();
                } else if (try r.any_string()) |_| {
                    // ignore
                } else break;
            }
            try r.require_close();

        } else if (try r.expression("justify")) {
            while (true) {
                if (try r.expression("left")) {
                    self.justify = .left;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("center")) {
                    self.justify = .center;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("right")) {
                    self.justify = .right;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("top")) {
                    self.baseline = .top;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("middle")) {
                    self.baseline = .middle;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("bottom")) {
                    self.baseline = .bottom;
                    try r.ignore_remaining_expression();
                } else if (try r.expression("mirror")) {
                    self.mirrored = true;
                    try r.ignore_remaining_expression();
                } else if (try r.any_expression()) |_| {
                    try r.ignore_remaining_expression();
                } else if (try r.any_string()) |_| {
                    // ignore
                } else break;
            }
            try r.require_close();

        } else if (try r.any_expression()) |_| {
            try r.ignore_remaining_expression();
        } else if (try r.any_string()) |_| {
            // ignore
        } else break;
    }

    try r.require_close();
    return true;
}

pub fn write_effects(self: Text_Style, w: *sx.Writer) !void {
    try w.expression_expanded("effects");
    try w.expression_expanded("font");

    const font = self.get_font();
    if (font.len > 0) {
        try w.expression("face");
        try w.string_quoted(font);
        try w.close();
    }

    try w.expression("size");
    try w.float(self.get_size_y().mm(f64));
    try w.float(self.get_size_x().mm(f64));
    try w.close();

    try w.expression("thickness");
    try w.float(self.get_thickness().mm(f64));
    try w.close();

    if (self.is_bold()) {
        try w.expression("bold");
        try w.string("yes");
        try w.close();
    }

    if (self.is_italic()) {
        try w.expression("italic");
        try w.string("yes");
        try w.close();
    }

    try w.close();

    const justification = self.get_justification();
    const baseline = self.get_baseline();
    const mirror = self.is_mirrored();
    if (mirror or justification != .center or baseline != .middle) {
        try w.expression("justify");
        if (justification != .center) {
            try w.string(@tagName(justification));
        }
        if (baseline != .middle) {
            try w.string(@tagName(baseline));
        }
        if (mirror) {
            try w.string("mirror");
        }
        try w.close();
    }

    try w.close();
}

const Micron = @import("Micron.zig");
const Ratio = @import("Ratio.zig");
const Layer = @import("../kicad.zig").Layer;
const sx = @import("sx");
const std = @import("std");
