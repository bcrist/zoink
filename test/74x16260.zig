pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74ALVCH16260DGG);
    U1.a.data = b.bus("A", 12);
    U1.bx.data = b.bus("BX", 12);
    U1.by.data = b.bus("BY", 12);

    U1.a.output_enable_low = b.net("OE");
    U1.a.enable_bx = b.net("SEL");

    U1.bx.output_enable_low = .p3v3;
    U1.bx.latch_input_data = .p3v3;
    U1.bx.latch_output_data = .gnd;

    U1.by.output_enable_low = .p3v3;
    U1.by.latch_input_data = .p3v3;
    U1.by.latch_output_data = .gnd;
}

test {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var b: zoink.Board = .{ .arena = arena.allocator(), .gpa = std.testing.allocator };
    defer b.deinit();
    try configure(&b);
    try b.finish_configuration(std.testing.allocator);
    var v = try zoink.Validator.init(&b, .{});
    defer v.deinit();

    const A = b.get_bus("A");
    const BX = b.get_bus("BX");
    const BY = b.get_bus("BY");
    const SEL = b.get_net("SEL");
    const OE = b.get_net("OE");

    try v.reset();

    try v.set_bus(BX, 0x123, LVCMOS);
    try v.set_bus(BY, 0x777, LVCMOS);
    try v.set(SEL, .gnd);
    try v.set(OE, .gnd);
    try v.update();
    try v.expect_bus(A, 0x777, LVCMOS);

    try v.set(SEL, .p3v3);
    try v.update();
    try v.expect_bus(A, 0x123, LVCMOS);

    try v.set(OE, .p3v3);
    try v.set(SEL, .gnd);
    try v.update();
    try v.expect_bus(A, 0x123, LVCMOS); // bus hold keeps the last value even though OE is no longer asserted
}

const SN74ALVCH16260DGG = zoink.parts.SN74ALVCH16260DGG;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
