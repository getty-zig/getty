const de = @import("../../../lib.zig").de;

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            visitFloat,
            visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        );

        const Value = T;

        fn visitFloat(self: Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return @floatCast(T, input);
        }

        fn visitInt(self: Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return @intToFloat(T, input);
        }
    };
}
