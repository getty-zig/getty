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

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (ally == null) {
                return error.MissingAllocator;
            }

            const a = ally.?;

            var set = BufSet.init(a);
            errdefer free(a, Deserializer, set);

            while (try seq.nextElement(a, []const u8)) |elem| {
                defer free(a, Deserializer, elem);

                try set.insert(elem);
            }

            return set;
        }
    };
}
