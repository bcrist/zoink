pub const Board = @import("Board.zig");
pub const Part = @import("Part.zig");
pub const Package = @import("Package.zig");
pub const Footprint = kicad.Footprint;
pub const Net_ID = enums.Net_ID;
pub const Pin_ID = enums.Pin_ID;
pub const Pin_Ref = @import("Pin_Ref.zig");
pub const Voltage = enums.Voltage;
pub const Validator = @import("Validator.zig");

pub const kicad = @import("kicad.zig");
pub const power = @import("power.zig");
pub const parts = @import("parts.zig");
pub const packages = @import("packages.zig");
pub const footprints = @import("footprints.zig");

const enums = @import("enums.zig");
