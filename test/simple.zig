pub fn configure(b: *Board) !void {
    const A = b.bus("A", 4);
    const B = b.bus("B", 4);
    const C = b.bus("C", 4);
    const Temp = b.bus("Temp", 4);
    const Result = b.bus("Result", 4);

    const U1 = b.part(SN74LVC08ADB);
    U1.logic = .{ .bus = .{
        .a = A,
        .b = B,
        .y = Temp,
    }};

    const U2 = b.part(SN74LVC32ADB);
    U2.logic = .{ .bus = .{
        .a = C,
        .b = Temp,
        .y = Result,
    }};

    const U3 = b.part(GS71116U);
    U3.addr = b.bus("addr", 16);
    U3.lower_data = b.bus("D[0:7]", 8);
    U3.upper_data = b.bus("D[8:15]", 8);
    U3.n_ce = .gnd;
    U3.n_lower_byte_enable = .gnd;
    U3.n_upper_byte_enable = .gnd;
    U3.n_we = b.net("~WE");
    U3.n_oe = b.net("~OE");

    const R1 = b.part(zoink.parts.R0402);
    R1.a = .gnd;
    R1.b = b.net("N1");
    R1.value = 1000;

    const R2 = b.part(zoink.parts.R0402);
    R2.a = b.net("N1");
    R2.b = b.net("N2");
    R2.value = 1000;

    const R3 = b.part(zoink.parts.R0402);
    R3.a = b.net("N2");
    R3.b = b.net("N3");
    R3.value = 1000;

    const R4 = b.part(zoink.parts.R0402);
    R4.a = b.net("N3");
    R4.b = .p5v;
    R4.value = 1000;
}

test {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var b: zoink.Board = .{ .arena = arena.allocator(), .gpa = std.testing.allocator };
    defer b.deinit();
    try configure(&b);
    try b.finish_configuration(std.testing.allocator);
    var v = try zoink.Validator.init(std.testing.allocator, &b, .{});
    defer v.deinit();

    const A = b.get_bus("A");
    const B = b.get_bus("B");
    const C = b.get_bus("C");
    const Result = b.get_bus("Result");

    const addr = b.get_bus("addr");
    const D = b.bus("D", 16);
    const WE = b.get_net("~WE");
    const OE = b.get_net("~OE");

    try v.reset();
    try v.set_bus(A, 3, LVCMOS_5VT);
    try v.set_bus(B, 7, LVCMOS_5VT);
    try v.set_bus(C, 1, LVCMOS_5VT);
    try v.set_bus(addr, 0x123, LVCMOS);
    try v.set_bus(D, 0xBCDE, LVCMOS);
    try v.set(WE, .gnd);
    try v.set(OE, .gnd);
    try v.update();
    try v.expect_state(Result, 3, LVCMOS_5VT);

    try v.set_bus(A, 3, LVCMOS_5VT);
    try v.set_bus(B, 4, LVCMOS_5VT);
    try v.set_bus(C, 4, LVCMOS_5VT);
    try v.set(WE, .p3v3);
    try v.unset_bus(D);
    try v.update();
    try v.expect_state(Result, 4, LVCMOS_5VT);
    try v.expect_state(D, 0xBCDE, LVCMOS);

    try v.expect_approx(b.get_net("N2"), .from_float(2.5), 0.1);
    try v.expect_approx(b.get_net("N3"), .from_float(3.75), 0.1);
    try v.expect_approx(b.get_net("N1"), .from_float(1.25), 0.1);
}

const SN74LVC08ADB = zoink.parts.SN74LVC08ADB;
const SN74LVC32ADB = zoink.parts.SN74LVC32ADB;
const GS71116U = zoink.parts.GS71116U;

const LVCMOS = zoink.Voltage.LVCMOS;
const LVCMOS_5VT = zoink.Voltage.LVCMOS_5VT;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
