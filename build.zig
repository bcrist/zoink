var builder: *std.Build = undefined;
var target: std.Build.ResolvedTarget = undefined;
var optimize: std.builtin.OptimizeMode = undefined;
var zoink: *std.Build.Module = undefined;
var all_tests_step: *std.Build.Step = undefined;

pub fn build(b: *std.Build) void {
    builder = b;
    target = b.host;
    optimize = b.standardOptimizeOption(.{});
    all_tests_step = b.step("test", "run all tests");

    zoink = b.createModule(.{
        .root_source_file = b.path("src/zoink.zig"),
    });

    const dep = .{
        .sokol = b.dependency("sokol", .{ .target = target, .optimize = optimize, .with_sokol_imgui = true }),
        .cimgui = b.dependency("cimgui", .{ .target = target, .optimize = optimize }),
    };
    dep.sokol.artifact("sokol_clib").addIncludePath(dep.cimgui.namedWriteFiles("cimgui").getDirectory());

    
    const preview = b.addExecutable(.{
        .name = "zoink_preview",
        .root_source_file = b.path("tools/preview.zig"),
        .target = target,
        .optimize = optimize,
    });
    preview.root_module.addImport("sokol", dep.sokol.module("sokol"));
    preview.root_module.addImport("imgui", dep.cimgui.module("cimgui"));
    b.installArtifact(preview);
    b.step("preview", "Run preview tool").dependOn(&b.addRunArtifact(preview).step);
    
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
