b: *const Board,
allocator: std.mem.Allocator,
solver_arena: std.heap.ArenaAllocator,
nets: std.MultiArrayList(Net_State),
parts: std.MultiArrayList(Part_Validator),
part_state: std.ArrayListUnmanaged(u8),
circuits: std.ArrayListUnmanaged(Circuit.Complex),
next_free_circuit: usize,
max_iterations: usize,
hash_part_state: bool,
float_v: Voltage,

const Net_State = struct {
    v: Voltage,
    circuit: Circuit,
    initial_circuit: Circuit, // must be .none or .simplex
};

const Circuit = union (enum) {
    none,
    simplex: Simplex,
    divider: [2]Simplex,
    complex: usize,

    pub const Simplex = struct {
        v: f32,
        r: f32,
    };

    pub const Complex = struct {
        power: std.ArrayListUnmanaged(f32),
        nets: std.ArrayListUnmanaged(Net_ID),
        resistors: std.ArrayListUnmanaged(Resistor),

        pub const empty: Complex = .{
            .power = .empty,
            .nets = .empty,
            .resistors = .empty,
        };

        pub const Resistor = struct {
            r: f32,
            node_a: u32,
            node_b: u32,
        };

        pub const power_node_offset: u32 = 0xE000_0000;

        pub fn deinit(self: *Complex, allocator: std.mem.Allocator) void {
            self.power.deinit(allocator);
            self.nets.deinit(allocator);
            self.resistors.deinit(allocator);
        }

        pub fn solver(self: *Complex, allocator: std.mem.Allocator) !mna.Solver {
            var s: mna.Solver = try .init(allocator, self.power.items, self.nets.items);
            for (self.resistors.items) |resistor| {
                const net_b = self.nets.items[resistor.node_b];
                if (resistor.node_a > power_node_offset) {
                    const v = self.power.items[resistor.node_a - power_node_offset - 1];
                    s.add_resistor_to_power(resistor.r, net_b, v);
                } else if (resistor.node_a == power_node_offset) {
                    s.add_resistor_to_power(resistor.r, net_b, 0.0);
                } else {
                    const net_a = self.nets.items[resistor.node_a];
                    s.add_resistor_between_nets(resistor.r, net_a, net_b);
                }
            }
            return s;
        }

        pub fn merge(self: *Complex, allocator: std.mem.Allocator, other: *Complex) !void {
            try self.power.ensureUnusedCapacity(allocator, other.power.items.len);
            try self.nets.ensureUnusedCapacity(allocator, other.nets.items.len);
            try self.resistors.ensureUnusedCapacity(allocator, other.resistors.items.len);

            for (other.resistors.items) |resistor| {
                if (resistor.node_a > power_node_offset) {
                    self.add_net_to_power(allocator, other.nets.items[resistor.node_b], other.power.items[resistor.node_a - power_node_offset - 1], resistor.r) catch unreachable;
                } else if (resistor.node_a == power_node_offset) {
                    self.add_net_to_power(allocator, other.nets.items[resistor.node_b], 0.0, resistor.r) catch unreachable;
                } else {
                    self.add_net_to_net(allocator, other.nets.items[resistor.node_a], other.nets.items[resistor.node_b], resistor.r) catch unreachable;
                }
            }

            other.power.clearRetainingCapacity();
            other.nets.clearRetainingCapacity();
            other.resistors.clearRetainingCapacity();
        }

        pub fn add_net_to_power(self: *Complex, allocator: std.mem.Allocator, net: Net_ID, v: f32, r: f32) !void {
            const pn = try self.power_node(allocator, v);
            const nn = try self.net_node(allocator, net);
            try self.resistors.append(allocator, .{
                .r = r,
                .node_a = pn,
                .node_b = nn,
            });
        }

        pub fn add_net_to_net(self: *Complex, allocator: std.mem.Allocator, net_a: Net_ID, net_b: Net_ID, r: f32) !void {
            const na = try self.net_node(allocator, net_a);
            const nb = try self.net_node(allocator, net_b);
            try self.resistors.append(allocator, .{
                .r = r,
                .node_a = na,
                .node_b = nb,
            });
        }

        fn power_node(self: *Complex, allocator: std.mem.Allocator, v: f32) !u32 {
            if (v == 0) return power_node_offset;
            for (power_node_offset + 1 .., self.power.items) |i, power_v| {
                if (v == power_v) return @intCast(i);
            }
            try self.power.append(allocator, v);
            return @intCast(power_node_offset + self.power.items.len);
        }

        fn net_node(self: *Complex, allocator: std.mem.Allocator, net: Net_ID) !u32 {
            for (0.., self.nets.items) |i, existing_net| {
                if (existing_net == net) return @intCast(i);
            }
            try self.nets.append(allocator, net);
            return @intCast(self.nets.items.len - 1);
        }
    };
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
    float_v: Voltage = .p1v,
};

