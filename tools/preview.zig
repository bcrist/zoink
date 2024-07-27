const state = struct {
    var pass_action: sokol.gfx.PassAction = .{};
};

const font_data = @embedFile("font.ttf");

var font: [*c]imgui.ImFont = null;

export fn init() void {
    sokol.gfx.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    
    sokol.imgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });


    font = imgui.ImFontAtlas_AddFontFromMemoryTTF(imgui.igGetIO()[0].Fonts, @constCast(@ptrCast(font_data.ptr)), font_data.len, 18.5, null, null);

    zgp.setup(.{
        .allocator = std.heap.page_allocator,
        .max_vertices = 1024 * 1024,
    }) catch |err| {
        log.err("Failed to set up ZGP: {}", .{ err });
    };

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };
}

var t: f64 = 0;

export fn frame() void {
    const width = sokol.app.width();
    const height = sokol.app.height();

    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);
    const aspect = w/h;

    sokol.imgui.newFrame(.{
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
    zgp.project(-aspect, aspect, 1.0, -1.0);

    // Draw an animated rectangle that rotates and changes its colors.
    t += sokol.app.frameDuration() * 4;
    const r: f32 = @floatCast(@sin(t)*0.5+0.5);
    const g: f32 = @floatCast(@cos(t)*0.5+0.5);

    zgp.set_color(.{ .r = 0, .g = 0, .b = 0 });
    zgp.draw_lines_strip(&.{
        .{ .x = 0.1, .y = 0 },
        .{ .x = 0.7, .y = 1 },
        .{ .x = 0.6, .y = -0.4 },
        .{ .x = -0.5, .y = -0.3 },
    }) catch unreachable;

    zgp.push_transform() catch unreachable;
    zgp.set_color(.{ .r = r, .g = g, .b = 0.3 });
    zgp.rotate_at(@floatCast(t), 0.0, 0.0);
    zgp.draw_filled_rect(-0.5, -0.5, 1.0, 1.0) catch unreachable;
    zgp.pop_transform() catch unreachable;

    zgp.set_color(.{ .r = 0, .g = 0, .b = 0 });
    zgp.draw_lines_strip(&.{
        .{ .x = 0, .y = 0 },
        .{ .x = 0.5, .y = 0.5 },
        .{ .x = 0.5, .y = -0.2 },
        .{ .x = -0.4, .y = -0.2 },
    }) catch unreachable;


    //=== UI CODE STARTS HERE
    imgui.igPushFont(font);
    imgui.igSetNextWindowPos(.{ .x = 10, .y = 10 }, imgui.ImGuiCond_Once, .{ .x = 0, .y = 0 });
    imgui.igSetNextWindowSize(.{ .x = 400, .y = 100 }, imgui.ImGuiCond_Once);
    _ = imgui.igBegin("Hello Dear ImGui!", 0, imgui.ImGuiWindowFlags_None);
    _ = imgui.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, imgui.ImGuiColorEditFlags_None);
    imgui.igPopFont();
    imgui.igEnd();
    //=== UI CODE ENDS HERE

    sokol.gfx.beginPass(.{ .action = state.pass_action, .swapchain = sokol.glue.swapchain() });
    zgp.flush() catch unreachable;
    zgp.end() catch unreachable;
    sokol.imgui.render();
    sokol.gfx.endPass();
    sokol.gfx.commit();
}

export fn cleanup() void {
    zgp.shutdown();
    sokol.imgui.shutdown();
    sokol.gfx.shutdown();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    // forward input events to sokol-imgui
    _ = sokol.imgui.handleEvent(ev.*);
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "sokol-zig + Dear Imgui",
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}

const log = std.log.scoped(.main);

const zgp = @import("zokol_gp.zig");
const imgui = @import("imgui");
const sokol = @import("sokol");
const std = @import("std");