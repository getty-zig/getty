const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime IndexedSet: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = IndexedSet;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var set = Value.initEmpty();
            errdefer free(ally.?, Deserializer, set);

            while (try seq.nextElement(ally, Value.Key)) |k| {
                defer free(ally.?, Deserializer, k);
                set.insert(k);
            }

            return set;
        }
    };
}
