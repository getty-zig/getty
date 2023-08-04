const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "bit_set.ArrayBitSet");
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

    const cap = value.capacity();
    std.debug.assert(cap != 0); // std.IntegerBitSet would be used if cap was 0.

    var s = try serializer.serializeSeq(cap);
    const seq = s.seq();

    const MaskInt = @TypeOf(value).MaskInt;
    const zero = @as(MaskInt, 0);
    const one = @as(MaskInt, 1);

    // The position of the last set bit in value.
    var last_pos = cap;

    // Serialize bits from N to M, where N is value's bit length and M is
    // the position of the last set bit in value.
    {
        var it = value.iterator(.{ .direction = .reverse });
        var i: usize = cap - 1;

        while (it.next()) |pos| {
            while (i != pos) {
                try seq.serializeElement(zero);
                if (i > 0) i -= 1;
            }

            try seq.serializeElement(one);
            if (i > 0) i -= 1;

            last_pos = pos;
        }
    }

    // Serialize remaining bits (which are all unset).
    if (last_pos != 0) {
        for (0..last_pos) |_| {
            try seq.serializeElement(zero);
        }
    }

    return try seq.end();
}

test "serialize - std.ArrayBitSet" {
    // Any size <= @bitSizeOf(usize) will result in std.IntegerBitSet being
    // used. So, 1 is added to size to make sure that std.ArrayBitSet is used.
    //
    // Also, another 1 is added to size to ensure that the bitset's length is
    // even, so that the LSB and MSB won't be the same. This lets us make sure
    // that the last element of a sequence is being serialized as the LSB of a
    // bitset, and not the MSB.
    const size = @bitSizeOf(usize) + 2;

    // Empty
    {
        var want = std.StaticBitSet(size).initEmpty();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = size } },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .U64 = 0 },
            .{ .SeqEnd = {} },
        });
    }

    // Full
    {
        var want = std.StaticBitSet(size).initFull();

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = size } },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .U64 = 1 },
            .{ .SeqEnd = {} },
        });
    }

    // Mixed (LSB set)
    {
        var want = std.StaticBitSet(size).initEmpty();
        {
            var i: usize = 0; // 0, 2, 4, ..., size - 2
            while (i < size) : (i += 2) want.set(i);
        }

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = size } },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .SeqEnd = {} },
        });
    }

    // Mixed (LSB unset)
    {
        var want = std.StaticBitSet(size).initEmpty();
        {
            var i: usize = 1; // 1, 3, 5, ..., size - 1
            while (i < size) : (i += 2) want.set(i);
        }

        try t.run(null, serialize, want, &.{
            .{ .Seq = .{ .len = size } },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .U64 = 1 },
            .{ .U64 = 0 },
            .{ .SeqEnd = {} },
        });
    }
}
