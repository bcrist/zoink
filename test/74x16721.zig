pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74ALVCH16721DGG);
    U1.d = b.bus("D", 20);
    U1.q = b.bus("Q", 20);

    U1.n_oe = b.net("~OE");
    U1.clk = b.net("CLK");
    U1.n_ce = b.net("~CE");
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

    const D = b.get_bus("D");
    const Q = b.get_bus("Q");
    const OE = b.get_net("~OE");
    const CLK = b.get_net("CLK");
    const CE = b.get_net("~CE");

    try v.reset();

    try v.set_bus(D, 0x12345, LVCMOS);
    try v.set(CE, .gnd);
    try v.set(OE, .gnd);
    try v.clock_low(CLK, LVCMOS);

    try v.clock_high(CLK, LVCMOS);
    try v.expect_state(Q, 0x12345, LVCMOS);

    try v.set_bus(D, 0xFFFFF, LVCMOS);
    try v.set(CE, .p3v3);
    try v.clock_low(CLK, LVCMOS);
    try v.expect_state(Q, 0x12345, LVCMOS);

    try v.clock_high(CLK, LVCMOS);
    try v.expect_state(Q, 0x12345, LVCMOS);

    try v.set(CE, .gnd);
    try v.clock_low(CLK, LVCMOS);
    try v.expect_state(Q, 0x12345, LVCMOS);

    try v.clock_high(CLK, LVCMOS);
    try v.expect_state(Q, 0xFFFFF, LVCMOS);
}

const SN74ALVCH16721DGG = zoink.parts.SN74ALVCH16721DGG;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
