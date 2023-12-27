const require = @import("protest").require;
const std = @import("std");

const DoublyLinkedListVisitor = @import("../impls/visitor/doubly_linked_list.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "linked_list.DoublyLinkedList");
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
    return DoublyLinkedListVisitor(T);
}

test "deserialize - std.DoublyLinkedList" {
    const List = std.DoublyLinkedList(i32);

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
                want.append(&one);
                want.append(&two);
                want.append(&three);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);

        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try require.equalf(t.want.len, result.value.len, "Test case: {s}", .{t.name});

        var it = t.want.first;
        while (it) |node| : (it = node.next) {
            const got_node = result.value.popFirst();
            try require.notNullf(got_node, "Test case: {s}", .{t.name});
            try require.equalf(node.data, got_node.?.data, "Test case: {s}", .{t.name});
        }
    }
}

test "deserialize - std.DoublyLinkedList (recursive)" {
    const Child = std.DoublyLinkedList(i32);
    const Parent = std.DoublyLinkedList(Child);

    var expected = Parent{};
    const a = Child{};
    var b = Child{};
    var c = Child{};

    var child_one = Child.Node{ .data = 1 };
    var child_two = Child.Node{ .data = 2 };
    var child_three = Child.Node{ .data = 3 };
    b.append(&child_one);
    c.append(&child_two);
    c.append(&child_three);

    var parent_one = Parent.Node{ .data = a };
    var parent_two = Parent.Node{ .data = b };
    var parent_three = Parent.Node{ .data = c };

    expected.append(&parent_one);
    expected.append(&parent_two);
    expected.append(&parent_three);

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

    var result = try testing.deserialize(null, Self, Parent, tokens);
    defer result.deinit();

    try require.equal(expected.len, result.value.len);

    var it = expected.first;
    while (it) |node| : (it = node.next) {
        var got_node = result.value.popFirst();

        // Sanity node check.
        try require.notNull(got_node);

        // Check that the inner lists' lengths match.
        try require.equal(node.data.len, got_node.?.data.len);

        var inner_it = node.data.first;
        while (inner_it) |inner_node| : (inner_it = inner_node.next) {
            const got_inner_node = got_node.?.data.popFirst();

            // Sanity inner node check.
            try require.notNull(got_inner_node);

            // Check that the inner lists' data match.
            try require.equal(inner_node.data, got_inner_node.?.data);
        }
    }
}
