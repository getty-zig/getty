const std = @import("std");

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

        fn visitMap(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            map: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            var m = Value{};

            while (try map.nextKey(result_ally, Value.Key)) |k| {
                const v = try map.nextValue(result_ally, Value.Value);
                m.put(k, v);
            }

            return m;
        }
    };
}
