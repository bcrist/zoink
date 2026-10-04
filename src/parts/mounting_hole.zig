pub const M2_NPTH = Connector("", 1, pkg.M2_NPTH);
pub const @"M2.5_NPTH" = Connector("", 1, pkg.@"M2.5_NPTH");
pub const M3_NPTH = Connector("", 1, pkg.M3_NPTH);
pub const @"M3.5_NPTH" = Connector("", 1, pkg.@"M3.5_NPTH");
pub const M4_NPTH = Connector("", 1, pkg.M4_NPTH);
pub const M5_NPTH = Connector("", 1, pkg.M5_NPTH);

pub const M2_PTH = Connector("", 1, pkg.M2_PTH);
pub const @"M2.5_PTH" = Connector("", 1, pkg.@"M2.5_PTH");
pub const M3_PTH = Connector("", 1, pkg.M3_PTH);
pub const @"M3.5_PTH" = Connector("", 1, pkg.@"M3.5_PTH");
pub const M4_PTH = Connector("", 1, pkg.M4_PTH);
pub const M5_PTH = Connector("", 1, pkg.M5_PTH);

const pkg = @import("../packages.zig").mounting_hole;
const Connector = @import("../parts.zig").Connector;
const std = @import("std");
