const std = @import("std");

const de = @import("../../de.zig").de;

const Visitor = @This();

pub usingnamespace de.Visitor(
    Visitor,
    Value,
    .{ .visitVoid = visitVoid },
);

const Value = void;

fn visitVoid(_: Visitor, _: ?std.mem.Allocator, comptime Deserializer: type) Deserializer.Error!Value {
    return {};
}
