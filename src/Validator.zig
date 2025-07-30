b: *const Board,
initial_nets: std.MultiArrayList(Net_State),
nets: std.MultiArrayList(Net_State),
net_v: []Voltage,
parts: std.MultiArrayList(Part_Validator),
part_state: std.ArrayListUnmanaged(u8),
max_iterations: usize,
hash_part_state: bool,

pub const Net_State = struct {
    v: Voltage = .gnd,
    s: Drive_Strength = .hiz,
};

pub const Part_Validator = struct {
    part: *const Part.Base,
    func: *const fn(part: *const Part.Base, validator: *Validator, state: *anyopaque, mode: Update_Mode) anyerror!void,
    state_offset: u32,
};

pub const Update_Mode = enum {
    reset, // reset internal part state
    nets_only, // nets are unstable; don't update any internal part state yet
    commit, // nets have stabilized; this is the last time the function will be called this cycle
};

const Validator = @This();

const Init_Options = struct {
    max_iterations: usize = 1000,
    hash_part_state: bool = true,
};

pub fn init(b: *const Board, options: Init_Options) !Validator {
    var initial_nets: std.MultiArrayList(Net_State) = .{};
    var nets: std.MultiArrayList(Net_State) = .{};
    errdefer initial_nets.deinit(std.testing.allocator);
    errdefer nets.deinit(std.testing.allocator);

    const num_nets = b.net_names.items.len;

    try initial_nets.ensureTotalCapacity(std.testing.allocator, num_nets);
    try nets.ensureTotalCapacity(std.testing.allocator, num_nets);

    initial_nets.len = num_nets;
    nets.len = num_nets;

    var parts: std.MultiArrayList(Part_Validator) = .{};
    errdefer parts.deinit(std.testing.allocator);
    try parts.ensureTotalCapacity(std.testing.allocator, b.parts.items.len);

    var part_state_needed: usize = 0;

    const board_parts = try std.testing.allocator.dupe(Part, b.parts.items);
    defer std.testing.allocator.free(board_parts);
    std.sort.pdq(Part, board_parts, {}, part_less_than);
    for (board_parts) |part| {
        if (part.vt.validate) |func| {
            const offset = std.mem.alignForward(usize, part_state_needed, part.vt.validator_state_align);
            part_state_needed = offset + part.vt.validator_state_bytes;
            
            parts.appendAssumeCapacity(.{
                .part = part.base,
                .func = func,
                .state_offset = @intCast(offset),
            });
        }
    }

    part_state_needed += 1;
    var part_state = try std.ArrayListUnmanaged(u8).initCapacity(std.testing.allocator, part_state_needed);
    errdefer part_state.deinit(std.testing.allocator);
    part_state.items.len = part_state_needed;

    return .{
        .b = b,
        .initial_nets = initial_nets,
        .nets = nets,
        .net_v = nets.items(.v),
        .parts = parts,
        .part_state = part_state,
        .max_iterations = options.max_iterations,
        .hash_part_state = options.hash_part_state,

    }; 
}

fn part_less_than(ctx: void, a: Part, b: Part) bool {
    _ = ctx;
    if (a.vt.validator_state_align != b.vt.validator_state_align) {
        // Parts with larger state probably also are more complicated to simulate, so
        // in addition to the obvious goal of reducing padding, putting them last
        // means that their inputs are more likely to be stable earlier, and we may
        // need fewer iterations overall.
        return a.vt.validator_state_align < b.vt.validator_state_align;
    }

    // Partitioning parts by their validation function should reduce icache misses
    const ap = if (a.vt.validate) |ptr| @intFromPtr(ptr) else 0;
    const bp = if (b.vt.validate) |ptr| @intFromPtr(ptr) else 0;
    return ap < bp;
}

pub fn deinit(self: *Validator) void {
    self.initial_nets.deinit(std.testing.allocator);
    self.nets.deinit(std.testing.allocator);
    self.parts.deinit(std.testing.allocator);
    self.part_state.deinit(std.testing.allocator);
}

