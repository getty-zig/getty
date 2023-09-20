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

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = Value{};
            errdefer free(ally, Deserializer, list);

            while (try seq.nextElement(ally, Value.Elem)) |elem| {
                errdefer free(ally, Deserializer, elem);
                try list.append(ally, elem);
            }

            return list;
        }
    };
}
