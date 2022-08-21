const std = @import("std");

const package_name = "getty";
const package_path = "src/lib.zig";

const tests = [_][]const u8{
    "src/tests/ser/tests.zig",
    "src/tests/de/tests.zig",
};

pub fn build(b: *std.build.Builder) void {
    // Options
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    // Tests
    const step = b.step("test", "Run framework tests");

    for (tests) |path| {
        const t = b.addTest(path);

        t.setBuildMode(mode);
        t.setTarget(target);
        t.addPackagePath("common/token.zig", "src/tests/common/token.zig");
        t.addPackagePath(package_name, package_path);
        step.dependOn(&t.step);
    }
}
