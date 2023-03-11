const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime BufMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = BufMap;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            if (allocator == null) {
                return error.MissingAllocator;
            }

            const a = allocator.?;

            var m = BufMap.init(a);
            errdefer free(a, Deserializer, m);

            while (try map.nextKey(a, []const u8)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(a, Deserializer, k);
                };

                const v = try map.nextValue(a, []const u8);
                defer free(a, Deserializer, v);

                try m.put(k, v);
            }

            return m;
        }
    };
}
