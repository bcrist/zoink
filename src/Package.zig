default_footprint: ?*const Footprint,
has_pin: *const fn(pin: Pin_ID) bool,

const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const Footprint = @import("kicad.zig").Footprint;
