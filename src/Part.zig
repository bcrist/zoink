base: *Base,
vt: *const VTable,

const Part = @This();

pub const Base = struct {
    package: *const Package,
    prefix: enums.Prefix,
    designator: u16 = 0,
    name: []const u8 = "",
    value: []const u8 = "",
};

pub const VTable = struct {
    finalize_power_nets: *const fn(base: *Part.Base, b: *Board) anyerror!void,
    validate: ?*const fn(base: *const Part.Base, v: *Validator, state: *anyopaque, mode: Validator.Update_Mode) anyerror!void,
    validator_state_bytes: u16,
    validator_state_align: u16,

    pub fn init(comptime P: type) *const VTable {
        const has_validate = @hasDecl(P, "validate");
        comptime var Validator_State = void;
        comptime var Validator_State_Pointer = void;
        comptime var validator_state_alignment = 1;
        if (has_validate and @typeInfo(@TypeOf(P.validate)).Fn.params.len == 4) {
            Validator_State_Pointer = @typeInfo(@TypeOf(P.validate)).Fn.params[2].type.?;
            const param_info = @typeInfo(Validator_State_Pointer).Pointer;
            std.debug.assert(param_info.Size == .One);
            Validator_State = param_info.child;
            validator_state_alignment = param_info.alignment;
        }

        const impl = struct {
            pub fn finalize_power_nets(base: *Part.Base, b: *Board) !void {
                const part: *P = @fieldParentPtr("base", base);

                if (@hasField(P, "pwr")) {
                    const Pwr = std.meta.FieldType(P, .pwr);
                    const pwr = &@field(part.*, "pwr");
                    const fields = @typeInfo(std.meta.FieldType(P, .pwr)).Struct.fields;
                    inline for (fields) |info| if (comptime std.meta.stringToEnum(Net_ID, info.name)) |net| {
                        if (info.type == Net_ID) {
                            maybe_set_power_net_or_generate_decoupler(Pwr, net, &@field(pwr, info.name), b);
                        } else {
                            for (&@field(pwr, info.name)) |*net_ptr| {
                                maybe_set_power_net_or_generate_decoupler(Pwr, net, net_ptr, b);
                            }
                        }
                    };
                }

                try check_for_unset_nets(P, part.*);
            }

            fn check_for_unset_nets(comptime T: type, value: T) !void {
                if (T == Part.Base) return;
                if (T == Net_ID) {
                    if (value == .unset) return error.UnassignedSignal;
                    return;
                }

                switch (@typeInfo(T)) {
                    .Struct => |struct_info| inline for (struct_info.fields) |field_info| {
                        try check_for_unset_nets(field_info.type, @field(value, field_info.name));
                    },
                    .Union => |union_info| inline for (union_info.fields) |field_info| {
                        if (value == @field(union_info.tag_type.?, field_info.name)) {
                            try check_for_unset_nets(field_info.type, @field(value, field_info.name));
                        }
                    },
                    else => for (value) |item| {
                        try check_for_unset_nets(@TypeOf(item), item);
                    },
                }
            }

            fn maybe_set_power_net_or_generate_decoupler(comptime Pwr: type, comptime power_net: Net_ID, net_ptr: *Net_ID, b: *Board) void {
                if (net_ptr.* != .unset) return;

                if (@hasDecl(Pwr, "Decouple") and power_net != .gnd) {
                    const decoupler = b.part(Pwr.Decouple);
                    decoupler.gnd = .gnd;
                    decoupler.internal = b.unique_net(@tagName(power_net));
                    decoupler.external = power_net;
                    net_ptr.* = decoupler.internal;
                } else {
                    net_ptr.* = power_net;
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
        return &.{
            .finalize_power_nets = impl.finalize_power_nets,
            .validate = if (has_validate) impl.validate else null,
            .validator_state_bytes = @sizeOf(Validator_State),
            .validator_state_align = validator_state_alignment,
        };
    }
};

pub fn finalize_power_nets(self: Part, b: *Board) !void {
    try self.vt.finalize_power_nets(self.base, b);
}

const Net_ID = enums.Net_ID;
const enums = @import("enums.zig");
const Package = @import("Package.zig");
const Validator = @import("Validator.zig");
const Board = @import("Board.zig");
const std = @import("std");
