const std = @import("std");
const t = @import("getty/testing");

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
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();

    var i: usize = 0;
    while (i < value.len) : (i += 1) {
        try seq.serializeElement(value.get(i));
    }

    return try seq.end();
}

test "serialize - std.PackedIntArray" {
    // Native endian
    {
        var array = std.PackedIntArray(u8, 3).init([_]u8{ 1, 2, 3 });

        try t.ser.run(array, &[_]t.Token{
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

        try t.ser.run(array, &[_]t.Token{
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

        try t.ser.run(slice, &[_]t.Token{
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

        try t.ser.run(slice, &[_]t.Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .U8 = 1 },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
        });
    }
}
