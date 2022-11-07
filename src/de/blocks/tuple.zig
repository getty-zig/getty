//! The default Deserialization Block for tuple values.

const std = @import("std");

const TupleVisitor = @import("../impls/visitor/tuple.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
}

pub fn Visitor(comptime T: type) type {
    return TupleVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}
