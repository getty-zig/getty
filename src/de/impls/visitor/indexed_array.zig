const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime IndexedArray: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = IndexedArray;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var array = Value.initUndefined();
            var seen: usize = 0;

            const V = Value.Value;

            errdefer {
                if (ally) |a| {
                    for (array.values[0..seen]) |v| {
                        free(a, Deserializer, v);
                    }
                }
            }

            for (&array.values) |*value| {
                if (try seq.nextElement(ally, V)) |v| {
                    value.* = v;
                    seen += 1;
                } else {
                    // End of sequence was reached early.
                    return error.InvalidLength;
                }
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(ally, V)) != null) {
                return error.InvalidLength;
            }

            return array;
        }
    };
}
