const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies.
    const dep_opts = .{ .target = target, .optimize = optimize };
    const protest_module = b.dependency("protest", dep_opts).module("protest");

    // Export Getty as a module.
    _ = b.addModule(package_name, .{
        .root_source_file = .{ .path = package_path },
        .imports = &.{
            .{ .name = "protest", .module = protest_module },
        },
    });

    // Tests.
    {
        const test_all_step = b.step("test", "Run tests");
        const test_ser_step = b.step("test-ser", "Run serialization tests");
        const test_de_step = b.step("test-de", "Run deserialization tests");

        // Serialization tests.
        const t_ser = b.addTest(.{
            .name = "serialization test",
            .root_source_file = .{ .path = "src/ser_test.zig" },
            .target = target,
            .optimize = optimize,
        });
        t_ser.root_module.addImport("protest", protest_module);
        test_ser_step.dependOn(&b.addRunArtifact(t_ser).step);
        test_all_step.dependOn(test_ser_step);

        // Deserialization tests.
        const t_de = b.addTest(.{
            .name = "deserialization test",
            .root_source_file = .{ .path = "src/de_test.zig" },
            .target = target,
            .optimize = optimize,
        });
        t_de.root_module.addImport("protest", protest_module);
        test_de_step.dependOn(&b.addRunArtifact(t_de).step);
        test_all_step.dependOn(test_de_step);
    }

    // Documentation.
    {
        const docs_step = b.step("docs", "Build the project documentation");

        const doc_obj = b.addObject(.{
            .name = "docs",
            .root_source_file = .{ .path = package_path },
            .target = target,
            .optimize = optimize,
        });

        const install_docs = b.addInstallDirectory(.{
            .source_dir = doc_obj.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs/getty",
        });
        docs_step.dependOn(&install_docs.step);
    }
}
