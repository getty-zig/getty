const std = @import("std");

const BufMapVisitor = @import("../impls/visitor/buf_map.zig").Visitor;
const getty_free = @import("../free.zig").free;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    return T == std.BufMap;
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

    return try deserializer.deserializeMap(ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return BufMapVisitor(T);
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
    var it = value.hash_map.iterator();
    while (it.next()) |entry| {
        getty_free(ally, Deserializer, entry.key_ptr.*);
        getty_free(ally, Deserializer, entry.value_ptr.*);
    }
    var mut = value;
    mut.hash_map.deinit();
}

test "deserialize - buf map" {
    const tests = .{
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.BufMap.init(std.testing.allocator),
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "one" },
                .{ .String = "foo" },
                .{ .String = "two" },
                .{ .String = "bar" },
                .{ .String = "three" },
                .{ .String = "baz" },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.BufMap.init(std.testing.allocator);
                try want.put("one", "foo");
                try want.put("two", "bar");
                try want.put("three", "baz");
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
        while (it.next()) |kv| {
            try testing.expectEqualStrings(t.name, t.want.get(kv.key_ptr.*).?, got.get(kv.key_ptr.*).?);
        }
    }
}
