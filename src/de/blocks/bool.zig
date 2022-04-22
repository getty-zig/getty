const std = @import("std");

const BoolVisitor = @import("../impl/visitor/bool.zig");

pub fn is(comptime T: type) bool {
    return T == bool;
}

pub fn Visitor(comptime _: type) type {
    return BoolVisitor;
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeBool(allocator, visitor);
}
