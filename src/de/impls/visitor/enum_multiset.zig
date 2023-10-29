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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var multiset = Value.initEmpty();

            const K = std.meta.FieldType(Value, .counts).Key;

            while (try seq.nextElement(ally, K)) |key| {
                try multiset.add(key, 1);
            }

            return multiset;
        }

        fn visitMap(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, map: anytype) Deserializer.Err!Value {
            var multiset = Value.initEmpty();

            const K = std.meta.FieldType(Value, .counts).Key;
            const V = std.meta.FieldType(Value, .counts).Value;

            while (try map.nextKey(ally, K)) |k| {
                const v = try map.nextValue(ally, V);
                try multiset.add(k, v);
            }

            return multiset;
        }
    };
}
