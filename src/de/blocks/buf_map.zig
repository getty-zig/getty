const std = @import("std");

const BufMapVisitor = @import("../impls/visitor/buf_map.zig").Visitor;
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
    /// A memory allocator for heap values that are part of the returned
    /// deserialized value.
    result_ally: std.mem.Allocator,
    /// A memory allocator for heap values that are not part of the returned
    /// deserialized value.
    scratch_ally: std.mem.Allocator,
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

test "deserialize - std.BufMap" {
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
        while (it.next()) |kv| {
            try testing.expectEqualStrings(t.name, t.want.get(kv.key_ptr.*).?, result.value.get(kv.key_ptr.*).?);
        }
    }
}
