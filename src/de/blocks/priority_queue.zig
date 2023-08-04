const std = @import("std");

const getty_free = @import("../free.zig").free;
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
    return PriorityQueueVisitor(T);
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
    var mut = value;
    var it = mut.iterator();
    while (it.next()) |elem| {
        getty_free(ally, Deserializer, elem);
    }
    value.deinit();
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer free(std.testing.allocator, Deserializer, t.want);

        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        // Check that the queues' lengths match.
        try testing.expectEqual(t.name, t.want.count(), got.count());

        var want_it = blk: {
            var mut = t.want;
            break :blk mut.iterator();
        };

        var got_it = blk: {
            var mut = got;
            break :blk mut.iterator();
        };

        while (want_it.next()) |elem| {
            var got_elem = got_it.next();

            // Check that the queues' elements match.
            try testing.expectEqual(t.name, elem, got_elem.?);
        }
    }
}
