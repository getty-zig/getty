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
            var m = BufMap.init(allocator.?);
            errdefer free(allocator.?, m);

            while (try map.nextKey(allocator, []const u8)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(allocator.?, k);
                };

                const v = try map.nextValue(allocator, []const u8);
                defer free(allocator.?, v);

                try m.put(k, v);
            }

            return m;
        }
    };
}
