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

fn visitString(_: Visitor, ally: ?std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Error!Value {
    if (ally == null) {
        return error.MissingAllocator;
    }

    const a = ally.?;

    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;
    errdefer free(a, Deserializer, ver);

    if (ver.pre == null and ver.build == null) {
        return ver;
    }

    if (ver.pre) |pre| {
        ver.pre = try a.dupe(u8, pre);
    }
    if (ver.build) |build| {
        ver.build = try a.dupe(u8, build);
    }

    return ver;
}
