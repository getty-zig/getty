const std = @import("std");

const Builder = std.build.Builder;

const package_name = "getty";
const package_path = "src/lib.zig";

pub fn build(b: *Builder) void {
    // Options
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    // Tests
    const step = b.step("test", "Run library tests");
    const t = b.addTest("src/tests/test.zig");

    t.addPackagePath(package_name, package_path);
    t.setBuildMode(mode);
    t.setTarget(target);

    step.dependOn(&t.step);

    // Library
    const lib = b.addStaticLibrary(package_name, package_path);
    lib.setBuildMode(mode);
    lib.install();
}
