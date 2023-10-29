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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = SegmentedList{};
            errdefer list.deinit(ally);

            const E = std.meta.Child(std.meta.FieldType(SegmentedList, .prealloc_segment));

            while (try seq.nextElement(ally, E)) |elem| {
                try list.append(ally, elem);
            }

            return list;
        }
    };
}
