gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
merges: std.AutoArrayHashMapUnmanaged(Net_ID, Net_ID),
old_kicad_id_to_name: std.AutoArrayHashMapUnmanaged(usize, []const u8),
name_to_kicad_id: std.StringHashMapUnmanaged(usize),
ordered_net_names: std.ArrayList([]const u8),

pub fn init(gpa: std.mem.Allocator) Net_Remap {
    return .{
        .gpa = gpa,
        .arena = .init(gpa),
        .merges = .empty,
        .old_kicad_id_to_name = .empty,
        .name_to_kicad_id = .empty,
        .ordered_net_names = .empty,
    };
}

pub fn deinit(self: *Net_Remap) void {
    self.merges.deinit(self.gpa);
    self.old_kicad_id_to_name.deinit(self.gpa);
    self.name_to_kicad_id.deinit(self.gpa);
    self.ordered_net_names.deinit(self.gpa);
    self.arena.deinit();
}

pub fn merge_overlapping_pad_nets(self: *Net_Remap, board: *Board) !void {
    for (board.parts.items) |*p| {
        try self.merge_overlapping_pad_nets_in_part(board, p);
    }
}

pub fn merge_overlapping_pad_nets_in_part(self: *Net_Remap, board: *Board, part: *const Part) !void {
    if (part.base.footprint) |base_fp| {
        for (0.., base_fp.pads) |i, pad| {
            for (base_fp.pads[i + 1 ..]) |other_pad| {
                if (pad.location.eql(other_pad.location)) {
                    const net = part.vt.pin_to_net(part.base, pad.pin);
                    const other_net = part.vt.pin_to_net(part.base, other_pad.pin);
                    try self.merge_nets(board, net, other_net);
                }
            }
        }
    }
}

pub fn merge_nets(self: *Net_Remap, board: *Board, a: Net_ID, b: Net_ID) !void {
    if (a == b) return;

    const maybe_merged_a = self.merges.get(a);
    const maybe_merged_b = self.merges.get(b);

    if (maybe_merged_a) |merged_a| {
        if (maybe_merged_b) |merged_b| {
            try self.update_merges(board, merged_a, merged_b);
        } else {
            log.info("Merging net {s} into {s}", .{
                board.net_name(b),
                board.net_name(merged_a),
            });
            try self.merges.put(self.gpa, b, merged_a);
        }
    } else if (maybe_merged_b) |merged_b| {
        log.info("Merging net {s} into {s}", .{
            board.net_name(a),
            board.net_name(merged_b),
        });
        try self.merges.put(self.gpa, a, merged_b);
    } else {
        log.info("Merging net {s} into {s}", .{
            board.net_name(a),
            board.net_name(b),
        });
        try self.merges.put(self.gpa, a, b);
    }
}
fn update_merges(self: *Net_Remap, board: *Board, old_merged: Net_ID, new_merged: Net_ID) !void {
    if (old_merged == new_merged) return;
    const keys = self.merges.keys();
    for (0.., self.merges.values()) |i, *net| {
        if (net.* == old_merged) {
            log.info("Merging net {s} into {s}", .{
                board.net_name(keys[i]),
                board.net_name(new_merged),
            });
            net.* = new_merged;
        }
    }
}

pub fn get_merged_net(self: *const Net_Remap, net: Net_ID) Net_ID {
    return self.merges.get(net) orelse net;
}

pub fn add_old_kicad_id(self: *Net_Remap, net_id: usize, net_name: []const u8) !void {
    try self.old_kicad_id_to_name.put(self.gpa, net_id, try self.arena.allocator().dupe(u8, net_name));
}

pub fn generate_mapping(self: *Net_Remap, board: *Board) !void {
    var names: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer names.deinit(self.gpa);

    try names.ensureTotalCapacity(self.gpa, self.old_kicad_id_to_name.count());
    for (self.old_kicad_id_to_name.values()) |name| {
        names.putAssumeCapacityNoClobber(name, {});
    }

    for (board.parts.items) |p| {
        if (p.base.footprint) |base_fp| {
            for (base_fp.pads) |pad| {
                const unmerged_net_id = p.vt.pin_to_net(p.base, pad.pin);
                const net_id = self.merges.get(unmerged_net_id) orelse unmerged_net_id;
                const net_name = board.net_name(net_id);
                try names.put(self.gpa, net_name, {});
            }
        }
    }

    const Sort_Context = struct {
        names: []const []const u8,
        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            const name_a = ctx.names[a];
            const name_b = ctx.names[b];

            if (name_a.len == 0) {
                return name_b.len > 0;
            } else if (name_b.len == 0) {
                return false;
            }

            if (std.meta.stringToEnum(Net_ID, name_a)) |net_a| {
                if (std.meta.stringToEnum(Net_ID, name_b)) |net_b| {
                    return @intFromEnum(net_a) < @intFromEnum(net_b);
                } else {
                    return true;
                }
            } else if (std.meta.stringToEnum(Net_ID, name_b)) |_| {
                return false;
            }

            return std.mem.lessThan(u8, name_a, name_b);
        }
    };
    names.entries.sort(Sort_Context { .names = names.keys() }); // note not using names.sort because we don't need the hash table part anymore

    self.name_to_kicad_id.clearRetainingCapacity();
    self.ordered_net_names.clearRetainingCapacity();
    try self.name_to_kicad_id.ensureTotalCapacity(self.gpa, @intCast(names.count()));
    try self.ordered_net_names.ensureTotalCapacity(self.gpa, @intCast(names.count()));

    self.ordered_net_names.appendSliceAssumeCapacity(names.keys());
    for (0.., names.keys()) |i, name| {
        self.name_to_kicad_id.putAssumeCapacityNoClobber(name, i);
    }
}

pub fn get_kicad_id_from_name(self: *const Net_Remap, net_name: []const u8) usize {
    return self.name_to_kicad_id.get(net_name) orelse unreachable;
}

pub fn convert_kicad_id(self: *const Net_Remap, old_net_id: usize) ?usize {
    const name = self.old_kicad_id_to_name.get(old_net_id) orelse return null;
    return self.get_kicad_id_from_name(name);
}

pub fn write_nets(self: *Net_Remap, w: *sx.Writer) !void {
    for (0.., self.ordered_net_names.items) |i, name| {
        try w.expression("net");
        try w.int(i, 10);
        try w.string_quoted(name);
        try w.close();
    }
}

const Net_Remap = @This();

const log = std.log.scoped(.zoink);

const Net_ID = enums.Net_ID;
const enums = @import("enums.zig");
const Board = @import("Board.zig");
const Part = @import("Part.zig");
const sx = @import("sx");
const std = @import("std");
