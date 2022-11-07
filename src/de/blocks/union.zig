//! The default Deserialization Block for union values.

const std = @import("std");

const UnionVisitor = @import("../impls/visitor/union.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Union;
}

pub fn Visitor(comptime T: type) type {
    return UnionVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeUnion(allocator, visitor);
}
