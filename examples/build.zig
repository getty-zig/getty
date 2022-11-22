const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    inline for (.{
        "bool-serializer",
        "bool-deserializer",
        "seq-serializer",
        "seq-deserializer",
    }) |example| {
        const exe = b.addExecutable("examples", example ++ "/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("getty", "../src/getty.zig");
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step("run-" ++ example, "Run the " ++ example ++ " example");
        run_step.dependOn(&run_cmd.step);
    }
}
