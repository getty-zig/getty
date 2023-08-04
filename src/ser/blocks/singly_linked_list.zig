const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList");
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

    var s = try serializer.serializeSeq(value.len());
    const seq = s.seq();
    {
        var iterator = value.first;
        while (iterator) |node| : (iterator = node.next) {
            try seq.serializeElement(node.data);
        }
    }
    return try seq.end();
}

test "serialize - std.SinglyLinkedList" {
    var list = std.SinglyLinkedList(i32){};

    try t.run(null, serialize, list, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    var one = @TypeOf(list).Node{ .data = 1 };
    var two = @TypeOf(list).Node{ .data = 2 };
    var three = @TypeOf(list).Node{ .data = 3 };

    list.prepend(&one);
    one.insertAfter(&two);
    two.insertAfter(&three);

    try t.run(null, serialize, list, &.{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = {} },
    });
}
