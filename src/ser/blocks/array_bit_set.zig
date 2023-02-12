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
    allocator: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = allocator;

    const Value = @TypeOf(value);
    const MaskInt = Value.MaskInt;
    const zero = @as(MaskInt, 0);
    const one = @as(MaskInt, 1);

    const cap = value.capacity();
    std.debug.assert(cap != 0); // std.IntegerBitSet would be used if cap was 0.

    var s = try serializer.serializeSeq(cap);
    const seq = s.seq();

    // Serialize bits from N to M, where N is value's bit length and M is the
    // last bit position in value that is set.
    var it = value.iterator(.{ .direction = .reverse });
    var i: usize = cap - 1;

    while (it.next()) |pos| {
        while (i != pos) {
            try seq.serializeElement(zero);
            if (i > 0) i -= 1;
        }

        try seq.serializeElement(one);
        if (i > 0) i -= 1;
    }

    // Serialize remaining bits (which are all unset).
    if (i != 0) {
        i += 1;

        while (i != 0) : (i -= 1) {
            try seq.serializeElement(zero);
        }
    }

    return try seq.end();
}

// NOTE: The token sequence's length needs to match the bitset's size, which
// must be a bit width supported by the test serializer.
test "serialize - std.ArrayBitSet" {
    const size = @bitSizeOf(usize) + 1;

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
            .{ .SeqEnd = {} },
        });
    }

    // Mixed
    {
        var want = std.StaticBitSet(size).initEmpty();
        want.set(1);
        want.set(3);
        want.set(5);
        want.set(7);
        want.set(9);
        want.set(11);
        want.set(13);
        want.set(15);
        want.set(17);
        want.set(19);
        want.set(21);
        want.set(23);
        want.set(25);
        want.set(27);
        want.set(29);
        want.set(31);
        want.set(33);
        want.set(35);
        want.set(37);
        want.set(39);
        want.set(41);
        want.set(43);
        want.set(45);
        want.set(47);
        want.set(49);
        want.set(51);
        want.set(53);
        want.set(55);
        want.set(57);
        want.set(59);
        want.set(61);
        want.set(63);

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
            .{ .SeqEnd = {} },
        });
    }
}
