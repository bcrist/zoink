arena: std.mem.Allocator,
gpa: std.mem.Allocator,

bus_lookup: std.StringArrayHashMapUnmanaged([]const Net_ID) = .{},
net_lookup: std.StringArrayHashMapUnmanaged(Net_ID) = .{},
net_names: std.ArrayListUnmanaged([]const u8) = .{},

parts: std.ArrayListUnmanaged(Part) = .{},


const Board = @This();

pub fn deinit(self: *Board) void {
    self.bus_lookup.deinit(self.gpa);
    self.net_lookup.deinit(self.gpa);
    self.net_names.deinit(self.gpa);
    self.parts.deinit(self.gpa);
    self.gpa = undefined;
    self.arena = undefined;
}

pub fn net_name(self: *const Board, net_id: Net_ID) []const u8 {
    if (net_id.is_power() or net_id == .no_connect or net_id == .unset) return @tagName(net_id);
    const idx = @intFromEnum(net_id);
    if (idx >= self.net_names.items.len) return "unset";
    return self.net_names.items[idx];
}

pub fn print_bus_name(self: *const Board, nets: anytype, writer: anytype) !void {
    if (nets.len == 0) return;

    var base_name = self.net_name(nets[0]);
    if (std.mem.indexOfScalar(u8, base_name, '[')) |end| {
        base_name = base_name[0..end];
    }

    const just_base = for (0.., nets) |i, net_id| {
        const full_name = self.net_name(net_id);
        const end = std.mem.indexOfScalar(u8, full_name, '[') orelse break false;
        if (full_name[full_name.len - 1] != ']') break false;
        const name = full_name[0 .. end];
        if (!std.mem.eql(u8, base_name, name)) break false;
        const bit = std.fmt.parseInt(u16, full_name[end + 1 .. full_name.len - 1], 10) catch break false;
        if (bit != i) break false;
    } else true;

    if (just_base) {
        try writer.writeAll(base_name);
    } else {
        try writer.writeByte('{');
        for (0.., nets) |i, net_id| {
            if (i > 0) try writer.writeAll(", ");
            try writer.writeAll(self.net_name(net_id));
        }
        try writer.writeByte('}');
    }
}

pub fn get_net(self: *Board, name: []const u8) Net_ID {
    return self.net_lookup.get(name) orelse std.debug.panic("Net not found: {s}", .{ name });
}

pub fn net(self: *Board, name: []const u8) Net_ID {
    const gop = self.net_lookup.getOrPut(self.gpa, name) catch @panic("OOM");
    if (gop.found_existing) {
        return gop.value_ptr.*;
    }

    if (self.net_names.items.len == 0) {
        self.net_names.append(self.gpa, "unset") catch @panic("OOM");
    }

    const net_id: Net_ID = @enumFromInt(self.net_names.items.len);
    gop.key_ptr.* = name;
    gop.value_ptr.* = net_id;
    self.net_names.append(self.gpa, name) catch @panic("OOM");
    return net_id;
}

pub fn unique_net(self: *Board, comptime name_prefix: []const u8) Net_ID {
    const name = std.fmt.allocPrint(self.arena, name_prefix ++ "#{}", .{ self.net_names.items.len }) catch @panic("OOM");
    return self.net(name);
}

pub fn get_bus(self: *Board, name: []const u8) []const Net_ID {
    return self.bus_lookup.get(name) orelse std.debug.panic("Bus not found: {s}", .{ name });
}

