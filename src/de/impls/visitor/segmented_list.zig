const std = @import("std");

const free = @import("../../free.zig").free;
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

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = SegmentedList{};
            errdefer free(ally.?, Deserializer, list);

            const E = std.meta.Child(std.meta.FieldType(SegmentedList, .prealloc_segment));

            while (try seq.nextElement(ally, E)) |elem| {
                try list.append(ally.?, elem);
            }

            return list;
        }
    };
}
