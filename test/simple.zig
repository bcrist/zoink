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
    U3.chip_enable_low = .gnd;
    U3.lower_byte_enable_low = .gnd;
    U3.upper_byte_enable_low = .gnd;
    U3.write_enable_low = b.net("~WE");
    U3.output_enable_low = b.net("~OE");

}

test {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var b: zoink.Board = .{ .arena = arena.allocator(), .gpa = std.testing.allocator };
    defer b.deinit();
    try configure(&b);
    try b.finish_configuration(std.testing.allocator);
    var v = try zoink.Validator.init(&b);
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
    try v.expect_bus(Result, 3, LVCMOS_5VT);

    try v.set_bus(A, 3, LVCMOS_5VT);
    try v.set_bus(B, 4, LVCMOS_5VT);
    try v.set_bus(C, 4, LVCMOS_5VT);
    try v.set(WE, .p3v3);
    try v.set_bus_hiz(D);
    try v.update();
    try v.expect_bus(Result, 4, LVCMOS_5VT);
    try v.expect_bus(D, 0xBCDE, LVCMOS);
}

const SN74LVC08ADB = zoink.parts.SN74LVC08ADB;
const SN74LVC32ADB = zoink.parts.SN74LVC32ADB;
const GS71116U = zoink.parts.GS71116U;

const LVCMOS = zoink.Voltage.LVCMOS;
const LVCMOS_5VT = zoink.Voltage.LVCMOS_5VT;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
