//! The default Deserialization Block for enum values.

const std = @import("std");

const EnumVisitor = @import("../impls/visitor/enum.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Enum;
}

pub fn Visitor(comptime T: type) type {
    return EnumVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeEnum(allocator, visitor);
}
