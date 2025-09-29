const state = struct {
    var pass_action: sokol.gfx.PassAction = .{};
};

const font_data = @embedFile("font.ttf");
var font: ?*ig.Font = null;

var sig: sokol_imgui.State = undefined;

export fn init() void {
    ig.check_version();

    sokol.gfx.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    
    sig = sokol_imgui.State.init(.{
        .allocator = std.heap.page_allocator,
    }) catch |err| {
        std.debug.panic("Failed to set up Sokol ImGui: {}", .{ err });
    };

    font = ig.get_io().fonts.?.add_font_from_memory_ttf_static(font_data, 18.5, .{});

    zgp.setup(.{
        .allocator = std.heap.page_allocator,
        .max_vertices = 1024 * 1024,
    }) catch |err| {
        std.debug.panic("Failed to set up ZGP: {}", .{ err });
    };

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.05, .g = 0.25, .b = 0.15, .a = 1.0 },
    };
}

var t: f64 = 0;

const Package_Data = union (enum) {
    smd: zoink.footprints.SMD_Data,

    pub fn format(self: Package_Data, writer: *std.io.Writer) !void {
        switch (self) {
            .smd => |data| try data.format(writer),
        }
    }
};

const package_options: []const Package_Data = &.{
    .{ .smd = zoink.packages.SOT23.data },
    .{ .smd = zoink.packages.SOT23_5.data },
    .{ .smd = zoink.packages.SOT23_6.data },
    .{ .smd = zoink.packages.SOT23_8.data },
    //.{ .sot = zoink.packages.SOT143.data },
    //.{ .sot = zoink.packages.SOT223.data },
    //.{ .sot = zoink.packages.SOT223_5.data },
    .{ .smd = zoink.packages.SOJ_14.data },
    .{ .smd = zoink.packages.SOJ_16.data },
    .{ .smd = zoink.packages.SOJ_18.data },
    .{ .smd = zoink.packages.SOJ_20.data },
    .{ .smd = zoink.packages.SOJ_24.data },
    .{ .smd = zoink.packages.SOJ_26.data },
    .{ .smd = zoink.packages.SOJ_28_300.data },
    .{ .smd = zoink.packages.SOJ_32_300.data },
    .{ .smd = zoink.packages.SOJ_42_300.data },
    .{ .smd = zoink.packages.SOJ_28_400.data },
    .{ .smd = zoink.packages.SOJ_32_400.data },
    .{ .smd = zoink.packages.SOJ_34_400.data },
    .{ .smd = zoink.packages.SOJ_36_400.data },
    .{ .smd = zoink.packages.SOJ_40_400.data },
    .{ .smd = zoink.packages.SOJ_42_400.data },
    .{ .smd = zoink.packages.SOJ_44.data },
    .{ .smd = zoink.packages.PLCC_18.data },
    .{ .smd = zoink.packages.PLCC_22.data },
    .{ .smd = zoink.packages.PLCC_28_9x5.data },
    .{ .smd = zoink.packages.PLCC_32.data },
    .{ .smd = zoink.packages.PLCC_20L.data },
    .{ .smd = zoink.packages.PLCC_28L.data },
    .{ .smd = zoink.packages.PLCC_44L.data },
    .{ .smd = zoink.packages.PLCC_52L.data },
    .{ .smd = zoink.packages.PLCC_68L.data },
    .{ .smd = zoink.packages.PLCC_84L.data },
    .{ .smd = zoink.packages.PLCC_100L.data },
    .{ .smd = zoink.packages.PLCC_124L.data },
    .{ .smd = zoink.packages.PLCC_20M.data },
    .{ .smd = zoink.packages.PLCC_28M.data },
    .{ .smd = zoink.packages.PLCC_44M.data },
    .{ .smd = zoink.packages.PLCC_52M.data },
    .{ .smd = zoink.packages.PLCC_68M.data },
    .{ .smd = zoink.packages.PLCC_84M.data },
    .{ .smd = zoink.packages.PLCC_100M.data },
    .{ .smd = zoink.packages.PLCC_124M.data },
    .{ .smd = zoink.packages.SOIC_8_150.data },
    .{ .smd = zoink.packages.SOIC_14_150.data },
    .{ .smd = zoink.packages.SOIC_16_150.data },
    .{ .smd = zoink.packages.SOIC_14_200.data },
    .{ .smd = zoink.packages.SOIC_16_200.data },
    .{ .smd = zoink.packages.SOIC_20_200.data },
    .{ .smd = zoink.packages.SOIC_8_300.data },
    .{ .smd = zoink.packages.SOIC_14_300.data },
    .{ .smd = zoink.packages.SOIC_16_300.data },
    .{ .smd = zoink.packages.SOIC_18_300.data },
    .{ .smd = zoink.packages.SOIC_20_300.data },
    .{ .smd = zoink.packages.SOIC_24_300.data },
    .{ .smd = zoink.packages.SOIC_28_300.data },
    .{ .smd = zoink.packages.SOIC_24_330.data },
    .{ .smd = zoink.packages.SOIC_28_330.data },
    .{ .smd = zoink.packages.SOIC_44_500.data },
    .{ .smd = zoink.packages.SOIC_48_500.data },
    .{ .smd = zoink.packages.TQFP_100_14mm.data },
    .{ .smd = zoink.packages.TSOP_II_32.data },
    .{ .smd = zoink.packages.TSOP_II_44.data },
    .{ .smd = zoink.packages.SSOP_8.data },
    .{ .smd = zoink.packages.SSOP_14.data },
    .{ .smd = zoink.packages.SSOP_16.data },
    .{ .smd = zoink.packages.SSOP_18.data },
    .{ .smd = zoink.packages.SSOP_20.data },
    .{ .smd = zoink.packages.SSOP_22.data },
    .{ .smd = zoink.packages.SSOP_24.data },
    .{ .smd = zoink.packages.SSOP_28_200.data },
    .{ .smd = zoink.packages.SSOP_30_200.data },
    .{ .smd = zoink.packages.SSOP_38_200.data },
    .{ .smd = zoink.packages.SSOP_28_300.data },
    .{ .smd = zoink.packages.SSOP_48.data },
    .{ .smd = zoink.packages.SSOP_56.data },
    .{ .smd = zoink.packages.SSOP_64.data },
    .{ .smd = zoink.packages.TSSOP_14.data },
    .{ .smd = zoink.packages.TSSOP_20.data },
    .{ .smd = zoink.packages.TSSOP_48.data },
    .{ .smd = zoink.packages.TSSOP_56.data },
    .{ .smd = zoink.packages.TVSOP_14.data },
    .{ .smd = zoink.packages.TVSOP_16.data },
    .{ .smd = zoink.packages.TVSOP_20.data },
    .{ .smd = zoink.packages.TVSOP_24.data },
    .{ .smd = zoink.packages.TVSOP_48.data },
    .{ .smd = zoink.packages.TVSOP_56.data },
    .{ .smd = zoink.packages.TVSOP_80.data },
    .{ .smd = zoink.packages.TVSOP_100.data },
};

