pub fn configure(b: *Board) !void {
    const U1 = b.part(SN74CBTLV16212G);
    U1.left[0] = b.bus("XA", 12);
    U1.left[1] = b.bus("XB", 12);
    U1.right[0] = b.bus("YA", 12);
    U1.right[1] = b.bus("YB", 12);
    U1.op_sel = b.bus("SEL", 3);
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

    const XA = b.get_bus("XA");
    const XB = b.get_bus("XB");
    const YA = b.get_bus("YA");
    const YB = b.get_bus("YB");
    const SEL = b.get_bus("SEL");

    try v.reset();

    try v.set_bus(XA, 0x1F3, LVCMOS);
    try v.set_bus(XB, 0xF0F, LVCMOS);
    try v.set_with_impedance(YA, .p1v5, 10_000);
    try v.set_with_impedance(YB, .p1v5, 10_000);
    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.disconnect), LVCMOS);
    try v.update();
    try v.expect_approx(YA, .p1v5, 0.1);
    try v.expect_approx(YB, .p1v5, 0.1);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.passthrough), LVCMOS);
    try v.update();
    try v.expect_state(YA, 0x1F3, LVCMOS);
    try v.expect_state(YB, 0xF0F, LVCMOS);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.exchange), LVCMOS);
    try v.update();
    try v.expect_state(YA, 0xF0F, LVCMOS);
    try v.expect_state(YB, 0x1F3, LVCMOS);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.l0_r1), LVCMOS);
    try v.update();
    try v.expect_approx(YA, .p1v5, 0.1);
    try v.expect_state(YB, 0x1F3, LVCMOS);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.l1_r1), LVCMOS);
    try v.update();
    try v.expect_approx(YA, .p1v5, 0.1);
    try v.expect_state(YB, 0xF0F, LVCMOS);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.l0_r0), LVCMOS);
    try v.update();
    try v.expect_state(YA, 0x1F3, LVCMOS);
    try v.expect_approx(YB, .p1v5, 0.1);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.l1_r0), LVCMOS);
    try v.update();
    try v.expect_state(YA, 0xF0F, LVCMOS);
    try v.expect_approx(YB, .p1v5, 0.1);

    try v.set_bus(SEL, @intFromEnum(SN74CBTLV16212G.Op.disconnect_alt), LVCMOS);
    try v.update();
    try v.expect_approx(YA, .p1v5, 0.1);
    try v.expect_approx(YB, .p1v5, 0.1);
}

const SN74CBTLV16212G = zoink.parts.SN74CBTLV16212G;

const LVCMOS = zoink.Voltage.LVCMOS;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
