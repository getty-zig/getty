const std = @import("std");

const Ignored = @import("../../impls/seed/ignored.zig").Ignored;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime PackedIntEndian: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
            },
        );

        const Value = PackedIntEndian;

        fn visitSeq(_: Self, ally: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var array = Value.initAllTo(0);

            if (array.len == 0) {
                return array;
            }

            for (0..array.len) |i| {
                if (try seq.nextElement(ally, Value.Child)) |value| {
                    array.set(i, value);
                } else {
                    // End of sequence was reached early.
                    return error.InvalidLength;
                }
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(ally, Ignored)) != null) {
                return error.InvalidLength;
            }

            return array;
        }
    };
}
