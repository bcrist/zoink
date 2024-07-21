pub fn configure(b: *Board) !void {
    const U1 = b.part(AS7C1025_J);
    U1.addr = b.bus("A", 17);
    U1.data = b.bus("D", 8);
    U1.chip_enable_low = .gnd;
    U1.write_enable_low = b.net("~WE");
    U1.output_enable_low = b.net("~OE");
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

    const A = b.get_bus("A");
    const D = b.get_bus("D");
    const WE = b.get_net("~WE");
    const OE = b.get_net("~OE");

    try v.reset();

    try v.set_bus(A, 0x123, TTL);
    try v.set_bus(D, 0x6B, TTL);
    try v.set(WE, .gnd);
    try v.set(OE, .gnd);
    try v.update();

    try v.set_bus(A, 0x124, TTL);
    try v.set_bus(D, 0xFF, TTL);
    try v.update();

    try v.set_bus(A, 0x122, TTL);
    try v.set_bus_hiz(D);
    try v.set(WE, .p3v3);
    try v.update();
    try v.expect_bus(D, 0xAA, TTL);

    try v.set_bus(A, 0x123, TTL);
    try v.update();
    try v.expect_bus(D, 0x6B, TTL);

    try v.set_bus(A, 0x124, TTL);
    try v.update();
    try v.expect_bus(D, 0xFF, TTL);
}

const AS7C1025_J = zoink.parts.AS7C1025_J;

const TTL = zoink.Voltage.TTL;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
