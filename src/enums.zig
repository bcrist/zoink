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

        // Voh is often only guaranteed to be 2.4V for TTL devices,
        // but using that might hide errors when a TTL signal is
        // fed into a (non-5V tolerant) LVTTL/LVCMOS input, so we're
        // using 3.8V instead:
        pub const Voh = from_float(3.8);
    };

    /// TTL with 3.3V Vcc and input clamping
    pub const LVTTL = struct {
        pub const Vil = from_float(0.7);
        pub const Vth = from_float(1.4);
        pub const Vih = from_float(2.2);
        pub const Vclamp = from_float(3.6);

        pub const Vol = from_float(0.4);
        pub const Voh = from_float(2.4);
    };
    
    /// LVTTL with 5V tolerant input clamping
    pub const LVTTL_5VT = struct {
        pub const Vil = from_float(0.7);
        pub const Vth = from_float(1.4);
        pub const Vih = from_float(2.2);
        pub const Vclamp = from_float(5.3);

        pub const Vol = from_float(0.4);
        pub const Voh = from_float(2.4);
    };

    pub const LVCMOS18 = CMOS_V(.p1v8, .p1v8);
    pub const LVCMOS18_3V3T = CMOS_V(.p1v8, .p3v3);

    pub const LVCMOS25 = CMOS_V(.p2v5, .p2v5);
    pub const LVCMOS25_3V3T = CMOS_V(.p2v5, .p3v3);
    pub const LVCMOS25_5VT = CMOS_V(.p2v5, .p5v);

    pub const LVCMOS = CMOS_V(.p3v3, .p3v3);
    pub const LVCMOS_5VT = CMOS_V(.p3v3, .p5v);
    
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

pub const Layer = enum (u8) {
    copper_front = 0,
    copper_internal_1 = 1,
    copper_internal_2 = 2,
    copper_internal_3 = 3,
    copper_internal_4 = 4,
    copper_internal_5 = 5,
    copper_internal_6 = 6,
    copper_internal_7 = 7,
    copper_internal_8 = 8,
    copper_internal_9 = 9,
    copper_internal_10 = 10,
    copper_internal_11 = 11,
    copper_internal_12 = 12,
    copper_internal_13 = 13,
    copper_internal_14 = 14,
    copper_internal_15 = 15,
    copper_internal_16 = 16,
    copper_internal_17 = 17,
    copper_internal_18 = 18,
    copper_internal_19 = 19,
    copper_internal_20 = 20,
    copper_internal_21 = 21,
    copper_internal_22 = 22,
    copper_internal_23 = 23,
    copper_internal_24 = 24,
    copper_internal_25 = 25,
    copper_internal_26 = 26,
    copper_internal_27 = 27,
    copper_internal_28 = 28,
    copper_internal_29 = 29,
    copper_internal_30 = 30,
    copper_back = 31,
    adhesive_back = 32,
    adhesive_front = 33,
    paste_back = 34, 
    paste_front = 35,
    silkscreen_back = 36,
    silkscreen_front = 37,
    soldermask_back = 38,
    soldermask_front = 39,
    user_drawings = 40,
    user_comments = 41,
    user_eco_1 = 42,
    user_eco_2 = 43,
    edges = 44,
    margins = 45,
    courtyard_back = 46,
    courtyard_front = 47,
    fab_back = 48,
    fab_front = 49,
    user_1 = 50,
    user_2 = 51,
    user_3 = 52,
    user_4 = 53,
    user_5 = 54,
    user_6 = 55,
    user_7 = 56,
    user_8 = 57,
    user_9 = 58,

    pub fn is_signal(self: Layer) bool {
        return @intFromEnum(self) <= @intFromEnum(Layer.copper_back);
    }

    const Kicad_Name_Options = struct {
        long_form: bool = false,
    };
    pub fn get_kicad_name(self: Layer, options: Kicad_Name_Options) []const u8 {
        switch (self) {
            .copper_front => "F.Cu",
            .copper_internal_1 => "In1.Cu",
            .copper_internal_2 => "In2.Cu",
            .copper_internal_3 => "In3.Cu",
            .copper_internal_4 => "In4.Cu",
            .copper_internal_5 => "In5.Cu",
            .copper_internal_6 => "In6.Cu",
            .copper_internal_7 => "In7.Cu",
            .copper_internal_8 => "In8.Cu",
            .copper_internal_9 => "In9.Cu",
            .copper_internal_10 => "In10.Cu",
            .copper_internal_11 => "In11.Cu",
            .copper_internal_12 => "In12.Cu",
            .copper_internal_13 => "In13.Cu",
            .copper_internal_14 => "In14.Cu",
            .copper_internal_15 => "In15.Cu",
            .copper_internal_16 => "In16.Cu",
            .copper_internal_17 => "In17.Cu",
            .copper_internal_18 => "In18.Cu",
            .copper_internal_19 => "In19.Cu",
            .copper_internal_20 => "In20.Cu",
            .copper_internal_21 => "In21.Cu",
            .copper_internal_22 => "In22.Cu",
            .copper_internal_23 => "In23.Cu",
            .copper_internal_24 => "In24.Cu",
            .copper_internal_25 => "In25.Cu",
            .copper_internal_26 => "In26.Cu",
            .copper_internal_27 => "In27.Cu",
            .copper_internal_28 => "In28.Cu",
            .copper_internal_29 => "In29.Cu",
            .copper_internal_30 => "In30.Cu",
            .copper_back => "B.Cu",
            .adhesive_back => if (options.long_form) "B.Adhesive" else "B.Adhes",
            .adhesive_front => if (options.long_form) "F.Adhesive" else "F.Adhes",
            .paste_back => "B.Paste",
            .paste_front => "F.Paste",
            .silkscreen_back => if (options.long_form) "B.Silkscreen" else "B.SilkS",
            .silkscreen_front => if (options.long_form) "F.Silkscreen" else "F.SilkS",
            .soldermask_back => "B.Mask",
            .soldermask_front => "F.Mask",
            .user_drawings => if (options.long_form) "User.Drawings" else "Dwgs.User",
            .user_comments => if (options.long_form) "User.Comments" else "Cmts.User",
            .user_eco_1 => if (options.long_form) "User.Eco1" else "Eco1.User",
            .user_eco_2 => if (options.long_form) "User.Eco2" else "Eco2.User",
            .edges => "Edge.Cuts",
            .margins => "Margin",
            .courtyard_back => if (options.long_form) "B.Courtyard" else "B.CrtYd",
            .courtyard_front => if (options.long_form) "F.Courtyard" else "F.CrtYd",
            .fab_back => "B.Fab",
            .fab_front => "F.Fab",
            .user_1 => "User.1",
            .user_2 => "User.2",
            .user_3 => "User.3",
            .user_4 => "User.4",
            .user_5 => "User.5",
            .user_6 => "User.6",
            .user_7 => "User.7",
            .user_8 => "User.8",
            .user_9 => "User.9",
        }
    }
};

const std = @import("std");
