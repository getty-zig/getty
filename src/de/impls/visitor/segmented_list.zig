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

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = SegmentedList{};
            errdefer free(allocator.?, Deserializer, list);

            const E = std.meta.Child(std.meta.FieldType(SegmentedList, .prealloc_segment));

            while (try seq.nextElement(allocator, E)) |elem| {
                try list.append(allocator.?, elem);
            }

            return list;
        }
    };
}
