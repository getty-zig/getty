const std = @import("std");

const de = @import("../de.zig");

const PointerVisitor = @import("../impls/visitor/pointer.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One;
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return PointerVisitor(T);
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    const Child = std.meta.Child(T);
    const db = de.de.find_db(@TypeOf(deserializer), Child);

    return try db.deserialize(allocator, Child, deserializer, visitor);
}
