//! The default Deserialization Block for struct values.

const std = @import("std");

const StructVisitor = @import("../impls/visitor/struct.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Struct and !@typeInfo(T).Struct.is_tuple;
}

pub fn Visitor(comptime T: type) type {
    return StructVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeStruct(allocator, visitor);
}
