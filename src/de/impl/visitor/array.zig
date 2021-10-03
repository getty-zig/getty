const std = @import("std");

const getty = @import("../../../lib.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        allocator: ?*std.mem.Allocator = null,

        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace getty.de.Visitor(
            *Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSequence,
            undefined,
            undefined,
            undefined,
        );

        fn visitSequence(self: *Self, sequenceAccess: anytype) @TypeOf(sequenceAccess).Error!Value {
            const Child = std.meta.Child(Value);
            var seen: usize = 0;
            var seq: Value = undefined;
            errdefer {
                var i: usize = 0;

                while (i < seen) : (i += 1) {
                    if (self.allocator) |allocator| getty.free(allocator, seq[i]);
                }
            }

            for (seq) |*elem| {
                if (try sequenceAccess.nextElement(Child)) |value| {
                    elem.* = value;
                    seen += 1;
                }
            }

            if (try sequenceAccess.nextElement(Child)) |_| {
                return error.InvalidLength;
            }

            return seq;
        }
    };
}
