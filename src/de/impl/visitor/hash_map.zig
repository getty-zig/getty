const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime HashMap: type) type {
    return struct {
        allocator: std.mem.Allocator,

        const Self = @This();
        const impl = @"impl Visitor"(HashMap);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.Value,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitMap,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime HashMap: type) type {
    const Self = Visitor(HashMap);

    return struct {
        pub const visitor = struct {
            pub const Value = HashMap;

            pub fn visitMap(self: Self, comptime Deserializer: type, map: anytype) Deserializer.Error!HashMap {
                var hash_map = if (unmanaged) HashMap{} else HashMap.init(self.allocator);
                errdefer getty.de.free(self.allocator, hash_map);

                while (try map.nextKey(K)) |key| {
                    errdefer getty.de.free(self.allocator, key);

                    const value = try map.nextValue(V);
                    errdefer getty.de.free(self.allocator, value);

                    try if (unmanaged) hash_map.put(self.allocator, key, value) else hash_map.put(key, value);
                }

                return hash_map;
            }

            const unmanaged = std.mem.startsWith(
                u8,
                @typeName(HashMap),
                "std.hash_map.HashMapUnmanaged",
            );

            const K = std.meta.fieldInfo(HashMap.KV, .key).field_type;
            const V = std.meta.fieldInfo(HashMap.KV, .value).field_type;
        };
    };
}
