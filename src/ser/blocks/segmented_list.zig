const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "segmented_list.SegmentedList");
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

    var s = try serializer.serializeSeq(value.len);
    const seq = s.seq();
    var it = value.constIterator(0);
    while (it.next()) |elem| {
        try seq.serializeElement(elem.*);
    }
    return try seq.end();
}

test "serialize - segmented list" {
    var list = std.SegmentedList(u32, 0){};
    defer list.deinit(std.testing.allocator);

    try t.run(null, serialize, list, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try list.appendSlice(std.testing.allocator, &[_]u32{ 1, 2, 4, 8, 16, 32 });

    try t.run(null, serialize, list, &.{
        .{ .Seq = .{ .len = 6 } },
        .{ .U32 = 1 },
        .{ .U32 = 2 },
        .{ .U32 = 4 },
        .{ .U32 = 8 },
        .{ .U32 = 16 },
        .{ .U32 = 32 },
        .{ .SeqEnd = {} },
    });
}
