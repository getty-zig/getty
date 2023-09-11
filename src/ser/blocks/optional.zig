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
    v: anytype,
    /// A `getty.Serializer` interface value.
    s: anytype,
) @TypeOf(s).Err!@TypeOf(s).Ok {
    _ = ally;

    return try if (v) |some| s.serializeSome(some) else s.serializeNull();
}

test "serialize - optional" {
    try t.run(null, serialize, @as(?i32, null), &.{.{ .Null = {} }});
    try t.run(null, serialize, @as(?i32, 0), &.{ .{ .Some = {} }, .{ .I32 = 0 } });
}
