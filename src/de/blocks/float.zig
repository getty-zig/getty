//! The default Deserialization Block for floating-point values.

const std = @import("std");

const FloatVisitor = @import("../impls/visitor/float.zig").Visitor;

pub fn is(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
        else => false,
    };
}

pub fn Visitor(comptime T: type) type {
    return FloatVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeFloat(allocator, visitor);
}
