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

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            var m = Value{};
            errdefer free(allocator.?, Deserializer, m);

            while (try map.nextKey(allocator, Value.Key)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(allocator.?, Deserializer, k);
                };

                const v = try map.nextValue(allocator, Value.Value);
                errdefer free(allocator.?, Deserializer, v);

                m.put(k, v);
            }

            return m;
        }
    };
}
