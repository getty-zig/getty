const std = @import("std");

const getty_free = @import("../free.zig").free;
const SinglyLinkedListVisitor = @import("../impls/visitor/singly_linked_list.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

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
    return SinglyLinkedListVisitor(T);
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
    var iterator = value.first;
    while (iterator) |node| {
        getty_free(ally, Deserializer, node.data);
        iterator = node.next;
        ally.destroy(node);
    }
}

test "deserialize - std.SinglyLinkedList" {
    const List = std.SinglyLinkedList(i32);

    var one = List.Node{ .data = 1 };
    var two = List.Node{ .data = 2 };
    var three = List.Node{ .data = 3 };

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = List{},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .I32 = 1 },
                .{ .I32 = 2 },
                .{ .I32 = 3 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = List{};
                want.prepend(&one);
                one.insertAfter(&two);
                two.insertAfter(&three);
                break :blk want;
            },
        },
    };

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);

        var got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        // Check that the lists' lengths match.
        try testing.expectEqual(t.name, t.want.len(), got.len());

        var it = t.want.first;
        while (it) |node| : (it = node.next) {
            var got_node = got.popFirst();

            // Sanity node check.
            try testing.expect(t.name, got_node != null);
            defer std.testing.allocator.destroy(got_node.?);

            // Check that the lists' data match.
            try testing.expectEqual(t.name, node.data, got_node.?.data);
        }
    }
}

test "deserialize - linked list (recursive)" {
    const Child = std.SinglyLinkedList(i32);
    const Parent = std.SinglyLinkedList(Child);

    var expected = Parent{};
    var a = Child{};
    var b = Child{};
    var c = Child{};

    var child_one = Child.Node{ .data = 1 };
    var child_two = Child.Node{ .data = 2 };
    var child_three = Child.Node{ .data = 3 };
    b.prepend(&child_one);
    c.prepend(&child_three);
    c.prepend(&child_two);

    var parent_one = Parent.Node{ .data = a };
    var parent_two = Parent.Node{ .data = b };
    var parent_three = Parent.Node{ .data = c };

    expected.prepend(&parent_three);
    expected.prepend(&parent_two);
    expected.prepend(&parent_one);

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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    var got = try testing.deserialize(std.testing.allocator, null, Self, Parent, tokens);
    defer free(std.testing.allocator, Deserializer, got);

    // Check that the lists' lengths match.
    try std.testing.expectEqual(expected.len(), got.len());

    var it = expected.first;
    while (it) |node| : (it = node.next) {
        var got_node = got.popFirst();

        // Sanity node check.
        try std.testing.expect(got_node != null);
        defer std.testing.allocator.destroy(got_node.?);

        // Check that the inner lists' lengths match.
        try std.testing.expectEqual(node.data.len(), got_node.?.data.len());

        var inner_it = node.data.first;
        while (inner_it) |inner_node| : (inner_it = inner_node.next) {
            var got_inner_node = got_node.?.data.popFirst();

            // Sanity inner node check.
            try std.testing.expect(got_inner_node != null);
            defer std.testing.allocator.destroy(got_inner_node.?);

            // Check that the inner lists' data match.
            try std.testing.expectEqual(inner_node.data, got_inner_node.?.data);
        }
    }
}
