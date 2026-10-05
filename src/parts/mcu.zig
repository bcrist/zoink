/// Raspberry Pi dual core ARM Cortex M0+
/// https://pip-assets.raspberrypi.com/categories/814-rp2040/documents/RP-008371-DS-1-rp2040-datasheet.pdf
/// https://pip-assets.raspberrypi.com/categories/814-rp2040/documents/RP-008279-DS-1-hardware-design-with-rp2040.pdf
pub const RP2040 = struct {
    base: Part.Base = .{
        .package = &pkg.QFN_56_7x7_EP.pkg,
        .prefix = .U,
        .value = "RP2040",
    },

    pwr_io: power.Multi(6, 1, .unset, parts.C0402_Decoupler) = .{}, // 1.8V - 3.3V
    pwr_vreg_in: power.Single(.unset, parts.C0402_Decoupler_1uf) = .{}, // 1.8V - 3.3V
    pwr_vreg_out: power.Single(.unset, parts.C0402_Decoupler_1uf) = .{}, // 1.1V
    pwr_int: power.Multi(2, 1, .unset, parts.C0402_Decoupler) = .{}, // 1.1V
    pwr_adc: power.Single(.unset, parts.C0402_Decoupler) = .{}, // 3.3V
    pwr_usb: power.Single_3V3(parts.C0402_Decoupler) = .{},

    gpio: [30]Net_ID = @splat(.unset),

    usb: struct {
        @"d+": Net_ID = .unset,
        @"d-": Net_ID = .unset,
    } = .{},

    qspi: struct {
        n_cs: Net_ID = .unset,
        data: [4]Net_ID = @splat(.unset),
        clk: Net_ID = .unset,
    } = .{},

    xtal: struct {
        in: Net_ID = .unset,
        out: Net_ID = .unset,
    } = .{},

    swd: struct {
        clk: Net_ID = .unset,
        io: Net_ID = .unset,
    } = .{},

    n_reset: Net_ID = .unset, // "RUN"
    test_en: Net_ID = .gnd,

    pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
        return switch (@backingInt(pin_id)) {
            0 => self.pwr_io.gnd[0],
            1 => self.pwr_io.vcc(0),
            2 => self.gpio[0],
            3 => self.gpio[1],
            4 => self.gpio[2],
            5 => self.gpio[3],
            6 => self.gpio[4],
            7 => self.gpio[5],
            8 => self.gpio[6],
            9 => self.gpio[7],
            10 => self.pwr_io.vcc(1),
            11 => self.gpio[8],
            12 => self.gpio[9],
            13 => self.gpio[10],
            14 => self.gpio[11],
            15 => self.gpio[12],
            16 => self.gpio[13],
            17 => self.gpio[14],
            18 => self.gpio[15],
            19 => self.test_en,
            20 => self.xtal.in,
            21 => self.xtal.out,
            22 => self.pwr_io.vcc(2),
            23 => self.pwr_int.vcc(0),
            24 => self.swd.clk,
            25 => self.swd.io,
            26 => self.n_reset,
            27 => self.gpio[16],
            28 => self.gpio[17],
            29 => self.gpio[18],
            30 => self.gpio[19],
            31 => self.gpio[20],
            32 => self.gpio[21],
            33 => self.pwr_io.vcc(3),
            34 => self.gpio[22],
            35 => self.gpio[23],
            36 => self.gpio[24],
            37 => self.gpio[25],
            38 => self.gpio[26], // ADC0
            39 => self.gpio[27], // ADC1
            40 => self.gpio[28], // ADC2
            41 => self.gpio[29], // ADC3
            42 => self.pwr_io.vcc(4),
            43 => self.pwr_adc.vcc(0),
            44 => self.pwr_vreg_in.vcc(0),
            45 => self.pwr_vreg_out.vcc(0),
            46 => self.usb.@"d-",
            47 => self.usb.@"d+",
            48 => self.pwr_usb.vcc(0),
            49 => self.pwr_io.vcc(5),
            50 => self.pwr_int.vcc(1),
            51 => self.qspi.data[3],
            52 => self.qspi.clk,
            53 => self.qspi.data[0],
            54 => self.qspi.data[2],
            55 => self.qspi.data[1],
            56 => self.qspi.n_cs,
            else => std.debug.panic("RP2040 does not have pin {}", .{@backingInt(pin_id)}),
        };
    }

    pub fn check_config(self: *@This(), b: *Board) !void {
        for (&self.pwr_io.v) |*net| {
            if (net.* == .unset) net.* = .p3v3;
        }
        if (self.pwr_adc.v == .unset) {
            self.pwr_adc.v = self.pwr_io.v[4];
        }
        if (self.pwr_vreg_in.v == .unset) {
            self.pwr_vreg_in.v = b.unique_net("vreg_in");
            _ = b.part(parts.C0402_Decoupler_1uf, b.fmt("{s} Vreg input cap", .{self.base.name}), .{
                .gnd = .gnd,
                .internal = self.pwr_vreg_in.v,
                .external = self.pwr_io.v[4],
            });
        }
        if (self.pwr_vreg_out.v == .unset and self.pwr_int.v[0] == .unset and self.pwr_int.v[1] == .unset) {
            const p1v1 = b.unique_net("p1v1");

            self.pwr_vreg_out.v = b.unique_net("vreg_out");
            _ = b.part(parts.C0402_Decoupler_1uf, b.fmt("{s} Vreg output cap", .{self.base.name}), .{
                .gnd = .gnd,
                .internal = self.pwr_vreg_out.v,
                .external = p1v1,
            });

            self.pwr_int.v[0] = b.unique_net("p1v1");
            _ = b.part(parts.C0402_Decoupler, b.fmt("{s} p1v1 decoupler #0", .{self.base.name}), .{
                .gnd = .gnd,
                .internal = self.pwr_int.v[0],
                .external = p1v1,
            });

            self.pwr_int.v[1] = b.unique_net("p1v1");
            _ = b.part(parts.C0402_Decoupler, b.fmt("{s} p1v1 decoupler #1", .{self.base.name}), .{
                .gnd = .gnd,
                .internal = self.pwr_int.v[1],
                .external = p1v1,
            });

            self.pwr_vreg_out.gnd = .gnd;
            self.pwr_int.gnd[0] = .gnd;
        }
    }

    // TODO check voltages in valid range during validation
};

