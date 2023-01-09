const std = @import("std");

const de = @import("../../de.zig").de;

pub fn Visitor(comptime PackedIntArray: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.Visitor(
            Self,
            Value,
            .{
                .visitSeq = visitSeq,
            },
        );

        const Value = PackedIntArray;

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
            if ((try seq.nextElement(allocator, de.Ignored)) != null) {
                return error.InvalidLength;
            }

            return array;
        }
    };
}
