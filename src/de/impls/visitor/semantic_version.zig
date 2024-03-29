const std = @import("std");

const StringLifetime = @import("../../lifetime.zig").StringLifetime;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;
const VisitStringReturn = @import("../../interfaces/visitor.zig").VisitStringReturn;

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
    ally: std.mem.Allocator,
    comptime Deserializer: type,
    input: anytype,
    lt: StringLifetime,
) Deserializer.Err!VisitStringReturn(Value) {
    var ver = std.SemanticVersion.parse(input) catch return error.InvalidValue;

    var used = false;
    switch (lt) {
        .heap => used = true,
        .stack, .managed => {
            if (ver.pre) |pre| ver.pre = try ally.dupe(u8, pre);
            if (ver.build) |build| ver.build = try ally.dupe(u8, build);
        },
    }

    return .{ .value = ver, .used = used };
}
