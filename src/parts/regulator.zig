pub const AP62300TWU = struct {
    base: Part.Base = .{
        .package = &pkg.SOT23_6.pkg,
        .prefix = .U,
    },

    v_in: Net_ID = .unset,
    enable: Net_ID = .unset,
    gnd: Net_ID = .gnd,
    bootstrap: Net_ID = .unset,
    out: Net_ID = .unset,
    feedback: Net_ID = .unset,


    pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
        return switch (@intFromEnum(pin_id)) {
            1 => self.gnd,
            2 => self.out,
            3 => self.v_in,
            4 => self.feedback,
            5 => self.enable,
            6 => self.bootstrap,
        };
    }
};

pub fn Linear_5pin(comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        v_in: Net_ID = .unset,
        enable: Net_ID = .unset,
        gnd: Net_ID = .gnd,
        v_out: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@intFromEnum(pin_id)) {
                1 => self.v_in,
                2 => self.gnd,
                3 => self.enable,
                4 => .no_connect,
                5 => self.v_out,
            };
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
