name: []const u8,
text: Text,

pub fn read(r: *sx.Reader, arena: std.mem.Allocator) !?Property {
    if (!try r.expression("property")) return null;
    const name = try arena.dupe(u8, try r.require_any_string());
    const content = try arena.dupe(u8, try r.require_any_string());

    return .{
        .name = name,
        .text = try Text.read_inner(r, arena, content),
    };
}

pub fn write(self: Property, w: *sx.Writer) !void {
    try w.expression("property");
    try w.string_quoted(self.name);
    try w.string_quoted(self.text.content);
    w.set_compact(false);

    try self.text.location.write(w, "at", self.text.rotation);

    try w.expression("layer");
    try w.string_quoted(self.text.style.get_layer().get_kicad_name(.{}));
    if (self.text.style.is_knockout()) {
        try w.string("knockout");
    }
    try w.close();

    if (self.text.style.is_hidden()) {
        try w.expression("hide");
        try w.string("yes");
        try w.close();
    }

    try self.text.uuid.write(w);
    try self.text.style.write_effects(w);
    try w.close();
}

const log = std.log.scoped(.zoink);

const Property = @This();

const Text = @import("Text.zig");
const sx = @import("sx");
const std = @import("std");
