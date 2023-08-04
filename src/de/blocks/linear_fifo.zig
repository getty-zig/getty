const std = @import("std");

const getty_free = @import("../free.zig").free;
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
    return LinearFifoVisitor(T);
}

/// Frees resources allocated by Getty during deserialization.
pub fn free(
    /// A memory allocator.
    ally: std.mem.Allocator,
    /// A `getty.Deserializer` interface type.
    comptime Deserializer: type,
    /// A value to deallocate.
    value: anytype,
) void {
    const is_buffer_dynamic = comptime std.meta.FieldType(@TypeOf(value), .allocator) != void;
    const is_buffer_static = comptime @typeInfo(std.meta.FieldType(@TypeOf(value), .buf)) == .Array;

    // Linearize the buffer so we can read it as a contiguous slice.
    var mut = value;
    mut.realign();
    for (mut.readableSlice(0)) |v| {
        getty_free(ally, Deserializer, v);
    }
    if (is_buffer_dynamic) {
        value.deinit();
    } else if (!is_buffer_static) {
        ally.free(value.buf);
    }
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

        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);

        try testing.expectEqual(t.name, t.want.readableLength(), got.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), got.peekItem(i));
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);

        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.readableLength(), got.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), got.peekItem(i));
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer t.want.deinit();

        const Want = @TypeOf(t.want);

        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.readableLength(), got.readableLength());

        for (0..t.want.readableLength()) |i| {
            try testing.expectEqual(t.name, t.want.peekItem(i), got.peekItem(i));
        }
    }
}
