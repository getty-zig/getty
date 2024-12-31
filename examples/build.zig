const std = @import("std");

const examples = .{
    "bool-serializer",
    "bool-deserializer",
    "seq-serializer",
    "seq-deserializer",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const target_optimize = .{ .target = target, .optimize = optimize };

    const getty_module = b.dependency("getty", target_optimize).module("getty");

    inline for (examples) |e| {
        const example_path = e ++ "/main.zig";
        const exe_name = "example-" ++ e;
        const run_name = "run-" ++ e;
        const run_desc = "Run the " ++ e ++ " example";

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_source_file = b.path(example_path),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("getty", getty_module);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(run_name, run_desc);
        run_step.dependOn(&run_cmd.step);
    }
}
