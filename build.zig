const std = @import("std");

const package_name = "getty";
const package_path = "src/lib.zig";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const test_all_step = b.step("test", "Run tests");
    const test_ser_step = b.step("test-ser", "Run serialization tests");
    const test_de_step = b.step("test-de", "Run deserialization tests");

    addTest(b, test_ser_step, "src/ser.zig", mode, target);
    addTest(b, test_de_step, "src/de.zig", mode, target);
    // TODO: for some reason, this isn't included in de.zig.
    addTest(b, test_de_step, "src/de/traits/dbt.zig", mode, target);
    test_all_step.dependOn(test_ser_step);
    test_all_step.dependOn(test_de_step);
}

fn addTest(
    b: *std.build.Builder,
    step: *std.build.Step,
    comptime path: []const u8,
    mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
) void {
    const t = b.addTest(path);
    t.setTarget(target);
    t.setBuildMode(mode);
    t.setMainPkgPath("src/");

    step.dependOn(&t.step);
}
