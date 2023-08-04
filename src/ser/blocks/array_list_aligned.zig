const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "array_list");
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

    var s = try serializer.serializeSeq(value.items.len);
    const seq = s.seq();
    for (value.items) |elem| {
        try seq.serializeElement(elem);
    }
    return try seq.end();
}

test "serialize - array list" {
    // managed
    {
        var list = std.ArrayList(std.ArrayList(u8)).init(std.testing.allocator);
        defer list.deinit();

        var a = std.ArrayList(u8).init(std.testing.allocator);
        defer a.deinit();

        var b = std.ArrayList(u8).init(std.testing.allocator);
        defer b.deinit();

        var c = std.ArrayList(u8).init(std.testing.allocator);
        defer c.deinit();

        try t.run(null, serialize, list, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try list.appendSlice(&[_]std.ArrayList(u8){ a, b, c });

        try t.run(null, serialize, list, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        });
    }

    // unmanaged
    {
        var list = std.ArrayListUnmanaged(std.ArrayListUnmanaged(u8)){};
        defer list.deinit(std.testing.allocator);

        var a = std.ArrayListUnmanaged(u8){};
        defer a.deinit(std.testing.allocator);

        var b = std.ArrayListUnmanaged(u8){};
        defer b.deinit(std.testing.allocator);

        var c = std.ArrayListUnmanaged(u8){};
        defer c.deinit(std.testing.allocator);

        try t.run(null, serialize, list, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        });

        try b.append(std.testing.allocator, 1);
        try c.append(std.testing.allocator, 2);
        try c.append(std.testing.allocator, 3);
        try list.appendSlice(std.testing.allocator, &[_]std.ArrayListUnmanaged(u8){ a, b, c });

        try t.run(null, serialize, list, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .U8 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .U8 = 2 },
            .{ .U8 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        });
    }
}
