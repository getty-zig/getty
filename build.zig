const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

var cached_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *std.build.Builder) std.build.Pkg {
    if (cached_pkg == null) {
        const getty_pkg = .{
            .name = package_name,
            .source = .{ .path = libPath(b, "/" ++ package_path) },
        };

        const testing_pkg = blk: {
            const deps = b.allocator.create([1]std.build.Pkg) catch unreachable;
            deps.* = .{getty_pkg};

            break :blk .{
                .name = "getty/testing",
                .source = .{ .path = libPath(b, "/src/testing/testing.zig") },
                .dependencies = deps,
            };
        };

        cached_pkg = blk: {
            const deps = b.allocator.create([2]std.build.Pkg) catch unreachable;
            deps.* = .{ getty_pkg, testing_pkg };

            break :blk .{
                .name = package_name,
                .source = .{ .path = libPath(b, "/" ++ package_path) },
                .dependencies = deps,
            };
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
