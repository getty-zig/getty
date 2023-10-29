const std = @import("std");

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

        fn visitMap(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            const K = std.meta.fieldInfo(Value.KV, .key).type;
            const V = std.meta.fieldInfo(Value.KV, .value).type;
            const unmanaged = is_hash_map_unmanaged or is_array_hash_map_unmanaged;

            var hash_map = if (unmanaged) HashMap{} else HashMap.init(ally);
            errdefer if (unmanaged) hash_map.deinit(ally) else hash_map.deinit();

            while (try map.nextKey(ally, K)) |key| {
                const value = try map.nextValue(ally, V);
                try if (unmanaged) hash_map.put(ally, key, value) else hash_map.put(key, value);
            }

            return hash_map;
        }

        const is_hash_map_unmanaged = std.mem.startsWith(u8, @typeName(Value), "hash_map.HashMapUnmanaged");
        const is_array_hash_map_unmanaged = std.mem.startsWith(u8, @typeName(Value), "array_hash_map.ArrayHashMapUnmanaged");
    };
}
