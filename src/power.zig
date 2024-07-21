pub fn Single(comptime v: Net_ID, comptime Maybe_Decoupler: ?type) type {
    return switch (v) {
        .p24v => Single_24V(Maybe_Decoupler),
        .p19v => Single_19V(Maybe_Decoupler),
        .p15v => Single_15V(Maybe_Decoupler),
        .p12v => Single_12V(Maybe_Decoupler),
        .p9v => Single_9V(Maybe_Decoupler),
        .p6v => Single_6V(Maybe_Decoupler),
        .p5v => Single_5V(Maybe_Decoupler),
        .p3v3 => Single_3V3(Maybe_Decoupler),
        .p3v => Single_3V(Maybe_Decoupler),
        .p2v5 => Single_2V5(Maybe_Decoupler),
        .p1v8 => Single_1V8(Maybe_Decoupler),
        .p1v5 => Single_1V5(Maybe_Decoupler),
        .p1v2 => Single_1V2(Maybe_Decoupler),
        .p1v => Single_1V(Maybe_Decoupler),
        else => @compileError(unreachable),
    };
}

pub fn Single_24V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p24v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p24v: Net_ID = .unset,
    };
}

pub fn Single_19V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p19v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p19v: Net_ID = .unset,
    };
}

pub fn Single_15V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p15v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p15v: Net_ID = .unset,
    };
}

pub fn Single_12V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p12v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p12v: Net_ID = .unset,
    };
}

pub fn Single_9V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p9v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p9v: Net_ID = .unset,
    };
}

pub fn Single_6V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p6v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p6v: Net_ID = .unset,
    };
}

pub fn Single_5V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p5v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p5v: Net_ID = .unset,
    };
}

pub fn Single_3V3(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p3v3: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p3v3: Net_ID = .unset,
    };
}

pub fn Single_3V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p3v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p3v: Net_ID = .unset,
    };
}

pub fn Single_2V5(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p2v5: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p2v5: Net_ID = .unset,
    };
}

pub fn Single_1V8(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p1v8: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p1v8: Net_ID = .unset,
    };
}

pub fn Single_1V5(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p1v5: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p1v5: Net_ID = .unset,
    };
}

pub fn Single_1V2(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p1v2: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p1v2: Net_ID = .unset,
    };
}

pub fn Single_1V(comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: Net_ID = .unset,
        p1v: Net_ID = .unset,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: Net_ID = .unset,
        p1v: Net_ID = .unset,
    };
}

pub fn Multi(comptime count: comptime_int, comptime v: Net_ID, comptime Maybe_Decoupler: ?type) type {
    return switch (v) {
        .p24v => Multi_24V(count, Maybe_Decoupler),
        .p19v => Multi_19V(count, Maybe_Decoupler),
        .p15v => Multi_15V(count, Maybe_Decoupler),
        .p12v => Multi_12V(count, Maybe_Decoupler),
        .p9v => Multi_9V(count, Maybe_Decoupler),
        .p6v => Multi_6V(count, Maybe_Decoupler),
        .p5v => Multi_5V(count, Maybe_Decoupler),
        .p3v3 => Multi_3V3(count, Maybe_Decoupler),
        .p3v => Multi_3V(count, Maybe_Decoupler),
        .p2v5 => Multi_2V5(count, Maybe_Decoupler),
        .p1v8 => Multi_1V8(count, Maybe_Decoupler),
        .p1v5 => Multi_1V5(count, Maybe_Decoupler),
        .p1v2 => Multi_1V2(count, Maybe_Decoupler),
        .p1v => Multi_1V(count, Maybe_Decoupler),
        else => @compileError(unreachable),
    };
}

pub fn Multi_24V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p24v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p24v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_19V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p19v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p19v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_15V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p15v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p15v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_12V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p12v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p12v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_9V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p9v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p9v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_6V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p6v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p6v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_5V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p5v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p5v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_3V3(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p3v3: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p3v3: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_3V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p3v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p3v: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_2V5(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p2v5: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p2v5: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_1V8(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v8: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v8: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_1V5(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v5: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v5: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_1V2(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v2: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v2: [count]Net_ID = .{ .unset } ** count,
    };
}

pub fn Multi_1V(comptime count: comptime_int, comptime Maybe_Decoupler: ?type) type {
    return if (Maybe_Decoupler) |Decoupler| struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v: [count]Net_ID = .{ .unset } ** count,
        pub const Decouple = Decoupler;
    } else struct {
        gnd: [count]Net_ID = .{ .unset } ** count,
        p1v: [count]Net_ID = .{ .unset } ** count,
    };
}

const Net_ID = enums.Net_ID;
const enums = @import("enums.zig");
