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

        fn visitSeq(
            _: Self,
            result_ally: std.mem.Allocator,
            scratch_ally: std.mem.Allocator,
            comptime Deserializer: type,
            seq: anytype,
        ) Deserializer.Err!Value {
            _ = scratch_ally;

            var list = Value{};
            errdefer list.deinit(result_ally);

            while (try seq.nextElement(result_ally, Value.Elem)) |elem| {
                try list.append(result_ally, elem);
            }

            return list;
        }
    };
}
