const std = @import("std");

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

        fn visitSeq(_: Self, result_ally: std.mem.Allocator, scratch_ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            var array = Value.initUndefined();
            const V = Value.Value;

            for (&array.values) |*value| {
                if (try seq.nextElement(ally, V)) |v| {
                    value.* = v;
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
