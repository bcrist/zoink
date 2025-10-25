pub fn configure(b: *Board) !void {
    const U1 = b.part(CY7C024V);
    U1.master = .p3v3;

    U1.left.addr = b.bus("LA", 12);
    U1.left.lower_data = b.bus("LD[0:7]", 8);
    U1.left.upper_data = b.bus("LD[8:15]", 8);
    U1.left.n_ce = .gnd;
    U1.left.n_lower_byte_enable = .gnd;
    U1.left.n_upper_byte_enable = .gnd;
    U1.left.n_semaphore_enable = .p3v3;
    U1.left.n_interrupt = .no_connect;
    U1.left.n_busy = .no_connect;
    U1.left.n_we = b.net("L~WE");
    U1.left.n_oe = b.net("L~OE");

    U1.right.addr = b.bus("RA", 12);
    U1.right.lower_data = b.bus("RD[0:7]", 8);
    U1.right.upper_data = b.bus("RD[8:15]", 8);
    U1.right.n_ce = .gnd;
    U1.right.n_lower_byte_enable = .gnd;
    U1.right.n_upper_byte_enable = .gnd;
    U1.right.n_semaphore_enable = .p3v3;
    U1.right.n_interrupt = .no_connect;
    U1.right.n_busy = .no_connect;
    U1.right.n_we = b.net("R~WE");
    U1.right.n_oe = b.net("R~OE");
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

    const LA = b.get_bus("LA");
    const LD = b.bus("LD", 16);
    const LWE = b.get_net("L~WE");
    const LOE = b.get_net("L~OE");

    const RA = b.get_bus("RA");
    const RD = b.bus("RD", 16);
    const RWE = b.get_net("R~WE");
    const ROE = b.get_net("R~OE");

    try v.reset();

    try v.set_bus(RA, 0x0, LVCMOS);
    try v.set_bus(RD, 0x0, LVCMOS);
    try v.set(RWE, .p3v3);
    try v.set(ROE, .p3v3);
    try v.set_bus(LA, 0x123, LVCMOS);
    try v.set_bus(LD, 0xBCDE, LVCMOS);
    try v.set(LWE, .gnd);
    try v.set(LOE, .gnd);
    try v.update();

    try v.set_bus(LA, 0xFF, LVCMOS);
    try v.set_bus(LD, 0x3333, LVCMOS);
    try v.update();

    try v.set_bus(LA, 0x0, LVCMOS);
    try v.set(LWE, .p3v3);
    try v.unset_bus(LD);
    try v.update();
    try v.expect_state(LD, 0xAAAA, LVCMOS);

    try v.set_bus(LA, 0xFF, LVCMOS);
    try v.update();
    try v.expect_state(LD, 0x3333, LVCMOS);

    try v.set_bus(LA, 0x123, LVCMOS);
    try v.update();
    try v.expect_state(LD, 0xBCDE, LVCMOS);
}

const CY7C024V = zoink.parts.CY7C024V;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