/// Raspberry Pi dual core ARM Cortex M33 / RISC-V Hazard3
/// https://pip-assets.raspberrypi.com/categories/1214-rp2350/documents/RP-008373-DS-2-rp2350-datasheet.pdf
/// https://pip-assets.raspberrypi.com/categories/1214-rp2350/documents/RP-008280-DS-1-hardware-design-with-rp2350.pdf
pub fn RP235xA(comptime device_name: []const u8, comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.QFN_60_7x7_EP.pkg,
            .prefix = .U,
            .value = device_name,
        },

        pwr_io: power.Multi(6, 1, .unset, Decoupler) = .{}, // 1.8V - 3.3V
        pwr_qspi: power.Single(.unset, Decoupler) = .{},
        pwr_int: power.Multi(3, 1, .unset, Decoupler) = .{}, // 1.1V
        pwr_adc: power.Single(.unset, Decoupler) = .{},
        pwr_usb_otp: power.Single_3V3(Decoupler) = .{},

        vreg: struct {
            vdd: Net_ID = .unset, // tie to v_in through a low pass RC filter
            v_in: Net_ID = .unset,
            fb: Net_ID = .unset,
            lx: Net_ID = .unset,
            gnd: Net_ID = .gnd,
        } = .{},

        gpio: [30]Net_ID = @splat(.unset),

        usb: struct {
            @"d+": Net_ID = .unset,
            @"d-": Net_ID = .unset,
        } = .{},

        qspi: struct {
            n_cs: Net_ID = .unset,
            data: [4]Net_ID = .unset,
            clk: Net_ID = .unset,
        } = .{},

        xtal: struct {
            in: Net_ID = .unset,
            out: Net_ID = .unset,
        } = .{},

        swd: struct {
            clk: Net_ID = .unset,
            io: Net_ID = .unset,
        } = .{},

        n_reset: Net_ID = .unset, // "RUN"

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@backingInt(pin_id)) {
                0 => self.pwr_io.gnd[0],
                1 => self.pwr_io.vcc(0),
                2 => self.gpio[0],
                3 => self.gpio[1],
                4 => self.gpio[2],
                5 => self.gpio[3],
                6 => self.pwr_int.vcc(0),
                7 => self.gpio[4],
                8 => self.gpio[5],
                9 => self.gpio[6],
                10 => self.gpio[7],
                11 => self.pwr_io.vcc(1),
                12 => self.gpio[8],
                13 => self.gpio[9],
                14 => self.gpio[10],
                15 => self.gpio[11],
                16 => self.gpio[12],
                17 => self.gpio[13],
                18 => self.gpio[14],
                19 => self.gpio[15],
                20 => self.pwr_io.vcc(2),
                21 => self.xtal.in,
                22 => self.xtal.out,
                23 => self.pwr_int.vcc(1),
                24 => self.swd.clk,
                25 => self.swd.io,
                26 => self.n_reset,
                27 => self.gpio[16],
                28 => self.gpio[17],
                29 => self.gpio[18],
                30 => self.pwr_io.vcc(3),
                31 => self.gpio[19],
                32 => self.gpio[20],
                33 => self.gpio[21],
                34 => self.gpio[22],
                35 => self.gpio[23],
                36 => self.gpio[24],
                37 => self.gpio[25],
                38 => self.pwr_io.vcc(4),
                39 => self.pwr_int.vcc(2),
                40 => self.gpio[26], // ADC0
                41 => self.gpio[27], // ADC1
                42 => self.gpio[28], // ADC2
                43 => self.gpio[29], // ADC3
                44 => self.pwr_adc.vcc(0),
                45 => self.pwr_io.vcc(5),
                46 => self.vreg.vdd,
                47 => self.vreg.gnd,
                48 => self.vreg.lx,
                49 => self.vreg.vin,
                50 => self.vreg.fb,
                51 => self.usb.@"d-",
                52 => self.usb.@"d+",
                53 => self.pwr_usb_otp.vcc(0),
                54 => self.pwr_qspi.vcc(0),
                55 => self.qspi.data[3],
                56 => self.qspi.clk,
                57 => self.qspi.data[0],
                58 => self.qspi.data[2],
                59 => self.qspi.data[1],
                60 => self.qspi.n_cs,
                else => std.debug.panic("RP2350A does not have pin {}", .{@backingInt(pin_id)}),
            };
        }

        pub fn check_config(self: @This()) !void {
            for (&self.pwr_io.v) |*net| {
                if (net.* == .unset) net.* = .p3v3;
            }
            if (self.pwr_adc.v == .unset) {
                self.pwr_adc.v = self.pwr_io.v[4];
            }
            if (self.pwr_qspi.v == .unset) {
                self.pwr_qspi.v = self.pwr_io.v[0];
            }
            for (&self.pwr_int.v) |*net| {
                if (net.* == .unset) net.* = .p1v1;
            }
        }

        // TODO check voltages in valid range during validation
    };
}
pub fn RP235xB(comptime device_name: []const u8, comptime Decoupler: type) type {
    return struct {
        base: Part.Base = .{
            .package = &pkg.QFN_80_10x10_EP.pkg,
            .prefix = .U,
            .value = device_name,
        },

        pwr_io: power.Multi(8, 1, .unset, Decoupler) = .{}, // 1.8V - 3.3V
        pwr_qspi: power.Single(.unset, Decoupler) = .{},
        pwr_int: power.Multi(3, 1, .unset, Decoupler) = .{}, // 1.1V
        pwr_adc: power.Single(.unset, Decoupler) = .{},
        pwr_usb_otp: power.Single_3V3(Decoupler) = .{},

        vreg: struct {
            vdd: Net_ID = .unset, // tie to v_in through a low pass RC filter
            v_in: Net_ID = .unset,
            fb: Net_ID = .unset,
            lx: Net_ID = .unset,
            gnd: Net_ID = .gnd,
        } = .{},

        gpio: [48]Net_ID = @splat(.unset),

        usb: struct {
            @"d+": Net_ID = .unset,
            @"d-": Net_ID = .unset,
        } = .{},

        qspi: struct {
            n_cs: Net_ID = .unset,
            data: [4]Net_ID = .unset,
            clk: Net_ID = .unset,
        } = .{},

        xtal: struct {
            in: Net_ID = .unset,
            out: Net_ID = .unset,
        } = .{},

        swd: struct {
            clk: Net_ID = .unset,
            io: Net_ID = .unset,
        } = .{},

        n_reset: Net_ID = .unset, // "RUN"

        pub fn pin(self: @This(), pin_id: Pin_ID) Net_ID {
            return switch (@backingInt(pin_id)) {
                0 => self.pwr_io.gnd[0],
                1 => self.gpio[4],
                2 => self.gpio[5],
                3 => self.gpio[6],
                4 => self.gpio[7],
                5 => self.pwr_io.vcc(1),
                6 => self.gpio[8],
                7 => self.gpio[9],
                8 => self.gpio[10],
                9 => self.gpio[11],
                10 => self.pwr_int.vcc(0),
                11 => self.gpio[12],
                12 => self.gpio[13],
                13 => self.gpio[14],
                14 => self.gpio[15],
                15 => self.pwr_io.vcc(2),
                16 => self.gpio[16],
                17 => self.gpio[17],
                18 => self.gpio[18],
                19 => self.gpio[19],
                20 => self.gpio[20],
                21 => self.gpio[21],
                22 => self.gpio[22],
                23 => self.gpio[23],
                24 => self.pwr_io.vcc(3),
                25 => self.gpio[24],
                26 => self.gpio[25],
                27 => self.gpio[26],
                28 => self.gpio[27],
                29 => self.pwr_io.vcc(4),
                30 => self.xtal.in,
                31 => self.xtal.out,
                32 => self.pwr_int.vcc(1),
                33 => self.swd.clk,
                34 => self.swd.io,
                35 => self.n_reset,
                36 => self.gpio[28],
                37 => self.gpio[29],
                38 => self.gpio[30],
                39 => self.gpio[31],
                40 => self.gpio[32],
                41 => self.pwr_io.vcc(5),
                42 => self.gpio[33],
                43 => self.gpio[34],
                44 => self.gpio[35],
                45 => self.gpio[36],
                46 => self.gpio[37],
                47 => self.gpio[38],
                48 => self.gpio[39],
                49 => self.gpio[40], // ADC0
                50 => self.pwr_io.vcc(6),
                51 => self.pwr_int.vcc(2),
                52 => self.gpio[41], // ADC1
                53 => self.gpio[42], // ADC2
                54 => self.gpio[43], // ADC3
                55 => self.gpio[44], // ADC4
                56 => self.gpio[45], // ADC5
                57 => self.gpio[46], // ADC6
                58 => self.gpio[47], // ADC7
                59 => self.pwr_adc.vcc(0),
                60 => self.pwr_io.vcc(7),
                61 => self.vreg.vdd,
                62 => self.vreg.gnd,
                63 => self.vreg.lx,
                64 => self.vreg.vin,
                65 => self.vreg.fb,
                66 => self.usb.@"d-",
                67 => self.usb.@"d+",
                68 => self.pwr_usb_otp.vcc(0),
                69 => self.pwr_qspi.vcc(0),
                70 => self.qspi.data[3],
                71 => self.qspi.clk,
                72 => self.qspi.data[0],
                73 => self.qspi.data[2],
                74 => self.qspi.data[1],
                75 => self.qspi.n_cs,
                76 => self.pwr_io.vcc(0),
                77 => self.gpio[0],
                78 => self.gpio[1],
                79 => self.gpio[2],
                80 => self.gpio[3],
                else => std.debug.panic("RP2350B does not have pin {}", .{@backingInt(pin_id)}),
            };
        }

        pub fn check_config(self: @This()) !void {
            for (&self.pwr_io.v) |*net| {
                if (net.* == .unset) net.* = .p3v3;
            }
            if (self.pwr_adc.v == .unset) {
                self.pwr_adc.v = self.pwr_io.v[4];
            }
            if (self.pwr_qspi.v == .unset) {
                self.pwr_qspi.v = self.pwr_io.v[0];
            }
            for (&self.pwr_int.v) |*net| {
                if (net.* == .unset) net.* = .p1v1;
            }
        }

        // TODO check voltages in valid range during validation
    };
}

const Pin_ID = enums.Pin_ID;
const Net_ID = enums.Net_ID;
const Board = @import("../Board.zig");
const Part = @import("../Part.zig");
const power = @import("../power.zig");
const enums = @import("../enums.zig");
const pkg = @import("../packages.zig");
const parts = @import("../parts.zig");
const std = @import("std");
