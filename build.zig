const std = @import("std");

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

    zoink = b.createModule(.{
        .root_source_file = b.path("src/zoink.zig"),
    });
    
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
