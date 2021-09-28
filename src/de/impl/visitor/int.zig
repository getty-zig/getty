const interface = @import("../../interface.zig");

const Allocator = @import("std").mem.Allocator;
const math = @import("std").math;

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
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

        fn visitFloat(_: *Self, comptime Error: type, input: anytype) Error!Value {
            if (math.round(input) != input or (input > math.maxInt(T) or input < math.minInt(T))) {
                @panic("Failure during float-to-int cast");
            }

            return @floatToInt(T, input);
        }

        fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
            return @intCast(T, input);
        }
    };
}