pub fn init(allocator: std.mem.Allocator, b: *const Board, options: Init_Options) !Validator {
    var nets: std.MultiArrayList(Net_State) = .{};
    errdefer nets.deinit(allocator);

    const num_nets = b.net_names.items.len;
    try nets.ensureTotalCapacity(allocator, num_nets);
    nets.len = num_nets;

    var parts: std.MultiArrayList(Part_Validator) = .{};
    errdefer parts.deinit(allocator);
    try parts.ensureTotalCapacity(allocator, b.parts.items.len);

    var part_state_needed: usize = 0;

    const board_parts = try allocator.dupe(Part, b.parts.items);
    defer allocator.free(board_parts);
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
    var part_state = try std.ArrayListUnmanaged(u8).initCapacity(allocator, part_state_needed);
    errdefer part_state.deinit(allocator);
    part_state.items.len = part_state_needed;

    return .{
        .b = b,
        .allocator = allocator,
        .solver_arena = .init(allocator),
        .nets = nets,
        .parts = parts,
        .part_state = part_state,
        .circuits = .empty,
        .next_free_circuit = 0,
        .max_iterations = options.max_iterations,
        .hash_part_state = options.hash_part_state,
        .float_v = options.float_v,
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
    for (self.circuits.items) |*circuit| circuit.deinit(self.allocator);
    self.circuits.deinit(self.allocator);
    self.nets.deinit(self.allocator);
    self.parts.deinit(self.allocator);
    self.part_state.deinit(self.allocator);
    self.solver_arena.deinit();
}

pub fn reset(self: *Validator) !void {
    @memset(self.nets.items(.v), self.float_v);
    @memset(self.nets.items(.initial_circuit), .none);
    self.reset_circuits();
    _ = try self.step(.reset);
}

fn reset_circuits(self: *Validator) void {
    @memcpy(self.nets.items(.circuit), self.nets.items(.initial_circuit));
    for (self.circuits.items) |*circuit| {
        circuit.power.clearRetainingCapacity();
        circuit.nets.clearRetainingCapacity();
        circuit.resistors.clearRetainingCapacity();
    }
    self.next_free_circuit = 0;
}

pub fn set(self: *Validator, net: Net_ID, v: Voltage) !void {
    try self.set_with_impedance(net, v, 1.0);
}

pub fn unset(self: *Validator, net: Net_ID) !void {
    const idx = @intFromEnum(net);
    if (idx >= @intFromEnum(Net_ID.p24v)) return error.CantDrivePower;
    if (idx >= self.nets.len) return error.InvalidNet;
    self.nets.items(.initial_circuit)[idx] = .none;
}

pub fn set_with_impedance(self: *Validator, what: anytype, v: Voltage, r: f32) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.set_net_with_impedance(what, v, r),
        else => for (what) |net| {
            try self.set_net_with_impedance(net, v, r);
        },
    }
}

