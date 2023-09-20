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

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            var m = BufMap.init(ally);
            errdefer free(ally, Deserializer, m);

            while (try map.nextKey(ally, []const u8)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(ally, Deserializer, k);
                };

                const v = try map.nextValue(ally, []const u8);
                defer free(ally, Deserializer, v);

                try m.put(k, v);
            }

            return m;
        }
    };
}
