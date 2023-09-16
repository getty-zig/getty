const std = @import("std");

const free = @import("../../free.zig").free;
const StringLifetime = @import("../../lifetime.zig").StringLifetime;
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

fn visitString(
    _: Visitor,
    ally: ?std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lifetime: StringLifetime,
) Deserializer.Err!Value {
    const heap_lt = lifetime == .heap;

    if (!heap_lt and ally == null) {
        return error.MissingAllocator;
    }

    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;
    errdefer if (!heap_lt) free(ally.?, Deserializer, ver);

    if (ver.pre == null and ver.build == null) {
        return ver;
    }

    if (ver.pre) |pre| {
        ver.pre = if (heap_lt) pre else try ally.?.dupe(u8, pre);
    }
    if (ver.build) |build| {
        ver.build = if (heap_lt) build else try ally.?.dupe(u8, build);
    }

    return ver;
}
