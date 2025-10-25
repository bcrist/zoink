pub fn configure(b: *Board) !void {
    const U1 = b.part(GS71116U);
    U1.addr = b.bus("A", 16);
    U1.lower_data = b.bus("D[0:7]", 8);
    U1.upper_data = b.bus("D[8:15]", 8);
    U1.n_ce = .gnd;
    U1.n_lower_byte_enable = .gnd;
    U1.n_upper_byte_enable = .gnd;
    U1.n_we = b.net("~WE");
    U1.n_oe = b.net("~OE");
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
    const D = b.bus("D", 16);
    const WE = b.get_net("~WE");
    const OE = b.get_net("~OE");

    try v.reset();

    try v.set_bus(A, 0x123, LVCMOS);
    try v.set_bus(D, 0xBCDE, LVCMOS);
    try v.set(WE, .gnd);
    try v.set(OE, .gnd);
    try v.update();

    try v.set_bus(A, 0xFFF, LVCMOS);
    try v.set_bus(D, 0x3333, LVCMOS);
    try v.update();

    try v.set_bus(A, 0x0, LVCMOS);
    try v.set(WE, .p3v3);
    try v.unset_bus(D);
    try v.update();
    try v.expect_state(D, 0xAAAA, LVCMOS);

    try v.set_bus(A, 0xFFF, LVCMOS);
    try v.update();
    try v.expect_state(D, 0x3333, LVCMOS);

    try v.set_bus(A, 0x123, LVCMOS);
    try v.update();
    try v.expect_state(D, 0xBCDE, LVCMOS);
}

const GS71116U = zoink.parts.GS71116U;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
