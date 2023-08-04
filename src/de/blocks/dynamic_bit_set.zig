const std = @import("std");
const test_ally = std.testing.allocator;

const DynamicBitSetVisitor = @import("../impls/visitor/dynamic_bit_set.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.DynamicBitSet or T == std.DynamicBitSetUnmanaged;
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
    return DynamicBitSetVisitor(T);
}

test "deserialize - std.DynamicBitSet" {
    const tests = .{
        .{
            .name = "zero-sized",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = try std.DynamicBitSet.initEmpty(test_ally, 0),
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
            .want = try std.DynamicBitSet.initEmpty(test_ally, 3),
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
            .want = try std.DynamicBitSet.initFull(test_ally, 3),
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
                var want = try std.DynamicBitSet.initEmpty(test_ally, 10);
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
                var want = try std.DynamicBitSet.initEmpty(test_ally, 10);
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
        var want = t.want;
        defer want.deinit();

        const Want = @TypeOf(want);
        var got = try testing.deserialize(test_ally, t.name, Self, Want, t.tokens);
        defer got.deinit();

        try testing.expectEqual(t.name, want.capacity(), got.capacity());
        try testing.expect(t.name, want.eql(got));
    }
}

test "deserialize - std.DynamicBitSetUnmanaged" {
    const tests = .{
        .{
            .name = "zero-sized",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = try std.DynamicBitSetUnmanaged.initEmpty(test_ally, 0),
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
            .want = try std.DynamicBitSetUnmanaged.initEmpty(test_ally, 3),
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
            .want = try std.DynamicBitSetUnmanaged.initFull(test_ally, 3),
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
                var want = try std.DynamicBitSetUnmanaged.initEmpty(test_ally, 10);
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
                var want = try std.DynamicBitSetUnmanaged.initEmpty(test_ally, 10);
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
        var want = t.want;
        defer want.deinit(test_ally);

        const Want = @TypeOf(want);
        var got = try testing.deserialize(test_ally, t.name, Self, Want, t.tokens);
        defer got.deinit(test_ally);

        try testing.expectEqual(t.name, want.capacity(), got.capacity());
        try testing.expect(t.name, want.eql(got));
    }
}