fn set_net_with_impedance(self: *Validator, net: Net_ID, v: Voltage, r: f32) !void {
    const idx = @intFromEnum(net);
    if (idx >= @intFromEnum(Net_ID.p24v)) return error.CantDrivePower;
    if (idx >= self.nets.len) return error.InvalidNet;
    self.nets.items(.initial_circuit)[idx] = .{ .simplex = .{
        .v = v.as_float(),
        .r = r,
    }};
}

pub fn set_logic(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    try self.set_with_impedance(net, if (high) levels.Vcco else .gnd, if (high) levels.Zoh else levels.Zol);
}

pub fn set_high(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_logic(net, true, levels);
}

pub fn set_low(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_logic(net, false, levels);
}

pub fn set_bus(self: *Validator, bus: anytype, value: usize, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        try self.set_logic(net, (value & bit) != 0, levels);
        bit = @shlExact(bit, 1);
    }
}

pub fn unset_bus(self: *Validator, bus: anytype) !void {
    for (bus) |net| try self.unset(net);
}

pub fn clock_high(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_logic(net, true, levels);
    try self.update();
    try self.update();
}

pub fn clock_low(self: *Validator, net: Net_ID, comptime levels: type) !void {
    try self.set_logic(net, false, levels);
    try self.update();
    try self.update();
}

pub fn connect_buses(self: *Validator, a: anytype, b: anytype, r: f32) !void {
    for (a, b) |a_net, b_net| {
        try self.connect_nets(a_net, b_net, r);
    }
}

pub fn connect_net_to_power(self: *Validator, net: Net_ID, v: f32, r: f32) !void {
    const net_idx = @intFromEnum(net);
    if (net_idx >= self.nets.len) return error.InvalidNet;

    const net_circuits = self.nets.items(.circuit);
    switch (net_circuits[net_idx]) {
        .none => net_circuits[net_idx] = .{
            .simplex = .{ .v = v, .r = r },
        },
        .simplex => |*existing| {
            if (existing.v == v) {
                existing.r = 1 / ((1 / existing.r) + (1 / r));
            } else net_circuits[net_idx] = .{
                .divider = .{
                    existing.*,
                    .{ .v = v, .r = r },
                },
            };
        },
        .divider => |*existing| {
            if (existing.*[0].v == v) {
                existing.*[0].r = 1 / ((1 / existing.*[0].r) + (1 / r));
            } else if (existing.*[1].v == v) {
                existing.*[1].r = 1 / ((1 / existing.*[1].r) + (1 / r));
            } else {
                const circuit_index = self.next_free_circuit;
                self.next_free_circuit += 1;

                while (self.circuits.items.len <= circuit_index) {
                    try self.circuits.append(self.allocator, .empty);
                }

                var circuit = &self.circuits.items[circuit_index];

                try circuit.add_net_to_power(self.allocator, net, existing.*[0].v, existing.*[0].r);
                try circuit.add_net_to_power(self.allocator, net, existing.*[1].v, existing.*[1].r);
                try circuit.add_net_to_power(self.allocator, net, v, r);

                net_circuits[net_idx] = .{ .complex = circuit_index };
            }
        },
        .complex => |circuit_index| {
            try self.circuits.items[circuit_index].add_net_to_power(self.allocator, net, v, r);
        },
    }
}