pub fn reset(self: *Validator) !void {
    @memset(self.initial_nets.items(.v), .gnd);
    @memset(self.initial_nets.items(.s), .hiz);
    _ = try self.step(.reset);
}

pub fn set(self: *Validator, net: Net_ID, v: Voltage) !void {
    try self.set_adv(net, v, .strong);
}

pub fn set_logic(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    try self.set_adv(net, if (high) levels.Voh else levels.Vol, .strong);
}

pub fn set_bus(self: *Validator, bus: anytype, value: usize, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        try self.set_logic(net, (value & bit) != 0, levels);
        bit = @shlExact(bit, 1);
    }
}

pub fn set_bus_hiz(self: *Validator, bus: anytype) !void {
    for (bus) |net| try self.set_adv(net, .gnd, .hiz);
}

pub fn clock_high(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_adv(net, levels.Voh, .strong);
    try self.update();
    try self.update();
}

pub fn clock_low(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_adv(net, levels.Vol, .strong);
    try self.update();
    try self.update();
}

pub fn set_adv(self: *Validator, net: Net_ID, v: Voltage, s: Drive_Strength) !void {
    const idx = @intFromEnum(net);
    if (idx >= @intFromEnum(Net_ID.p24v)) return error.CantDrivePower;
    if (idx >= self.initial_nets.len) return error.InvalidNet;
    self.initial_nets.set(idx, .{ .v = v, .s = s });
}

pub fn drive_net(self: *Validator, net: Net_ID, v: Voltage, s: Drive_Strength) !void {
    if (net == .no_connect or net == .unset) return;
    const idx = @intFromEnum(net);
    if (idx >= @intFromEnum(Net_ID.p24v)) return error.CantDrivePower;
    if (idx >= self.nets.len) return error.InvalidNet;
    const old: Net_State = self.nets.get(idx);
    if (old.s == .contending) return;

    const old_v: usize = old.v.raw();
    const new_v: usize = v.raw();
    const raw_v: usize = old_v * old.s.raw() + new_v * s.raw();

    const raw_s = old.s.raw() +| s.raw();
    const combined_s = Drive_Strength.init(raw_s);

    if (combined_s == .contending) {
        log.err("Contention on net: {s}\n", .{ self.b.net_name(net) });
        return error.InvalidNetState;
    }

    const combined_v = Voltage.init(@intCast(std.math.clamp(raw_v / raw_s, 0, 255)));

    self.nets.set(idx, .{
        .v = combined_v,
        .s = combined_s,
    });
}

pub fn drive_logic(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    try self.drive_net(net, if (high) levels.Voh else levels.Vol, .strong);
}

pub fn drive_logic_weak(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    try self.drive_net(net, if (high) levels.Voh else levels.Vol, .weak);
}

pub fn drive_bus(self: *Validator, bus: anytype, value: usize, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        try self.drive_logic(net, (value & bit) != 0, levels);
        bit = @shlExact(bit, 1);
    }
}

pub fn drive_bus_weak(self: *Validator, bus: anytype, value: usize, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        try self.drive_logic_weak(net, (value & bit) != 0, levels);
        bit = @shlExact(bit, 1);
    }
}

pub fn read_net_strength(self: *const Validator, net: Net_ID) Drive_Strength {
    return switch (net) {
        .unset, .no_connect => Drive_Strength.hiz,
        .gnd, .p1v, .p1v2, .p1v5, .p1v8,
        .p2v5, .p3v, .p3v3, .p5v, .p6v,.p9v,
        .p12v, .p15v, .p19v, .p24v,
        => Drive_Strength.init(200),
        else => self.nets.items(.s)[@intFromEnum(net)],
    };
}