var current_package_index: usize = package_options.len;

export fn frame() void {
    const width = sokol.app.width();
    const height = sokol.app.height();

    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);
    const aspect = w/h;

    sig.new_frame(.{
        .width = width,
        .height = height,
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    
    zgp.begin(width, height) catch unreachable;
    zgp.viewport(.{
        .x = 0, .y = 0,
        .w = width, .h = height,
    }) catch unreachable;
    zgp.project(-10 * aspect, 10 * aspect, 10.0, -10.0);

    _ = zgp.draw_grid(1, 1, .{ .axis_lines = true }) catch unreachable;

    ig.push_font(font.?);
    ig.set_next_window_pos(.{ .x = 10, .y = 10 }, .{ .cond = .once });
    ig.set_next_window_size(.{ .x = 400, .y = 100 }, .{ .cond = .once });
    _ = ig.begin("Package", .{});
    
    _ = ig.combo("package", Package_Data, &current_package_index, package_options, .{});

    if (current_package_index < package_options.len) {
        switch (package_options[current_package_index]) {
            .smd => |data| {
                draw_package.draw_smd(data) catch unreachable;
            },
        }
    }

    //_ = ig.color_edit3("Background", @ptrCast(&state.pass_action.colors[0].clear_value.r), .{});
    ig.new_line();
    _ = ig.text("Hello World", .{});

    ig.show_metrics_window(.{});
    //ig.show_id_stack_tool_window(null);
    ig.show_demo_window(.{});
    ig.show_debug_log_window(.{});

    ig.end();
    ig.pop_font();

    sokol.gfx.beginPass(.{ .action = state.pass_action, .swapchain = sokol.glue.swapchain() });
    zgp.render() catch unreachable;
    zgp.end();
    sig.render();
    sokol.gfx.endPass();
    sokol.gfx.commit();
}

export fn cleanup() void {
    zgp.shutdown();
    sig.deinit();
    sokol.gfx.shutdown();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    // forward input events to sokol-imgui
    _ = sig.handle_event(ev.*);
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "Zoink!",
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}

const log = std.log.scoped(.main);

const draw_package = @import("draw_package.zig");
const zoink = @import("zoink");
const zgp = @import("zokol_gp.zig");
const ig = @import("ig");
const sokol_imgui = @import("sokol_imgui");
const sokol = @import("sokol");
const std = @import("std");