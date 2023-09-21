const std = @import("std");

const LinearFifoVisitor = @import("../impls/visitor/linear_fifo.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "fifo.LinearFifo");
}

/// Specifies the deserialization process for types relevant to this block.
pub fn deserialize(
    /// A memory allocator.
    ally: std.mem.Allocator,
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
    return LinearFifoVisitor(T);
}

test "deserialize - std.LinearFifo (static)" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.fifo.LinearFifo(u32, .{ .Static = 8 }).init(),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 8 } },
                .{ .U32 = 1 },
                .{ .U32 = 2 },
                .{ .U32 = 3 },
                .{ .U32 = 4 },
                .{ .U32 = 5 },
                .{ .U32 = 6 },
                .{ .U32 = 7 },
                .{ .U32 = 8 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.fifo.LinearFifo(u32, .{ .Static = 8 }).init();
                want.writeAssumeCapacity(&[_]u32{ 1, 2, 3, 4, 1, 2, 3, 4 });
                want.discard(4);
                want.writeAssumeCapacity(&[_]u32{ 5, 6, 7, 8 });
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);

        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.readableLength(), result.value.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), result.value.peekItem(i));
        }
    }
}

test "deserialize - std.LinearFifo (slice)" {
    var buf: [10]u32 = undefined;

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.fifo.LinearFifo(u32, .Slice).init(&[_]u32{}),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 8 } },
                .{ .U32 = 1 },
                .{ .U32 = 2 },
                .{ .U32 = 3 },
                .{ .U32 = 4 },
                .{ .U32 = 5 },
                .{ .U32 = 6 },
                .{ .U32 = 7 },
                .{ .U32 = 8 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.fifo.LinearFifo(u32, .Slice).init(&buf);
                want.writeAssumeCapacity(&[_]u32{ 1, 2, 3, 4, 1, 2, 3, 4 });
                want.discard(4);
                want.writeAssumeCapacity(&[_]u32{ 5, 6, 7, 8 });
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);

        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.readableLength(), result.value.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), result.value.peekItem(i));
        }
    }
}

test "deserialize - std.LinearFifo (dynamic)" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.fifo.LinearFifo(u32, .Dynamic).init(std.testing.allocator),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 8 } },
                .{ .U32 = 1 },
                .{ .U32 = 2 },
                .{ .U32 = 3 },
                .{ .U32 = 4 },
                .{ .U32 = 5 },
                .{ .U32 = 6 },
                .{ .U32 = 7 },
                .{ .U32 = 8 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.fifo.LinearFifo(u32, .Dynamic).init(std.testing.allocator);
                try want.write(&[_]u32{ 1, 2, 3, 4, 1, 2, 3, 4 });
                want.discard(4);
                try want.write(&[_]u32{ 5, 6, 7, 8 });
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        defer t.want.deinit();

        const Want = @TypeOf(t.want);

        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.readableLength(), result.value.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), result.value.peekItem(i));
        }
    }
}
