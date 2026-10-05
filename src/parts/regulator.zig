pub fn Linear_SOT23(comptime part_number: []const u8, comptime Input_Cap: type, comptime Output_Cap: type, comptime vout: Net_ID, comptime max_vin: Voltage) type {
    return Linear_5pin(part_number, Input_Cap, Output_Cap, vout, max_vin, pkg.SOT23_5);
}

pub fn Linear_5pin(comptime part_number: []const u8, comptime Input_Cap: type, comptime Output_Cap: type, comptime vout: Net_ID, comptime max_vin: Voltage, comptime Pkg: type) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
            .value = part_number,
        },

        pwr_in: power.Single_Unknown(Input_Cap) = .{},
        pwr_out: power.Multi(1, 0, vout, Output_Cap) = .{},
        enable: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@backingInt(pin_id)) {
                1 => self.pwr_in.vcc(0),
                2 => self.pwr_in.gnd,
                3 => self.enable,
                4 => .no_connect,
                5 => self.pwr_out.vcc(0),
                else => unreachable,
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {
                    try v.expect_below(self.pwr_in.vcc(0), max_vin);
                    try v.expect_below(self.enable, max_vin);
                },
                .nets_only => {},
            }
        }
    };
}

pub const AP62300TWU = struct {
    base: Part.Base = .{
        .package = &pkg.SOT23_6.pkg,
        .prefix = .U,
        .value = "AP62300TWU",
    },

    v_in: Net_ID = .unset,
    enable: Net_ID = .unset,
    gnd: Net_ID = .gnd,
    bootstrap: Net_ID = .unset,
    out: Net_ID = .unset,
    feedback: Net_ID = .unset,

    pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
        return switch (@backingInt(pin_id)) {
            1 => self.gnd,
            2 => self.out,
            3 => self.v_in,
            4 => self.feedback,
            5 => self.enable,
            6 => self.bootstrap,
            else => unreachable,
        };
    }
};

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Voltage = enums.Voltage;
const Validator = @import("../Validator.zig");
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
