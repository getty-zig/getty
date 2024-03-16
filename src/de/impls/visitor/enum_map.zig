const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime EnumMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = EnumMap;

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            var m = Value{};

            while (try map.nextKey(ally, Value.Key)) |k| {
                const v = try map.nextValue(ally, Value.Value);
                m.put(k, v);
            }

            return m;
        }
    };
}
