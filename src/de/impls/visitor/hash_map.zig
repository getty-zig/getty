const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime HashMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = HashMap;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            const K = std.meta.fieldInfo(Value.KV, .key).type;
            const V = std.meta.fieldInfo(Value.KV, .value).type;
            const unmanaged = comptime std.mem.startsWith(
                u8,
                @typeName(Value),
                "hash_map.HashMapUnmanaged",
            );

            var hash_map = if (unmanaged) HashMap{} else HashMap.init(allocator.?);
            errdefer de.free(allocator.?, hash_map);

            while (try map.nextKey(allocator, K)) |key| {
                errdefer de.free(allocator.?, key);

                const value = try map.nextValue(allocator, V);
                errdefer de.free(allocator.?, value);

                try if (unmanaged) hash_map.put(allocator.?, key, value) else hash_map.put(key, value);
            }

            return hash_map;
        }
    };
}
