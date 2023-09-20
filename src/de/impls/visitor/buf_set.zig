const std = @import("std");

const free = @import("../../free.zig").free;
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

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var set = BufSet.init(ally);
            errdefer free(ally, Deserializer, set);

            while (try seq.nextElement(ally, []const u8)) |elem| {
                defer free(ally, Deserializer, elem);

                try set.insert(elem);
            }

            return set;
        }
    };
}
