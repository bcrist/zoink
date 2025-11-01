start: Location = .origin,
end: Location = .origin,
stroke: Stroke_Style = .{},
layer: Layer = .silkscreen_front,
uuid: Uuid = .nil,

pub fn read(r: *sx.Reader, expr: []const u8) !?Line {
    if (!try r.expression(expr)) return null;

    var self: Line = .{};

    while (true) {
        if (try Location.read(r, "start", null)) |loc| {
            self.start = loc;
        } else if (try Location.read(r, "end", null)) |loc| {
            self.end = loc;
        } else if (try Stroke_Style.read(r)) |ss| {
            self.stroke = ss;
        } else if (try Uuid.read(r)) |id| {
            self.uuid = id;
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
    return self;
}

pub fn write(self: Line, w: *sx.Writer, expr: []const u8) !void {
    try w.expression_expanded(expr); // fp_line or gr_line

    try self.start.write(w, "start", null);
    try self.end.write(w, "end", null);

    try self.stroke.write(w);

    try w.expression("layer");
    try w.string_quoted(self.layer.get_kicad_name(.{}));
    try w.close();

    try self.uuid.write(w);

    try w.close();
}

const log = std.log.scoped(.zoink);

const Line = @This();

const Layer = @import("../kicad.zig").Layer;
const Uuid = @import("Uuid.zig");
const Stroke_Style = @import("Stroke_Style.zig");
const Location = @import("Location.zig");
const sx = @import("sx");
const std = @import("std");
