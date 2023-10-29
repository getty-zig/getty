const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime SegmentedList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = SegmentedList;

        fn visitSeq(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            seq: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            var list = SegmentedList{};
            errdefer list.deinit(result_ally);

            const E = std.meta.Child(std.meta.FieldType(SegmentedList, .prealloc_segment));

            while (try seq.nextElement(result_ally, E)) |elem| {
                try list.append(result_ally, elem);
            }

            return list;
        }
    };
}
