const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

const Visitor = @This();

pub usingnamespace VisitorInterface(
    Visitor,
    Value,
    .{
        .visitString = visitString,
    },
);

const Value = std.SemanticVersion;

fn visitString(_: Visitor, allocator: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
    if (allocator == null) {
        return error.MissingAllocator;
    }

    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;
    errdefer {
        if (ver.pre) |pre| allocator.?.free(pre);
        if (ver.build) |build| allocator.?.free(build);
    }

    if (ver.pre == null and ver.build == null) {
        return ver;
    }

    if (ver.pre) |pre| {
        ver.pre = try allocator.?.dupe(u8, pre);
    }
    if (ver.build) |build| {
        ver.build = try allocator.?.dupe(u8, build);
    }

    return ver;
}
