pub fn Single(comptime v: Net_ID, comptime Decoupler: type) type {
    return switch (v) {
        .p24v => Single_24V(Decoupler),
        .p19v => Single_19V(Decoupler),
        .p15v => Single_15V(Decoupler),
        .p12v => Single_12V(Decoupler),
        .p9v => Single_9V(Decoupler),
        .p6v => Single_6V(Decoupler),
        .p5v => Single_5V(Decoupler),
        .p3v3 => Single_3V3(Decoupler),
        .p3v => Single_3V(Decoupler),
        .p2v5 => Single_2V5(Decoupler),
        .p1v8 => Single_1V8(Decoupler),
        .p1v5 => Single_1V5(Decoupler),
        .p1v2 => Single_1V2(Decoupler),
        .p1v => Single_1V(Decoupler),
        else => @compileError(unreachable),
    };
}

pub fn Single_24V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p24v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    };
}

pub fn Single_19V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p19v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    };
}

pub fn Single_15V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p15v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    };
}

pub fn Single_12V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p12v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p12v;
    };
}

pub fn Single_9V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p9v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p9v;
    };
}

pub fn Single_6V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p6v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p6v;
    };
}

pub fn Single_5V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p5v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p5v;
    };
}

pub fn Single_3V3(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p3v3: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p3v3;
    };
}

pub fn Single_3V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p3v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p3v;
    };
}

pub fn Single_2V5(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p2v5: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p2v5;
    };
}

pub fn Single_1V8(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p1v8: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v8;
    };
}

pub fn Single_1V5(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p1v5: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v5;
    };
}

pub fn Single_1V2(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p1v2: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v2;
    };
}

pub fn Single_1V(comptime Decoupler: type) type {
    return struct {
        gnd: Net_ID = .unset,
        p1v: Net_ID = .unset,
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v;
    };
}

pub fn Multi(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime v: Net_ID, comptime Decoupler: type) type {
    return switch (v) {
        .p24v => Multi_24V(vcc_count, gnd_count, Decoupler),
        .p19v => Multi_19V(vcc_count, gnd_count, Decoupler),
        .p15v => Multi_15V(vcc_count, gnd_count, Decoupler),
        .p12v => Multi_12V(vcc_count, gnd_count, Decoupler),
        .p9v => Multi_9V(vcc_count, gnd_count, Decoupler),
        .p6v => Multi_6V(vcc_count, gnd_count, Decoupler),
        .p5v => Multi_5V(vcc_count, gnd_count, Decoupler),
        .p3v3 => Multi_3V3(vcc_count, gnd_count, Decoupler),
        .p3v => Multi_3V(vcc_count, gnd_count, Decoupler),
        .p2v5 => Multi_2V5(vcc_count, gnd_count, Decoupler),
        .p1v8 => Multi_1V8(vcc_count, gnd_count, Decoupler),
        .p1v5 => Multi_1V5(vcc_count, gnd_count, Decoupler),
        .p1v2 => Multi_1V2(vcc_count, gnd_count, Decoupler),
        .p1v => Multi_1V(vcc_count, gnd_count, Decoupler),
        else => @compileError(unreachable),
    };
}

pub fn Multi_24V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p24v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
    };
}

pub fn Multi_19V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p19v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
    };
}

pub fn Multi_15V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p15v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
    };
}

pub fn Multi_12V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p12v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p12v;
    };
}

pub fn Multi_9V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p9v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p9v;
    };
}

pub fn Multi_6V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p6v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p6v;
    };
}

pub fn Multi_5V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p5v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p5v;
    };
}

pub fn Multi_3V3(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p3v3: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p3v3;
    };
}

pub fn Multi_3V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p3v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p3v;
    };
}

pub fn Multi_2V5(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p2v5: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p2v5;
    };
}

pub fn Multi_1V8(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p1v8: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v8;
    };
}

pub fn Multi_1V5(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p1v5: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v5;
    };
}

pub fn Multi_1V2(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p1v2: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v2;
    };
}

pub fn Multi_1V(comptime vcc_count: comptime_int, comptime gnd_count: comptime_int, comptime Decoupler: type) type {
    return struct {
        gnd: [gnd_count]Net_ID = @splat(.unset),
        p1v: [vcc_count]Net_ID = @splat(.unset),
        pub const Decouple = Decoupler;
        pub const V = Voltage.p1v;
    };
}

const Voltage = enums.Voltage;
const Net_ID = enums.Net_ID;
const enums = @import("enums.zig");
