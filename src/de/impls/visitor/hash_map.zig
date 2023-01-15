const std = @import("std");

const de = @import("../../de.zig").de;

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
            const unmanaged = is_hash_map_unamanaged or is_array_hash_map_unmanaged;

            var hash_map = if (unmanaged) HashMap{} else HashMap.init(allocator.?);
            errdefer de.free(allocator.?, hash_map);

            while (try map.nextKey(allocator, K)) |key| {
                errdefer if (map.isKeyAllocated(@TypeOf(key))) {
                    de.free(allocator.?, key);
                };

                const value = try map.nextValue(allocator, V);
                errdefer de.free(allocator.?, value);

                try if (unmanaged) hash_map.put(allocator.?, key, value) else hash_map.put(key, value);
            }

            return hash_map;
        }

        const is_hash_map_unamanaged = std.mem.startsWith(u8, @typeName(Value), "hash_map.HashMapUnmanaged");
        const is_array_hash_map_unmanaged = std.mem.startsWith(u8, @typeName(Value), "array_hash_map.HashMapUnmanaged");
    };
}