pub fn connect_nets(self: *Validator, a: Net_ID, b: Net_ID, r: f32) !void {
    if (a == .no_connect or a == .unset or b == .no_connect or b == .unset) return;

    if (a.is_power()) {
        if (!b.is_power()) {
            try self.connect_net_to_power(b, Voltage.from_net(a).as_float(), r);
        }
        return;
    }

    if (b.is_power()) {
        try self.connect_net_to_power(a, Voltage.from_net(b).as_float(), r);
        return;
    }

    const a_idx = @intFromEnum(a);
    const b_idx = @intFromEnum(b);

    if (a_idx >= self.nets.len or b_idx >= self.nets.len) return error.InvalidNet;

    const net_circuits = self.nets.items(.circuit);

    const circuit_index = switch (net_circuits[a_idx]) {
        .complex => |idx| idx,
        else => switch (net_circuits[b_idx]) {
            .complex => |idx| idx,
            else => self.next_free_circuit,
        },
    };

    if (circuit_index == self.next_free_circuit) self.next_free_circuit += 1;

    while (self.circuits.items.len <= circuit_index) {
        try self.circuits.append(self.allocator, .empty);
    }

    var circuit = &self.circuits.items[circuit_index];

    try self.ensure_net_circuit_complex(a, circuit_index, circuit);
    try self.ensure_net_circuit_complex(b, circuit_index, circuit);
    try circuit.add_net_to_net(self.allocator, a, b, r);

    // self.debug_circuit(a, self.nets.items(.circuit)[a_idx], "Connection A");
    // self.debug_circuit(b, self.nets.items(.circuit)[b_idx], "Connection B");
}

fn ensure_net_circuit_complex(self: *Validator, net: Net_ID, circuit_index: usize, circuit: *Circuit.Complex) !void {
    const net_idx = @intFromEnum(net);

    const net_circuits = self.nets.items(.circuit);
    switch (net_circuits[net_idx]) {
        .none => {},
        .simplex => |existing| {
            try circuit.add_net_to_power(self.allocator, net, existing.v, existing.r);
        },
        .divider => |existing| {
            try circuit.add_net_to_power(self.allocator, net, existing[0].v, existing[0].r);
            try circuit.add_net_to_power(self.allocator, net, existing[1].v, existing[1].r);
        },
        .complex => |other_circuit_index| {
            if (other_circuit_index != circuit_index) {
                try circuit.merge(self.allocator, &self.circuits.items[other_circuit_index]);
            }
        },
    }

    net_circuits[net_idx] = .{ .complex = circuit_index };
}

fn debug_circuit(self: *Validator, net: Net_ID, circuit: Circuit, comptime text: []const u8) void {
    log.warn(text ++ ":", .{});
    switch (circuit) {
        .none => log.warn("  (no circuit)", .{}),
        .simplex => |s| log.warn("  R={d} ohm between {s} and {f} (simplex)", .{ s.r, self.b.net_name(net), Voltage.from_float(s.v) }),
        .divider => |s| {
            log.warn("  R={d} ohm between {s} and {f} (divider)", .{ s[0].r, self.b.net_name(net), Voltage.from_float(s[0].v) });
            log.warn("  R={d} ohm between {s} and {f} (divider)", .{ s[1].r, self.b.net_name(net), Voltage.from_float(s[1].v) });
        },
        .complex => |circuit_index| {
            const c = self.circuits.items[circuit_index];
            for (c.resistors.items) |resistor| {
                if (resistor.node_a > Circuit.Complex.power_node_offset) {
                    log.warn("  R={d} ohm between {s} and {f}", .{
                        resistor.r,
                        self.b.net_name(c.nets.items[resistor.node_b]),
                        Voltage.from_float(c.power.items[resistor.node_a - Circuit.Complex.power_node_offset - 1]),
                    });
                } else if (resistor.node_a == Circuit.Complex.power_node_offset) {
                    log.warn("  R={d} ohm between {s} and GND", .{
                        resistor.r,
                        self.b.net_name(c.nets.items[resistor.node_b]),
                    });
                } else {
                    log.warn("  R={d} ohm between {s} and {s}", .{
                        resistor.r,
                        self.b.net_name(c.nets.items[resistor.node_a]),
                        self.b.net_name(c.nets.items[resistor.node_b]),
                    });
                }
            }
        },
    }
}

