const std = @import("std");
const t = @import("../testing.zig");

const OptionalVisitor = @import("../impls/visitor/optional.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Optional;
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

    return try deserializer.deserializeOptional(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return OptionalVisitor(T);
}

test "deserialize - optional" {
    try t.run(deserialize, Visitor, &.{.{ .Null = {} }}, @as(?i32, null));
    try t.run(deserialize, Visitor, &.{ .{ .Some = {} }, .{ .I32 = 0 } }, @as(?i32, 0));
}
