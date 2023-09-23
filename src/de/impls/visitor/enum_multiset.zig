const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime EnumMultiset: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
                .visitMap = visitMap,
            },
        );

        const Value = EnumMultiset;

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var multiset = Value.initEmpty();

            const K = std.meta.FieldType(Value, .counts).Key;

            while (try seq.nextElement(ally, K)) |key| {
                try multiset.add(key, 1);
            }

            return multiset;
        }

        fn visitMap(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            var multiset = Value.initEmpty();

            const K = std.meta.FieldType(Value, .counts).Key;
            const V = std.meta.FieldType(Value, .counts).Value;

            while (try map.nextKey(ally, K)) |ret| {
                var k = ret.value;
                defer {
                    const k_info = @typeInfo(K);
                    if (k_info == .Pointer and ret.lifetime == .heap) {
                        switch (k_info.Pointer.size) {
                            .One => ally.destroy(k),
                            .Slice => ally.free(k),
                            else => {},
                        }
                    }
                }

                const v = try map.nextValue(ally, V);
                try multiset.add(k, v);
            }

            return multiset;
        }
    };
}
