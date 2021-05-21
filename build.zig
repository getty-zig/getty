const std = @import("std");

const Builder = std.build.Builder;

const package_name = "getty";
const package_path = "src/lib.zig";

const modes = [_]std.builtin.Mode{.Debug};

const test_files = [_][]const u8{
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

    inline for (&modes) |m| {
        const mode = switch (m) {
            .Debug => "DEBUG",
            .ReleaseSafe => "RELEASE-SAFE",
            .ReleaseFast => "RELEASE-FAST",
            .ReleaseSmall => "RELEASE-SMALL",
        };

        const step = b.step("(" ++ mode ++ ")", "Run tests in " ++ mode ++ " mode.");
        test_step.dependOn(step);

        inline for (&test_files) |f| {
            const t = b.addTest(f);

            t.addPackagePath(package_name, package_path);
            t.setBuildMode(m);
            t.setTarget(target);

            step.dependOn(&t.step);
        }
    }
}

fn library(b: *Builder, mode: std.builtin.Mode) void {
    const lib = b.addStaticLibrary(package_name, package_path);
    lib.setBuildMode(mode);
    lib.install();
}
