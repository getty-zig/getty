const std = @import("std");
const t = @import("getty/testing");

const BoolVisitor = @import("../impls/visitor/bool.zig");

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == bool;
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

    return try deserializer.deserializeBool(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    _ = T;

    return BoolVisitor;
}

test "deserialize - bool" {
    try t.de.run(deserialize, Visitor, &.{.{ .Bool = true }}, true);
    try t.de.run(deserialize, Visitor, &.{.{ .Bool = false }}, false);
}