pub fn drive_net(self: *Validator, net: Net_ID, v: Voltage, impedance: f32) !void {
    if (net == .no_connect or net == .unset) return;
    if (net.is_power()) return error.CantDrivePower;
    try self.connect_net_to_power(net, v.as_float(), impedance);
}

pub fn drive_logic(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    const v: Voltage = if (high) levels.Vcco else .gnd;
    const z: f32 = if (high) levels.Zoh else levels.Zol;
    try self.drive_net(net, v, z);
}

pub fn drive_logic_weak(self: *Validator, net: Net_ID, high: bool, comptime levels: type) !void {
    const v: Voltage = if (high) levels.Vcco else .gnd;
    try self.drive_net(net, v, levels.Rpull);
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
        else => self.nets.items(.v)[@intFromEnum(net)],
    };
}

pub fn read_logic(self: *const Validator, net: Net_ID, comptime levels: type) bool {
    return self.read_net(net).raw() >= levels.Vth.raw();
}

pub fn read_logic_with_pull(self: *const Validator, net: Net_ID, comptime levels: type, pull: bool) bool {
    if (net == .unset or net == .no_connect) return pull;
    return self.read_net(net).raw() > levels.Vth.raw();
}

pub fn pull_and_read_logic(self: *Validator, net: Net_ID, comptime levels: type, pull: bool) !bool {
    const pull_v = if (pull) levels.Vcco else .gnd;
    try self.drive_net(net, pull_v, levels.Rpull);
    return self.read_logic_with_pull(net, levels, pull);
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

pub fn read_bus_with_pull(self: *Validator, bus: anytype, comptime levels: type, pull: usize) usize {
    var bit: usize = 1;
    var result: usize = 0;
    for (bus) |net| {
        if (self.read_logic_with_pull(net, levels, (pull & bit) != 0)) {
            result |= bit;
        }
        bit = @shlExact(bit, 1);
    }
    return result;
}

pub fn pull_and_read_bus(self: *Validator, bus: anytype, comptime levels: type, pull: usize) !usize {
    var bit: usize = 1;
    var result: usize = 0;
    for (bus) |net| {
        if (try self.pull_and_read_logic(net, levels, (pull & bit) != 0)) {
            result |= bit;
        }
        bit = @shlExact(bit, 1);
    }
    return result;
}

pub fn update(self: *Validator) !void {
    var hash = try self.step(.nets_only);
    for (1..self.max_iterations) |_| {
        const new_hash = try self.step(.nets_only);
        if (new_hash == hash) {
            _ = try self.step(.commit);
            break;
        }

        hash = new_hash;
    } else return error.Unstable;
}

fn step(self: *Validator, mode: Update_Mode) !u64 {
    if (mode != .commit) self.reset_circuits();

    for (self.parts.items(.part), self.parts.items(.func), self.parts.items(.state_offset)) |part, func, offset| {
        try func(part, self, &self.part_state.items[offset], mode);
    }
    
    if (mode == .commit) return 0;

    const net_v = self.nets.items(.v);
    for (0.., self.nets.items(.circuit)) |net_idx, circuit| {
        switch (circuit) {
            .none => {},
            .simplex => |s| net_v[net_idx] = .from_float(s.v),
            .divider => |s| {
                const total_r = s[0].r + s[1].r;
                const temp = s[0].v * s[1].r + s[1].v * s[0].r;
                net_v[net_idx] = .from_float(temp / total_r);
            },
            .complex => {},
        }
    }

    // for (0.., self.circuits.items[0..self.next_free_circuit]) |circuit_index, circuit| {
    //     if (circuit.nets.items.len == 0) continue;

    //     self.debug_circuit(.gnd, .{ .complex = circuit_index }, "Circuit");
    // }

    for (0.., self.circuits.items[0..self.next_free_circuit]) |circuit_index, *circuit| {
        if (circuit.nets.items.len == 0) continue;

        _ = self.solver_arena.reset(.retain_capacity);
        var solver = try circuit.solver(self.solver_arena.allocator());
        solver.solve() catch |err| switch (err) {
            error.Noninvertible => {
                self.debug_circuit(.gnd, .{ .complex = circuit_index }, "Can't solve circuit");
                return error.BadCircuit;
            },
            else => return err,
        };
        for (circuit.nets.items) |net| {
            net_v[@intFromEnum(net)] = solver.get_net_voltage(net);
        }
    }

    var hash = std.hash.Wyhash.init(0);

    if (self.hash_part_state) {
        hash.update(self.part_state.items);
    }

    for (self.nets.items(.v)) |v| {
        hash.update(std.mem.asBytes(&v));
    }

    return hash.final();
}

pub fn verify_power_limit(self: *Validator, a: anytype, b: anytype, resistance: f32, power_limit: f32) !void {
    switch (@typeInfo(@TypeOf(a))) {
        .@"enum" => try self.verify_net_power_limit(a, b, resistance, power_limit),
        else => for (a, b) |a_net, b_net| {
            try self.verify_net_power_limit(a_net, b_net, resistance, power_limit);
        },
    }
}

pub fn verify_net_power_limit(self: *Validator, a: Net_ID, b: Net_ID, resistance: f32, power_limit: f32) !void {
    if (a == .no_connect or a == .unset or b == .no_connect or b == .unset) return;

    const va = self.read_net(a);
    const vb = self.read_net(b);
    const v = @abs(va.as_float() - vb.as_float());
    const p = v * v / resistance;
    if (p > power_limit) {
        log.warn("Voltage drop of {f} between resistive connection between {s} and {s} requires power limit > {d} W", .{
            Voltage.from_float(v),
            self.b.net_name(a),
            self.b.net_name(b),
            p,
        });
    }
}

pub fn expect_above(self: *const Validator, what: anytype, v: Voltage) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_above(what, v),
        else => for (what) |net| {
            try self.expect_net_above(net, v);
        },
    }
}

