const std = @import("std");

const OptionalVisitor = @import("../impls/visitor/optional.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Optional;
}

pub fn Visitor(comptime T: type) type {
    return OptionalVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeOptional(allocator, visitor);
}
