const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    tests(b, mode, target);
    docs(b);
}

fn tests(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) void {
    const test_all_step = b.step("test", "Run tests");
    const test_ser_step = b.step("test-ser", "Run serialization tests");
    const test_de_step = b.step("test-de", "Run deserialization tests");

    addTest(b, mode, target, test_all_step, test_ser_step, "src/ser.zig");
    addTest(b, mode, target, test_all_step, test_de_step, "src/de.zig");
}

fn docs(b: *std.build.Builder) void {
    const cmd = b.addSystemCommand(&[_][]const u8{
        "zig",
        "build-obj",
        "-femit-docs",
        package_path,
    });

    const docs_step = b.step("docs", "Generate project documentation");
    docs_step.dependOn(&cmd.step);
}

fn addTest(
    b: *std.build.Builder,
    mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
    all_step: *std.build.Step,
    step: *std.build.Step,
    comptime path: []const u8,
) void {
    const t = b.addTest(path);
    t.setTarget(target);
    t.setBuildMode(mode);
    t.setMainPkgPath("src/");

    step.dependOn(&t.step);
    all_step.dependOn(step);
}
