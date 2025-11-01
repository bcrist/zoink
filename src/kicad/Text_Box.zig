text: Text,
start: Location,
end: Location,
margins: [4]Micron,

pub fn read(r: *sx.Reader, arena: std.mem.Allocator, expr: []const u8) !?Text_Box {
    if (!try r.expression(expr)) return null;
    const content = try arena.dupe(u8, try r.require_any_string());

    var start: Location = .origin;
    var end: Location = .origin;
    var margins: [4]Micron = @splat(.zero);

    if (try Location.read(r, "start", null)) |loc| start = loc;
    if (try Location.read(r, "end", null)) |loc| end = loc;

    if (try r.expression("margins")) {
        margins[0] = .init_mm(try r.require_any_float(f64));
        margins[1] = .init_mm(try r.require_any_float(f64));
        margins[2] = .init_mm(try r.require_any_float(f64));
        margins[3] = .init_mm(try r.require_any_float(f64));

        try r.ignore_remaining_expression();
    }

    return .{
        .text = try Text.read_inner(r, arena, content),
        .start = start,
        .end = end,
        .margins = margins,
    };
}

pub fn write(self: Text_Box, w: *sx.Writer, expr: []const u8) !void {
    try w.expression(expr); // gr_text_box or fp_text_box
    try w.string_quoted(self.text.content);
    w.set_compact(false);

    try self.start.write(w, "start", null);
    try self.end.write(w, "end", null);

    try w.expression("margins");
    try w.float(self.margins[0].mm(f64));
    try w.float(self.margins[1].mm(f64));
    try w.float(self.margins[2].mm(f64));
    try w.float(self.margins[3].mm(f64));
    try w.close();

    try w.expression("layer");
    try w.string_quoted(self.text.style.get_layer().get_kicad_name(.{}));
    if (self.text.style.is_knockout()) {
        try w.string("knockout");
    }
    try w.close();

    try self.text.uuid.write(w);
    try self.text.style.write_effects(w);
    try w.close();
}

const Text_Box = @This();

const Micron = @import("Micron.zig");
const Location = @import("Location.zig");
const Text = @import("Text.zig");
const sx = @import("sx");
const std = @import("std");
