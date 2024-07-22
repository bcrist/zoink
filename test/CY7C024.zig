pub fn configure(b: *Board) !void {
    const U1 = b.part(CY7C024V);
    U1.master = .p3v3;

    U1.left.addr = b.bus("LA", 12);
    U1.left.lower_data = b.bus("LD[0:7]", 8);
    U1.left.upper_data = b.bus("LD[8:15]", 8);
    U1.left.chip_enable_low = .gnd;
    U1.left.lower_byte_enable_low = .gnd;
    U1.left.upper_byte_enable_low = .gnd;
    U1.left.semaphore_enable_low = .p3v3;
    U1.left.interrupt_low = .no_connect;
    U1.left.busy_low = .no_connect;
    U1.left.write_enable_low = b.net("L~WE");
    U1.left.output_enable_low = b.net("L~OE");

    U1.right.addr = b.bus("RA", 12);
    U1.right.lower_data = b.bus("RD[0:7]", 8);
    U1.right.upper_data = b.bus("RD[8:15]", 8);
    U1.right.chip_enable_low = .gnd;
    U1.right.lower_byte_enable_low = .gnd;
    U1.right.upper_byte_enable_low = .gnd;
    U1.right.semaphore_enable_low = .p3v3;
    U1.right.interrupt_low = .no_connect;
    U1.right.busy_low = .no_connect;
    U1.right.write_enable_low = b.net("R~WE");
    U1.right.output_enable_low = b.net("R~OE");
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
    try v.set_bus_hiz(LD);
    try v.update();
    try v.expect_bus(LD, 0xAAAA, LVCMOS);

    try v.set_bus(LA, 0xFF, LVCMOS);
    try v.update();
    try v.expect_bus(LD, 0x3333, LVCMOS);

    try v.set_bus(LA, 0x123, LVCMOS);
    try v.update();
    try v.expect_bus(LD, 0xBCDE, LVCMOS);
}

const CY7C024V = zoink.parts.CY7C024V;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
