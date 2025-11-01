content: []const u8,
location: Location = .origin,
rotation: Rotation = .none,
style: Text_Style = .{},
uuid: Uuid = .nil,

pub fn read(r: *sx.Reader, arena: std.mem.Allocator, expr: []const u8) !?Text {
    if (!try r.expression(expr)) return null;
    const content = try arena.dupe(u8, try r.require_any_string());
    return try read_inner(r, arena, content);
}

pub fn read_inner(r: *sx.Reader, arena: std.mem.Allocator, content: []const u8) !Text {
    var location: Location = .origin;
    var rotation: Rotation = .none;
    var style: Text_Style = .{};
    var uuid: Uuid = .nil;

    while (true) {
        if (try r.expression("locked")) {
            style.locked = try r.string("yes");
            try r.ignore_remaining_expression();
        } else if (try r.expression("hide")) {
            style.hidden = try r.string("yes");
            try r.ignore_remaining_expression();
        } else if (try r.expression("layer")) {
            if (try r.any_string()) |layer_name| {
                if (Layer.from_kicad_name(layer_name)) |layer| {
                    style.layer = layer;
                }
            }
            if (try r.string("knockout")) {
                style.knockout = true;
            }
            try r.ignore_remaining_expression();
        } else if (try Uuid.read(r)) |id| {
            uuid = id;
        } else if (try Location.read(r, "at", &rotation)) |loc| {
            location = loc;
        } else if (try style.read_effects(r, arena)) {
            // ok
        } else if (try r.any_expression()) |_| {
            try r.ignore_remaining_expression();
        } else if (try r.any_string()) |_| {
            // ignore
        } else break;
    }

    try r.require_close();

    return .{
        .content = content,
        .location = location,
        .rotation = rotation,
        .style = style,
        .uuid = uuid,
    };
}

pub fn write(self: Text, w: *sx.Writer, expr: []const u8) !void {
    try w.expression(expr); // gr_text or fp_text
    try w.string_quoted(self.content);
    w.set_compact(false);

    try self.location.write(w, "at", self.rotation);

    try w.expression("layer");
    try w.string_quoted(self.style.get_layer().get_kicad_name(.{}));
    if (self.style.is_knockout()) {
        try w.string("knockout");
    }
    try w.close();

    try self.uuid.write(w);
    try self.style.write_effects(w);
    try w.close();
}

const Text = @This();

const Layer = @import("../kicad.zig").Layer;
const Uuid = @import("Uuid.zig");
const Location = @import("Location.zig");
const Rotation = @import("Rotation.zig");
const Text_Style = @import("Text_Style.zig");
const sx = @import("sx");
const std = @import("std");
