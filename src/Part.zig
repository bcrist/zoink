base: *Base,
vt: *const VTable,

const Part = @This();

pub const Base = struct {
    package: *const Package,
    footprint: ?*const kicad.Footprint = null,
    prefix: enums.Prefix,
    designator: u16 = 0,
    name: []const u8 = "",
    value: []const u8 = "",
    description: []const u8 = "",
    layer: ?kicad.Layer = null,
    location: ?kicad.Location = null,
    rotation: ?kicad.Rotation = null,
    locked: ?bool = null,
    populate: bool = true,
    include_in_bom: bool = true,
    include_in_position_files: bool = true,
};

pub const VTable = struct {
    pin_to_net: *const fn(base: *Part.Base, pin: Pin_ID) Net_ID,
    check_config: ?*const fn(base: *Part.Base, b: *Board) anyerror!void,
    check_for_unset_nets: *const fn(base: *Part.Base) anyerror!void,
    get_or_generate_decouplers: *const fn(base: *Part.Base, b: *Board, decoupler_buf: []Part) []const Part,
    validate: ?*const fn(base: *const Part.Base, v: *Validator, state: *anyopaque, mode: Validator.Update_Mode) anyerror!void,
    validator_state_bytes: usize,
    validator_state_align: usize,

    pub fn init(comptime P: type) *const VTable {
        @setEvalBranchQuota(100_000);
        const has_check_config = @hasDecl(P, "check_config");
        const has_validate = @hasDecl(P, "validate");
        comptime var Validator_State = void;
        comptime var Validator_State_Pointer = void;
        comptime var validator_state_alignment = 1;
        if (has_validate and @typeInfo(@TypeOf(P.validate)).@"fn".params.len == 4) {
            Validator_State_Pointer = @typeInfo(@TypeOf(P.validate)).@"fn".params[2].type.?;
            const param_info = @typeInfo(Validator_State_Pointer).pointer;
            std.debug.assert(param_info.size == .one);
            Validator_State = param_info.child;
            validator_state_alignment = param_info.alignment;
        }

        const impl = struct {
            pub fn pin_to_net(base: *Part.Base, pin: Pin_ID) Net_ID {
                const part: *P = @fieldParentPtr("base", base);
                return part.pin(pin);
            }

            pub fn check_config(base: *Part.Base, b: *Board) !void {
                const part: *P = @fieldParentPtr("base", base);
                errdefer dump_nets(P, part.*, b, base, "");
                const func_info: std.builtin.Type.Fn = @typeInfo(@TypeOf(P.check_config)).@"fn";
                if (func_info.params.len == 2) {
                    try part.check_config(b);
                } else {
                    try part.check_config();
                }
            }

            fn dump_nets(comptime T: type, value: T, b: *Board, base: *Part.Base, comptime prefix: []const u8) void {
                if (T == Part.Base or T == void) return;
                if (T == Net_ID) {
                    std.log.err("{s}{s} = {s}", .{ base.name, prefix, b.net_name(value) });
                    return;
                }

                switch (@typeInfo(T)) {
                    .int, .float => {},
                    .@"struct" => |struct_info| inline for (struct_info.fields) |field_info| {
                        dump_nets(field_info.type, @field(value, field_info.name), b, base, prefix ++ "." ++ field_info.name);
                    },
                    .@"union" => |union_info| inline for (union_info.fields) |field_info| {
                        if (value == @field(union_info.tag_type.?, field_info.name)) {
                            dump_nets(field_info.type, @field(value, field_info.name), b, base, prefix ++ "." ++ field_info.name);
                        }
                    },
                    .pointer => |info| if (info.size == .slice) {
                        for (value) |item| {
                            dump_nets(@TypeOf(item), item, b, base, prefix ++ "[?]");
                        }
                    },
                    .optional => |info| {
                        if (value) |v| {
                            dump_nets(info.child, v, b, base, prefix);
                        }
                    },
                    .array => |info| inline for (0..info.len) |i| {
                        dump_nets(info.child, value[i], b, base, std.fmt.comptimePrint("{s}[{}]", .{ prefix, i }));
                    },
                    else => {},
                }
            }

            pub fn get_or_generate_decouplers(base: *Part.Base, b: *Board, buf: []Part) []const Part {
                @setEvalBranchQuota(10000);

                const part: *P = @fieldParentPtr("base", base);
                var decoupler_buf_index: usize = 0;
                var decoupler_number: usize = 1;

                inline for (@typeInfo(P).@"struct".fields) |field| {
                    if (comptime std.mem.startsWith(u8, field.name, "pwr")) {
                        const Pwr = field.type;
                        const pwr = &@field(part.*, field.name);
                        inline for (@typeInfo(Pwr).@"struct".fields) |info| {
                            const field_ptr = &@field(pwr, info.name);
                            const slice: []Net_ID = if (info.type == Net_ID) field_ptr[0..1] else field_ptr;
                            if (comptime std.mem.eql(u8, info.name, "gnd")) {
                                for (slice) |*net_ptr| {
                                    if (net_ptr.* == .unset) net_ptr.* = .gnd;
                                }
                            } else {
                                const power_net = comptime std.meta.stringToEnum(Net_ID, info.name) orelse .unset;
                                for (slice) |*net_ptr| {
                                    if (maybe_set_power_net_or_generate_decoupler(Pwr, power_net, net_ptr, b, base.name, decoupler_number)) |decoupler| {
                                        if (decoupler_buf_index < buf.len) {
                                            buf[decoupler_buf_index] = decoupler;
                                            decoupler_buf_index += 1;
                                        }
                                    }
                                    decoupler_number += 1;
                                }
                            }
                        }
                    }
                }

                return buf[0..decoupler_buf_index];
            }

            fn maybe_set_power_net_or_generate_decoupler(comptime Pwr: type, comptime power_net: Net_ID, net_ptr: *Net_ID, b: *Board, part_name: []const u8, decoupler_number: usize) ?Part {
                defer if (net_ptr.* == .unset) {
                    net_ptr.* = power_net;
                };

                if (@hasDecl(Pwr, "Decouple") and Pwr.Decouple != void) {
                    const decoupler_name = b.fmt("Decoupler: {s} #{}", .{ part_name, decoupler_number });
                    if (b.get_part(decoupler_name)) |existing| return existing;

                    if (power_net.is_power() and net_ptr.* == .unset or power_net == .unset and net_ptr.is_power()) {
                        const internal_net = b.unique_net(if (power_net == .unset) "Vcc" else @tagName(power_net));
                        const external_net = if (power_net == .unset) net_ptr.* else power_net;
                        net_ptr.* = internal_net;

                        const decoupler = b.part(Pwr.Decouple, decoupler_name, .{
                            .gnd = .gnd,
                            .internal = internal_net,
                            .external = external_net,
                        });
                        return .{
                            .base = &decoupler.base,
                            .vt = comptime Part.VTable.init(Pwr.Decouple),
                        };
                    }
                }

                return null;
            }

            pub fn check_for_unset_nets(base: *Part.Base) !void {
                const part: *P = @fieldParentPtr("base", base);
                try check_for_unset_nets_generic(P, part.*, base, "");
            }

            fn check_for_unset_nets_generic(comptime T: type, value: T, base: *Part.Base, comptime prefix: []const u8) !void {
                @setEvalBranchQuota(100_000);
                if (T == Part.Base or T == void) return;
                if (T == Net_ID) {
                    if (value == .unset) {
                        log.err("{s}{s} has not been assigned\n", .{ base.name, prefix });
                        return error.UnassignedSignal;
                    }
                    return;
                }

                switch (@typeInfo(T)) {
                    .int, .float => {},
                    .@"struct" => |struct_info| inline for (struct_info.fields) |field_info| {
                        try check_for_unset_nets_generic(field_info.type, @field(value, field_info.name), base, prefix ++ "." ++ field_info.name);
                    },
                    .@"union" => |union_info| inline for (union_info.fields) |field_info| {
                        if (value == @field(union_info.tag_type.?, field_info.name)) {
                            try check_for_unset_nets_generic(field_info.type, @field(value, field_info.name), base, prefix ++ "." ++ field_info.name);
                        }
                    },
                    .pointer => |info| if (info.size == .slice) {
                        for (value) |item| {
                            try check_for_unset_nets_generic(@TypeOf(item), item, base, prefix ++ "[?]");
                        }
                    },
                    .optional => |info| if (value) |v| {
                        try check_for_unset_nets_generic(info.child, v, base, prefix);
                    },
                    .array => |info| inline for (0..info.len) |i| {
                        try check_for_unset_nets_generic(@TypeOf(value[i]), value[i], base, std.fmt.comptimePrint("{s}[{}]", .{ prefix, i }));
                    },
                    else => {},
                }
            }

            pub fn validate(base: *const Part.Base, v: *Validator, raw_state: *anyopaque, mode: Validator.Update_Mode) anyerror!void {
                const part: *const P = @fieldParentPtr("base", base);
                if (Validator_State_Pointer == void) {
                    try part.validate(v, mode);
                } else {
                    const state: Validator_State_Pointer = @alignCast(@ptrCast(raw_state));
                    try part.validate(v, state, mode);
                }
            }
        };
        return comptime &.{
            .pin_to_net = impl.pin_to_net,
            .check_config = if (has_check_config) impl.check_config else null,
            .check_for_unset_nets = impl.check_for_unset_nets,
            .get_or_generate_decouplers = impl.get_or_generate_decouplers,
            .validate = if (has_validate) impl.validate else null,
            .validator_state_bytes = @sizeOf(Validator_State),
            .validator_state_align = validator_state_alignment,
        };
    }
};

pub fn identity_remap(comptime T: type, comptime n: usize) [n]T {
    var remap: [n]T = undefined;
    for (&remap, 0..) |*out, i| {
        out.* = i;
    }
    return remap;
}

const log = std.log.scoped(.zoink);

const Net_ID = enums.Net_ID;
const Pin_ID = enums.Pin_ID;
const enums = @import("enums.zig");
const Package = @import("Package.zig");
const kicad = @import("kicad.zig");
const Validator = @import("Validator.zig");
const Board = @import("Board.zig");
const std = @import("std");
