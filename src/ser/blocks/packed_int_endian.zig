const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    comptime {
        const is_array = std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntArrayEndian");
        const is_slice = std.mem.startsWith(u8, @typeName(T), "packed_int_array.PackedIntSliceEndian");

        return is_array or is_slice;
    }
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

    for (0..value.len) |i| {
        try seq.serializeElement(value.get(i));
    }

    return try seq.end();
}

test "serialize - std.PackedIntArray" {
    // Native endian
    {
        var array = std.PackedIntArray(u8, 3).init([_]u8{ 1, 2, 3 });

        try t.run(null, serialize, array, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 1 },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
        });
    }

    // Custom endian
    {
        var array = std.PackedIntArrayEndian(u8, .Big, 3).init([_]u8{ 1, 2, 3 });

        try t.run(null, serialize, array, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 1 },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
        });
    }
}

test "serialize - std.PackedIntSlice" {
    // Native endian
    {
        var array = std.PackedIntArray(u8, 3).init([_]u8{ 1, 2, 3 });
        const slice = array.slice(0, 3);

        try t.run(null, serialize, slice, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 1 },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
        });
    }

    // Custom endian
    {
        var array = std.PackedIntArrayEndian(u8, .Big, 3).init([_]u8{ 1, 2, 3 });
        const slice = array.slice(0, 3);

        try t.run(null, serialize, slice, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 1 },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
        });
    }
}
