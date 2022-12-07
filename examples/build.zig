const std = @import("std");

const pkg_name = "getty";
const pkg_path = "../src/getty.zig";

const examples = .{
    "bool-serializer",
    "bool-deserializer",
    "seq-serializer",
    "seq-deserializer",
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    inline for (examples) |e| {
        const example_path = e ++ "/main.zig";
        const exe_name = "example-" ++ e;
        const run_name = "run-" ++ e;
        const run_desc = "Run the " ++ e ++ " example";

        const exe = b.addExecutable(exe_name, example_path);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath(pkg_name, pkg_path);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(run_name, run_desc);
        run_step.dependOn(&run_cmd.step);
    }
}
