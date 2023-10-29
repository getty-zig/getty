const std = @import("std");

const IndexedMapVisitor = @import("../impls/visitor/indexed_map.zig").Visitor;
const testing = @import("../testing.zig");

const Self = @This();

/// Specifies all types that can be deserialized by this block.
pub fn is(
    /// The type being deserialized into.
    comptime T: type,
) bool {
    const is_indexed_map = comptime std.mem.startsWith(u8, @typeName(T), "enums.IndexedMap");
    const is_enum_map = comptime std.mem.startsWith(u8, @typeName(T), "enums.EnumMap");

    return is_indexed_map or is_enum_map;
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

    return try deserializer.deserializeMap(result_ally, scratch_ally, visitor);
}

/// Returns a type that implements `getty.de.Visitor`.
pub fn Visitor(
    /// The type being deserialized into.
    comptime T: type,
) type {
    return IndexedMapVisitor(T);
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

test "deserialize - std.IndexedMap" {
    const Color = StringIndexer(&.{ "red", "yellow", "blue" });

    const tests = .{
        // std.IndexedMap's put function directly accesses its internal
        // dense array without checking length of the array. Since the
        // length of the array is determined by the Indexer, this will
        // fail to compile with "error: indexing into empty array is not
        // allowed" on an empty index.
        // .{
        //     .name = "zero-sized",
        //     .tokens = &.{
        //         .{ .Map = .{ .len = 0 } },
        //         .{ .MapEnd = {} },
        //     },
        //     .want = std.enums.IndexedMap(StringIndexer(&.{}), u32, null){},
        // },
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.enums.IndexedMap(Color, u32, null){},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .String = "red" },
                .{ .U32 = 1 },
                .{ .String = "yellow" },
                .{ .U32 = 3 },
                .{ .String = "blue" },
                .{ .U32 = 2 },
                .{ .MapEnd = {} },
            },
            .want = blk: {
                var want = std.enums.IndexedMap(Color, u32, null){};
                want.put("red", 1);
                want.put("yellow", 3);
                want.put("blue", 2);
                break :blk want;
            },
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.count(), result.value.count());

        var mut = t.want;
        var it = mut.iterator();
        while (it.next()) |kv| {
            try testing.expect(t.name, result.value.contains(kv.key));
            try testing.expectEqual(t.name, kv.value.*, result.value.get(kv.key).?);
        }
    }
}

test "deserialize - std.EnumMap" {
    const Color = enum { red, yellow, blue };

    const tests = .{
        // std.EnumIndexer, which is used internally by std.EnumMap,
        // fails to compile on an empty enum due to field access occuring
        // before checking field length.
        // .{
        //     .name = "zero-sized",
        //     .tokens = &.{
        //         .{ .Map = .{ .len = 0 } },
        //         .{ .MapEnd = {} },
        //     },
        //     .want = std.enums.EnumMap(enum {}, u32){},
        // },
        .{
            .name = "empty",
            .tokens = &.{
                .{ .Map = .{ .len = 0 } },
                .{ .MapEnd = {} },
            },
            .want = std.enums.EnumMap(Color, u32){},
        },
        .{
            .name = "non-empty",
            .tokens = &.{
                .{ .Map = .{ .len = 3 } },
                .{ .Enum = {} },
                .{ .String = "red" },
                .{ .U32 = 1 },
                .{ .Enum = {} },
                .{ .String = "yellow" },
                .{ .U32 = 3 },
                .{ .Enum = {} },
                .{ .String = "blue" },
                .{ .U32 = 2 },
                .{ .MapEnd = {} },
            },
            .want = std.enums.EnumMap(Color, u32).init(.{
                .red = 1,
                .yellow = 3,
                .blue = 2,
            }),
        },
    };

    inline for (tests) |t| {
        const Want = @TypeOf(t.want);
        var result = try testing.deserialize(t.name, Self, Want, t.tokens);
        defer result.deinit();

        try testing.expectEqual(t.name, t.want.count(), result.value.count());

        var mut = t.want;
        var it = mut.iterator();
        while (it.next()) |kv| {
            try testing.expect(t.name, result.value.contains(kv.key));
            try testing.expectEqual(t.name, kv.value.*, result.value.get(kv.key).?);
        }
    }
}
