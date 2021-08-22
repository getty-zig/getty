const de = @import("../../../lib.zig").de;

pub fn FloatVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) de.Visitor(
            *Self,
            T,
            undefined,
            visitFloat,
            visitInt,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
        ) {
            return .{ .context = self };
        }

        fn visitFloat(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Float);

            return @floatCast(T, value);
        }

        fn visitInt(self: *Self, comptime Error: type, input: anytype) Error!Value {
            _ = self;

            comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Int);

            return @intToFloat(T, value);
        }
    };
}
