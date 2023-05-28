const std = @import("std");

const module_name = "getty";
const module_path = "../src/getty.zig";

const examples = .{
    "bool-serializer",
    "bool-deserializer",
    "seq-serializer",
    "seq-deserializer",
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (examples) |e| {
        const example_path = e ++ "/main.zig";
        const exe_name = "example-" ++ e;
        const run_name = "run-" ++ e;
        const run_desc = "Run the " ++ e ++ " example";

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_source_file = .{ .path = example_path },
            .target = target,
            .optimize = optimize,
        });
        const module = b.addModule(module_name, .{
            .source_file = .{ .path = module_path },
        });

        exe.addModule(module_name, module);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(run_name, run_desc);
        run_step.dependOn(&run_cmd.step);
    }
}
