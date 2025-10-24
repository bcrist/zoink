pub fn configure(b: *Board) !void {
    const U1 = b.part(IDT7216);
    U1.x = b.bus("X", 16);
    U1.y = b.bus("Y", 16);
    U1.p = b.bus("P", 16);
    U1.xm = b.net("XM");
    U1.ym = b.net("YM");
    U1.ft = b.net("FT");
    U1.fa = b.net("FA");
    U1.rnd = b.net("RND");
    U1.n_oe_y = b.net("~OEY");
    U1.n_oe_p = b.net("~OEP");
    U1.lsp_sel = b.net("LSP_SEL");
    U1.clk_x = b.net("CLK_X");
    U1.clk_y = b.net("CLK_Y");
    U1.clk_msp = b.net("CLK_MSP");
    U1.clk_lsp = b.net("CLK_LSP");
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

    var rng: std.Random.Xoshiro256 = .init(std.testing.random_seed);
    var rnd = rng.random();

    const X = b.get_bus("X");
    const Y = b.get_bus("Y");
    // const P = b.get_bus("P");
    const XM = b.net("XM");
    const YM = b.net("YM");
    const FT = b.net("FT");
    const FA = b.net("FA");
    const RND = b.net("RND");
    const nOEY = b.net("~OEY");
    const nOEP = b.net("~OEP");
    const LSP_SEL = b.net("LSP_SEL");
    const CLK_X = b.net("CLK_X");
    const CLK_Y = b.net("CLK_Y");
    const CLK_MSP = b.net("CLK_MSP");
    const CLK_LSP = b.net("CLK_LSP");

    try v.reset();

    try v.set_bus(X, 0, TTL);
    try v.set_bus(Y, 0, TTL);
    try v.set(XM, .gnd);
    try v.set(YM, .gnd);
    try v.set(FT, .p5v);
    try v.set(FA, .p5v);
    try v.set(RND, .gnd);
    try v.set(nOEY, .p5v);
    try v.set(nOEP, .gnd);
    try v.set(LSP_SEL, .p5v);
    try v.set(CLK_X, .gnd);
    try v.set(CLK_Y, .gnd);
    try v.set(CLK_LSP, .gnd);
    try v.set(CLK_MSP, .gnd);
    try v.update();

    try clk_x(&v, &b, 4, .unsigned);
    try clk_y(&v, &b, 4, .unsigned);
    try expect_product(&v, &b, 16);

    try clk_x(&v, &b, 3, .unsigned);
    try clk_y(&v, &b, 7, .unsigned);
    try expect_product(&v, &b, 21);

    for (0..1_000) |_| {
        const x: u16 = rnd.int(u16);
        const y: u16 = rnd.int(u16);
        try clk_x(&v, &b, x, .unsigned);
        try clk_y(&v, &b, y, .unsigned);
        try expect_product(&v, &b, @as(u32, x) * y);
    }

    try clk_x(&v, &b, 1234, .unsigned);
    try clk_y(&v, &b, 4567, .unsigned);
    try expect_product(&v, &b, 0x55_FE5E);

    try v.clock_low(CLK_LSP, TTL);
    try v.clock_low(CLK_MSP, TTL);
    try v.clock_high(CLK_LSP, TTL);
    try v.clock_high(CLK_MSP, TTL);
    try expect_product(&v, &b, 0x55_FE5E);

    try v.set_low(FT, TTL);
    try expect_product(&v, &b, 0x55_FE5E);

    try clk_x(&v, &b, 222, .unsigned);
    try clk_y(&v, &b, 2, .unsigned);

    try expect_product(&v, &b, 0x55_FE5E);

    try v.clock_low(CLK_MSP, TTL);
    try v.clock_high(CLK_MSP, TTL);

    try expect_product(&v, &b, 0xFE5E);

    try v.clock_low(CLK_LSP, TTL);
    try v.clock_high(CLK_LSP, TTL);

    try expect_product(&v, &b, 444);
}

fn clk_x(v: *zoink.Validator, b: *zoink.Board, x: u16, xm: IDT7216.Input_Format) !void {
    const clk = b.net("CLK_X");
    try v.clock_low(clk, TTL);
    try v.set_bus(b.get_bus("X"), x, TTL);
    try v.set_logic(b.net("XM"), @intFromEnum(xm) != 0, TTL);
    try v.clock_high(clk, TTL);
}

fn clk_y(v: *zoink.Validator, b: *zoink.Board, y: u16, ym: IDT7216.Input_Format) !void {
    const clk = b.net("CLK_Y");
    try v.clock_low(clk, TTL);
    try v.set_bus(b.get_bus("Y"), y, TTL);
    try v.set_logic(b.net("YM"), @intFromEnum(ym) != 0, TTL);
    try v.clock_high(clk, TTL);
}

fn expect_product(v: *zoink.Validator, b: *zoink.Board, expected: i64) !void {
    errdefer log.err("expected product: {d}", .{ expected });

    const unsigned: u64 = @bitCast(expected);
    const expected_lsp: u16 = @truncate(unsigned);
    const expected_msp: u16 = @truncate(unsigned >> 16);

    const LSP_SEL = b.net("LSP_SEL");
    const P = b.get_bus("P");

    try v.set_high(LSP_SEL, TTL);
    try v.update();
    try v.expect_state(P, expected_lsp, TTL);

    try v.set_low(LSP_SEL, TTL);
    try v.update();
    try v.expect_state(P, expected_msp, TTL);
}

const IDT7216 = zoink.parts.IDT7216L_C;

const log = std.log.scoped(.zoink);

const TTL = zoink.Voltage.TTL;
const Board = zoink.Board;
const zoink = @import("zoink");
const bits = @import("bits");
const std = @import("std");