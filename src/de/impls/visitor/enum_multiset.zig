const std = @import("std");

const free = @import("../../free.zig").free;
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

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var multiset = Value.initEmpty();
            errdefer free(ally.?, Deserializer, multiset);

            const K = std.meta.FieldType(Value, .counts).Key;

            while (try seq.nextElement(ally, K)) |key| {
                try multiset.add(key, 1);
            }

            return multiset;
        }

        fn visitMap(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            var multiset = Value.initEmpty();
            errdefer free(ally.?, Deserializer, multiset);

            const K = std.meta.FieldType(Value, .counts).Key;
            const V = std.meta.FieldType(Value, .counts).Value;

            while (try map.nextKey(ally, K)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(ally.?, Deserializer, k);
                };

                const v = try map.nextValue(ally, V);
                errdefer free(ally.?, Deserializer, v);

                try multiset.add(k, v);
            }

            return multiset;
        }
    };
}
