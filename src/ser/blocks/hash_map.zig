const std = @import("std");
const t = @import("getty/testing");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "hash_map");
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
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

        try t.ser.run(serialize, map, &[_]t.Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(1, 2);

        try t.ser.run(serialize, map, &[_]t.Token{
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

        try t.ser.run(serialize, map, &[_]t.Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put(std.testing.allocator, 1, 2);

        try t.ser.run(serialize, map, &[_]t.Token{
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

        try t.ser.run(serialize, map, &[_]t.Token{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });

        try map.put("1", 2);

        try t.ser.run(serialize, map, &[_]t.Token{
            .{ .Map = .{ .len = 1 } },
            .{ .String = "1" },
            .{ .I32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}