pub fn read_net(self: *const Validator, net: Net_ID) Voltage {
    return switch (net) {
        .unset, .no_connect, .gnd => .gnd,
        .p1v => .p1v,
        .p1v2 => .p1v2,
        .p1v5 => .p1v5,
        .p1v8 => .p1v8,
        .p2v5 => .p2v5,
        .p3v => .p3v,
        .p3v3 => .p3v3,
        .p5v => .p5v,
        .p6v => .p6v,
        .p9v => .p9v,
        .p12v => .p12v,
        .p15v => .saturated,
        .p19v => .saturated,
        .p24v => .saturated,
        else => self.net_v[@intFromEnum(net)],
    };
}

pub fn read_logic(self: *const Validator, net: Net_ID, comptime levels: type) bool {
    return self.read_net(net).raw() >= levels.Vth.raw();
}

pub fn read_bus(self: *const Validator, bus: anytype, comptime levels: type) usize {
    var bit: usize = 1;
    var result: usize = 0;
    for (bus) |net| {
        if (self.read_logic(net, levels)) result |= bit;
        bit = @shlExact(bit, 1);
    }
    return result;
}

pub fn read_bus_fallback(self: *const Validator, bus: anytype, comptime levels: type, fallback: usize) usize {
    var bit: usize = 1;
    var result: usize = 0;
    for (bus) |net| {
        if (self.read_net_strength(net) == .hiz) {
            if ((fallback & bit) != 0) result |= bit;
        } else if (self.read_logic(net, levels)) {
            result |= bit;
        }
        bit = @shlExact(bit, 1);
    }
    return result;
}

pub fn update(self: *Validator) !void {
    @memcpy(self.nets.items(.v), self.initial_nets.items(.v));
    @memcpy(self.nets.items(.s), self.initial_nets.items(.s));
    var hash = try self.step(.nets_only);
    for (1..self.max_iterations) |_| {
        @memcpy(self.nets.items(.s), self.initial_nets.items(.s));
        const new_hash = try self.step(.nets_only);
        if (new_hash == hash) {
            _ = try self.step(.commit);
            break;
        }
        hash = new_hash;
    } else return error.Unstable;
}

fn step(self: *Validator, mode: Update_Mode) !u64 {
    for (self.parts.items(.part), self.parts.items(.func), self.parts.items(.state_offset)) |part, func, offset| {
        try func(part, self, &self.part_state.items[offset], mode);
    }

    var hash = std.hash.Wyhash.init(0);

    if (self.hash_part_state) {
        hash.update(self.part_state.items);
    }

    for (self.nets.items(.v)) |v| {
        hash.update(std.mem.asBytes(&v));
    }

    for (self.nets.items(.s)) |s| {
        hash.update(std.mem.asBytes(&s));
    }

    return hash.final();
}

pub fn expect_hiz(self: *const Validator, what: anytype) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_hiz(what),
        else => try self.expect_bus_hiz(what),
    }
}

pub fn expect_not_hiz(self: *const Validator, what: anytype) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_not_hiz(what),
        else => try self.expect_bus_not_hiz(what),
    }
}

pub fn expect_strong(self: *const Validator, what: anytype) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_strong(what),
        else => try self.expect_bus_strong(what),
    }
}

pub fn expect_weak(self: *const Validator, what: anytype) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_weak(what),
        else => try self.expect_bus_weak(what),
    }
}

pub fn expect_above(self: *const Validator, what: anytype, v: Voltage) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_above(what, v),
        else => try self.expect_bus_above(what, v),
    }
}

pub fn expect_below(self: *const Validator, what: anytype, v: Voltage) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_below(what, v),
        else => try self.expect_bus_below(what, v),
    }
}

pub fn expect_approx(self: *const Validator, what: anytype, v: Voltage, epsilon: f32) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_approx(what, v, epsilon),
        else => try self.expect_bus_approx(what, v, epsilon),
    }
}

pub fn expect_high(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_high(what, levels),
        else => self.expect_bus_high(what, levels) catch {
            self.b.print_bus_name(what, std.io.getStdErr().writer()) catch {};
            log.info(" is {X}\n", .{ self.read_bus(what, levels) });
            return error.InvalidNetState;
        },
    }
}

