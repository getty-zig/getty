const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "priority_dequeue.PriorityDequeue");
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    v: anytype,
    /// A `getty.Serializer` interface value.
    s: anytype,
) @TypeOf(s).Err!@TypeOf(s).Ok {
    _ = ally;

    var ss = try s.serializeSeq(v.count());
    const seq = ss.seq();
    {
        var mut = v;
        var it = mut.iterator();
        while (it.next()) |elem| {
            try seq.serializeElement(elem);
        }
    }
    return try seq.end();
}

fn lessThan(context: void, a: i32, b: i32) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

test "serialize - std.PriorityDequeue" {
    var deque = std.PriorityDequeue(i32, void, lessThan).init(std.testing.allocator, {});
    defer deque.deinit();

    try t.run(null, serialize, deque, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try deque.add(1);
    try deque.add(2);
    try deque.add(3);

    try deque.addSlice(&.{ -1, -2, -3 });

    try t.run(null, serialize, deque, &.{
        .{ .Seq = .{ .len = 6 } },
        .{ .I32 = -3 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .I32 = 1 },
        .{ .I32 = -1 },
        .{ .I32 = -2 },
        .{ .SeqEnd = {} },
    });
}
