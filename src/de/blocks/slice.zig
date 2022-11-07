//! The default Deserialization Block for slice values.

const std = @import("std");

const SliceVisitor = @import("../impls/visitor/slice.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .Slice;
}

pub fn Visitor(comptime T: type) type {
    return SliceVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try switch (comptime std.meta.trait.isZigString(T)) {
        true => deserializer.deserializeString(allocator, visitor),
        false => deserializer.deserializeSeq(allocator, visitor),
    };
}
