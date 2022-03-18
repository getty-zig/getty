const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime HashMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            visitMap,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const Value = HashMap;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            const K = std.meta.fieldInfo(Value.KV, .key).field_type;
            const V = std.meta.fieldInfo(Value.KV, .value).field_type;
            const unmanaged = std.mem.startsWith(
                u8,
                @typeName(Value),
                "std.hash_map.HashMapUnmanaged",
            );

            var hash_map = if (unmanaged) HashMap{} else HashMap.init(allocator.?);
            errdefer getty.de.free(allocator.?, hash_map);

            while (try map.nextKey(allocator, K)) |key| {
                errdefer getty.de.free(allocator.?, key);

                const value = try map.nextValue(allocator, V);
                errdefer getty.de.free(allocator.?, value);

                try if (unmanaged) hash_map.put(allocator.?, key, value) else hash_map.put(key, value);
            }

            return hash_map;
        }
    };
}
