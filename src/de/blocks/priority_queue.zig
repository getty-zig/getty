const std = @import("std");

const PriorityQueueVisitor = @import("../impls/visitor/priority_queue.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "priority_queue.PriorityQueue");
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
    return PriorityQueueVisitor(T);
}

fn lessThan(context: void, a: i32, b: i32) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

test "deserialize - std.PriorityQueue" {
    const PQ = std.PriorityQueue(i32, void, lessThan);

    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = PQ.init(std.testing.allocator, {}),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 4 } },
                .{ .I32 = 1 },
                .{ .I32 = 3 },
                .{ .I32 = 2 },
                .{ .I32 = 4 },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = PQ.init(std.testing.allocator, {});
                try want.add(3);
                try want.add(1);
                try want.add(2);
                try want.add(4);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        defer t.want.deinit();

        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        // Check that the queues' lengths match.
        try testing.expectEqual(t.name, t.want.count(), result.value.count());

        var want_it = want_it: {
            var mut = t.want;
            break :want_it mut.iterator();
        };

        var got_it = got_it: {
            var mut = result.value;
            break :got_it mut.iterator();
        };

        while (want_it.next()) |elem| {
            var got_elem = got_it.next();

            // Check that the queues' elements match.
            try testing.expectEqual(t.name, elem, got_elem.?);
        }
    }
}
