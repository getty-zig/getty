const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    const is_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
    const is_array_hash_map = comptime std.mem.startsWith(u8, @typeName(T), "array_hash_map");

    return is_hash_map or is_array_hash_map;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = ally;

    var m = try serializer.serializeMap(value.count());
    const map = m.map();
    {
        var iterator = value.iterator();
        while (iterator.next()) |entry| {
            try map.serializeEntry(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return try map.end();
}

test "serialize - hash map" {
    // managed
    {
        var map = std.AutoHashMap(i32, i32).init(std.testing.allocator);
        defer map.deinit();

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(1, 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // unmanaged
    {
        var map = std.AutoHashMapUnmanaged(i32, i32){};
        defer map.deinit(std.testing.allocator);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(std.testing.allocator, 1, 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // string
    {
        var map = std.StringHashMap(i32).init(std.testing.allocator);
        defer map.deinit();

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put("1", 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .String = "1" },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}

test "serialize - array hash map" {
    // managed
    {
        var map = std.AutoArrayHashMap(i32, i32).init(std.testing.allocator);
        defer map.deinit();

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(1, 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // unmanaged
    {
        var map = std.AutoArrayHashMapUnmanaged(i32, i32){};
        defer map.deinit(std.testing.allocator);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(std.testing.allocator, 1, 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }

    // string
    {
        var map = std.StringArrayHashMap(i32).init(std.testing.allocator);
        defer map.deinit();

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put("1", 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 1 } },
            .{ .String = "1" },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}
