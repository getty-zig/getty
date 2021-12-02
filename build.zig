const std = @import("std");
const pkgs = @import("deps.zig").pkgs;

const package_name = "getty";
const package_path = "src/lib.zig";

const getty_pkg = std.build.Pkg{
    .name = package_name,
    .path = .{ .path = package_path },
    .dependencies = &[_]std.build.Pkg{
        pkgs.concepts,
    },
};

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
        pkgs.addAllTo(t);
        t.addPackagePath("common/token.zig", "src/tests/common/token.zig");
        t.addPackage(getty_pkg);
        step.dependOn(&t.step);
    }
}
