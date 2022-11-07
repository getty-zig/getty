//! The default Deserialization Block for std.ArrayList values.

const std = @import("std");

const ArrayListVisitor = @import("../impls/visitor/array_list.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "array_list");
}

pub fn Visitor(comptime T: type) type {
    return ArrayListVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}
