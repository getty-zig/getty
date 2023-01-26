const std = @import("std");
const t = @import("../testing.zig");

const TailQueueVisitor = @import("../impls/visitor/tail_queue.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.TailQueue");
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
    return TailQueueVisitor(T);
}

test "deserialize - tail queue" {
    {
        var expected = std.TailQueue(i32){};

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = std.TailQueue(i32){};
        var one = @TypeOf(expected).Node{ .data = 1 };
        var two = @TypeOf(expected).Node{ .data = 2 };
        var three = @TypeOf(expected).Node{ .data = 3 };

        expected.append(&one);
        expected.append(&two);
        expected.append(&three);

        try t.run(deserialize, Visitor, &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        const free = @import("../free.zig").free;

        const Child = std.TailQueue(i32);
        const Parent = std.TailQueue(Child);

        var expected = Parent{};
        var a = Child{};
        var b = Child{};
        var c = Child{};

        var one = Child.Node{ .data = 1 };
        var two = Child.Node{ .data = 2 };
        var three = Child.Node{ .data = 3 };
        b.append(&one);
        c.append(&two);
        c.append(&three);

        expected.append(&Parent.Node{ .data = a });
        expected.append(&Parent.Node{ .data = b });
        expected.append(&Parent.Node{ .data = c });

        const tokens = &.{
            .{ .Seq = .{ .len = 3 } },
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = {} },
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
            .{ .SeqEnd = {} },
        };

        // Test manually since the `t` function cannot recursively test
        // user-defined containers containers without ugly hacks.
        var v = Visitor(Parent){};
        const visitor = v.visitor();

        var d = t.DefaultDeserializer.init(tokens);
        const deserializer = d.deserializer();

        var got = deserialize(std.testing.allocator, Parent, deserializer, visitor) catch return error.UnexpectedTestError;
        defer free(std.testing.allocator, got);

        try std.testing.expectEqual(expected.len, got.len);
        var iterator = expected.first;
        while (iterator) |node| : (iterator = node.next) {
            var got_node = got.popFirst();
            try std.testing.expect(got_node != null);
            defer std.testing.allocator.destroy(got_node.?);

            try std.testing.expectEqual(node.data.len, got_node.?.data.len);
            var inner_iterator = node.data.first;
            while (inner_iterator) |inner_node| : (inner_iterator = inner_node.next) {
                var got_inner_node = got_node.?.data.popFirst();
                try std.testing.expect(got_inner_node != null);
                defer std.testing.allocator.destroy(got_inner_node.?);

                try std.testing.expectEqual(inner_node.data, got_inner_node.?.data);
            }
        }
    }
}
