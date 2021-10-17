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

        const K = blk: {
            inline for (std.meta.fields(HashMap.KV)) |field| {
                if (std.mem.eql(u8, "key", field.name)) {
                    break :blk field.field_type;
                }
            }

            unreachable;
        };

        const V = blk: {
            inline for (std.meta.fields(HashMap.KV)) |field| {
                if (std.mem.eql(u8, "value", field.name)) {
                    break :blk field.field_type;
                }
            }

            unreachable;
        };

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
            errdefer if (unmanaged) map.deinit(self.allocator) else map.deinit();

            while (try mapAccess.nextKey(K)) |key| {
                const value = try mapAccess.nextValue(V);
                try if (unmanaged) map.put(self.allocator, key, value) else map.put(key, value);
            }

            return map;
        }
    };
}