pub fn expect_below(self: *const Validator, what: anytype, v: Voltage) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_below(what, v),
        else => for (what) |net| {
            try self.expect_net_below(net, v);
        },
    }
}

pub fn expect_approx(self: *const Validator, what: anytype, v: Voltage, epsilon: f32) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_approx(what, v, epsilon),
        else => for (what) |net| {
            try self.expect_net_approx(net, v, epsilon);
        },
    }
}

pub fn expect_state(self: *const Validator, what: anytype, expected: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_state(what, expected, levels),
        else => self.expect_bus_state(what, expected, levels) catch {
            var buf: [256]u8 = undefined;
            var w = std.io.Writer.fixed(&buf);
            self.b.print_bus_name(what, &w) catch {};
            log.err("{s} is {X}\n", .{ w.buffered(), self.read_bus(what, levels) });
            return error.InvalidNetState;
        },
    }
}

pub fn expect_high(self: *const Validator, what: anytype, comptime levels: type) !void {
    try self.expect_state(what, true, levels);
}

pub fn expect_low(self: *const Validator, what: anytype, comptime levels: type) !void {
    try self.expect_state(what, false, levels);
}

pub fn expect_valid(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_valid(what, levels),
        else => for (what) |net| {
            try self.expect_net_valid(net, levels);
        },
    }
}

pub fn expect_valid_or_unconnected(self: *const Validator, what: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_valid_or_unconnected(what, levels),
        else => for (what) |net| {
            try self.expect_net_valid_or_unconnected(net, levels);
        },
    }
}

pub fn expect_output_valid(self: *const Validator, what: anytype, expected: anytype, comptime levels: type) !void {
    switch (@typeInfo(@TypeOf(what))) {
        .@"enum" => try self.expect_net_output_valid(what, expected, levels),
        else => try self.expect_bus_output_valid(what, expected, levels),
    }
}

