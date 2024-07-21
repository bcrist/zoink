const std = @import("std");


pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const all_tests = b.step("test", "run all tests");

    const zoink = b.createModule(.{
        .root_source_file = b.path("src/zoink.zig"),
    });

    const simple = b.addTest(.{
        .name = "simple",
        .root_source_file = b.path("simple.zig"),
        .target = target,
        .optimize = optimize,
    });
    simple.root_module.addImport("zoink", zoink);

    b.installArtifact(simple);

    all_tests.dependOn(&b.addRunArtifact(simple).step);
}
