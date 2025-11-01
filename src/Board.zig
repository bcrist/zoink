arena: std.mem.Allocator,
gpa: std.mem.Allocator,

dimensions: ?Dimensions = null,

bus_lookup: std.StringArrayHashMapUnmanaged([]const Net_ID) = .{},
net_lookup: std.StringArrayHashMapUnmanaged(Net_ID) = .{},
net_names: std.ArrayListUnmanaged([]const u8) = .{},

part_lookup: std.AutoArrayHashMapUnmanaged(u64, usize) = .{},
parts: std.ArrayListUnmanaged(Part) = .{},

const Board = @This();

const Dimensions = struct {
    width: kicad.Micron,
    height: kicad.Micron,
    corner_radius: kicad.Micron = .init_mm(1),
};

pub fn deinit(self: *Board) void {
    self.bus_lookup.deinit(self.gpa);
    self.net_lookup.deinit(self.gpa);
    self.net_names.deinit(self.gpa);
    self.part_lookup.deinit(self.gpa);
    self.parts.deinit(self.gpa);
    self.gpa = undefined;
    self.arena = undefined;
}

pub fn net_name(self: *const Board, net_id: Net_ID) []const u8 {
    if (net_id == .unset) return "";
    if (net_id.is_power() or net_id == .no_connect) return @tagName(net_id);
    const idx = @intFromEnum(net_id);
    if (idx >= self.net_names.items.len) return "";
    return self.net_names.items[idx];
}

pub fn print_bus_name(self: *const Board, nets: anytype, writer: *std.io.Writer) !void {
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
    if (self.net_lookup.count() == 0) {
        self.net_lookup.ensureUnusedCapacity(self.gpa, std.enums.values(Net_ID).len) catch @panic("OOM");
        for (std.enums.values(Net_ID)) |net_id| {
            self.net_lookup.putAssumeCapacityNoClobber(self.net_name(net_id), net_id);
        }
    }

    return self.net_lookup.get(name) orelse std.debug.panic("Net not found: {s}", .{ name });
}

pub fn net(self: *Board, name: []const u8) Net_ID {
    if (self.net_lookup.count() == 0) {
        self.net_lookup.ensureUnusedCapacity(self.gpa, std.enums.values(Net_ID).len) catch @panic("OOM");
        for (std.enums.values(Net_ID)) |net_id| {
            self.net_lookup.putAssumeCapacityNoClobber(self.net_name(net_id), net_id);
        }
    }

    const gop = self.net_lookup.getOrPut(self.gpa, name) catch @panic("OOM");
    if (gop.found_existing) {
        return gop.value_ptr.*;
    }

    if (self.net_names.items.len == 0) {
        self.net_names.append(self.gpa, "") catch @panic("OOM");
    }

    const net_id: Net_ID = @enumFromInt(self.net_names.items.len);
    gop.key_ptr.* = name;
    gop.value_ptr.* = net_id;
    self.net_names.append(self.gpa, name) catch @panic("OOM");
    return net_id;
}

pub fn fmt(self: *Board, comptime format: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrint(self.arena, format, args) catch @panic("OOM");
}

pub fn unique_net(self: *Board, comptime name_prefix: []const u8) Net_ID {
    const name = self.fmt(name_prefix ++ "#{}", .{ self.net_names.items.len });
    return self.net(name);
}

pub fn unique_part_name(self: *Board, comptime name_prefix: []const u8) []const u8 {
    return self.fmt(name_prefix ++ "#{}", .{ self.parts.items.len });
}

pub fn get_bus(self: *Board, name: []const u8) []const Net_ID {
    return self.bus_lookup.get(name) orelse std.debug.panic("Bus not found: {s}", .{ name });
}

