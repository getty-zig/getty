const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Array;
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
    for (value) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}

test "serialize - array" {
    // empty
    {
        var arr = [_]i32{};

        try t.run(null, serialize, arr, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    // non-empty
    {
        var arr = [_]i32{ 1, 2, 3 };

        try t.run(null, serialize, arr, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        });
    }
}
