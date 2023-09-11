const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Vector;
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
    const info = @typeInfo(@TypeOf(v)).Vector;

    const Array = [info.len]info.child;
    return try getty_serialize(ally, @as(Array, v), s);
}

test "serialize - vector" {
    try t.run(null, serialize, @as(@Vector(2, i32), @splat(@as(i32, 1))), &.{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .I32 = 1 },
        .{ .SeqEnd = {} },
    });
}
