const std = @import("std");

const de = @import("../../de.zig");

const PointerVisitor = @import("../impls/visitor/pointer.zig").Visitor;

pub fn is(comptime T: type) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

pub fn Visitor(comptime T: type) type {
    return PointerVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime T: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    const Child = std.meta.Child(T);
    const db = de.de.find_db(@TypeOf(deserializer), Child);

    return try db.deserialize(allocator, Child, deserializer, visitor);
}
