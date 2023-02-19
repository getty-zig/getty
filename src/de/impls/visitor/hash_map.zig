const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime HashMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = HashMap;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            if (allocator == null) {
                return error.MissingAllocator;
            }

            const a = allocator.?;

            const K = std.meta.fieldInfo(Value.KV, .key).type;
            const V = std.meta.fieldInfo(Value.KV, .value).type;
            const unmanaged = is_hash_map_unmanaged or is_array_hash_map_unmanaged;

            var hash_map = if (unmanaged) HashMap{} else HashMap.init(a);
            errdefer free(a, hash_map);

            while (try map.nextKey(a, K)) |key| {
                errdefer if (map.isKeyAllocated(@TypeOf(key))) {
                    free(a, key);
                };

                const value = try map.nextValue(a, V);
                errdefer free(a, value);

                try if (unmanaged) hash_map.put(a, key, value) else hash_map.put(key, value);
            }

            return hash_map;
        }

        const is_hash_map_unmanaged = std.mem.startsWith(u8, @typeName(Value), "hash_map.HashMapUnmanaged");
        const is_array_hash_map_unmanaged = std.mem.startsWith(u8, @typeName(Value), "array_hash_map.ArrayHashMapUnmanaged");
    };
}
