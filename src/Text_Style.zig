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

const Justification = enum {
    left,
    center,
    right,
};

const Text_Style = @This();

pub fn get_layer(self: Text_Style) Layer {
    return self.layer orelse if (self.parent) |parent| parent.get_layer() else .front_silkscreen;
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

const Micron = @import("Micron.zig");
const Ratio = @import("Ratio.zig");
const Layer = @import("enums.zig").Layer;
