center: Location = .origin,
start: Location,
end: Location, // distance from center is normalized to equal distance from start to center
clockwise: bool = true,
stroke: Stroke_Style = .{},
layer: Layer = .silkscreen_front,
uuid: Uuid = .nil,

pub fn read(r: *sx.Reader, expr: []const u8) !?Arc {
    if (!try r.expression(expr)) return null;

    var self: Arc = .{
        .start = .origin,
        .end = .origin,
    };
    var mid: Location = .origin;

    while (true) {
        if (try Location.read(r, "start", null)) |loc| {
            self.start = loc;
        } else if (try Location.read(r, "end", null)) |loc| {
            self.end = loc;
        } else if (try Location.read(r, "mid", null)) |loc| {
            mid = loc;
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

    if (self.start.x.um == self.end.x.um and self.start.y.um == self.end.y.um) {
        if (mid.x.um == self.start.x.um and mid.y.um == self.start.y.um) {
            // special case: 0 degrees
            self.center = self.start;
            self.clockwise = false;
        } else {
            // special case: 360 degrees
            self.center.x.um = self.start.x.um + @divTrunc(self.center.x.um, 2);
            self.center.y.um = self.start.y.um + @divTrunc(self.center.y.um, 2);
            self.clockwise = false;
        }
    } else {
        const a: @Vector(2, f64) = .{
            @floatFromInt(self.start.x.um - mid.x.um),
            @floatFromInt(self.start.y.um - mid.y.um),
        };
        const alen2 = @reduce(.Add, a * a);

        const b: @Vector(2, f64) = .{
            @floatFromInt(self.end.x.um - mid.x.um),
            @floatFromInt(self.end.y.um - mid.y.um),
        };
        const blen2 = @reduce(.Add, b * b);

        const cn: @Vector(2, f64) = .{
            b[1] * alen2 - a[1] * blen2,
            a[0] * blen2 - b[0] * alen2,
        };
        const cd: @Vector(2, f64) = @splat(2 * (a[0] * b[1] - a[1] * b[0]));
        const c = cn / cd;

        self.center.x.um = @intFromFloat(c[0] + @as(f64, @floatFromInt(mid.x.um)));
        self.center.y.um = @intFromFloat(c[1] + @as(f64, @floatFromInt(mid.y.um)));

        // Since the overall arc length must be <= 360 degrees, the arc length from the midpoint to end must be <= 180 degrees.
        // Therefore from a reference frame where the midpoint is at the bottom and the center of the arc is directly above it,
        // if the end point is to the left then the arc is clockwise, and if it's to the right the arc is anti-clockwise.
        // We can check this by projecting the vector from mid to end onto the perpendicular of the vector from mid to center:
        self.clockwise = (c[1] * b[0] - c[0] * b[1]) >= 0;
    }

    return self;
}

pub fn write(self: Arc, w: *sx.Writer, expr: []const u8) !void {
    try w.expression_expanded(expr);

    try self.start.write(w, "start", null);

    if (self.start.x.um == self.center.x.um and self.start.y.um == self.center.y.um) {
        // special case: 0 degrees
        try self.start.write(w, "mid", null);
        try self.start.write(w, "end", null);
        
    } else if (self.start.x.um == self.end.x.um and self.start.y.um == self.end.y.um) {
        // special case: 360 degrees
        const mid: Location = .{
            .x = .{ .um = 2 * self.center.x.um - self.start.x.um },
            .y = .{ .um = 2 * self.center.y.um - self.start.y.um },
        };

        try mid.write(w, "mid", null);
        try self.end.write(w, "end", null);

    } else {
        // 1. normalize endpoint to have same radius from center as start point
        // 2. find the midpoint between start and normalized end point
        // 3. find a tangent vector to the vector from start to end point
        //      - tangent handedness should match "clockwise" property of arc
        //      - this step removes the numerical instability when the start/end points are
        //        near opposite each other, and ensures that the result has the proper winding direction.
        // 4. add tagnent vector to midpoint and normalize to same radius as start point

        const center: @Vector(2, f64) = .{
            @floatFromInt(self.center.x.um),
            @floatFromInt(self.center.y.um),
        };

        const start: @Vector(2, f64) = .{
            @floatFromInt(self.start.x.um - self.center.x.um),
            @floatFromInt(self.start.y.um - self.center.y.um),
        };

        const original_end: @Vector(2, f64) = .{
            @floatFromInt(self.end.x.um - self.center.x.um),
            @floatFromInt(self.end.y.um - self.center.y.um),
        };

        const one_half: @Vector(2, f64) = @splat(0.5);

        const start_radius = @sqrt(@reduce(.Add, start * start));
        const original_end_radius = @sqrt(@reduce(.Add, original_end * original_end));
        const end_radius_adjust: @Vector(2, f64) = @splat(start_radius / original_end_radius);
        const end = original_end * end_radius_adjust;
        const midpoint = (start + end) * one_half;
        const delta = end - start;

        const tangent: @Vector(2, f64) = if (self.clockwise)
            .{ delta[1], -delta[0] }
        else
            .{ -delta[1], delta[0] };

        const modified_midpoint_1 = tangent + midpoint;
        const modified_midpoint_2 = tangent - midpoint;
        const modified_midpoint_1_radius2 = @reduce(.Add, modified_midpoint_1 * modified_midpoint_1);
        const modified_midpoint_2_radius2 = @reduce(.Add, modified_midpoint_2 * modified_midpoint_2);
        const normalized_midpoint = if (modified_midpoint_1_radius2 > modified_midpoint_2_radius2) result: {
            const k: @Vector(2, f64) = @splat(start_radius / @sqrt(modified_midpoint_1_radius2));
            break :result modified_midpoint_1 * k;
        } else result: {
            const k: @Vector(2, f64) = @splat(start_radius / @sqrt(modified_midpoint_2_radius2));
            break :result modified_midpoint_2 * k;
        };

        const mid_loc: Location = .{
            .x = .{ .um = @intFromFloat((center + normalized_midpoint)[0]) },
            .y = .{ .um = @intFromFloat((center + normalized_midpoint)[1]) },
        };

        const end_loc: Location = .{
            .x = .{ .um = @intFromFloat((center + end)[0]) },
            .y = .{ .um = @intFromFloat((center + end)[1]) },
        };

        try mid_loc.write(w, "mid", null);
        try end_loc.write(w, "end", null);
    }

    try self.stroke.write(w);
    
    try w.expression("layer");
    try w.string_quoted(self.layer.get_kicad_name(.{}));
    try w.close();

    try self.uuid.write(w);

    try w.close();
}

const Arc = @This();

const Layer = @import("../kicad.zig").Layer;
const Uuid = @import("Uuid.zig");
const Location = @import("Location.zig");
const Stroke_Style = @import("Stroke_Style.zig");
const sx = @import("sx");
const zm = @import("zm");
const std = @import("std");