pub fn expect_low(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_low(what, levels),
        else => self.expect_bus_low(what, levels) catch {
            self.b.print_bus_name(what, std.io.getStdErr().writer()) catch {};
            log.info(" is {X}\n", .{ self.read_bus(what, levels) });
            return error.InvalidNetState;
        },
    }
}

pub fn expect_valid(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_valid(what, levels),
        else => self.expect_bus_valid(what, levels) catch {
            self.b.print_bus_name(what, std.io.getStdErr().writer()) catch {};
            log.info(" is {X}\n", .{ self.read_bus(what, levels) });
            return error.InvalidNetState;
        },
    }
}

pub fn expect_valid_or_nc(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_valid_or_nc(what, levels),
        else => self.expect_bus_valid_or_nc(what, levels) catch {
            self.b.print_bus_name(what, std.io.getStdErr().writer()) catch {};
            log.info(" is {X}\n", .{ self.read_bus(what, levels) });
            return error.InvalidNetState;
        },
    }
}

pub fn expect_bus(self: *const Validator, bus: anytype, expected: usize, comptime levels: type) !void {
    self.expect_bus_state(bus, expected, levels) catch {
        log.err("Expected bus ", .{});
        self.b.print_bus_name(bus, std.io.getStdErr().writer()) catch {};
        log.info(" == {X}; found {X}\n", .{ expected, self.read_bus(bus, levels) });
        return error.InvalidNetState;
    };
}

fn expect_bus_state(self: *const Validator, bus: anytype, expected: usize, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        if (0 == (expected & bit)) {
            try self.expect_net_low(net, levels);
        } else {
            try self.expect_net_high(net, levels);
        }
        bit = @shlExact(bit, 1);
    }
}

fn expect_bus_hiz(self: *const Validator, bus: anytype) !void {
    for (bus) |net| {
        try self.expect_net_hiz(net);
    }
}

fn expect_bus_not_hiz(self: *const Validator, bus: anytype) !void {
    for (bus) |net| {
        try self.expect_net_not_hiz(net);
    }
}

fn expect_bus_strong(self: *const Validator, bus: anytype) !void {
    for (bus) |net| {
        try self.expect_net_strong(net);
    }
}

fn expect_bus_weak(self: *const Validator, bus: anytype) !void {
    for (bus) |net| {
        try self.expect_net_weak(net);
    }
}

fn expect_bus_above(self: *const Validator, bus: anytype, v: Voltage) !void {
    for (bus) |net| {
        try self.expect_net_above(net, v);
    }
}

fn expect_bus_below(self: *const Validator, bus: anytype, v: Voltage) !void {
    for (bus) |net| {
        try self.expect_net_below(net, v);
    }
}

fn expect_bus_approx(self: *const Validator, bus: anytype, v: Voltage, epsilon: f32) !void {
    for (bus) |net| {
        try self.expect_net_approx(net, v, epsilon);
    }
}

fn expect_bus_high(self: *const Validator, bus: anytype, comptime levels: type) !void {
    for (bus) |net| {
        try self.expect_net_high(net, levels);
    }
}

fn expect_bus_low(self: *const Validator, bus: anytype, comptime levels: type) !void {
    for (bus) |net| {
        try self.expect_net_low(net, levels);
    }
}

fn expect_bus_valid_or_nc(self: *const Validator, bus: anytype, comptime levels: type) !void {
    for (bus) |net| {
        try self.expect_net_valid_or_nc(net, levels);
    }
}

fn expect_bus_valid(self: *const Validator, bus: anytype, comptime levels: type) !void {
    for (bus) |net| {
        try self.expect_net_valid(net, levels);
    }
}

fn expect_net_hiz(self: *const Validator, net: Net_ID) !void {
    const s = self.read_net_strength(net);
    if (s != .hiz) {
        log.err("Expected {s} to be Hi-Z; found {} @ {}\n", .{ self.b.net_name(net), self.read_net(net), s });
        return error.InvalidNetState;
    }
}

