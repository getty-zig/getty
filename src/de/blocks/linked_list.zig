const std = @import("std");
const t = @import("getty/testing");

const LinkedListVisitor = @import("../impls/visitor/linked_list.zig").Visitor;

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.SinglyLinkedList");
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
    return LinkedListVisitor(T);
}

test "deserialize - linked list" {
    {
        var expected = std.SinglyLinkedList(i32){};

        try t.de.run(&[_]t.Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        var expected = std.SinglyLinkedList(i32){};
        var one = @TypeOf(expected).Node{ .data = 1 };
        var two = @TypeOf(expected).Node{ .data = 2 };
        var three = @TypeOf(expected).Node{ .data = 3 };

        expected.prepend(&one);
        one.insertAfter(&two);
        two.insertAfter(&three);

        try t.de.run(&[_]t.Token{
            .{ .Seq = .{ .len = 3 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = {} },
        }, expected);
    }

    {
        const getty = @import("../../getty.zig");

        const Child = std.SinglyLinkedList(i32);
        const Parent = std.SinglyLinkedList(Child);

        var expected = Parent{};
        var a = Child{};
        var b = Child{};
        var c = Child{};

        var one = Child.Node{ .data = 1 };
        var two = Child.Node{ .data = 2 };
        var three = Child.Node{ .data = 3 };
        b.prepend(&one);
        c.prepend(&three);
        c.prepend(&two);

        expected.prepend(&Parent.Node{ .data = c });
        expected.prepend(&Parent.Node{ .data = b });
        expected.prepend(&Parent.Node{ .data = a });

        const tokens = &[_]t.Token{
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
        var d = t.de.Deserializer.init(tokens);
        var v = getty.deserialize(std.testing.allocator, Parent, d.deserializer()) catch return error.UnexpectedTestError;
        defer getty.de.free(std.testing.allocator, v);

        try std.testing.expectEqual(expected.len(), v.len());
        var iterator = expected.first;
        while (iterator) |node| : (iterator = node.next) {
            var got_node = v.popFirst();
            try std.testing.expect(got_node != null);
            defer std.testing.allocator.destroy(got_node.?);

            try std.testing.expectEqual(node.data.len(), got_node.?.data.len());
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
