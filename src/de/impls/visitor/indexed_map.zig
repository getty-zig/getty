const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime IndexedMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = IndexedMap;

        fn visitMap(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            var m = Value{};
            errdefer free(ally.?, Deserializer, m);

            while (try map.nextKey(ally, Value.Key)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(ally.?, Deserializer, k);
                };

                const v = try map.nextValue(ally, Value.Value);
                errdefer free(ally.?, Deserializer, v);

                m.put(k, v);
            }

            return m;
        }
    };
}
