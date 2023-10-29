const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime BufSet: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = BufSet;

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var set = BufSet.init(ally);
            errdefer set.deinit();

            while (try seq.nextElement(ally, []const u8)) |elem| {
                try set.insert(elem);
            }

            return set;
        }
    };
}
