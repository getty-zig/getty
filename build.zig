const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

var cached_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *std.build.Builder) std.build.Pkg {
    if (cached_pkg == null) {
        const pkgs = struct {
            const getty = std.build.Pkg{
                .name = package_name,
                .source = .{ .path = package_path },
                .dependencies = &[_]std.build.Pkg{},
            };

            const testing = std.build.Pkg{
                .name = "getty/testing",
                .source = .{ .path = "src/testing/testing.zig" },
                .dependencies = &[_]std.build.Pkg{
                    getty,
                },
            };
        };

        const dependencies = b.allocator.create([2]std.build.Pkg) catch unreachable;
        dependencies.* = .{ pkgs.getty, pkgs.testing };

        cached_pkg = .{
            .name = package_name,
            .source = .{ .path = "src/getty.zig" },
            .dependencies = dependencies,
        };
    }

    return cached_pkg.?;
}

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
    const t_ser = b.addTest("src/ser/ser.zig");
    t_ser.setTarget(target);
    t_ser.setBuildMode(mode);
    for (pkg(b).dependencies.?) |d| t_ser.addPackage(d);

    const t_de = b.addTest("src/de/de.zig");
    t_de.setTarget(target);
    t_de.setBuildMode(mode);
    for (pkg(b).dependencies.?) |d| t_de.addPackage(d);

    // Configure module-level test steps.
    test_ser_step.dependOn(&t_ser.step);
    test_de_step.dependOn(&t_de.step);

    // Configure top-level test step.
    test_all_step.dependOn(test_ser_step);
    test_all_step.dependOn(test_de_step);
}

fn docs(b: *std.build.Builder) void {
    // Remove cache.
    const cmd = b.addSystemCommand(&[_][]const u8{
        "rm",
        "-rf",
        "zig-cache",
    });

    const clean_step = b.step("clean", "Remove project artifacts");
    clean_step.dependOn(&cmd.step);

    // Build docs.
    const docs_obj = b.addObject("docs", package_path);
    docs_obj.emit_docs = .emit;
    for (pkg(b).dependencies.?) |d| docs_obj.addPackage(d);

    const docs_step = b.step("docs", "Generate project documentation");
    docs_step.dependOn(clean_step);
    docs_step.dependOn(&docs_obj.step);
}

fn clean(b: *std.build.Builder) void {
    const cmd = b.addSystemCommand(&[_][]const u8{
        "rm",
        "-rf",
        "zig-cache",
        "docs",
        "getty.o",
        "getty.o.o",
        "gyro.lock",
        ".gyro",
    });

    const clean_step = b.step("clean", "Remove project artifacts");
    clean_step.dependOn(&cmd.step);
}
