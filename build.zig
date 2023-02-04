const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    _ = b.addModule(.{
        .name = "getty",
        .source_file = .{ .path = "src/getty.zig" },
    });

    tests(b, target, mode);
    docs(b, target, mode);
    clean(b);
}

fn tests(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const test_all_step = b.step("test", "Run tests");
    const test_ser_step = b.step("test-ser", "Run serialization tests");
    const test_de_step = b.step("test-de", "Run deserialization tests");

    // Configure tests.
    const t_ser = b.addTest(.{
        .name = "serialization test",
        .root_source_file = .{ .path = "src/ser/ser.zig" },
        .target = target,
        .optimize = mode,
    });
    t_ser.setMainPkgPath(libPath(b, "/"));

    const t_de = b.addTest(.{
        .name = "deserialization test",
        .root_source_file = .{ .path = "src/de/de.zig" },
        .target = target,
        .optimize = mode,
    });
    t_de.setMainPkgPath(libPath(b, "/"));

    // Configure module-level test steps.
    test_ser_step.dependOn(&t_ser.step);
    test_de_step.dependOn(&t_de.step);

    // Configure top-level test step.
    test_all_step.dependOn(test_ser_step);
    test_all_step.dependOn(test_de_step);
}

fn docs(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    // Remove cache.
    const cmd = b.addSystemCommand(&[_][]const u8{
        "rm",
        "-rf",
        "zig-cache",
    });

    const clean_step = b.step("clean", "Remove project artifacts");
    clean_step.dependOn(&cmd.step);

    // Build docs.
    const docs_obj = b.addObject(.{
        .name = "docs",
        .root_source_file = .{ .path = libPath(b, "/" ++ package_path) },
        .target = target,
        .optimize = mode,
    });
    docs_obj.emit_docs = .emit;

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

const unresolved_dir = (struct {
    inline fn unresolvedDir() []const u8 {
        return comptime std.fs.path.dirname(@src().file) orelse ".";
    }
}).unresolvedDir();

fn thisDir(allocator: std.mem.Allocator) []const u8 {
    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir;
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
    }

    return cached_dir.*.?;
}

inline fn libPath(b: *std.build.Builder, comptime suffix: []const u8) []const u8 {
    return libPathAllocator(b.allocator, suffix);
}

inline fn libPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
    return libPathInternal(allocator, suffix.len, suffix[0..suffix.len].*);
}

fn libPathInternal(allocator: std.mem.Allocator, comptime len: usize, comptime suffix: [len]u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");

    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir ++ @as([]const u8, &suffix);
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
    }

    return cached_dir.*.?;
}
