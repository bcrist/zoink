points: []const Location,
stroke: Stroke_Style = .{},
fill: bool = false,
layer: Layer = .silkscreen_front,
uuid: Uuid = .nil,

pub fn read(r: *sx.Reader, arena: std.mem.Allocator, expr: []const u8) !?Polygon {
    if (!try r.expression(expr)) return null;

    var pts: std.ArrayList(Location) = .empty;

    var self: Polygon = .{ .points = &.{} };

    while (true) {
        if (try r.expression("pts")) {
            while (try Location.read(r, "xy", null)) |loc| {
                try pts.append(arena, loc);
            }
            try r.ignore_remaining_expression();

        } else if (try Stroke_Style.read(r)) |ss| {
            self.stroke = ss;
        } else if (try Uuid.read(r)) |id| {
            self.uuid = id;
        } else if (try r.expression("fill")) {
            self.fill = try r.string("yes");
            try r.ignore_remaining_expression();

        } else if (try r.expression("layer")) {
            if (try r.any_string()) |layer_name| {
                if (Layer.from_kicad_name(layer_name)) |layer| {
                    self.layer = layer;
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

    self.points = pts.items;

    return self;
}

pub fn write(self: Polygon, w: *sx.Writer, expr: []const u8) !void {
    try w.expression_expanded(expr);

    try w.expression("pts");
    for (self.points) |pt| try pt.write(w, "xy", null);
    try w.close();

    try self.stroke.write(w);

    try w.expression("fill");
    try w.string(if (self.fill) "yes" else "no");
    try w.close();

    try w.expression("layer");
    try w.string_quoted(self.layer.get_kicad_name(.{}));
    try w.close();

    try self.uuid.write(w);

    try w.close();
}

const log = std.log.scoped(.zoink);

const Polygon = @This();

const Layer = @import("../kicad.zig").Layer;
const Uuid = @import("Uuid.zig");
const Location = @import("Location.zig");
const Stroke_Style = @import("Stroke_Style.zig");
const sx = @import("sx");
const std = @import("std");
