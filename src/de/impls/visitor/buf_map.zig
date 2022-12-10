const std = @import("std");

const de = @import("../../../de.zig").de;

pub fn Visitor(comptime BufMap: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{ .visitMap = visitMap },
        );

        const Value = BufMap;

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            var m = BufMap.init(allocator.?);
            errdefer de.free(allocator.?, m);

            while (try map.nextKey(allocator, []const u8)) |k| {
                defer de.free(allocator.?, k);

                const v = try map.nextValue(allocator, []const u8);
                defer de.free(allocator.?, v);

                try m.put(k, v);
            }

            return m;
        }
    };
}
