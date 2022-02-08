const getty = @import("../../../lib.zig");
const std = @import("std");

pub fn Visitor(comptime HashMap: type) type {
    return struct {
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

            pub fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!HashMap {
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
