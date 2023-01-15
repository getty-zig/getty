const std = @import("std");

const HashMapVisitor = @import("../impls/visitor/hash_map.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
    const is_array_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "array_hash_map");

    return is_hash_map or is_array_hash_map;
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
    _ = T;

    return try deserializer.deserializeMap(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return HashMapVisitor(T);
}
