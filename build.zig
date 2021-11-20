const std = @import("std");

const package_name = "getty";
const package_path = "src/lib.zig";

const packages = struct {
    const getty = std.build.Pkg{
        .name = package_name,
        .path = .{ .path = package_path },
        .dependencies = &[_]std.build.Pkg{
            concepts,
        },
    };

    const token = std.build.Pkg{
        .name = "common/token.zig",
        .path = .{ .path = "src/tests/common/token.zig" },
    };

    const concepts = std.build.Pkg{
        .name = "concepts",
        .path = .{ .path = "deps/concepts/src/lib.zig" },
    };
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

        t.addPackage(packages.getty);
        t.addPackage(packages.token);

        step.dependOn(&t.step);
    }

    // Library
    const lib = b.addStaticLibrary(package_name, package_path);

    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();
}
