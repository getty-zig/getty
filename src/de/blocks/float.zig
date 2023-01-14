const std = @import("std");
const t = @import("getty/testing");

const FloatVisitor = @import("../impls/visitor/float.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Float, .ComptimeFloat => true,
        else => false,
    };
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

    return try deserializer.deserializeFloat(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return FloatVisitor(T);
}

test "deserialize - float" {
    try t.de.run(deserialize, Visitor, &.{.{ .F16 = 0 }}, @as(f16, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .F32 = 0 }}, @as(f32, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .F64 = 0 }}, @as(f64, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .F64 = 0 }}, @as(f128, 0));
}
