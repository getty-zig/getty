const std = @import("std");
const test_ally = std.testing.allocator;

const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return T == std.DynamicBitSet;
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
    return try blocks.DynamicBitSetUnmanaged.serialize(ally, value.unmanaged, serializer);
}

test "serialize - std.DynamicBitSet" {
    const size = @bitSizeOf(usize) + 2;

    // Empty
    {
        var want = try std.DynamicBitSet.initEmpty(test_ally, size);
        defer want.deinit();

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
        var want = try std.DynamicBitSet.initFull(test_ally, size);
        defer want.deinit();

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
        var want = try std.DynamicBitSet.initEmpty(test_ally, size);
        defer want.deinit();
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
        var want = try std.DynamicBitSet.initEmpty(test_ally, size);
        defer want.deinit();
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
