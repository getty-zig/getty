const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime HashMap: type) type {
    const unmanaged = comptime std.mem.startsWith(
        u8,
        @typeName(HashMap),
        "std.hash_map.HashMapUnmanaged",
    );

    return struct {
        allocator: *std.mem.Allocator,

        const Self = @This();

        const K = std.meta.fieldInfo(HashMap.KV, .key).field_type;
        const V = std.meta.fieldInfo(HashMap.KV, .value).field_type;

        pub usingnamespace getty.de.Visitor(
            Self,
            HashMap,
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

        fn visitMap(self: Self, mapAccess: anytype) @TypeOf(mapAccess).Error!HashMap {
            var map = if (unmanaged) HashMap{} else HashMap.init(self.allocator);
            errdefer getty.free(self.allocator, map);

            while (try mapAccess.nextKey(K)) |key| {
                const value = try mapAccess.nextValue(V);
                try if (unmanaged) map.put(self.allocator, key, value) else map.put(key, value);
            }

            return map;
        }
    };
}
