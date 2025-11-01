path: []const u8,
scale_x: Ratio = .{},
scale_y: Ratio = .{},
scale_z: Ratio = .{},
rot_x: Rotation = .{},
rot_y: Rotation = .{},
rot_z: Rotation = .{},
offset_x: Micron = .{ .um = 0 },
offset_y: Micron = .{ .um = 0 },
offset_z: Micron = .{ .um = 0 },
opacity: Ratio = .{},

const Ratio = @import("Ratio.zig");
const Rotation = @import("Rotation.zig");
const Micron = @import("Micron.zig");
