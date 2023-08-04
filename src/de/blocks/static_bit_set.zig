const std = @import("std");

const BitSetVisitor = @import("../impls/visitor/bit_set.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_int_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.IntegerBitSet");
    const is_arr_bitset = comptime std.mem.startsWith(u8, @typeName(T), "bit_set.ArrayBitSet");

    return is_int_bitset or is_arr_bitset;
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeSeq(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return BitSetVisitor(T);
}

test "deserialize - std.IntegerBitSet" {
    const tests = .{
        .{
            .name = "zero-sized",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.StaticBitSet(0).initEmpty(),
        },
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 0 },
                .{ .I32 = 0 },
                .{ .I32 = 0 },
                .{ .SeqEnd = {} },
            },
            .want = std.StaticBitSet(3).initEmpty(),
        },
        .{
            .name = "full",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .I32 = 1 },
                .{ .I32 = 1 },
                .{ .SeqEnd = {} },
            },
            .want = std.StaticBitSet(3).initFull(),
        },
        .{
            .name = "mixed (LSB set)",
            .tokens = &.{
                .{ .Seq = .{ .len = 10 } },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.StaticBitSet(10).initEmpty();
                want.set(0);
                want.set(2);
                want.set(4);
                want.set(6);
                want.set(8);
                break :blk want;
            },
        },
        .{
            .name = "mixed (LSB unset)",
            .tokens = &.{
                .{ .Seq = .{ .len = 10 } },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.StaticBitSet(10).initEmpty();
                want.set(1);
                want.set(3);
                want.set(5);
                want.set(7);
                want.set(9);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        try testing.expectEqual(t.name, t.want, got);
    }
}

test "deserialize - std.ArrayBitSet" {
    // Any size <= @bitSizeOf(usize) will result in std.IntegerBitSet being
    // used. So, 1 is added to size to make sure that std.ArrayBitSet is used.
    //
    // Also, another 1 is added to size to ensure that the bitset's length is
    // even, so that the LSB and MSB won't be the same. This lets us make sure
    // that the last element of a sequence is being deserialized as the LSB of
    // a bitset, and not the MSB.
    const size = @bitSizeOf(usize) + 2;

    const tests = .{
        .{
            .name = "empty",
            .want = std.StaticBitSet(size).initEmpty(),
            .tokens = &.{
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
            },
        },
        .{
            .name = "full",
            .want = std.StaticBitSet(size).initFull(),
            .tokens = &.{
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
            },
        },
        .{
            .name = "mixed (LSB set)",
            .tokens = &.{
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
            },
            .want = blk: {
                var want = std.StaticBitSet(size).initEmpty();
                {
                    var i: usize = 0; // 0, 2, 4, ..., size - 2
                    while (i < size) : (i += 2) want.set(i);
                }
                break :blk want;
            },
        },
        .{
            .name = "mixed (LSB unset)",
            .tokens = &.{
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
            },
            .want = blk: {
                var want = std.StaticBitSet(size).initEmpty();
                {
                    var i: usize = 1; // 1, 3, 5, ..., size - 1
                    while (i < size) : (i += 2) want.set(i);
                }
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(null, t.name, Self, Want, t.tokens);
        try testing.expectEqual(t.name, t.want, got);
    }
}
