pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74LVTH16652DGG);
    U1.u[0].a = b.bus("A[0:7]", 8);
    U1.u[1].a = b.bus("A[8:15]", 8);

    U1.u[0].b = b.bus("B[0:7]", 8);
    U1.u[1].b = b.bus("B[8:15]", 8);

    U1.u[0].a_to_b.output_enable = b.net("OEAB");
    U1.u[1].a_to_b.output_enable = b.net("OEAB");
    U1.u[0].a_to_b.output_register = b.net("SAB");
    U1.u[1].a_to_b.output_register = b.net("SAB");
    U1.u[0].a_to_b.clk = b.net("CLKAB");
    U1.u[1].a_to_b.clk = b.net("CLKAB");

    U1.u[0].b_to_a.output_enable_low = b.net("~OEBA");
    U1.u[1].b_to_a.output_enable_low = b.net("~OEBA");
    U1.u[0].b_to_a.output_register = b.net("SBA");
    U1.u[1].b_to_a.output_register = b.net("SBA");
    U1.u[0].b_to_a.clk = b.net("CLKBA");
    U1.u[1].b_to_a.clk = b.net("CLKBA");
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
    const B = b.bus("B", 16);

    const AB_OE = b.net("OEAB");
    const AB_REG = b.net("SAB");
    const AB_CLK = b.net("CLKAB");

    const BA_OE = b.net("~OEBA");
    const BA_REG = b.net("SBA");
    const BA_CLK = b.net("CLKBA");

    try v.reset();

    try v.set_bus(A, 0xFACE, LVCMOS);
    try v.set(AB_OE, .p3v3);
    try v.set(BA_OE, .p3v3);
    try v.set(AB_REG, .gnd);
    try v.set(BA_REG, .p3v3);
    try v.set(AB_CLK, .gnd);
    try v.set(BA_CLK, .gnd);
    try v.update();
    try v.clock_high(AB_CLK, LVCMOS);
    try v.expect_bus(B, 0xFACE, LVCMOS);
    
    try v.set_bus_hiz(A);
    try v.set(BA_OE, .gnd);
    try v.set(AB_REG, .p3v3);
    try v.update();
    try v.expect_bus(A, 0xAAAA, LVCMOS);
    try v.expect_bus(B, 0xFACE, LVCMOS);
    try v.clock_high(BA_CLK, LVCMOS);
    try v.expect_bus(A, 0xFACE, LVCMOS);
}

const SN74LVTH16652DGG = zoink.parts.SN74LVTH16652DGG;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
