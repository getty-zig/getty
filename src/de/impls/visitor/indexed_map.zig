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

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            var m = Value{};

            while (try map.nextKey(ally, Value.Key)) |ret| {
                var k = ret.value;
                defer {
                    const k_info = @typeInfo(Value.Key);
                    if (k_info == .Pointer and ret.lifetime == .heap) {
                        switch (k_info.Pointer.size) {
                            .One => ally.destroy(k),
                            .Slice => ally.free(k),
                            else => {},
                        }
                    }
                }

                const v = try map.nextValue(ally, Value.Value);
                m.put(k, v);
            }

            return m;
        }
    };
}