pub fn bus(self: *Board, comptime name: []const u8, comptime bits: comptime_int) [bits]Net_ID {
    var result: [bits]Net_ID = undefined;

    comptime var full_bus = true;
    comptime var base = name;
    comptime var delta = 1;
    const lsb = comptime if (std.mem.lastIndexOfScalar(u8, name, '[')) |subscript_begin| lsb: {
        full_bus = false;
        if (!std.mem.endsWith(u8, name, "]")) @compileError("Expected closing ] in bus name: " ++ name);
        base = name[0..subscript_begin];
        const subscript = name[subscript_begin + 1 .. name.len - 1];
        if (std.mem.indexOfScalar(u8, subscript, ':')) |separator_pos| {
            const first = std.fmt.parseInt(u16, subscript[0..separator_pos], 10) catch @compileError("Invalid bus subscript: " ++ name);
            const last = std.fmt.parseInt(u16, subscript[separator_pos + 1 ..], 10) catch @compileError("Invalid bus subscript: " ++ name);
            const max: u16 = @max(first, last);
            const min: u16 = @min(first, last);
            const count = max - min + 1;
            if (bits != count) {
                @compileError(std.fmt.comptimePrint("Subscript indicates bus length of {} but result has length {}", .{ count, bits }));
            }
            if (first > last) delta = -1;
            break :lsb first;
        } else {
            break :lsb std.fmt.parseInt(u16, subscript) catch @compileError("Invalid bus subscript: " ++ name);
        }
    } else 0;

    inline for (0..bits) |i| {
        result[i] = self.net(std.fmt.comptimePrint("{s}[{}]", .{ base, lsb + i * delta }));
    }

    if (full_bus) {
        const gop = self.bus_lookup.getOrPut(self.gpa, base) catch @panic("OOM");
        if (gop.found_existing) {
            const found_bits = gop.value_ptr.*.len;
            if (found_bits != bits) {
                std.debug.panic("Expected {} bits for bus {s}; found {}", .{ bits, base, found_bits });
            }
        } else {
            gop.key_ptr.* = base;
            gop.value_ptr.* = self.arena.dupe(Net_ID, &result) catch @panic("OOM");
        }
    } else if (self.bus_lookup.get(base)) |full| {
        const expected_bits = @max(lsb, lsb + (bits - 1) * delta);
        if (full.len <= expected_bits) {
            std.debug.panic("Expected at least {} bits for bus {s}; found {}", .{ expected_bits, base, full.len });
        }
    }

    return result;
}

pub fn part(self: *Board, comptime Type: type) *Type {
    self.parts.ensureUnusedCapacity(self.gpa, 1) catch @panic("OOM");
    const ptr = self.arena.create(Type) catch @panic("OOM");
    ptr.* = .{};
    self.parts.appendAssumeCapacity(.{
        .base = &ptr.base,
        .vt = comptime Part.VTable.init(Type),
    });
    return ptr;
}


pub fn finish_configuration(self: *Board, temp: std.mem.Allocator) !void {
    { // generate decoupling caps and ensure power nets are set
        // This process may add new parts, so we can't assume self.parts.items will be stable
        var i: usize = self.parts.items.len;
        while (i > 0) {
            i -= 1;
            try self.parts.items[i].finalize_power_nets(self);
        }
    }

    { // assign designators
        var designators = std.EnumArray(Prefix, std.AutoHashMapUnmanaged(u16, *Part.Base)).initFill(.{});
        defer for (&designators.values) |*map| {
            map.deinit(temp);
        };

        for (self.parts.items) |p| {
            if (p.base.designator == 0) continue;
            // TODO putNoClobber isn't very debuggable
            designators.getPtr(p.base.prefix).putNoClobber(temp, p.base.designator, p.base) catch @panic("OOM");
        }

        var next_designators = std.EnumArray(Prefix, u16).initFill(1);
        for (self.parts.items) |p| {
            if (p.base.designator != 0) continue;

            p.base.designator = next_designators.get(p.base.prefix);
            var used = designators.getPtr(p.base.prefix);

            while (used.get(p.base.designator) != null) {
                p.base.designator += 1;
            }

            used.putNoClobber(temp, p.base.designator, p.base) catch @panic("OOM");
            next_designators.set(p.base.prefix, p.base.designator + 1);
        }
    }
}

const Part = @import("Part.zig");
const Net_ID = enums.Net_ID;
const Prefix = enums.Prefix;
const enums = @import("enums.zig");
const std = @import("std");
