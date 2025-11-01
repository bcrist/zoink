pub fn build(b: *std.Build) void {
    const sx = b.dependency("sx", .{}).module("sx");
    const zm = b.dependency("zm", .{}).module("zm");
    const lc4k = b.dependency("lc4k", .{}).module("lc4k");
    const bits = b.dependency("bit_helper", .{}).module("bits");

    const ctx: Context = .{
        .b = b,
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .all_tests_step = b.step("test", "run all tests"),
        .lc4k = lc4k,
        .bits = bits,
        .zoink = b.addModule("zoink", .{
            .root_source_file = b.path("src/zoink.zig"),
            .imports = &.{
                .{ .name = "sx", .module = sx },
                .{ .name = "zm", .module = zm },
                .{ .name = "lc4k", .module = lc4k },
                .{ .name = "bits", .module = bits },
            },
        }),
    };

    ctx.add_test("main");
    ctx.add_test("simple");
    ctx.add_test("AS7C31025");
    ctx.add_test("GS71116");
    ctx.add_test("CY7C024");
    ctx.add_test("74x138");
    ctx.add_test("74x16244");
    ctx.add_test("74x16245");
    ctx.add_test("74x16260");
    ctx.add_test("74x16652");
    ctx.add_test("74x16721");
    ctx.add_test("LC4032ZE");
    ctx.add_test("74CBTLV16212");
    ctx.add_test("IDT7216");
    ctx.add_test("IDT7217");
    ctx.add_test("L4C381");
}

const Context = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zoink: *std.Build.Module,
    lc4k: *std.Build.Module,
    bits: *std.Build.Module,
    all_tests_step: *std.Build.Step,

    fn add_test(self: *const Context, comptime name: []const u8) void {
        const test_exe = self.b.addTest(.{
            .name = name,
            .root_module = self.b.createModule(.{
                .root_source_file = self.b.path("test/" ++ name ++ ".zig"),
                .target = self.target,
                .optimize = self.optimize,
                .imports = &.{
                    .{ .name = "zoink", .module = self.zoink },
                    .{ .name = "lc4k", .module = self.lc4k },
                    .{ .name = "bits", .module = self.bits },
                },
            }),
        });
        self.b.installArtifact(test_exe);
        self.all_tests_step.dependOn(&self.b.addRunArtifact(test_exe).step);
    }
};

const std = @import("std");
