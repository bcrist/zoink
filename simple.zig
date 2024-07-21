pub fn configure(b: *Board) !void {
    const A = b.bus("A", 4);
    const B = b.bus("B", 4);
    const C = b.bus("C", 4);
    const Temp = b.bus("Temp", 4);
    const Result = b.bus("Result", 4);

    const U1 = b.part(SN74LVC08ADB);
    U1.logic = .{ .bus = .{
        .a = A,
        .b = B,
        .y = Temp,
    }};

    const U2 = b.part(SN74LVC32ADB);
    U2.logic = .{ .bus = .{
        .a = C,
        .b = Temp,
        .y = Result,
    }};

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
    const B = b.get_bus("B");
    const C = b.get_bus("C");
    const Result = b.get_bus("Result");

    try v.reset();
    try v.set_bus(A, 3, CMOS33);
    try v.set_bus(B, 7, CMOS33);
    try v.set_bus(C, 1, CMOS33);
    try v.update();
    try v.expect_bus(Result, 3, CMOS33);

    try v.reset();
    try v.set_bus(A, 3, CMOS33);
    try v.set_bus(B, 4, CMOS33);
    try v.set_bus(C, 4, CMOS33);
    try v.update();
    try v.expect_bus(Result, 4, CMOS33);
}

const SN74LVC08ADB = zoink.parts.SN74LVC08ADB;
const SN74LVC32ADB = zoink.parts.SN74LVC32ADB;

const CMOS33 = zoink.Voltage.CMOS33;
const Board = zoink.Board;
const zoink = @import("zoink");
const std = @import("std");
