const std = @import("std");

const Builder = std.build.Builder;

const package_name = "getty";
const package_path = "src/lib.zig";

const test_files = [_][]const u8{
    "src/attributes.zig",
    "src/ser.zig",
    "src/json.zig",
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    tests(b, mode, target);
    library(b, mode);
}

fn tests(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) void {
    const step = b.step("test", "Run library tests");

    inline for (&test_files) |f| {
        const t = b.addTest(f);

        t.addPackagePath(package_name, package_path);
        t.setBuildMode(mode);
        t.setTarget(target);

        step.dependOn(&t.step);
    }
}

fn library(b: *Builder, mode: std.builtin.Mode) void {
    const lib = b.addStaticLibrary(package_name, package_path);
    lib.setBuildMode(mode);
    lib.install();
}
