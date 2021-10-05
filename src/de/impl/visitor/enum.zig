const interface = @import("../../interface.zig");

const Allocator = @import("std").mem.Allocator;
const math = @import("std").math;
const meta = @import("std").meta;

pub fn Visitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub usingnamespace interface.Visitor(
            *Self,
            Value,
            undefined,
            visitEnum,
            undefined,
            visitInt,
            undefined,
            undefined,
            undefined,
            visitString,
            undefined,
            undefined,
        );

        const Value = T;

        fn visitEnum(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return input;
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return meta.intToEnum(Value, input) catch unreachable;
        }

        fn visitString(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            return meta.stringToEnum(Value, input) orelse return error.UnknownVariant;
        }
    };
}
