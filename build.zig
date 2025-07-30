var builder: *std.Build = undefined;
var target: std.Build.ResolvedTarget = undefined;
var optimize: std.builtin.OptimizeMode = undefined;
var zoink: *std.Build.Module = undefined;
var all_tests_step: *std.Build.Step = undefined;

pub fn build(b: *std.Build) void {
    builder = b;
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});
    all_tests_step = b.step("test", "run all tests");

    // const sokol = b.dependency("sokol", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    
    // const dear_zig_bindings = b.dependency("dear_zig_bindings", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .naming = .snake,
    //     .validate_packed_structs = true,
    // });

    // const dear_zig_bindings_sokol = b.dependency("dear_zig_bindings_sokol", .{});
    
    // const sx = b.dependency("sx", .{});

    // dep.sokol.artifact("sokol_clib").addIncludePath(dep.cimgui.namedWriteFiles("cimgui").getDirectory());

    zoink = b.createModule(.{
        .root_source_file = b.path("src/zoink.zig"),
        .imports = &.{
            .{ .name = "sx", .module = b.dependency("sx", .{}).module("sx") },
            .{ .name = "lc4k", .module = b.dependency("lc4k", .{}).module("lc4k") },
        },
    });
    
    // const preview = b.addExecutable(.{
    //     .name = "zoink_preview",
    //     .root_source_file = b.path("tools/preview.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // preview.root_module.addImport("zoink", zoink);
    // preview.root_module.addImport("sokol", sokol.module("sokol"));
    // preview.root_module.addImport("ig", dear_zig_bindings.module("ig"));
    // preview.root_module.addImport("sokol_imgui", dear_zig_bindings_sokol.module("sokol_imgui"));
    // b.installArtifact(preview);
    // b.step("preview", "Run preview tool").dependOn(&b.addRunArtifact(preview).step);
    
    add_test("main");
    add_test("simple");
    add_test("AS7C31025");
    add_test("GS71116");
    add_test("CY7C024");
    add_test("74x16244");
    add_test("74x16245");
    add_test("74x16260");
    add_test("74x16652");
    add_test("74x16721");
}

fn add_test(comptime name: []const u8) void {
    const test_exe = builder.addTest(.{
        .name = name,
        .root_source_file = builder.path("test/" ++ name ++ ".zig"),
        .target = target,
        .optimize = optimize,
    });
    test_exe.root_module.addImport("zoink", zoink);
    all_tests_step.dependOn(&builder.addRunArtifact(test_exe).step);
}

const std = @import("std");
