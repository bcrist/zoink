width: Micron = .init_mm(0.2),
stroke_type: Type = .solid,

const Type = enum {
    solid,
    dash,
    dot,
    dash_dot,
    dash_dot_dot,
};

pub fn read(r: *sx.Reader) !?Stroke_Style {
    if (!try r.expression("stroke")) return null;

    var self: Stroke_Style = .{};

    while (true) {
        if (try r.expression("width")) {
            self.width = .init_mm(try r.require_any_float(f64));
            try r.ignore_remaining_expression();
        } else if (try r.expression("type")) {
            if (try r.any_string()) |str| {
                if (std.meta.stringToEnum(Type, str)) |t| {
                    self.stroke_type = t;
                }
            }
            try r.ignore_remaining_expression();
        } else if (try r.any_expression()) |_| {
            try r.ignore_remaining_expression();
        } else if (try r.any_string()) |_| {
            // ignore
        } else break;
    }

    try r.require_close();
    return self;
}

pub fn write(self: Stroke_Style, w: *sx.Writer) !void {
    try w.expression_expanded("stroke");

    try w.expression("width");
    try w.float(self.width.mm(f64));
    try w.close();

    try w.expression("type");
    try w.string(@tagName(self.stroke_type));
    try w.close();

    try w.close();
}

const Stroke_Style = @This();

const Micron = @import("Micron.zig");
const sx = @import("sx");
const std = @import("std");
