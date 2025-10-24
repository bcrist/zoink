pub fn configure(b: *Board) !void {
    const U1 = b.part(L4C381);
    U1.a = b.bus("A", 16);
    U1.b = b.bus("B", 16);
    U1.f = b.bus("F", 16);
    U1.operation = b.bus("OP", 3);
    U1.operand_select = b.bus("OS", 2);
    U1.carry_in = b.net("Cin");
    U1.carry_out = b.net("Cout");
    U1.n_carry_propagate = b.net("~P");
    U1.n_carry_generate = b.net("~G");
    U1.zero = b.net("Z");
    U1.overflow = b.net("V");
    U1.flowthrough_ab = b.net("FT_AB");
    U1.flowthrough_f = b.net("FT_F");
    U1.n_oe = b.net("~OE");
    U1.clk = b.net("CLK");
    U1.n_ce_a = b.net("~CEA");
    U1.n_ce_b = b.net("~CEB");
    U1.n_ce_f = b.net("~CEF");
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

    const A = b.get_bus("A");
    const B = b.get_bus("B");
    const F = b.get_bus("F");
    const OP = b.get_bus("OP");
    const OS = b.get_bus("OS");
    const Cin = b.net("Cin");
    const Cout = b.net("Cout");
    const nP = b.net("~P");
    const nG = b.net("~G");
    const V = b.net("V");
    const Z = b.net("Z");
    const FT_AB = b.net("FT_AB");
    const FT_F = b.net("FT_F");
    const nOE = b.net("~OE");
    const CLK = b.net("CLK");
    const nCEA = b.net("~CEA");
    const nCEB = b.net("~CEB");
    const nCEF = b.net("~CEF");

    try v.reset();

    try v.set_bus(A, 0, TTL);
    try v.set_bus(B, 0, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.zeroes), TTL);
    try v.set_bus(OS, @intFromEnum(L4C381.Operand_Select.a_b), TTL);
    try v.set(Cin, .gnd);
    try v.set(FT_AB, .p5v);
    try v.set(FT_F, .p5v);
    try v.set(nOE, .gnd);
    try v.set(CLK, .gnd);
    try v.set(nCEA, .p5v);
    try v.set(nCEB, .p5v);
    try v.set(nCEF, .p5v);
    try v.update();

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.zeroes), TTL);
    try v.update();
    try v.expect_state(F, 0, TTL);

    try v.set_bus(OP, @intFromEnum(L4C381.Operation.ones), TTL);
    try v.update();
    try v.expect_state(F, 0xFFFF, TTL);

    try v.set_bus(OP, @intFromEnum(L4C381.Operation.xor), TTL);
    try v.update();
    try v.expect_state(F, 0x5750, TTL);
    for (0..1_000) |_| {
        const aa: u16 = rnd.int(u16);
        const bb: u16 = rnd.int(u16);
        try v.set_bus(A, aa, TTL);
        try v.set_bus(B, bb, TTL);
        try v.update();
        try v.expect_state(F, aa ^ bb, TTL);
        try v.expect_state(Z, (aa ^ bb) == 0, TTL);
    }

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.@"or"), TTL);
    try v.update();
    try v.expect_state(F, 0x5774, TTL);
    for (0..1_000) |_| {
        const aa: u16 = rnd.int(u16);
        const bb: u16 = rnd.int(u16);
        try v.set_bus(A, aa, TTL);
        try v.set_bus(B, bb, TTL);
        try v.update();
        try v.expect_state(F, aa | bb, TTL);
        try v.expect_state(Z, (aa | bb) == 0, TTL);
    }

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.@"and"), TTL);
    try v.update();
    try v.expect_state(F, 0x0024, TTL);
    for (0..1_000) |_| {
        const aa: u16 = rnd.int(u16);
        const bb: u16 = rnd.int(u16);
        try v.set_bus(A, aa, TTL);
        try v.set_bus(B, bb, TTL);
        try v.update();
        try v.expect_state(F, aa & bb, TTL);
        try v.expect_state(Z, (aa & bb) == 0, TTL);
    }

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.add), TTL);
    try v.update();
    try v.expect_state(F, 0x1234 + 0x4564, TTL);
    for (0..1_000) |_| {
        const aa: u32 = rnd.int(u16);
        const bb: u32 = rnd.int(u16);
        const cin = rnd.boolean();
        try v.set_bus(A, aa, TTL);
        try v.set_bus(B, bb, TTL);
        try v.set_logic(Cin, cin, TTL);
        try v.update();
        const sum = aa + bb + @intFromBool(cin);
        try v.expect_state(F, sum & 0xFFFF, TTL);
        try v.expect_state(Z, (sum & 0xFFFF) == 0, TTL);

        const g = aa & bb;
        const p = aa | bb;

        var pp: [16]bool = undefined;
        var gg: [16]bool = undefined;
        var cc: [16]bool = undefined;
        pp[0] = (p & 1) != 0;
        gg[0] = (g & 1) != 0;
        cc[0] = cin;
        for (1..16) |bit| {
            const mask = @as(u16, 1) << @as(u4, @intCast(bit));
            pp[bit] = (p & mask) != 0 and pp[bit - 1];
            gg[bit] = (g & mask) != 0 or (p & mask) != 0 and gg[bit - 1];
            cc[bit] = gg[bit - 1] or pp[bit - 1] and cin;
        }

        const ng = !gg[15];
        const np = !pp[15];
        const c16 = gg[15] or pp[15] and cin;
        const ovf = cc[15] != c16;

        try v.expect_state(Cout, c16, TTL);
        try v.expect_state(nP, np, TTL);
        try v.expect_state(nG, ng, TTL);
        try v.expect_state(V, ovf, TTL);
    }

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set(Cin, .gnd);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.nadd), TTL);
    try v.update();
    try v.expect_state(F, (0xFFFF ^ 0x1234) + 0x4564, TTL);
    for (0..1_000) |_| {
        const aa: u32 = rnd.int(u16);
        const bb: u32 = rnd.int(u16);
        const cin = rnd.boolean();
        try v.set_bus(A, ~aa, TTL);
        try v.set_bus(B, bb, TTL);
        try v.set_logic(Cin, cin, TTL);
        try v.update();
        const sum = aa + bb + @intFromBool(cin);
        try v.expect_state(F, sum & 0xFFFF, TTL);
        try v.expect_state(Z, (sum & 0xFFFF) == 0, TTL);

        const g = aa & bb;
        const p = aa | bb;

        var pp: [16]bool = undefined;
        var gg: [16]bool = undefined;
        var cc: [16]bool = undefined;
        pp[0] = (p & 1) != 0;
        gg[0] = (g & 1) != 0;
        cc[0] = cin;
        for (1..16) |bit| {
            const mask = @as(u16, 1) << @as(u4, @intCast(bit));
            pp[bit] = (p & mask) != 0 and pp[bit - 1];
            gg[bit] = (g & mask) != 0 or (p & mask) != 0 and gg[bit - 1];
            cc[bit] = gg[bit - 1] or pp[bit - 1] and cin;
        }

        const ng = !gg[15];
        const np = !pp[15];
        const c16 = gg[15] or pp[15] and cin;
        const ovf = cc[15] != c16;

        try v.expect_state(Cout, c16, TTL);
        try v.expect_state(nP, np, TTL);
        try v.expect_state(nG, ng, TTL);
        try v.expect_state(V, ovf, TTL);
    }

    try v.set_bus(A, 0x1234, TTL);
    try v.set_bus(B, 0x4564, TTL);
    try v.set(Cin, .gnd);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.sub), TTL);
    try v.update();
    try v.expect_state(F, 0x1234 + (0xFFFF ^ 0x4564), TTL);
        for (0..1_000) |_| {
        const aa: u32 = rnd.int(u16);
        const bb: u32 = rnd.int(u16);
        const cin = rnd.boolean();
        try v.set_bus(A, aa, TTL);
        try v.set_bus(B, ~bb, TTL);
        try v.set_logic(Cin, cin, TTL);
        try v.update();
        const sum = aa + bb + @intFromBool(cin);
        try v.expect_state(F, sum & 0xFFFF, TTL);
        try v.expect_state(Z, (sum & 0xFFFF) == 0, TTL);

        const g = aa & bb;
        const p = aa | bb;

        var pp: [16]bool = undefined;
        var gg: [16]bool = undefined;
        var cc: [16]bool = undefined;
        pp[0] = (p & 1) != 0;
        gg[0] = (g & 1) != 0;
        cc[0] = cin;
        for (1..16) |bit| {
            const mask = @as(u16, 1) << @as(u4, @intCast(bit));
            pp[bit] = (p & mask) != 0 and pp[bit - 1];
            gg[bit] = (g & mask) != 0 or (p & mask) != 0 and gg[bit - 1];
            cc[bit] = gg[bit - 1] or pp[bit - 1] and cin;
        }

        const ng = !gg[15];
        const np = !pp[15];
        const c16 = gg[15] or pp[15] and cin;
        const ovf = cc[15] != c16;

        try v.expect_state(Cout, c16, TTL);
        try v.expect_state(nP, np, TTL);
        try v.expect_state(nG, ng, TTL);
        try v.expect_state(V, ovf, TTL);
    }

    try v.set(FT_AB, .gnd);
    try v.set(FT_F, .gnd);
    try v.set(nCEA, .gnd);
    try v.set(nCEB, .gnd);
    try v.set(nCEF, .gnd);

    try v.set_bus(A, 1234, TTL);
    try v.set_bus(B, 4567, TTL);
    try v.set(Cin, .gnd);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.ones), TTL);
    try v.clock_low(CLK, TTL);
    try v.clock_high(CLK, TTL);
    try v.expect_state(F, 0xFFFF, TTL);

    try v.set(nCEB, .p5v);
    try v.set(nCEF, .p5v);
    try v.set_bus(A, 1111, TTL);
    try v.set_bus(B, 2222, TTL);
    try v.set_bus(OP, @intFromEnum(L4C381.Operation.add), TTL);
    try v.clock_low(CLK, TTL);
    try v.clock_high(CLK, TTL);
    try v.expect_state(F, 0xFFFF, TTL);

    try v.set(nCEB, .gnd);
    try v.set(nCEF, .gnd);
    try v.clock_low(CLK, TTL);
    try v.clock_high(CLK, TTL);
    try v.expect_state(F, 1111 + 4567, TTL);

    try v.clock_low(CLK, TTL);
    try v.clock_high(CLK, TTL);
    try v.expect_state(F, 1111 + 2222, TTL);
}

const L4C381 = zoink.parts.L4C381;

const log = std.log.scoped(.zoink);

const TTL = zoink.Voltage.TTL;
const Board = zoink.Board;
const zoink = @import("zoink");
const bits = @import("bits");
const std = @import("std");