const std = @import("std");

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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var list = Value{};
            errdefer list.deinit(ally);

            while (try seq.nextElement(ally, Value.Elem)) |elem| {
                try list.append(ally, elem);
            }

            return list;
        }
    };
}