fn expect_bus_state(self: *const Validator, bus: anytype, expected: anytype, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        if (@TypeOf(expected) == bool) {
            if (expected) {
                try self.expect_net_state(net, true, levels);
            } else {
                try self.expect_net_state(net, false, levels);
            }
        } else if (0 == (expected & bit)) {
            try self.expect_net_state(net, false, levels);
        } else {
            try self.expect_net_state(net, true, levels);
        }
        bit = @shlExact(bit, 1);
    }
}

fn expect_bus_output_valid(self: *const Validator, bus: anytype, expected: anytype, comptime levels: type) !void {
    var bit: usize = 1;
    for (bus) |net| {
        if (@TypeOf(expected) == bool) {
            if (expected) {
                try self.expect_net_output_valid(net, true, levels);
            } else {
                try self.expect_net_output_valid(net, false, levels);
            }
        } else if (0 == (expected & bit)) {
            try self.expect_net_output_valid(net, false, levels);
        } else {
            try self.expect_net_output_valid(net, true, levels);
        }
        bit = @shlExact(bit, 1);
    }
}

fn expect_net_above(self: *const Validator, net: Net_ID, v: Voltage) !void {
    const found_v = self.read_net(net);
    if (found_v.raw() < v.raw()) {
        log.err("Expected {s} >= {f}; found {f}\n", .{ self.b.net_name(net), v, found_v });
        return error.InvalidNetState;
    }
}

fn expect_net_below(self: *const Validator, net: Net_ID, v: Voltage) !void {
    const found_v = self.read_net(net);
    if (found_v.raw() > v.raw()) {
        log.err("Expected {s} <= {f}; found {f}\n", .{ self.b.net_name(net), v, found_v });
        return error.InvalidNetState;
    }
}

fn expect_net_approx(self: *const Validator, net: Net_ID, v: Voltage, epsilon: f32) !void {
    const found_v = self.read_net(net);
    if (!std.math.approxEqAbs(f32, v.as_float(), found_v.as_float(), epsilon)) {
        log.err("Expected {s} ~= {f} +/- {d}; found {f}\n", .{ self.b.net_name(net), v, epsilon, found_v });
        return error.InvalidNetState;
    }
}

fn expect_net_state(self: *const Validator, net: Net_ID, expected: bool, comptime levels: type) !void {
    if (expected) {
        try self.expect_net_below(net, levels.Vclamp);
        try self.expect_net_above(net, levels.Vih);
    } else {
        try self.expect_net_below(net, levels.Vil);
    }
}

fn expect_net_valid_or_unconnected(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    if (net ==  .no_connect or net == .unset) return;
    try self.expect_net_valid(net, levels);
}

fn expect_net_valid(self: *const Validator, net: Net_ID, comptime levels: type) !void {
    const found_v = self.read_net(net);
    if (found_v.raw() <= levels.Vil.raw()) return;
    if (found_v.raw() >= levels.Vih.raw() and found_v.raw() <= levels.Vclamp.raw()) return;

    log.err("Expected {s} <= {f} or between {f} and {f}; found {f}\n", .{
        self.b.net_name(net),
        levels.Vil,
        levels.Vih,
        levels.Vclamp,
        found_v,
    });
    return error.InvalidNetState;
}

fn expect_net_output_valid(self: *const Validator, net: Net_ID, expected: bool, comptime levels: type) !void {
    if (net == .no_connect or net == .unset) return;
    if (expected) {
        try self.expect_net_below(net, levels.Vclamp);
        try self.expect_net_above(net, levels.Voh);
    } else {
        try self.expect_net_below(net, levels.Vol);
    }
}

const log = std.log.scoped(.zoink);

const Net_ID = enums.Net_ID;
const Voltage = enums.Voltage;
const Part = @import("Part.zig");
const Board = @import("Board.zig");
const mna = @import("mna.zig");
const enums = @import("enums.zig");
const std = @import("std");
