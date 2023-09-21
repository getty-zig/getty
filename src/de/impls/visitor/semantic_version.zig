const std = @import("std");

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

fn visitString(_: Visitor, ally: std.mem.Allocator, comptime Deserializer: type, input: anytype) Deserializer.Err!Value {
    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;

    if (ver.pre == null and ver.build == null) {
        return ver;
    }

    if (ver.pre) |pre| {
        ver.pre = try ally.dupe(u8, pre);
    }
    if (ver.build) |build| {
        ver.build = try ally.dupe(u8, build);
    }

    return ver;
}
