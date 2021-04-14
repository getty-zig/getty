const builtin = @import("builtin");
const std = @import("std");

const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub fn build(builder: *Builder) void {
    // Standard release options (Debug, ReleaseSafe, ReleaseSmall, ReleaseFast)
    const mode = builder.standardReleaseOptions();
    //const modes = [_]std.builtin.Mode{ .Debug, .ReleaseSafe, .ReleaseFast, .ReleaseSmall };
    const modes = [_]std.builtin.Mode{.Debug};

    // Standard target options (any target is allowed; default is native)
    const target = builder.standardTargetOptions(.{});

    // Tests
    const test_step = builder.step("test", "Run library tests.");
    const test_files = [_][]const u8{
        "src/serialize.zig",
        "src/deserialize.zig",
        "src/derive.zig",
    };

    inline for (&modes) |m| {
        const mode_str = switch (m) {
            .Debug => "DEBUG",
            .ReleaseSafe => "RELEASE-SAFE",
            .ReleaseFast => "RELEASE-FAST",
            .ReleaseSmall => "RELEASE-SMALL",
        };

        const step = builder.step("(" ++ mode_str ++ ")", "Run tests in " ++ mode_str ++ " mode.");
        test_step.dependOn(step);

        inline for (&test_files) |f| {
            const tests = builder.addTest(f);

            tests.addPackagePath("getty", "src/main.zig");
            tests.setBuildMode(m);
            tests.setTarget(target);
            //tests.setNamePrefix(mode_str ++ " ");

            step.dependOn(&tests.step);
        }
    }

    // Library
    const lib = builder.addStaticLibrary("getty", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();
}
