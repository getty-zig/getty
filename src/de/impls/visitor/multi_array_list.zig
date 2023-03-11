const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime MultiArrayList: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = MultiArrayList;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (allocator == null) {
                return error.MissingAllocator;
            }

            const a = allocator.?;

            var list = Value{};
            errdefer free(a, Deserializer, list);

            while (try seq.nextElement(a, Value.Elem)) |elem| {
                errdefer free(a, Deserializer, elem);
                try list.append(a, elem);
            }

            return list;
        }
    };
}
