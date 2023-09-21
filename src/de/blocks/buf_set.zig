const std = @import("std");

const BufSetVisitor = @import("../impls/visitor/buf_set.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.BufSet;
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
    return BufSetVisitor(T);
}

test "deserialize - std.BufSet" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 0 } },
                .{ .SeqEnd = {} },
            },
            .want = std.BufSet.init(std.testing.allocator),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Seq = .{ .len = 3 } },
                .{ .String = "foo" },
                .{ .String = "bar" },
                .{ .String = "baz" },
                .{ .SeqEnd = {} },
            },
            .want = blk: {
                var want = std.BufSet.init(std.testing.allocator);
                try want.insert("foo");
                try want.insert("bar");
                try want.insert("baz");
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        defer {
            var mut = t.want;
            mut.deinit();
        }

        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.count(), result.value.count());

        var it = t.want.iterator();
        while (it.next()) |key_ptr| {
            try testing.expect(t.name, result.value.contains(key_ptr.*));
        }
    }
}
