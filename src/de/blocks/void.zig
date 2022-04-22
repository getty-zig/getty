const std = @import("std");

const VoidVisitor = @import("../impls/visitor/void.zig");

pub fn is(comptime T: type) bool {
    return T == void;
}

pub fn Visitor(comptime _: type) type {
    return VoidVisitor;
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeVoid(allocator, visitor);
}
