x: Micron,
y: Micron,

pub const origin: Location = .{
    .x = .zero,
    .y = .zero,
};

pub fn init_um(x: f64, y: f64) Location {
    return .{
        .x = .init_um(x),
        .y = .init_um(y),
    };
}

pub fn init_um_transformed(xf: zm.Mat3, x: f64, y: f64) Location {
    const vec = xf.multiplyVec3(.{ x, y, 1 });
    return .{
        .x = .init_um(vec[0]),
        .y = .init_um(vec[1]),
    };
}

pub fn init_mm(x: f64, y: f64) Location {
    return .{
        .x = .init_mm(x),
        .y = .init_mm(y),
    };
}

pub fn init_mm_transformed(xf: zm.Mat3, x: f64, y: f64) Location {
    const vec = xf.multiplyVec3(.{ x, y, 1 });
    return .{
        .x = .init_mm(vec[0]),
        .y = .init_mm(vec[1]),
    };
}

pub fn dst_mm(self: Location, other: Location) f64 {
    const dx = self.x.mm(f64) - other.x.mm(f64);
    const dy = self.y.mm(f64) - other.y.mm(f64);
    return @sqrt(dx * dx + dy * dy);
}

pub fn read(r: *sx.Reader, expr: []const u8, maybe_rotation: ?*Rotation) !?Location {
    if (!try r.expression(expr)) return null;

    var self: Location = .origin;
    if (try r.any_float(f64)) |x| self.x = .init_mm(x);
    if (try r.any_float(f64)) |y| self.y = .init_mm(y);

    if (maybe_rotation) |rotation| {
        if (try r.any_int(isize, 10)) |deg| {
            rotation.deg = deg;
        }
    }

    try r.ignore_remaining_expression();
    return self;
}

pub fn write(self: Location, w: *sx.Writer, expr: []const u8, rotation: ?Rotation) !void {
    try w.expression(expr);
    try w.float(self.x.mm(f64));
    try w.float(self.y.mm(f64));
    if (rotation) |r| {
        try w.int(r.deg, 10);
    }
    try w.close();
}

const log = std.log.scoped(.zoink);

const Location = @This();

const Rotation = @import("Rotation.zig");
const Micron = @import("Micron.zig");
const sx = @import("sx");
const zm = @import("zm");
const std = @import("std");
