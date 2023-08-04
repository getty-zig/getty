const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bounded_array");
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

    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();
    for (value.constSlice()) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}

test "serialize - bounded array" {
    // empty
    {
        var arr = try std.BoundedArray(u8, 10).fromSlice(&[_]u8{});

        try t.run(null, serialize, arr, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    // non-empty
    {
        var arr = try std.BoundedArray(u8, 5).fromSlice(&[_]u8{1} ** 5);

        try t.run(null, serialize, arr, &.{
            .{ .Seq = .{ .len = 5 } },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
        });
    }
}
