const std = @import("std");

const Builder = std.build.Builder;

//const MODES = [_]std.builtin.Mode{ .Debug, .ReleaseSafe, .ReleaseFast, .ReleaseSmall };
const MODES = [_]std.builtin.Mode{.Debug};

const PACKAGE_NAME = "getty";
const PACKAGE_PATH = "src/lib.zig";

const TEST_FILES = [_][]const u8{
    //"src/de.zig",
    "src/derive.zig",
    "src/ser.zig",
    "src/json.zig",
};

pub fn build(builder: *Builder) void {
    const mode = builder.standardReleaseOptions();
    const target = builder.standardTargetOptions(.{});

    tests(builder, target);
    library(builder, mode);
}

fn tests(builder: *Builder, target: std.zig.CrossTarget) void {
    const test_step = builder.step("test", "Run library tests.");

    inline for (&MODES) |m| {
        const mode = switch (m) {
            .Debug => "DEBUG",
            .ReleaseSafe => "RELEASE-SAFE",
            .ReleaseFast => "RELEASE-FAST",
            .ReleaseSmall => "RELEASE-SMALL",
        };

        const step = builder.step("(" ++ mode ++ ")", "Run tests in " ++ mode ++ " mode.");
        test_step.dependOn(step);

        inline for (&TEST_FILES) |f| {
            const t = builder.addTest(f);

            t.addPackagePath(PACKAGE_NAME, PACKAGE_PATH);
            t.setBuildMode(m);
            t.setTarget(target);
            //t.setNamePrefix(mode ++ " ");

            step.dependOn(&t.step);
        }
    }
}

fn library(builder: *Builder, mode: std.builtin.Mode) void {
    const lib = builder.addStaticLibrary(PACKAGE_NAME, PACKAGE_PATH);
    lib.setBuildMode(mode);
    lib.install();
}
