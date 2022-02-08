const std = @import("std");

const ArrayVisitor = @import("../impl/visitor/array.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Array;
}

pub fn Visitor(comptime T: type) type {
    return ArrayVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}
