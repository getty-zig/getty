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
    allocator: ?std.mem.Allocator,
    /// The type being deserialized into.
    comptime T: type,
    /// A `getty.Deserializer` interface value.
    deserializer: anytype,
    /// A `getty.de.Visitor` interface value.
    visitor: anytype,
) !@TypeOf(visitor).Value {
    _ = T;

    return try deserializer.deserializeSeq(allocator, visitor);
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
            .name = "mixed (LSB unset)",
            .tokens = &.{
                .{ .Seq = .{ .len = 5 } },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.StaticBitSet(5).initEmpty();
                want.set(1);
                want.set(3);
                break :blk want;
            },
        },
        .{
            .name = "mixed (LSB set)",
            .tokens = &.{
                .{ .Seq = .{ .len = 5 } },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .I32 = 0 },
                .{ .I32 = 1 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.StaticBitSet(5).initEmpty();
                want.set(0);
                want.set(2);
                want.set(4);
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
