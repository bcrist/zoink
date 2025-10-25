pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74LVC138);
    U1.sel = b.bus("SEL", 3);
    U1.y = b.bus("Y", 8);
    U1.enable = b.net("EN");
    U1.n_enable = b.bus("~EN", 2);
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

    const SEL = b.get_bus("SEL");
    const Y = b.get_bus("Y");
    const EN = b.net("EN");
    const nEN = b.get_bus("~EN");

    try v.reset();

    try v.set_bus(SEL, 0, LVCMOS);
    try v.set_high(EN, LVCMOS);
    try v.set_bus(nEN, 0, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11111110, LVCMOS);

    try v.set_bus(SEL, 1, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11111101, LVCMOS);

    try v.set_bus(SEL, 2, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11111011, LVCMOS);

    try v.set_bus(SEL, 3, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11110111, LVCMOS);

    try v.set_bus(SEL, 4, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11101111, LVCMOS);

    try v.set_bus(SEL, 5, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b11011111, LVCMOS);

    try v.set_bus(SEL, 6, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b10111111, LVCMOS);

    try v.set_bus(SEL, 7, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0b01111111, LVCMOS);

    try v.set_low(EN, LVCMOS);
    try v.update();
    try v.expect_state(Y, 0xFF, LVCMOS);

    try v.set_high(EN, LVCMOS);
    try v.set_bus(nEN, 0, LVCMOS);
    try v.set_high(nEN[0], LVCMOS);
    try v.update();
    try v.expect_state(Y, 0xFF, LVCMOS);

    try v.set_high(EN, LVCMOS);
    try v.set_bus(nEN, 0, LVCMOS);
    try v.set_high(nEN[1], LVCMOS);
    try v.update();
    try v.expect_state(Y, 0xFF, LVCMOS);
}

const SN74LVC138 = zoink.parts.SN74LVC138AD;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
