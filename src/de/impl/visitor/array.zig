const std = @import("std");

const interface = @import("../../interface.zig");

pub fn Visitor(comptime Value: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
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
            _ = self;

            var seq: Value = undefined;
            const Child = std.meta.Child(Value);

            for (seq) |*elem| {
                if (try sequenceAccess.nextElement(Child)) |value| {
                    elem.* = value;
                }
            }

            if (try sequenceAccess.nextElement(Child)) |_| {
                @panic("expected end of sequence, found element");
            }

            return seq;
        }
    };
}
