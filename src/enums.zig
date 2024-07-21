pub const Prefix = enum {
    C, // Capacitor
    R, // Resistor
    U, // IC, opto-iso, other
    D, // Diode
    Q, // Transistor, non-diode discrete semiconductor
    L, // Inductor, ferrite bead, delay line
    X, // Crystal
    J, // Jumper, jack connector
    P, // Test point, plug connector
    S, // Switch
    T, // Transformer
    K, // Relay, solenoid, speaker
    G, // Battery, generator
    F, // Fuse, non-diode protection devices
    M, // Motor, microphone
    V, // Vacuum tube, valve
};

pub const Net_ID = enum (u32) {
    unset = 0,
    no_connect = 0xFFFF_FFFF,
    gnd = 0xFFFF_FFFE,
    p1v = 0xFFFF_FFFD,
    p1v2 = 0xFFFF_FFFC,
    p1v5 = 0xFFFF_FFFB,
    p1v8 = 0xFFFF_FFFA,
    p2v5 = 0xFFFF_FFF9,
    p3v = 0xFFFF_FFF8,
    p3v3 = 0xFFFF_FFF7,
    p5v = 0xFFFF_FFF6,
    p6v = 0xFFFF_FFF5,
    p9v = 0xFFFF_FFF4,
    p12v = 0xFFFF_FFF3,
    p15v = 0xFFFF_FFF2,
    p19v = 0xFFFF_FFF1,
    p24v = 0xFFFF_FFF0,
    _,

    pub fn is_power(self: Net_ID) bool {
        return switch (self) {
            .gnd, .p1v, .p1v2, .p1v5, .p1v8,
            .p2v5, .p3v, .p3v3, .p5v, .p6v,
            .p9v, .p12v, .p15v, .p19v, .p24v,
            => true,

            .unset, .no_connect,
            => false,

            _ => false,
        };
    }
};

pub const Pin_ID = enum (u16) {
    heatsink = 0,
    _,
};

pub const Voltage = enum (u8) {
    gnd = 0,
    p1v = 20,
    p1v2 = 24,
    p1v5 = 30,
    p1v8 = 36,
    p2v5 = 50,
    p3v = 60,
    p3v3 = 66,
    p5v = 100,
    p6v = 120,
    p9v = 180,
    p12v = 240,
    saturated = 255,
    _,

    pub fn init(raw_int: u8) Voltage {
        return @enumFromInt(raw_int);
    }

    pub fn from_float(v: f32) Voltage {
        const raw_int: u8 = @intFromFloat(std.math.clamp(@round(v * 20), 0, 255));
        return @enumFromInt(raw_int);
    }

    pub fn as_float(self: Voltage) f32 {
        const raw_float: f32 = @floatFromInt(self.raw());
        return raw_float / 20.0;
    }

    pub fn raw(self: Voltage) u8 {
        return @intFromEnum(self);
    }

    pub fn format(self: Voltage, fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self == .saturated) {
            try writer.writeAll("OL V");
        } else {
            try writer.print("{d:.2} V", .{ self.as_float() });
        }
    }

    pub const TTL = struct {
        pub const Vil = from_float(0.7);
        pub const Vth = from_float(1.4);
        pub const Vih = from_float(2.2);
        pub const Vclamp = from_float(5.3);

        pub const Vol = from_float(0.4);
        pub const Voh = from_float(2.4);
    };

    pub const LVTTL = struct {
        pub const Vil = from_float(0.7);
        pub const Vth = from_float(1.4);
        pub const Vih = from_float(2.2);
        pub const Vclamp = from_float(3.6);

        pub const Vol = from_float(0.4);
        pub const Voh = from_float(2.4);
    };

    pub const LVCMOS18 = CMOS_V(.p1v8, .p1v8);
    pub const LVCMOS25 = CMOS_V(.p2v5, .p2v5);
    pub const LVCMOS = CMOS_V(.p3v3, .p3v3);

    pub const CMOS25 = CMOS_V(.p2v5, .p5v);
    pub const CMOS33 = CMOS_V(.p3v3, .p5v);
    pub const CMOS = CMOS_V(.p5v, .p5v);

    pub fn CMOS_V(vcc: Voltage, vclamp: Voltage) type {
        const vcc_float = vcc.as_float();
        return struct {
            pub const Vil = from_float(0.3 * vcc_float);
            pub const Vth = from_float(0.5 * vcc_float);
            pub const Vih = from_float(0.7 * vcc_float);
            pub const Vclamp = from_float(vclamp.as_float() + 0.3);

            pub const Vol = from_float(0.15 * vcc_float);
            pub const Voh = from_float(0.85 * vcc_float);
        };
    }
};

pub const Drive_Strength = enum (u8) {
    hiz = 0,
    weak = 1,
    strong = 128,
    contending = 255,
    _,

    pub fn init(raw_int: u8) Drive_Strength {
        return @enumFromInt(raw_int);
    }

    pub fn raw(self: Drive_Strength) u8 {
        return @intFromEnum(self);
    }

    pub fn format(self: Drive_Strength, fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .hiz => try writer.writeAll("Hi-Z"),
            .contending => try writer.writeAll("Contention"),
            else => try writer.print("{d}", .{ self.raw() }),
        }
    }
};

const std = @import("std");
