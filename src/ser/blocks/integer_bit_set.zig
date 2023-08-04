const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bit_set.IntegerBitSet");
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

    const bit_length = @TypeOf(value).bit_length;

    var s = try serializer.serializeSeq(bit_length);
    const seq = s.seq();

    if (bit_length == 0) {
        return try seq.end();
    }

    // Serialize bits from N to 1, where N is the bitset's bit length.
    //
    // NOTE: The 0th bit needs to be serialized separately due to compile
    // errors related to the shift bit being too large or something.
    comptime var i: usize = bit_length - 1;
    inline while (i > 0) : (i -= 1) {
        const bit = (value.mask & (1 << i)) >> i;
        try seq.serializeElement(bit);
    }

    // Serialize 0th bit.
    const bit = (value.mask & (1 << 0)) >> 0;
    try seq.serializeElement(bit);

    return try seq.end();
}

test "serialize - std.IntegerBitSet" {
    // Zero-sized
    {
        var want = std.StaticBitSet(0).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });
    }

    // Empty
    {
        var want = std.StaticBitSet(8).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }

    // Full
    {
        var want = std.StaticBitSet(8).initFull();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
        });
    }

    // Mixed
    {
        var want = std.StaticBitSet(8).initEmpty();
        want.set(1);
        want.set(3);
        want.set(5);
        want.set(7);

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = 8 } },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .U8 = 1 },
            .{ .U8 = 0 },
            .{ .SeqEnd = {} },
        });
    }
}
