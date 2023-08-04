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

        fn visitMap(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

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
