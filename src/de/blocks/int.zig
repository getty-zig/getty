const std = @import("std");
const t = @import("getty/testing");

const IntVisitor = @import("../impls/visitor/int.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt => true,
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

    return try deserializer.deserializeInt(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return IntVisitor(T);
}

test "deserialize - integer" {
    // signed
    try t.de.run(deserialize, Visitor, &.{.{ .I8 = 0 }}, @as(i8, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .I16 = 0 }}, @as(i16, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .I32 = 0 }}, @as(i32, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .I64 = 0 }}, @as(i64, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .I128 = 0 }}, @as(i128, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .I128 = 0 }}, @as(isize, 0));

    // unsigned
    try t.de.run(deserialize, Visitor, &.{.{ .U8 = 0 }}, @as(u8, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .U16 = 0 }}, @as(u16, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .U32 = 0 }}, @as(u32, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .U64 = 0 }}, @as(u64, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .U128 = 0 }}, @as(u128, 0));
    try t.de.run(deserialize, Visitor, &.{.{ .U128 = 0 }}, @as(usize, 0));
}
