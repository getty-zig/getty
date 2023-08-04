const std = @import("std");

const BufSetVisitor = @import("../impls/visitor/buf_set.zig").Visitor;
const getty_free = @import("../free.zig").free;
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
    return BufSetVisitor(T);
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
    var it = value.hash_map.keyIterator();
    while (it.next()) |key_ptr| {
        getty_free(ally, Deserializer, key_ptr.*);
    }
    var mut = value;
    mut.hash_map.deinit();
}

test "deserialize - buf set" {
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

    const Deserializer = testing.DefaultDeserializer.@"getty.Deserializer";

    inline for (tests) |t| {
        defer free(std.testing.allocator, Deserializer, t.want);

        const Want = @TypeOf(t.want);
        const got = try testing.deserialize(std.testing.allocator, t.name, Self, Want, t.tokens);
        defer free(std.testing.allocator, Deserializer, got);

        try testing.expectEqual(t.name, t.want.count(), got.count());

        var it = t.want.iterator();
        while (it.next()) |key_ptr| {
            try testing.expect(t.name, got.contains(key_ptr.*));
        }
    }
}
