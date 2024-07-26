const state = struct {
    var pass_action: sokol.gfx.PassAction = .{};
};

export fn init() void {
    // initialize sokol-gfx
    sokol.gfx.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    // initialize sokol-imgui
    sokol.imgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // initial clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };
}

export fn frame() void {
    // call simgui.newFrame() before any ImGui calls
    sokol.imgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });

    //=== UI CODE STARTS HERE
    imgui.igSetNextWindowPos(.{ .x = 10, .y = 10 }, imgui.ImGuiCond_Once, .{ .x = 0, .y = 0 });
    imgui.igSetNextWindowSize(.{ .x = 400, .y = 100 }, imgui.ImGuiCond_Once);
    _ = imgui.igBegin("Hello Dear ImGui!", 0, imgui.ImGuiWindowFlags_None);
    _ = imgui.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, imgui.ImGuiColorEditFlags_None);
    imgui.igEnd();
    //=== UI CODE ENDS HERE

    // call simgui.render() inside a sokol-gfx pass
    sokol.gfx.beginPass(.{ .action = state.pass_action, .swapchain = sokol.glue.swapchain() });
    sokol.imgui.render();
    sokol.gfx.endPass();
    sokol.gfx.commit();
}

export fn cleanup() void {
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
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}

const imgui = @import("imgui");
const sokol = @import("sokol");
