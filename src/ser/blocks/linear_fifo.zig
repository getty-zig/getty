const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "fifo.LinearFifo");
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

    var s = try serializer.serializeSeq(value.readableLength());
    const seq = s.seq();
    for (0..value.readableLength()) |i| {
        try seq.serializeElement(value.peekItem(i));
    }
    return try seq.end();
}

test "serialize - std.LinearFifo (static)" {
    var fifo = std.fifo.LinearFifo(u8, .{ .Static = 8 }).init();

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    fifo.writeAssumeCapacity(&[_]u8{ 8, 7, 6, 5, 1, 2, 3, 4 });
    fifo.discard(4);
    fifo.writeAssumeCapacity(&[_]u8{ 8, 7, 6, 5 });

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 8 } },
        .{ .U8 = 1 },
        .{ .U8 = 2 },
        .{ .U8 = 3 },
        .{ .U8 = 4 },
        .{ .U8 = 8 },
        .{ .U8 = 7 },
        .{ .U8 = 6 },
        .{ .U8 = 5 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - std.LinearFifo (slice)" {
    var buf: [10]u8 = undefined;
    var fifo = std.fifo.LinearFifo(u8, .Slice).init(&buf);

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    fifo.writeAssumeCapacity(&[_]u8{ 8, 7, 6, 5, 1, 2, 3, 4 });
    fifo.discard(4);
    fifo.writeAssumeCapacity(&[_]u8{ 8, 7, 6, 5 });

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 8 } },
        .{ .U8 = 1 },
        .{ .U8 = 2 },
        .{ .U8 = 3 },
        .{ .U8 = 4 },
        .{ .U8 = 8 },
        .{ .U8 = 7 },
        .{ .U8 = 6 },
        .{ .U8 = 5 },
        .{ .SeqEnd = {} },
    });
}

test "serialize - std.LinearFifo (dynamic)" {
    var fifo = std.fifo.LinearFifo(u8, .Dynamic).init(std.testing.allocator);
    defer fifo.deinit();

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try fifo.write(&[_]u8{ 8, 7, 6, 5, 1, 2, 3, 4 });
    fifo.discard(4);
    try fifo.write(&[_]u8{ 8, 7, 6, 5 });

    try t.run(null, serialize, fifo, &.{
        .{ .Seq = .{ .len = 8 } },
        .{ .U8 = 1 },
        .{ .U8 = 2 },
        .{ .U8 = 3 },
        .{ .U8 = 4 },
        .{ .U8 = 8 },
        .{ .U8 = 7 },
        .{ .U8 = 6 },
        .{ .U8 = 5 },
        .{ .SeqEnd = {} },
    });
}
