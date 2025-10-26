const BJT_Pinout = enum {
    bce,
    bec,
    cbe,
    ceb,
    ebc,
    ecb,
};

const BJT_Type = enum {
    npn,
    pnp,
};

/// Note: the validation simulation is not sophisticated enough to accurately model BJTs, but it might be good enough in cases where the transistor is always in saturation or off.
fn BJT(comptime bjt_type: BJT_Type, comptime Pkg: type, comptime pinout: BJT_Pinout) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .Q,
        },

        b: Net_ID = .unset,
        c: Net_ID = .unset,
        e: Net_ID = .unset,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (pinout) {
                .bce => switch (@intFromEnum(pin_id)) {
                    1 => self.b,
                    2 => self.c,
                    3 => self.e,
                    else => unreachable,
                },
                .bec => switch (@intFromEnum(pin_id)) {
                    1 => self.b,
                    2 => self.e,
                    3 => self.c,
                    else => unreachable,
                },
                .cbe => switch (@intFromEnum(pin_id)) {
                    1 => self.c,
                    2 => self.b,
                    3 => self.e,
                    else => unreachable,
                },
                .ceb => switch (@intFromEnum(pin_id)) {
                    1 => self.c,
                    2 => self.e,
                    3 => self.b,
                    else => unreachable,
                },
                .ebc => switch (@intFromEnum(pin_id)) {
                    1 => self.e,
                    2 => self.b,
                    3 => self.c,
                    else => unreachable,
                },
                .ecb => switch (@intFromEnum(pin_id)) {
                    1 => self.e,
                    2 => self.c,
                    3 => self.b,
                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {},
                .nets_only => {
                    const b = v.read_net(self.b);
                    const e = v.read_net(self.e);
                    const vbe = b.as_float() - e.as_float();
                    switch (bjt_type) {
                        .npn => if (vbe >= 0.6) {
                            v.connect_nets(self.c, self.e, 50);
                        },
                        .pnp => if (vbe <= -0.6) {
                            v.connect_nets(self.c, self.e, 50);
                        },
                    }
                },
            }
        }
    };
}

const FET_Pinout = enum {
    gds,
    gsd,
    dgs,
    dsg,
    sgd,
    sdg,
};

const FET_Type = enum {
    n_channel,
    p_channel,
};

/// Note: the validation simulation is not sophisticated enough to accurately model FETs, but it might be good enough in cases where the transistor is always in saturation or off.
fn FET(comptime fet_type: FET_Type, comptime Pkg: type, comptime pinout: FET_Pinout) type {
    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .Q,
        },

        g: Net_ID = .unset,
        d: Net_ID = .unset,
        s: Net_ID = .unset,
        vgs_th: f32 = 1.95,
        rds_on: f32 = 2,

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (pinout) {
                .gds => switch (@intFromEnum(pin_id)) {
                    1 => self.g,
                    2 => self.d,
                    3 => self.s,
                    else => unreachable,
                },
                .gsd => switch (@intFromEnum(pin_id)) {
                    1 => self.g,
                    2 => self.s,
                    3 => self.d,
                    else => unreachable,
                },
                .dgs => switch (@intFromEnum(pin_id)) {
                    1 => self.d,
                    2 => self.g,
                    3 => self.s,
                    else => unreachable,
                },
                .dsg => switch (@intFromEnum(pin_id)) {
                    1 => self.d,
                    2 => self.s,
                    3 => self.g,
                    else => unreachable,
                },
                .sgd => switch (@intFromEnum(pin_id)) {
                    1 => self.s,
                    2 => self.g,
                    3 => self.d,
                    else => unreachable,
                },
                .sdg => switch (@intFromEnum(pin_id)) {
                    1 => self.s,
                    2 => self.d,
                    3 => self.g,
                    else => unreachable,
                },
            };
        }

        pub fn validate(self: @This(), v: *Validator, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {},
                .commit => {},
                .nets_only => {
                    const g = v.read_net(self.g);
                    const s = v.read_net(self.s);
                    const vgs = g.as_float() - s.as_float();
                    switch (fet_type) {
                        .n_channel => if (vgs >= self.vgs_th) {
                            v.connect_nets(self.d, self.s, self.rds_on);
                        },
                        .p_channel => if (vgs <= -self.vgs_th) {
                            v.connect_nets(self.d, self.s, self.rds_on);
                        },
                    }
                },
            }
        }
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Validator = @import("../Validator.zig");
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
