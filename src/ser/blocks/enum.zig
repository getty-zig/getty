const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return switch (@typeInfo(T)) {
        .Enum, .EnumLiteral => true,
        else => false,
    };
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = allocator;

    return try serializer.serializeEnum(value);
}

test "serialize - enum" {
    // literal
    try t.run(null, serialize, .foo, &.{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.run(null, serialize, .bar, &.{ .{ .Enum = {} }, .{ .String = "bar" } });

    // non-literal
    const T = enum { foo, bar };
    try t.run(null, serialize, T.foo, &.{ .{ .Enum = {} }, .{ .String = "foo" } });
    try t.run(null, serialize, T.bar, &.{ .{ .Enum = {} }, .{ .String = "bar" } });
}
