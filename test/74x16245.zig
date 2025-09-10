pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74ALVCH16245DGG);
    U1.u[0].a = b.bus("A[0:7]", 8);
    U1.u[1].a = b.bus("A[8:15]", 8);

    U1.u[0].b = b.bus("B[0:7]", 8);
    U1.u[1].b = b.bus("B[8:15]", 8);

    U1.u[0].output_enable_low = b.net("~OE[0]");
    U1.u[1].output_enable_low = b.net("~OE[1]");
    U1.u[0].a_to_b = b.net("DIR[0]");
    U1.u[1].a_to_b = b.net("DIR[1]");
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

    const A = b.bus("A", 16);
    const B = b.bus("B", 16);
    const OE = b.bus("~OE", 2);
    const DIR = b.bus("DIR", 2);

    try v.reset();
    
    try v.set_with_impedance(B, .p1v5, 10_000);

    try v.set_bus(A, 0xFEDC, LVCMOS);
    try v.set_bus(OE, 0x3, LVCMOS);
    try v.set_bus(DIR, 0x3, LVCMOS);
    try v.update();
    try v.expect_approx(B, .p1v5, 0.25);

    try v.set_bus(OE, 0x0, LVCMOS);
    try v.update();
    try v.expect_state(B, 0xFEDC, LVCMOS);

    try v.set_with_impedance(A, .p1v5, 1_000);
    try v.set_bus(B, 0xFFFF, LVCMOS);
    try v.set_bus(DIR, 0x0, LVCMOS);
    try v.update();
    try v.expect_state(A, 0xFFFF, LVCMOS);

    try v.set_bus(OE, 0x3, LVCMOS);
    try v.update();
    try v.expect_approx(A, .p1v5, 0.25);
}

const SN74ALVCH16245DGG = zoink.parts.SN74ALVCH16245DGG;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
