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

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var array = Value.initAllTo(0);

            if (array.len == 0) {
                return array;
            }

            var i: usize = 0;
            while (i < array.len) : (i += 1) {
                if (try seq.nextElement(allocator, Value.Child)) |value| {
                    array.set(i, value);
                } else {
                    // End of sequence was reached early.
                    return error.InvalidLength;
                }
            }

            // Expected end of sequence, but found an element.
            if ((try seq.nextElement(allocator, Ignored)) != null) {
                return error.InvalidLength;
            }

            return array;
        }
    };
}