pub fn bus(self: *Board, comptime name: []const u8, comptime bits: comptime_int) [bits]Net_ID {
    @setEvalBranchQuota(100_000);
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

pub fn part(self: *Board, comptime Type: type, name: []const u8, init: Type) *Type {
    self.part_lookup.ensureUnusedCapacity(self.gpa, 1) catch @panic("OOM");
    self.parts.ensureUnusedCapacity(self.gpa, 1) catch @panic("OOM");
    const name_owned = self.arena.dupe(u8, name) catch @panic("OOM");
    const ptr = self.arena.create(Type) catch @panic("OOM");
    ptr.* = init;
    ptr.base.name = name_owned;
    self.parts.appendAssumeCapacity(.{
        .base = &ptr.base,
        .vt = comptime Part.VTable.init(Type),
    });
    const hash = std.hash.Wyhash.hash(0x057c11, name_owned);
    if (self.part_lookup.contains(hash)) {
        log.err("Duplicate part name or hash collision for name: {s}", .{ name_owned });
    }
    self.part_lookup.putAssumeCapacityNoClobber(hash, self.parts.items.len - 1);
    return ptr;
}

pub fn finish_configuration(self: *Board, temp: std.mem.Allocator) !void {
    { // call check_config functions
        // This process may add new parts, so we can't assume self.parts.items will be stable
        var i: usize = self.parts.items.len;
        while (i > 0) {
            i -= 1;
            const p = self.parts.items[i];
            if (p.vt.check_config) |func| {
                try func(p.base, self);
            }
        }
    }

    { // generate decoupling caps and ensure power nets are set
        // This process may add new parts, so we can't assume self.parts.items will be stable
        var i: usize = self.parts.items.len;
        while (i > 0) {
            i -= 1;
            try self.parts.items[i].finalize_power_nets(self);
        }
    }

    { // assign designators and default footprints
        var designators = std.EnumArray(Prefix, std.AutoHashMapUnmanaged(u16, *Part.Base)).initFill(.{});
        defer for (&designators.values) |*map| {
            map.deinit(temp);
        };

        for (self.parts.items) |p| {
            if (p.base.footprint == null) {
                p.base.footprint = p.base.package.default_footprint;
            }

            if (p.base.designator == 0) continue;
            const designator_map = designators.getPtr(p.base.prefix);
            if (designator_map.contains(p.base.designator)) {
                log.err("Duplicate designator: {t}{}", .{ p.base.prefix, p.base.designator });
            }
            designator_map.putNoClobber(temp, p.base.designator, p.base) catch @panic("OOM");
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

pub fn generate_or_update_kicad_pcb_file(self: *Board, temp: std.mem.Allocator, path: []const u8, options: kicad.Writer_Options) !void {
    const prev_contents = std.fs.cwd().readFileAlloc(temp, path, 1_000_000_000) catch |err| switch (err) {
        error.FileNotFound => try temp.alloc(u8, 0),
        else => return err,
    };
    defer temp.free(prev_contents);

    var buf: [16384]u8 = undefined;
    var af = try std.fs.cwd().atomicFile(path, .{
        .make_path = true,
        .write_buffer = &buf,
    });
    defer af.deinit();
    try self.generate_or_update_kicad_pcb(temp, &af.file_writer.interface, prev_contents, options);
    try af.finish();
}

pub fn generate_or_update_kicad_pcb(self: *Board, temp: std.mem.Allocator, writer: *std.io.Writer, prev_contents: []const u8, options: kicad.Writer_Options) !void {
    var w = sx.writer(temp, writer);
    w.indent = "\t";
    defer w.deinit();

    if (prev_contents.len > 0) {
        var reader = std.io.Reader.fixed(prev_contents);
        var r = sx.reader(temp, &reader);
        defer r.deinit();

        log.info("Updating existing pcb", .{});
        self.update_kicad_pcb(&r, &w, options) catch |err| switch (err) {
            error.SExpressionSyntaxError => {
                var buf: [64]u8 = undefined;
                var stderr = std.fs.File.stderr().writer(&buf);

                const ctx = try r.token_context();
                try ctx.print_for_string(prev_contents, &stderr.interface, 160);
                try stderr.interface.flush();
                return err;
            },
            else => return err,
        };
    } else {
        log.info("Generating pcb", .{});
        try self.generate_kicad_pcb(&w, options);
    }
}

pub fn generate_kicad_pcb(self: *Board, w: *sx.Writer, options: kicad.Writer_Options) !void {
    try w.expression_expanded("kicad_pcb");
        try w.expression("version");
        try w.int(20241229, 10);
        try w.close();

        try w.expression("generator");
        try w.string_quoted("pcbnew");
        try w.close();

        try w.expression("generator_version");
        try w.string_quoted("9.0");
        try w.close();

        try w.expression_expanded("general");
            try w.expression("thickness");
            try w.float(1.59);
            try w.close();

            try w.expression("legacy_teardrops");
            try w.string("no");
            try w.close();
        try w.close();

        try w.expression("paper");
        try w.string_quoted("A4");
        try w.close();

        try write_layers(w);
        try write_setup(w);
        try self.write_nets(w);

        try self.write_footprints(w, options);

        try self.write_board_outline(w);

        try w.expression("embedded_fonts");
        try w.string("no");
        try w.close();
    try w.done();
}


fn update_kicad_pcb(self: *Board, r: *sx.Reader, w: *sx.Writer, options: kicad.Writer_Options) !void {
    try r.require_expression("kicad_pcb");
    try w.expression_expanded("kicad_pcb");

    try r.require_expression("version");
    try w.expression("version");
    try r.require_string("20241229");
    try w.int(20241229, 10);
    try r.require_close();
    try w.close();

    try r.require_expression("generator");
    try w.expression("generator");
    try r.require_string("pcbnew");
    try w.string_quoted("pcbnew");
    try r.require_close();
    try w.close();

    try r.require_expression("generator_version");
    try w.expression("generator_version");
    try r.require_string("9.0");
    try w.string_quoted("9.0");
    try r.require_close();
    try w.close();

    try copy_until_expr(r, w, &.{ "net", "footprint" });

    while (try r.expression("net")) try r.ignore_remaining_expression();
    try self.write_nets(w);

    try copy_until_expr(r, w, &.{ "footprint" });

    try self.update_footprints(r, w, options);

    if (options.update_board_outline) {
        try self.write_board_outline(w);
        while (true) {
            try copy_until_expr(r, w, &.{ "gr_line", "gr_arc", "gr_rect" });
            if (try kicad.Line.read(r, "gr_line")) |line| {
                if ((line.uuid.raw | 0x7) != 0x00000000_8888_8888_8888_000000000007) {
                    try line.write(w, "gr_line");
                }
            } else if (try kicad.Arc.read(r, "gr_arc")) |arc| {
                if ((arc.uuid.raw | 0x7) != 0x00000000_8888_8888_8888_000000000007) {
                    try arc.write(w, "gr_arc");
                }
            } else if (try kicad.Rect.read(r, "gr_rect")) |rect| {
                if ((rect.uuid.raw | 0x7) != 0x00000000_8888_8888_8888_000000000007) {
                    try rect.write(w, "gr_rect");
                }
            } else break;
        }
    } else {
        try copy_until_end_of_expr(r, w);
    }

    try r.require_close();
    try w.done();
    try r.require_done();
}

fn copy_until_expr(r: *sx.Reader, w: *sx.Writer, exprs: []const []const u8) !void {
    while (true) {
        w.set_compact(try r.is_compact());
        if (try r.any_string_quoted()) |str| {
            try w.string_quoted(str);
        } else if (try r.any_string()) |str| {
            try w.string(str);
        } else {
            r.set_peek(true);
            for (exprs) |expr| {
                if (try r.expression(expr)) {
                    r.set_peek(false);
                    return;
                }
            }
            r.set_peek(false);
            if (try r.any_expression()) |ex| {
                try w.expression(ex);
                try copy_until_end_of_expr(r, w);
                try r.require_close();
                try w.close();
            } else return;
        }
    }
}

fn copy_until_end_of_expr(r: *sx.Reader, w: *sx.Writer) !void {
    while (true) {
        w.set_compact(try r.is_compact());
        if (try r.any_string_quoted()) |str| {
            try w.string_quoted(str);
        } else if (try r.any_string()) |str| {
            try w.string(str);
        } else if (try r.any_expression()) |expr| {
            try w.expression(expr);
            try copy_until_end_of_expr(r, w);
            try r.require_close();
            try w.close();
        } else return;
    }
}

fn write_layers(w: *sx.Writer) !void {
    try w.expression_expanded("layers");

    const layers = [_]kicad.Layer {
        .copper_front,
        .copper_internal_1,
        .copper_internal_2,
        .copper_back,
        .adhesive_front,
        .adhesive_back,
        .paste_front,
        .paste_back,
        .silkscreen_front,
        .silkscreen_back,
        .soldermask_front,
        .soldermask_back,
        .user_drawings,
        .user_comments,
        .user_eco_1,
        .user_eco_2,
        .edges,
        .margins,
        .courtyard_front,
        .courtyard_back,
        .fab_front,
        .fab_back,
        .names,
        .values,
        .designators,
    };

    for (layers) |layer| {
        const name = layer.get_kicad_name(.{});
        const long_name = layer.get_kicad_name(.{ .long_form = true });
        try w.open();
        try w.int(@intFromEnum(layer), 10);
        try w.string_quoted(name);
        try w.string(if (layer.is_copper()) "signal" else "user");
        if (!std.mem.eql(u8, name, long_name)) {
            try w.string_quoted(long_name);
        }
        try w.close();
    }

    try w.close();
}

fn write_setup(w: *sx.Writer) !void {
    try w.expression_expanded("setup");
    try w.expression_expanded("stackup");

    try write_stackup_layer(w, "F.SilkS", "Top Silk Screen", .{ .color = "White" });
    try write_stackup_layer(w, "F.Paste", "Top Solder Paste", .{});
    try write_stackup_layer(w, "F.Mask", "Top Solder Mask", .{ .color = "Green", .thickness = 0.01 });
    try write_stackup_layer(w, "F.Cu", "copper", .{ .thickness = 0.035 });
    try write_stackup_layer(w, "dielectric 1", "prepreg", .{ .thickness = 0.2, .material = "FR4", .epsilon_r = 4.6, .loss_tangent = 0.02 });
    try write_stackup_layer(w, "In1.Cu", "copper", .{ .thickness = 0.0175 });
    try write_stackup_layer(w, "dielectric 2", "core", .{ .thickness = 1.065, .material = "FR4", .epsilon_r = 4.6, .loss_tangent = 0.02 });
    try write_stackup_layer(w, "In2.Cu", "copper", .{ .thickness = 0.0175 });
    try write_stackup_layer(w, "dielectric 3", "prepreg", .{ .thickness = 0.2, .material = "FR4", .epsilon_r = 4.6, .loss_tangent = 0.02 });
    try write_stackup_layer(w, "B.Cu", "copper", .{ .thickness = 0.035 });
    try write_stackup_layer(w, "B.Mask", "Bottom Solder Mask", .{ .color = "Green", .thickness = 0.01 });
    try write_stackup_layer(w, "B.Paste", "Bottom Solder Paste", .{});
    try write_stackup_layer(w, "B.SilkS", "Bottom Silk Screen", .{ .color = "White" });

    try w.expression("copper_finish");
    try w.string_quoted("ENIG");
    try w.close();

    try w.expression("dielectric_constraints");
    try w.string("yes");
    try w.close();

    try w.close();

    try w.expression("pad_to_mask_clearance");
    try w.float(0.05);
    try w.close();

    try w.expression("solder_mask_min_width");
    try w.float(0.2);
    try w.close();

    try w.expression("pad_to_paste_clearance");
    try w.float(-0.05);
    try w.close();

    try w.expression("pad_to_paste_clearance_ratio");
    try w.float(-0.01);
    try w.close();

    try w.expression("allow_soldermask_bridges_in_footprints");
    try w.string("no");
    try w.close();

    try w.expression("tenting");
    try w.string("front");
    try w.string("back");
    try w.close();

    try w.close();
}

const Stackup_Extra = struct {
    color: []const u8 = "",
    thickness: f64 = 0,
    material: []const u8 = "",
    epsilon_r: f64 = 0,
    loss_tangent: f64 = 0,
};

fn write_stackup_layer(w: *sx.Writer, name: []const u8, layer_type: []const u8, extra: Stackup_Extra) !void {
    try w.expression("layer");
    try w.string_quoted(name);
    w.set_compact(false);

    try w.expression("type");
    try w.string_quoted(layer_type);
    try w.close();

    if (extra.color.len > 0) {
        try w.expression("color");
        try w.string_quoted(extra.color);
        try w.close();
    }

    if (extra.thickness != 0) {
        try w.expression("thickness");
        try w.float(extra.thickness);
        try w.close();
    }

    if (extra.material.len > 0) {
        try w.expression("material");
        try w.string_quoted(extra.material);
        try w.close();
    }
    
    if (extra.epsilon_r != 0) {
        try w.expression("epsilon_r");
        try w.float(extra.epsilon_r);
        try w.close();
    }
    
    if (extra.loss_tangent != 0) {
        try w.expression("loss_tangent");
        try w.float(extra.loss_tangent);
        try w.close();
    }

    try w.close();
}

fn write_nets(self: *Board, w: *sx.Writer) !void {
    for (std.enums.values(Net_ID)) |net_id| {
        if (net_id == .no_connect) continue;
        try w.expression("net");
        try w.int(net_id.kicad_net_id(), 10);
        try w.string_quoted(self.net_name(net_id));
        try w.close();
    }
    for (0.., self.net_names.items) |i, name| {
        if (i == 0) continue;
        const net_id: Net_ID = @enumFromInt(i);
        try w.expression("net");
        try w.int(net_id.kicad_net_id(), 10);
        try w.string_quoted(name);
        try w.close();
    }
}

fn write_footprints(self: *Board, w: *sx.Writer, options: kicad.Writer_Options) !void {
    var temp: std.heap.ArenaAllocator = .init(self.gpa);
    defer temp.deinit();

    try self.write_new_footprints(&temp, null, w, options);
}

fn update_footprints(self: *Board, r: *sx.Reader, w: *sx.Writer, options: kicad.Writer_Options) !void {
    var written_footprints: std.AutoHashMapUnmanaged(u64, void) = .empty;
    defer written_footprints.deinit(self.gpa);

    var temp: std.heap.ArenaAllocator = .init(self.gpa);
    defer temp.deinit();

    while (try kicad.Footprint.read(r, temp.allocator())) |existing_fp| {
        defer _ = temp.reset(.retain_capacity);
        if (existing_fp.uuid.to_hash()) |hash| {
            if (self.part_lookup.get(hash)) |part_index| {
                if (options.reset_footprints_outside_board and (existing_fp.location.x.um < 0 or existing_fp.location.y.um < 0)) {
                    continue;
                }
                log.info("Updating existing footprint: {f}", .{ existing_fp.uuid });
                try written_footprints.put(self.gpa, hash, {});
                const p = self.parts.items[part_index];
                try self.write_footprint(hash, p, .origin, existing_fp, temp.allocator(), w, options);
            } else {
                log.warn("Deleting obsolete footprint: {f}", .{ existing_fp.uuid });
            }
        } else {
            log.warn("Deleting footprint with invalid UUID: {f}", .{ existing_fp.uuid });
        }
    }

    try self.write_new_footprints(&temp, &written_footprints, w, options);
}

fn write_new_footprints(self: *Board, temp: *std.heap.ArenaAllocator, maybe_written_footprints: ?*std.AutoHashMapUnmanaged(u64, void), w: *sx.Writer, options: kicad.Writer_Options) !void {
    var bounding_boxes: std.ArrayList(Bounding_Box) = .empty;
    defer bounding_boxes.deinit(self.gpa);

    const board_outline: Bounding_Box = .{
        .hash = 0,
        .min = @splat(0),
        .max = if (self.dimensions) |dim| .{
            dim.width.mm(f64),
            dim.height.mm(f64),
        } else @splat(100),
    };

    for (self.part_lookup.keys(), self.part_lookup.values()) |hash, part_index| {
        if (maybe_written_footprints) |written| if (written.contains(hash)) continue;
        log.info("Adding new footprint: {X:0<8}", .{ hash });
        const p = self.parts.items[part_index];
        if (p.base.footprint) |base_fp| {
            if (p.base.location) |loc| {
                try self.write_footprint(hash, p, loc, null, temp.allocator(), w, options);
            } else {
                try bounding_boxes.append(self.gpa, .init_from_footprint(base_fp.*, hash));
            }
        }
    }

    const len = bounding_boxes.items.len;

    var rng: std.Random.Xoshiro256 = .init(1234);
    const rnd = rng.random();

    for (bounding_boxes.items) |*bb| {
        if (len <= 10) {
            bb.unapplied_offset = .{
                @floatFromInt(rnd.intRangeAtMostBiased(isize, -10, -1)),
                @floatFromInt(rnd.intRangeAtMostBiased(isize, 0, @intFromFloat(board_outline.max[1] / 2))),
            };
        } else { 
            bb.unapplied_offset = .{
                @floatFromInt(rnd.intRangeAtMostBiased(isize, -10, -1)),
                @floatFromInt(rnd.intRangeAtMostBiased(isize, 0, @intFromFloat(board_outline.max[1]))),
            };
        }
        bb.apply_offset();
    }

    const max_iterations = 10_000;
    for (0..max_iterations) |iteration| {
        var found_intersection = false;

        if (len > 1) {
            for (0.., bounding_boxes.items[0 .. len - 1]) |i, *bb0| {
                for (bounding_boxes.items[i + 1 ..]) |*bb1| {
                    if (bb0.check_and_resolve_intersection(bb1, rnd)) {
                        found_intersection = true;
                    }
                }
            }
        }

        for (bounding_boxes.items) |*bb| {
            if (bb.check_and_resolve_intersection_static(board_outline, rnd)) {
                found_intersection = true;
            }
        }

        if (found_intersection) {
            for (bounding_boxes.items) |*bb| {
                bb.apply_offset();
            }
        } else {
            log.debug("Found non-overlapping positions for new footprints after {} iterations", .{ iteration + 1 });
            break;
        }
    } else {
        log.warn("Failed to find non-overlapping positions for footprints after {} iterations", .{ max_iterations });
    }

    for (bounding_boxes.items) |bb| {
        defer _ = temp.reset(.retain_capacity);
        const part_index = self.part_lookup.get(bb.hash) orelse unreachable;
        const p = self.parts.items[part_index];
        try self.write_footprint(bb.hash, p, .init_mm(bb.offset[0], bb.offset[1]), null, temp.allocator(), w, options);
    }
}

fn write_footprint(self: *Board, hash: u64, p: Part, initial_location: kicad.Location, existing_fp: ?kicad.Footprint, arena: std.mem.Allocator, w: *sx.Writer, options: kicad.Writer_Options) !void {
    var designator_buf: [64]u8 = undefined;
    var designator = std.io.Writer.fixed(&designator_buf);
    try designator.print("{t}{}", .{ p.base.prefix, p.base.designator });

    if (p.base.footprint) |base_fp| {
        var fp = base_fp.*;
        fp.uuid = .init_v8_from_hash(hash);
        fp.location = p.base.location orelse if (existing_fp) |efp| efp.location else initial_location;
        const needed_rotation: kicad.Rotation = p.base.rotation orelse if (existing_fp) |efp| efp.rotation else .none;
        const needed_layer: kicad.Layer = p.base.layer orelse if (existing_fp) |efp| efp.layer else .copper_front;
        fp.locked = p.base.locked orelse if (existing_fp) |efp| efp.locked else false;
        fp.do_not_populate = !p.base.populate;
        fp.exclude_from_bom = !p.base.include_in_bom;
        fp.exclude_from_position_files = !p.base.include_in_position_files;
        
        const line_height = 0.6;

        var properties: std.ArrayList(kicad.Property) = .empty;
        try properties.appendSlice(arena, &.{
            .{
                .name = "Description",
                .text = .{
                    .content = p.base.description,
                    .location = .{ .x = .zero, .y = .init_mm(line_height * -2) },
                    .style = .{
                        .parent = &kicad.Text_Style.names_and_descriptions,
                        .hidden = p.base.description.len == 0,
                    },
                },
            },
            .{
                .name = "Reference",
                .text = .{
                    .content = designator.buffered(),
                    .location = .{ .x = .zero, .y = .init_mm(-line_height) },
                    .style = .designators,
                },
            },
            .{
                .name = "Name",
                .text = .{
                    .content = p.base.name,
                    .style = .names_and_descriptions,
                    .location = .{ .x = .zero, .y = .init_mm(line_height) },
                },
            },
            .{
                .name = "Value",
                .text = .{
                    .content = p.base.value,
                    .location = .{ .x = .zero, .y = .init_mm(line_height * 2) },
                    .style = .{
                        .parent = &kicad.Text_Style.values,
                        .hidden = p.base.value.len == 0,
                    },
                },
            },
            .{
                .name = "Datasheet",
                .text = .{
                    .content = "",
                    .location = .{ .x = .zero, .y = .init_mm(line_height * 3) },
                    .style = .{
                        .parent = &kicad.Text_Style.names_and_descriptions,
                        .hidden = true,
                    },
                },
            },
        });
        
        if (needed_layer != fp.layer or needed_rotation.deg != fp.rotation.deg) {
            const rotation_delta = needed_rotation.deg - fp.rotation.deg;

            var new_pads: std.ArrayList(kicad.Pad) = try .initCapacity(arena, fp.pads.len);
            var new_lines: std.ArrayList(kicad.Line) = try .initCapacity(arena, fp.lines.len);
            var new_rects: std.ArrayList(kicad.Rect) = try .initCapacity(arena, fp.rects.len);
            var new_polys: std.ArrayList(kicad.Polygon) = try .initCapacity(arena, fp.polygons.len);
            var new_circles: std.ArrayList(kicad.Circle) = try .initCapacity(arena, fp.circles.len);
            var new_arcs: std.ArrayList(kicad.Arc) = try .initCapacity(arena, fp.arcs.len);
            var new_texts: std.ArrayList(kicad.Text) = try .initCapacity(arena, fp.texts.len);

            for (fp.pads) |old_pad| {
                var pad = old_pad;
                if (needed_layer != fp.layer) {
                    pad.layers = kicad.Layer.flip_sides_set(pad.layers);
                    pad.location.y.um *= -1;
                    pad.shape_offset.y.um *= -1;
                    pad.rotation.deg *= -1;
                }
                pad.rotation.deg += rotation_delta;
                try new_pads.append(arena, pad);
            }

            for (fp.lines) |old_line| {
                var line = old_line;
                if (needed_layer != fp.layer) {
                    line.layer = line.layer.flip_sides();
                    line.start.y.um *= -1;
                    line.end.y.um *= -1;
                }
                try new_lines.append(arena, line);
            }

            for (fp.rects) |old_rect| {
                var rect = old_rect;
                if (needed_layer != fp.layer) {
                    rect.layer = rect.layer.flip_sides();
                    rect.start.y.um *= -1;
                    rect.end.y.um *= -1;
                }
                if (@rem(rotation_delta, 90) == 0) {
                    try new_rects.append(arena, rect);
                } else {
                    const x0 = rect.start.x.mm(f64);
                    const x1 = rect.end.x.mm(f64);
                    const y0 = rect.start.y.mm(f64);
                    const y1 = rect.end.y.mm(f64);
                    const poly: kicad.Polygon = .{
                        .points = try arena.dupe(kicad.Location, &.{
                            .init_mm(x0, y0),
                            .init_mm(x1, y0),
                            .init_mm(x1, y1),
                            .init_mm(x0, y1),
                        }),
                        .stroke = rect.stroke,
                        .fill = rect.fill,
                        .layer = rect.layer,
                        .uuid = rect.uuid,
                    };
                    try new_polys.append(arena, poly);
                }
            }

            for (fp.polygons) |old_poly| {
                var poly = old_poly;
                const pts = try arena.dupe(kicad.Location, old_poly.points);
                if (needed_layer != fp.layer) {
                    poly.layer = poly.layer.flip_sides();
                    for (pts) |*pt| {
                        pt.y.um *= -1;
                    }
                }
                poly.points = pts;
                try new_polys.append(arena, poly);
            }

            for (fp.circles) |old_circle| {
                var circle = old_circle;
                if (needed_layer != fp.layer) {
                    circle.layer = circle.layer.flip_sides();
                    circle.center.y.um *= -1;
                    circle.end.y.um *= -1;
                }
                try new_circles.append(arena, circle);
            }

            for (fp.arcs) |old_arc| {
                var arc = old_arc;
                if (needed_layer != fp.layer) {
                    arc.layer = arc.layer.flip_sides();
                    arc.start.y.um *= -1;
                    arc.center.y.um *= -1;
                    arc.end.y.um *= -1;
                    arc.clockwise = !arc.clockwise;
                }
                try new_arcs.append(arena, arc);
            }

            for (fp.texts) |old_txt| {
                var txt = old_txt;
                if (needed_layer != fp.layer) {
                    txt.style.layer = txt.style.get_layer().flip_sides();
                    if (txt.style.get_layer() != old_txt.style.get_layer()) {
                        txt.style.mirrored = !txt.style.is_mirrored();
                    }
                    txt.rotation.deg *= -1;
                }
                txt.rotation.deg += rotation_delta;
                try new_texts.append(arena, txt);
            }

            for (properties.items) |*old_prop| {
                var prop = old_prop.*;
                if (needed_layer != fp.layer) {
                    prop.text.style.layer = prop.text.style.get_layer().flip_sides();
                    if (prop.text.style.get_layer() != old_prop.text.style.get_layer()) {
                        prop.text.style.mirrored = !prop.text.style.is_mirrored();
                    }
                    prop.text.rotation.deg *= -1;
                }
                prop.text.rotation.deg += rotation_delta;
                old_prop.* = prop;
            }

            fp.layer = needed_layer;
            fp.rotation.deg = needed_rotation.deg;
            fp.pads = new_pads.items;
            fp.lines = new_lines.items;
            fp.rects = new_rects.items;
            fp.polygons = new_polys.items;
            fp.circles = new_circles.items;
            fp.arcs = new_arcs.items;
            fp.texts = new_texts.items;
        }

        if (existing_fp) |efp| {
            for (efp.properties) |prop| {
                if (std.mem.eql(u8, prop.name, "Description")) {
                    properties.items[0].text.uuid = prop.text.uuid;
                    if (!options.reset_property_attributes) {
                        properties.items[0].text.location = prop.text.location;
                        properties.items[0].text.rotation = prop.text.rotation;
                        properties.items[0].text.style = prop.text.style;
                    }
                } else if (std.mem.eql(u8, prop.name, "Reference")) {
                    properties.items[1].text.uuid = prop.text.uuid;
                    if (!options.reset_property_attributes) {
                        properties.items[1].text.location = prop.text.location;
                        properties.items[1].text.rotation = prop.text.rotation;
                        properties.items[1].text.style = prop.text.style;
                    }
                } else if (std.mem.eql(u8, prop.name, "Name")) {
                    properties.items[2].text.uuid = prop.text.uuid;
                    if (!options.reset_property_attributes) {
                        properties.items[2].text.location = prop.text.location;
                        properties.items[2].text.rotation = prop.text.rotation;
                        properties.items[2].text.style = prop.text.style;
                    }
                } else if (std.mem.eql(u8, prop.name, "Value")) {
                    properties.items[3].text.uuid = prop.text.uuid;
                    if (!options.reset_property_attributes) {
                        properties.items[3].text.location = prop.text.location;
                        properties.items[3].text.rotation = prop.text.rotation;
                        properties.items[3].text.style = prop.text.style;
                    }
                } else if (std.mem.eql(u8, prop.name, "Datasheet")) {
                    properties.items[4].text = prop.text;
                    if (!options.reset_property_attributes) {
                        properties.items[4].text.location = prop.text.location;
                        properties.items[4].text.rotation = prop.text.rotation;
                        properties.items[4].text.style = prop.text.style;
                    }
                } else {
                    try properties.append(arena, prop);
                }
            }
        }

        fp.properties = properties.items;

        try fp.write(w, self, p, options);
    } else {
        log.err("No footprint specified for part: {s}", .{ p.base.name });
    }
}

fn write_board_outline(b: *Board, w: *sx.Writer) !void {
    const dimensions: Board.Dimensions = b.dimensions orelse .{
        .width = .init_mm(100),
        .height = .init_mm(100),
    };
    const stroke: kicad.Stroke_Style = .{
        .width = .init_mm(0.01),
    };
    if (dimensions.corner_radius.um == 0) {
        const rect: kicad.Rect = .{
            .start = .origin,
            .end = .{
                .x = dimensions.width,
                .y = dimensions.height,
            },
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000000 },
        };
        try rect.write(w, "gr_rect");
    } else {
        try (kicad.Line {
            .start = .{
                .x = dimensions.corner_radius,
                .y = .zero,
            },
            .end = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = .zero,
            },
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000000 },
        }).write(w, "gr_line");

        try (kicad.Line {
            .start = .{
                .x = dimensions.width,
                .y = dimensions.corner_radius,
            },
            .end = .{
                .x = dimensions.width,
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000001 },
        }).write(w, "gr_line");

        try (kicad.Line {
            .start = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = dimensions.height,
            },
            .end = .{
                .x = dimensions.corner_radius,
                .y = dimensions.height,
            },
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000002 },
        }).write(w, "gr_line");

        try (kicad.Line {
            .start = .{
                .x = .zero,
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .end = .{
                .x = .zero,
                .y = dimensions.corner_radius,
            },
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000003 },
        }).write(w, "gr_line");

        try (kicad.Arc {
            .start = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = .zero,
            },
            .center = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = dimensions.corner_radius,
            },
            .end = .{
                .x = dimensions.width,
                .y = dimensions.corner_radius,
            },
            .clockwise = true,
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000004 },
        }).write(w, "gr_arc");

        try (kicad.Arc {
            .start = .{
                .x = dimensions.width,
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .center = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .end = .{
                .x = .{ .um = dimensions.width.um - dimensions.corner_radius.um },
                .y = dimensions.height,
            },
            .clockwise = true,
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000005 },
        }).write(w, "gr_arc");

        try (kicad.Arc {
            .start = .{
                .x = dimensions.corner_radius,
                .y = dimensions.height,
            },
            .center = .{
                .x = dimensions.corner_radius,
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .end = .{
                .x = .zero,
                .y = .{ .um = dimensions.height.um - dimensions.corner_radius.um },
            },
            .clockwise = true,
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000006 },
        }).write(w, "gr_arc");

        try (kicad.Arc {
            .start = .{
                .x = .zero,
                .y = dimensions.corner_radius,
            },
            .center = .{
                .x = dimensions.corner_radius,
                .y = dimensions.corner_radius,
            },
            .end = .{
                .x = dimensions.corner_radius,
                .y = .zero,
            },
            .clockwise = true,
            .stroke = stroke,
            .layer = .edges,
            .uuid = .{ .raw = 0x00000000_8888_8888_8888_000000000007 },
        }).write(w, "gr_arc");
    }
}

const log = std.log.scoped(.zoink);

const Bounding_Box = @import("Bounding_Box.zig");
const kicad = @import("kicad.zig");
const Part = @import("Part.zig");
const Net_ID = enums.Net_ID;
const Prefix = enums.Prefix;
const enums = @import("enums.zig");
const sx = @import("sx");
const zm = @import("zm");
const std = @import("std");
