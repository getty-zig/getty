const std = @import("std");

const VoidVisitor = @import("../impls/visitor/void.zig");
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == void;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator for heap values that are part of the returned
    /// deserialized value.
    result_ally: std.mem.Allocator,
    /// A memory allocator for heap values that are not part of the returned
    /// deserialized value.
    scratch_ally: std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeVoid(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    _ = T;

    return VoidVisitor;
}

test "deserialize - void" {
    var result = try testing.deserialize(null, Self, void, &.{.{ .Void = {} }});
    defer result.deinit();

    try std.testing.expectEqual({}, result.value);
}
