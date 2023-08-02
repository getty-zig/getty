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

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var multiset = Value.initEmpty();
            errdefer free(allocator.?, Deserializer, multiset);

            const K = std.meta.FieldType(Value, .counts).Key;

            while (try seq.nextElement(allocator, K)) |key| {
                // defer free(allocator.?, Deserializer, key);
                try multiset.add(key, 1);
            }

            return multiset;
        }

        fn visitMap(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Error!Value {
            var multiset = Value.initEmpty();
            errdefer free(allocator.?, Deserializer, multiset);

            const K = std.meta.FieldType(Value, .counts).Key;
            const V = std.meta.FieldType(Value, .counts).Value;

            while (try map.nextKey(allocator, K)) |k| {
                defer if (map.isKeyAllocated(@TypeOf(k))) {
                    free(allocator.?, Deserializer, k);
                };

                const v = try map.nextValue(allocator, V);
                errdefer free(allocator.?, Deserializer, v);

                try multiset.add(k, v);
            }

            return multiset;
        }
    };
}
