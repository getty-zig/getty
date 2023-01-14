const std = @import("std");
const t = @import("getty/testing");

const EnumVisitor = @import("../impls/visitor/enum.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Enum;
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

    return try deserializer.deserializeEnum(allocator, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return EnumVisitor(T);
}

test "deserialize - enum" {
    const T = enum { zero, one, two, three, four };

    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .U8 = 0 } }, T.zero);
    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .U16 = 1 } }, T.one);
    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .U32 = 2 } }, T.two);
    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .U64 = 3 } }, T.three);
    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .U128 = 4 } }, T.four);

    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .String = "zero" } }, T.zero);
    try t.de.run(deserialize, Visitor, &.{ .{ .Enum = {} }, .{ .String = "four" } }, T.four);
}
