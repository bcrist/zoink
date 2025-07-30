pub fn LC4k(
    comptime device_type: lc4k.Device_Type,
    comptime vcc: Net_ID,
    comptime vcco0: Net_ID,
    comptime vcco1: Net_ID,
    comptime Decoupler: type,
) type {
    const Chip_Config = lc4k.Chip_Config(device_type);
    const Signal = Chip_Config.Signal;
    const Device = Chip_Config.Device;
    const Simulator = lc4k.Simulator(Device);

    const Pkg = switch (Device.package) {
        .TQFP44 => pkg.TQFP_48_7mm,
        .TQFP48 => pkg.TQFP_44_10mm,
        .TQFP100 => pkg.LQFP_100_14mm,
        .TQFP128 => pkg.LQFP_128_14mm,
        .TQFP144 => pkg.LQFP_144_20mm,
        .csBGA56 => pkg.lattice.csBGA56,
        .csBGA64 => pkg.lattice.csBGA64,
        .ucBGA64 => pkg.lattice.ucBGA64,
        .csBGA132 => pkg.lattice.csBGA132,
        .ucBGA132 => pkg.lattice.ucBGA132,
        .csBGA144 => pkg.lattice.csBGA144,
    };

    switch (Device.family) {
        .low_power => switch (vcc) {
            .p3v3 => {}, // V
            .p2v5 => {}, // B
            .p1v8 => {}, // C
            else => unreachable,
        },
        .zero_power, .zero_power_enhanced => std.debug.assert(vcc == .p1v8),
    }

    std.debug.assert(Device.num_mcs_per_glb == 16);

    const vcco0_f = @field(Voltage, @tagName(vcco0)).as_float();
    const vcco1_f = @field(Voltage, @tagName(vcco1)).as_float();

    const Power = power.Multi(Device.vcc_pins.len, Device.gnd_pins.len, vcc, Decoupler);
    const Power_Bank0 = power.Multi(Device.vcco_bank0_pins.len, Device.gnd_bank0_pins.len, vcco0, Decoupler);
    const Power_Bank1 = power.Multi(Device.vcco_bank1_pins.len, Device.gnd_bank1_pins.len, vcco1, Decoupler);

    return struct {
        base: Part.Base = .{
            .package = &Pkg.pkg,
            .prefix = .U,
        },

        config: *const Chip_Config,

        pwr: Power = .{},
        pwr_bank0: Power_Bank0 = .{},
        pwr_bank1: Power_Bank1 = .{},
        jtag: struct {
            tdi: Net_ID = .unset,
            tdo: Net_ID = .unset,
            tms: Net_ID = .unset,
            tck: Net_ID = .unset,
        } = .{},

        io: [Device.num_glbs][16]Net_ID = @splat(@splat(.unset)),
        in: [Device.input_pins.len]Net_ID = @splat(.unset),
        clk: [Device.clock_pins.len]Net_ID = @splat(.unset),

        pub const input_levels = struct {
            pub const low_threshold = struct {
                pub const Vil = Voltage.from_float(0.35 * 1.8);
                pub const Vth = Voltage.from_float(0.5 * 1.8);
                pub const Vih = Voltage.from_float(0.65 * 1.8);
                pub const Vclamp = Voltage.from_float(3.6);
            };
            pub const high_threshold = struct {
                pub const Vil = Voltage.from_float(0.7);
                pub const Vth = Voltage.from_float(1.35);
                pub const Vih = Voltage.from_float(2.0);
                pub const Vclamp = Voltage.from_float(5.5);
            };
        };

        pub const output_levels = struct {
            pub const bank0 = struct {
                pub const Vol = Voltage.from_float(@max(0.1 * vcco0_f, 0.4));
                pub const Voh = Voltage.from_float(@min(0.9 * vcco0_f, vcco0_f - 0.4));
            };
            pub const bank1 = struct {
                pub const Vol = Voltage.from_float(@max(0.1 * vcco1_f, 0.4));
                pub const Voh = Voltage.from_float(@min(0.9 * vcco1_f, vcco1_f - 0.4));
            };
        };

        pub fn set_net_by_pin(self: @This(), p: lc4k.Pin(Signal), net: Net_ID) void {
            switch (p.func()) {
                .io, .io_oe0, .io_oe1 => |mc_index| {
                    self.io[p.info.glb.?][mc_index] = net;
                },
                .input => for (0.., Device.input_pins) |input_index, input_pin| {
                    if (input_pin.info.all_pins_index == p.info.all_pins_index) {
                        self.in[input_index] = net;
                        break;
                    }
                } else unreachable,
                .clock => for (0.., Device.clock_pins) |clock_index, clock_pin| {
                    if (clock_pin.info.all_pins_index == p.info.all_pins_index) {
                        self.clk[clock_index] = net;
                        break;
                    }
                } else unreachable,
                else => unreachable,
            }
        }

        pub fn set_net(self: @This(), signal: Signal, net: Net_ID) void {
            self.set_net_by_pin(signal.pin(), net);
        }

        pub fn set_bus_by_pins(self: @This(), pins: []const lc4k.Pin(Signal), nets: []const Net_ID) void {
            for (pins, nets) |p, net| {
                self.set_net_by_pin(p, net);
            }
        }

        pub fn set_bus(self: @This(), signals: []const Signal, nets: []const Net_ID) void {
            for (signals, nets) |signal, net| {
                self.set_net_by_pin(signal.pin(), net);
            }
        }

        pub fn check_config(self: @This()) !void {
            for (0..Device.num_glbs) |glb| {
                for (0..16) |mc| {
                    const fb = Signal.mc_fb(.init(glb, mc));
                    if (fb.maybe_pin() == null) {
                        switch (self.io[glb][mc]) {
                            .unset => self.io[glb][mc] = .no_connect,
                            .no_connect => {},
                            else => {
                                log.err("Net {s} is a no-connect on the {s} package", .{ @tagName(fb), @tagName(Device.package) });
                                return error.UnassignedSignal;
                            },
                        }
                    }
                }
            }
        }

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            const pin_number = @intFromEnum(pin_id);
            if (pin_id == .heatsink or pin_number > Device.all_pins.len) return .no_connect;

            const pin_index = pin_number - 1;
            const p: lc4k.Pin(Signal) = Device.all_pins[pin_index];
            return switch (p.func()) {
                .io, .io_oe0, .io_oe1 => |mc_index| self.io[p.glb.?][mc_index],
                .input => for (0.., Device.input_pins) |input_index, input_pin| {
                    if (input_pin.info.all_pins_index == pin_index) {
                        break self.in[input_index];
                    }
                } else unreachable,
                .clock => for (0.., Device.clock_pins) |clock_index, clock_pin| {
                    if (clock_pin.info.all_pins_index == pin_index) {
                        break self.clk[clock_index];
                    }
                } else unreachable,
                .gnd => for (0.., Device.gnd_pins) |gnd_index, gnd_pin| {
                    if (gnd_pin.info.all_pins_index == pin_index) {
                        break self.pwr.gnd[gnd_index];
                    }
                } else unreachable,
                .vcc_core => for (0.., Device.vcc_pins) |vcc_index, vcc_pin| {
                    if (vcc_pin.info.all_pins_index == pin_index) {
                        break @field(self.pwr, @tagName(vcc))[vcc_index];
                    }
                } else unreachable,
                .gndo => |bank| switch (bank) {
                    0 => for (0.., Device.gnd_bank0_pins) |gnd_index, gnd_pin| {
                        if (gnd_pin.info.all_pins_index == pin_index) {
                            break self.pwr_bank0.gnd[gnd_index];
                        }
                    } else unreachable,
                    1 => for (0.., Device.gnd_bank1_pins) |gnd_index, gnd_pin| {
                        if (gnd_pin.info.all_pins_index == pin_index) {
                            break self.pwr_bank1.gnd[gnd_index];
                        }
                    } else unreachable,
                    else => unreachable,
                },
                .vcco => |bank| switch (bank) {
                    0 => for (0.., Device.vcco_bank0_pins) |vcc_index, vcc_pin| {
                        if (vcc_pin.info.all_pins_index == pin_index) {
                            break @field(self.pwr_bank0, @tagName(vcco0))[vcc_index];
                        }
                    } else unreachable,
                    1 => for (0.., Device.vcco_bank1_pins) |vcc_index, vcc_pin| {
                        if (vcc_pin.info.all_pins_index == pin_index) {
                            break @field(self.pwr_bank1, @tagName(vcco1))[vcc_index];
                        }
                    } else unreachable,
                    else => unreachable,
                },
                .tck => self.jtag.tck,
                .tms => self.jtag.tms,
                .tdi => self.jtag.tdi,
                .tdo => self.jtag.tdo,
                .no_connect => .no_connect,
            };
        }

        pub fn validate(self: @This(), v: *Validator, state: *Simulator.State, mode: Validator.Update_Mode) !void {
            switch (mode) {
                .reset => {
                    state.* = self.config.simulator(null);
                },
                .commit, .nets_only => {
                    var sim: Simulator = .{
                        .chip = self,
                        .state = state.*,
                    };

                    if (mode == .commit) {
                        for (0.., self.clk) |i, net| {
                            try self.check_threshold(self.config.clock[i], net);
                        }
                        for (0.., self.in) |i, net| {
                            try self.check_threshold(self.config.input[i], net);
                        }
                        for (0..Device.num_glbs) |glb| {
                            for (0..16) |mc| {
                                try self.check_threshold(self.config.glb[glb].mc[mc].input, v, self.io[glb][mc]);
                            }
                        }
                    }

                    for (0.., self.clk, Device.clock_pins) |i, net, clock_pin| {
                        try self.read_into_sim(self.config.clock[i], v, &sim, clock_pin.pad(), net);
                    }
                    for (0.., self.in, Device.input_pins) |i, net, input_pin| {
                        try self.read_into_sim(self.config.input[i], v, &sim, input_pin.pad(), net);
                    }
                    for (0..Device.num_glbs) |glb| {
                        for (0.., self.io[glb]) |mc, net| {
                            if (Signal.maybe_mc_pad(.init(glb, mc))) |pad| {
                                try self.read_into_sim(self.config.glb[glb].mc[mc].input, v, &sim, pad, net);
                            }
                        }
                    }

                    try sim.simulate(.{
                        .max_iterations = if (v.hash_part_state) 10 else 100,
                    });

                    for (0.., self.clk, Device.clock_pins) |i, net, clock_pin| {
                        try self.drive_maintenance(self.config.clock[i], v, &sim, clock_pin.pad(), net);
                    }
                    for (0.., self.in, Device.input_pins) |i, net, input_pin| {
                        try self.drive_maintenance(self.config.input[i], v, &sim, input_pin.pad(), net);
                    }
                    for (0..Device.num_glbs) |glb| {
                        for (0.., self.io[glb]) |mc, net| {
                            if (Signal.maybe_mc_pad(.init(glb, mc))) |pad| {
                                try self.drive_maintenance(self.config.glb[glb].mc[mc].input, v, &sim, pad, net);
                                try self.maybe_drive_output(self.config.glb[glb].mc[mc].output, v, &sim, pad, net);
                            }
                        }
                    }

                    if (mode == .commit) {
                        state.* = sim.state;
                    }
                },
            }
        }

        fn check_threshold(self: @This(), input_config: anytype, v: *Validator, net: Net_ID) !void {
            switch (self.threshold(input_config)) {
                .low => try v.expect_valid(net, input_levels.low_threshold),
                .high => try v.expect_valid(net, input_levels.high_threshold),
            }
        }

        fn threshold(self: @This(), input_config: anytype) lc4k.Input_Threshold {
            return input_config.threshold orelse self.config.default_input_threshold;
        }

        fn read_into_sim(self: @This(), input_config: anytype, v: *Validator, sim: *Simulator, pad: Signal, net: Net_ID) !void {
            sim.state.data.setPresent(pad, switch (self.threshold(input_config)) {
                .low => v.read_logic(net, input_levels.low_threshold),
                .high => v.read_logic(net, input_levels.high_threshold),
            });
        }

        fn maintenance(self: @This(), input_config: anytype) lc4k.Bus_Maintenance {
            if (@hasField(@TypeOf(input_config), "bus_maintenance")) {
                if (input_config.bus_maintenance) |m| return m;
            }
            return self.config.default_bus_maintenance;
        }

        fn drive_maintenance(self: @This(), input_config: anytype, v: *Validator, sim: *Simulator, pad: Signal, net: Net_ID) !void {
            if (pad.maybe_pin()) |p| {
                const state = sim.state.data.contains(pad);
                switch (p.info.bank.?) {
                    0 => switch (self.maintenance(input_config)) {
                        .float => {},
                        .pulldown => try v.drive_logic_weak(net, false, output_levels.bank0),
                        .pullup => try v.drive_logic_weak(net, true, output_levels.bank0),
                        .keeper => try v.drive_logic_weak(net, state, output_levels.bank0),
                    },
                    1 => switch (self.maintenance(input_config)) {
                        .float => {},
                        .pulldown => try v.drive_logic_weak(net, false, output_levels.bank1),
                        .pullup => try v.drive_logic_weak(net, true, output_levels.bank1),
                        .keeper => try v.drive_logic_weak(net, state, output_levels.bank1),
                    },
                }
            }
        }

        fn drive_type(self: @This(), output_config: anytype) lc4k.Drive_Type {
            return output_config.drive_type orelse self.config.default_drive_type;
        }

        fn maybe_drive_output(self: @This(), output_config: anytype, v: *Validator, sim: *Simulator, pad: Signal, net: Net_ID) !void {
            if (pad.maybe_pin()) |p| {
                if (sim.state.oe.contains(pad)) {
                    const state = sim.state.data.contains(pad);
                    switch (self.drive_type(output_config)) {
                        .open_drain => if (state) return,
                        .push_pull => {},
                    }
                    switch (p.info.bank.?) {
                        0 => try v.drive_logic(net, state, output_levels.bank0),
                        1 => try v.drive_logic(net, state, output_levels.bank1),
                    }
                }
            }
        }
    };
}

const log = std.log.scoped(.zoink);

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Voltage = enums.Voltage;
const pkg = @import("../packages.zig");
const enums = @import("../enums.zig");
const power = @import("../power.zig");
const Part = @import("../Part.zig");
const Validator = @import("../Validator.zig");
const lc4k = @import("lc4k");
const std = @import("std");
