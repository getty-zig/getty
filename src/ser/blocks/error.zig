const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .ErrorSet;
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
    return try getty_serialize(ally, @as([]const u8, @errorName(v)), s);
}

test "serialize - error" {
    try t.run(null, serialize, error.Foobar, &.{.{ .String = "Foobar" }});
}
