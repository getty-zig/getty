const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";
const internal_dir = "src/internal/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const target_optimize = .{ .target = target, .optimize = optimize };

    // External modules.
    const protest_module = b.dependency("protest", target_optimize).module("protest");

    // Internal modules.
    const attr_module = b.createModule(.{ .root_source_file = b.path(internal_dir ++ "attr/attr.zig") });
    const block_module = b.createModule(.{ .root_source_file = b.path(internal_dir ++ "block/block.zig") });
    const helpers_module = b.createModule(.{ .root_source_file = b.path(internal_dir ++ "helpers/helpers.zig") });
    const testing_module = b.createModule(.{ .root_source_file = b.path(internal_dir ++ "testing/testing.zig") });

    // Package module.
    const imports = .{
        // External
        .{ .name = "protest", .module = protest_module },

        // Internal
        .{ .name = "attr", .module = attr_module },
        .{ .name = "block", .module = block_module },
        .{ .name = "helpers", .module = helpers_module },
        .{ .name = "testing", .module = testing_module },
    };

    _ = b.addModule(package_name, .{
        .root_source_file = b.path(package_path),
        .imports = &imports,
    });

    // Tests.
    {
        const test_all_step = b.step("test", "Run tests");

        // Allow a test filter to be specified.
        //
        // ## Example
        //
        // ```
        // $ zig build test -- "serialize - array"
        // ```
        if (b.args) |args| {
            std.debug.assert(args.len != 0); // b.args would be null if no arguments were given.

            for (args) |arg| {
                const t_filter = b.addTest(.{
                    .name = "filtered test",
                    .root_source_file = b.path("src/getty.zig"),
                    .filter = arg,
                    .target = target,
                    .optimize = optimize,
                });
                inline for (imports) |imp| t_filter.root_module.addImport(imp.name, imp.module);
                test_all_step.dependOn(&b.addRunArtifact(t_filter).step);
            }

            return;
        }

        const test_ser_step = b.step("test-ser", "Run serialization tests");
        const test_de_step = b.step("test-de", "Run deserialization tests");

        // Serialization tests.
        const t_ser = b.addTest(.{
            .name = "serialization test",
            .root_source_file = b.path("src/ser/ser.zig"),
            .target = target,
            .optimize = optimize,
        });
        inline for (imports) |imp| t_ser.root_module.addImport(imp.name, imp.module);
        test_ser_step.dependOn(&b.addRunArtifact(t_ser).step);
        test_all_step.dependOn(test_ser_step);

        // Deserialization tests.
        const t_de = b.addTest(.{
            .name = "deserialization test",
            .root_source_file = b.path("src/de/de.zig"),
            .target = target,
            .optimize = optimize,
        });
        inline for (imports) |imp| t_de.root_module.addImport(imp.name, imp.module);
        test_de_step.dependOn(&b.addRunArtifact(t_de).step);
        test_all_step.dependOn(test_de_step);
    }

    // Documentation.
    {
        const docs_step = b.step("docs", "Build the project documentation");

        const doc_obj = b.addObject(.{
            .name = "docs",
            .root_source_file = b.path(package_path),
            .target = target,
            .optimize = optimize,
        });
        inline for (imports) |imp| doc_obj.root_module.addImport(imp.name, imp.module);

        const install_docs = b.addInstallDirectory(.{
            .source_dir = doc_obj.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs/getty",
        });
        docs_step.dependOn(&install_docs.step);
    }
}