fn expect_net_not_hiz(self: *const Validator, net: Net_ID) !void {
    const s = self.read_net_strength(net);
    if (s == .hiz) {
        log.err("Unexpected Hi-Z net: {s}\n", .{ self.b.net_name(net) });
        return error.InvalidNetState;
    }
    if (s == .contending) {
        log.err("Contention on net: {s}\n", .{ self.b.net_name(net) });
        return error.InvalidNetState;
    }
}

fn expect_net_strong(self: *const Validator, net: Net_ID) !void {
    const s = self.read_net_strength(net);
    if (s == .contending) {
        log.err("Contention on net: {s}\n", .{ self.b.net_name(net) });
        return error.InvalidNetState;
    }
    if (@intFromEnum(s) < @intFromEnum(Drive_Strength.strong)) {
        log.err("Expected {s} to be strongly driven; found {} @ {}\n", .{ self.b.net_name(net), self.read_net(net), s });
        return error.InvalidNetState;
    }
}

fn expect_net_weak(self: *const Validator, net: Net_ID) !void {
    const s = self.read_net_strength(net);
    if (s == .hiz or @intFromEnum(s) >= @intFromEnum(Drive_Strength.strong)) {
        log.err("Expected {s} to be weakly driven; found {} @ {}\n", .{ self.b.net_name(net), self.read_net(net), s });
        return error.InvalidNetState;
    }
}

fn expect_net_above(self: *const Validator, net: Net_ID, v: Voltage) !void {
    const found_v = self.read_net(net);
    if (found_v.raw() < v.raw()) {
        log.err("Expected {s} >= {}; found {} @ {}\n", .{ self.b.net_name(net), v, found_v, self.read_net_strength(net) });
        return error.InvalidNetState;
    }
}

fn expect_net_below(self: *const Validator, net: Net_ID, v: Voltage) !void {
    const found_v = self.read_net(net);
    if (found_v.raw() > v.raw()) {
        log.err("Expected {s} <= {}; found {} @ {}\n", .{ self.b.net_name(net), v, found_v, self.read_net_strength(net) });
        return error.InvalidNetState;
    }
}

fn expect_net_approx(self: *const Validator, net: Net_ID, v: Voltage, epsilon: f32) !void {
    const found_v = self.read_net(net);
    if (!std.math.approxEqAbs(f32, v.as_float(), found_v.as_float(), epsilon)) {
        log.err("Expected {s} ~= {} +/- {d}; found {} @ {}\n", .{ self.b.net_name(net), v, epsilon, found_v, self.read_net_strength(net) });
        return error.InvalidNetState;
    }
}

fn expect_net_high(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    try self.expect_net_not_hiz(net);
    try self.expect_net_below(net, levels.Vclamp);
    try self.expect_net_above(net, levels.Vih);
}

fn expect_net_low(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    try self.expect_net_not_hiz(net);
    try self.expect_net_below(net, levels.Vil);
}

fn expect_net_valid_or_nc(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    if (net == .no_connect) return;
    try self.expect_net_valid(net, levels);
}

fn expect_net_valid(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    try self.expect_net_not_hiz(net);
    const found_v = self.read_net(net);
    if (found_v.raw() <= levels.Vil.raw()) return;
    if (found_v.raw() >= levels.Vih.raw() and found_v.raw() <= levels.Vclamp.raw()) return;

    log.err("Expected {s} <= {} or between {} and {}; found {} @ {}\n", .{
        self.b.net_name(net),
        levels.Vil,
        levels.Vih,
        levels.Vclamp,
        found_v,
        self.read_net_strength(net),
    });
    return error.InvalidNetState;
}

const log = std.log.scoped(.zoink);

const Net_ID = enums.Net_ID;
const Voltage = enums.Voltage;
const Drive_Strength = enums.Drive_Strength;
const Part = @import("Part.zig");
const Board = @import("Board.zig");
const enums = @import("enums.zig");
const std = @import("std");
