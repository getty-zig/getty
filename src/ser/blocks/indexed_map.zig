const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const blocks = @import("../blocks.zig");
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    const is_indexed_map = comptime std.mem.startsWith(u8, @typeName(T), "enums.IndexedMap");
    const is_enum_map = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumMap");

    return is_indexed_map or is_enum_map;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    allocator: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
    _ = allocator;

    var m = try serializer.serializeMap(value.count());
    const map = m.map();

    var mut = value;
    var it = mut.iterator();
    while (it.next()) |entry| {
        try map.serializeEntry(entry.key, entry.value.*);
    }

    return try map.end();
}

fn StringIndexer(comptime str_keys: []const []const u8) type {
    if (str_keys.len == 0) {
        return struct {
            pub const Key = []const u8;
            pub const count: usize = 0;
            pub fn indexOf(k: Key) usize {
                _ = k;
                unreachable;
            }
            pub fn keyForIndex(i: usize) Key {
                _ = i;
                unreachable;
            }
        };
    }

    return struct {
        pub const Key = []const u8;
        pub const count: usize = str_keys.len;
        pub fn indexOf(k: Key) usize {
            for (str_keys, 0..) |key, i| {
                if (std.mem.eql(u8, k, key)) {
                    return i;
                }
            }
            unreachable;
        }
        pub fn keyForIndex(i: usize) Key {
            return str_keys[i];
        }
    };
}

test "serialize - std.IndexedMap" {
    const Color = StringIndexer(&.{ "red", "yellow", "blue", "green", "orange", "violet" });

    // zero-sized
    // std.IndexedMap's put function directly accesses its internal
    // dense array without checking length of the array. Since the
    // length of the array is determined by the Indexer, this will
    // fail to compile with "error: indexing into empty array is not
    // allowed" on an empty index.
    // {
    //     var map = std.enums.IndexedMap(StringIndexer(&.{}), u32, null){};

    //     try t.run(null, serialize, map, &.{
    //         .{ .Map = .{ .len = 0 } },
    //         .{ .MapEnd = {} },
    //     });
    // }

    // empty
    {
        var map = std.enums.IndexedMap(Color, u32, null){};

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });
    }

    // non-empty
    {
        var map = std.enums.IndexedMap(Color, u32, null){};

        map.put("red", 1);
        map.put("blue", 2);
        map.put("yellow", 3);
        map.put("orange", 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 4 } },
            .{ .String = "red" },
            .{ .U32 = 1 },
            .{ .String = "yellow" },
            .{ .U32 = 3 },
            .{ .String = "blue" },
            .{ .U32 = 2 },
            .{ .String = "orange" },
            .{ .U32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}

test "serialize - std.EnumMap" {
    const Color = enum { red, yellow, blue, green, orange, violet };

    // zero-sized
    // std.EnumIndexer, which is used internally by std.EnumMap,
    // fails to compile on an empty enum due to field access occuring
    // before checking field length.
    // {
    //     var map = std.enums.EnumMap(enum {}, u32){};

    //     try t.run(null, serialize, map, &.{
    //         .{ .Map = .{ .len = 0 } },
    //         .{ .MapEnd = {} },
    //     });
    // }

    // empty
    {
        var map = std.enums.EnumMap(Color, u32){};

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 0 } },
            .{ .MapEnd = {} },
        });
    }

    // non-empty
    {
        var map = std.enums.EnumMap(Color, u32){};

        map.put(.red, 1);
        map.put(.blue, 2);
        map.put(.yellow, 3);
        map.put(.orange, 2);

        try t.run(null, serialize, map, &.{
            .{ .Map = .{ .len = 4 } },
            .{ .Enum = {} },
            .{ .String = "red" },
            .{ .U32 = 1 },
            .{ .Enum = {} },
            .{ .String = "yellow" },
            .{ .U32 = 3 },
            .{ .Enum = {} },
            .{ .String = "blue" },
            .{ .U32 = 2 },
            .{ .Enum = {} },
            .{ .String = "orange" },
            .{ .U32 = 2 },
            .{ .MapEnd = {} },
        });
    }
}
