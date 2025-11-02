//! Currently just used for ensuring newly added footprints don't overlap each other

hash: u64,
min: @Vector(2, f64) = @splat(std.math.nan(f64)),
max: @Vector(2, f64) = @splat(std.math.nan(f64)),
offset: @Vector(2, f64) = @splat(0),
unapplied_offset: @Vector(2, f64) = @splat(0),

pub fn init_from_footprint(fp: kicad.Footprint, hash: u64) Bounding_Box {
    var self = Bounding_Box {
        .hash = hash,
    };

    for (fp.pads) |pad| {
        // this isn't super accurate, but it's close enough for my needs
        self.expand(pad.location, @max(pad.w.mm(f64), pad.h.mm(f64)));
    }
    for (fp.lines) |line| {
        self.expand(line.start, 0);
        self.expand(line.end, 0);
    }
    for (fp.rects) |rect| {
        self.expand(rect.start, 0);
        self.expand(rect.end, 0);
    }
    for (fp.polygons) |poly| {
        for (poly.points) |pt| self.expand(pt, 0);
    }
    for (fp.circles) |circle| {
        const radius = circle.center.dst_mm(circle.end);
        self.expand(circle.center, radius);
    }
    for (fp.arcs) |arc| {
        // TODO this is overconservative
        const radius = arc.center.dst_mm(arc.start);
        self.expand(arc.center, radius);
    }

    if (std.math.isNan(self.min[0])) {
        self.min = @splat(0);
        self.max = @splat(0);
    }
    
    return self;
}

pub fn expand(self: *Bounding_Box, loc: kicad.Location, radius: f64) void {
    const x = loc.x.mm(f64);
    const y = loc.y.mm(f64);
    if (std.math.isNan(self.min[0])) {
        self.min = .{
            x - radius,
            y - radius,
        };
        self.max = .{
            x + radius,
            y + radius,
        };
    } else {
        self.min = .{
            @min(self.min[0], x - radius),
            @min(self.min[1], y - radius),
        };
        self.max = .{
            @max(self.max[0], x + radius),
            @max(self.max[1], y + radius),
        };
    }
}

pub fn area(self: Bounding_Box) f64 {
    return @reduce(.Mul, self.max - self.min);
}

pub fn nudge(self: *Bounding_Box, rnd: std.Random) void {
    self.unapplied_offset += .{ rnd.float(f64) - 0.7, rnd.float(f64) - 0.7 };
}

pub fn check_and_resolve_intersection(self: *Bounding_Box, other: *Bounding_Box, rnd: std.Random) bool {
    if (self.max[0] < other.min[0]) return false;
    if (self.min[0] > other.max[0]) return false;
    if (self.max[1] < other.min[1]) return false;
    if (self.min[1] > other.max[1]) return false;

    const increase_x = other.max[0] - self.min[0] + 1;
    const decrease_x = self.max[0] - other.min[0] + 1;
    const increase_y = other.max[1] - self.min[1] + 1;
    const decrease_y = self.max[1] - other.min[1] + 1;
    const min = @min(increase_x, decrease_x, increase_y, decrease_y);

    const self_area = self.area();
    const other_area = other.area();
    if (increase_x == min) {
        self.unapplied_offset[0] += min * other_area / (self_area + other_area);
        other.unapplied_offset[0] -= min * self_area / (self_area + other_area);
    } else if (decrease_x == min) {
        self.unapplied_offset[0] -= min * other_area / (self_area + other_area);
        other.unapplied_offset[0] += min * self_area / (self_area + other_area);
    } else if (increase_y == min) {
        self.unapplied_offset[1] += min * other_area / (self_area + other_area);
        other.unapplied_offset[1] -= min * self_area / (self_area + other_area);
    } else {
        std.debug.assert(decrease_y == min);
        self.unapplied_offset[1] -= min * other_area / (self_area + other_area);
        other.unapplied_offset[1] += min * self_area / (self_area + other_area);
    }
    self.nudge(rnd);
    other.nudge(rnd);
    return true;
}

pub fn check_and_resolve_intersection_static(self: *Bounding_Box, other: Bounding_Box, rnd: std.Random) bool {
    if (self.max[0] < other.min[0]) return false;
    if (self.min[0] > other.max[0]) return false;
    if (self.max[1] < other.min[1]) return false;
    if (self.min[1] > other.max[1]) return false;

    const increase_x = other.max[0] - self.min[0] + 1;
    const decrease_x = self.max[0] - other.min[0] + 1;
    const increase_y = other.max[1] - self.min[1] + 1;
    const decrease_y = self.max[1] - other.min[1] + 1;
    const min = @min(increase_x, decrease_x, increase_y, decrease_y);

    if (decrease_x == min) {
        self.unapplied_offset[0] -= min;
    } else if (increase_x == min) {
        self.unapplied_offset[0] += min;
    } else if (decrease_y == min) {
        self.unapplied_offset[1] -= min;
    } else {
        std.debug.assert(increase_y == min);
        self.unapplied_offset[1] += min;
    }
    self.nudge(rnd);
    return true;
}

pub fn check_and_resolve_extreme_distance(self: *Bounding_Box) bool {
    var moved = false;
    if (self.offset[0] < -100) {
        self.unapplied_offset[0] = -self.offset[0] - 50;
        moved = true;
    }
    if (self.offset[1] < -100) {
        self.unapplied_offset[1] = -self.offset[1] - 50;
        moved = true;
    }
    return moved;
}

pub fn apply_offset(self: *Bounding_Box) void {
    self.offset += self.unapplied_offset;
    self.min += self.unapplied_offset;
    self.max += self.unapplied_offset;
    self.unapplied_offset = @splat(0);
}

const Bounding_Box = @This();

const kicad = @import("kicad.zig");
const std = @import("std");
