const std = @import("std");

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

        fn visitMap(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            map: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            var m = BufMap.init(result_ally);
            errdefer m.deinit();

            while (try map.nextKey(result_ally, []const u8)) |k| {
                const v = try map.nextValue(result_ally, []const u8);
                try m.put(k, v);
            }

            return m;
        }
    };
}
