const de = @import("../../../lib.zig").de;

const math = @import("std").math;

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace de.Visitor(
            *Self,
            Value,
            undefined,
            undefined,
            undefined,
            visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const Value = T;

        fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
            return @intCast(T, input);
        }
    };
}
