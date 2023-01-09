const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

const pkgs = struct {
    const getty = std.build.Pkg{
        .name = package_name,
        .source = .{ .path = package_path },
        .dependencies = &[_]std.build.Pkg{},
    };

    const getty_testing = std.build.Pkg{
        .name = "getty/testing",
        .source = .{ .path = "src/tests/testing.zig" },
        .dependencies = &[_]std.build.Pkg{
            getty,
        },
    };
};

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    tests(b, mode, target);
    docs(b);
    clean(b);
}

fn tests(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) void {
    const test_all_step = b.step("test", "Run tests");
    const test_ser_step = b.step("test-ser", "Run serialization tests");
    const test_de_step = b.step("test-de", "Run deserialization tests");

    // Configure tests.
    const t_ser = b.addTest("src/ser.zig");
    t_ser.setTarget(target);
    t_ser.setBuildMode(mode);
    t_ser.addPackage(pkgs.getty);
    t_ser.addPackage(pkgs.getty_testing);

    const t_de = b.addTest("src/de.zig");
    t_de.setTarget(target);
    t_de.setBuildMode(mode);
    t_de.addPackage(pkgs.getty);
    t_de.addPackage(pkgs.getty_testing);

    // Configure module-level test steps.
    test_ser_step.dependOn(&t_ser.step);
    test_de_step.dependOn(&t_de.step);

    // Configure top-level test step.
    test_all_step.dependOn(test_ser_step);
    test_all_step.dependOn(test_de_step);
}

fn docs(b: *std.build.Builder) void {
    const cmd = b.addSystemCommand(&[_][]const u8{
        "zig",
        "build-obj",
        "-femit-docs",
        package_path,
    });

    const docs_step = b.step("docs", "Generate project documentation");
    docs_step.dependOn(&cmd.step);
}

fn clean(b: *std.build.Builder) void {
    const cmd = b.addSystemCommand(&[_][]const u8{
        "rm",
        "-rf",
        "zig-cache",
        "docs",
        "*.o",
        "gyro.lock",
        ".gyro",
    });

    const clean_step = b.step("clean", "Remove project artifacts");
    clean_step.dependOn(&cmd.step);
}
