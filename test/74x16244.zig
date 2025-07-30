pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74ALVCH16244DGG);
    U1.u[0].a = b.bus("A[0:3]", 4);
    U1.u[1].a = b.bus("A[4:7]", 4);
    U1.u[2].a = b.bus("A[8:11]", 4);
    U1.u[3].a = b.bus("A[12:15]", 4);

    U1.u[0].y = b.bus("Y[0:3]", 4);
    U1.u[1].y = b.bus("Y[4:7]", 4);
    U1.u[2].y = b.bus("Y[8:11]", 4);
    U1.u[3].y = b.bus("Y[12:15]", 4);

    U1.u[0].output_enable_low = b.net("~OE[0]");
    U1.u[1].output_enable_low = b.net("~OE[1]");
    U1.u[2].output_enable_low = b.net("~OE[2]");
    U1.u[3].output_enable_low = b.net("~OE[3]");
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

    const A = b.bus("A", 16);
    const Y = b.bus("Y", 16);
    const OE = b.bus("~OE", 4);

    try v.reset();

    try v.set_bus(A, 0xFEDC, LVCMOS);
    try v.set_bus(OE, 0xF, LVCMOS);
    try v.update();
    try v.expect_hiz(Y);

    try v.set_bus(OE, 0x0, LVCMOS);
    try v.update();
    try v.expect_bus(Y, 0xFEDC, LVCMOS);

    try v.set_bus(A, 0x1234, LVCMOS);
    try v.update();
    try v.expect_bus(Y, 0x1234, LVCMOS);
}

const SN74ALVCH16244DGG = zoink.parts.SN74ALVCH16244DGG;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
