const std = @import("std");

const package_name = "getty";
const package_path = "src/lib.zig";

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    {
        const unit_tests = b.addTest("src/tests/unit.zig");
        unit_tests.setTarget(target);
        unit_tests.setBuildMode(mode);
        unit_tests.addPackagePath("common/token.zig", "src/tests/common/token.zig");
        unit_tests.addPackagePath(package_name, package_path);

        const test_step = b.step("test", "Run all unit tests");
        test_step.dependOn(&unit_tests.step);
    }

    {
        const unit_tests = b.addTest("src/tests/ser/unit.zig");
        unit_tests.setTarget(target);
        unit_tests.setBuildMode(mode);
        unit_tests.addPackagePath("common/token.zig", "src/tests/common/token.zig");
        unit_tests.addPackagePath(package_name, package_path);

        const test_step = b.step("test-ser", "Run serialization unit tests");
        test_step.dependOn(&unit_tests.step);
    }

    {
        const unit_tests = b.addTest("src/tests/de/unit.zig");
        unit_tests.setTarget(target);
        unit_tests.setBuildMode(mode);
        unit_tests.addPackagePath("common/token.zig", "src/tests/common/token.zig");
        unit_tests.addPackagePath(package_name, package_path);

        const test_step = b.step("test-de", "Run deserialization unit tests");
        test_step.dependOn(&unit_tests.step);
    }
}
