const std = @import("std");

const Builder = std.build.Builder;

const MODES = [_]std.builtin.Mode{.Debug};

const PACKAGE_NAME = "getty";
const PACKAGE_PATH = "src/lib.zig";

const TEST_FILES = [_][]const u8{
    "src/attributes.zig",
    "src/ser.zig",
    "src/json.zig",
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    tests(b, target);
    library(b, mode);
}

fn tests(b: *Builder, target: std.zig.CrossTarget) void {
    const test_step = b.step("test", "Run library tests.");

    inline for (&MODES) |m| {
        const mode = switch (m) {
            .Debug => "DEBUG",
            .ReleaseSafe => "RELEASE-SAFE",
            .ReleaseFast => "RELEASE-FAST",
            .ReleaseSmall => "RELEASE-SMALL",
        };

        const step = b.step("(" ++ mode ++ ")", "Run tests in " ++ mode ++ " mode.");
        test_step.dependOn(step);

        inline for (&TEST_FILES) |f| {
            const t = b.addTest(f);

            t.addPackagePath(PACKAGE_NAME, PACKAGE_PATH);
            t.setBuildMode(m);
            t.setTarget(target);

            step.dependOn(&t.step);
        }
    }
}

fn library(b: *Builder, mode: std.builtin.Mode) void {
    const lib = b.addStaticLibrary(PACKAGE_NAME, PACKAGE_PATH);
    lib.setBuildMode(mode);
    lib.install();
}
