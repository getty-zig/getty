const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Optional;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = ally;

    return try if (value) |v| serializer.serializeSome(v) else serializer.serializeNull();
}

test "serialize - optional" {
    try t.run(null, serialize, @as(?i32, null), &.{.{ .Null = {} }});
    try t.run(null, serialize, @as(?i32, 0), &.{ .{ .Some = {} }, .{ .I32 = 0 } });
}
