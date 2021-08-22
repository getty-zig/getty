const de = @import("../../../lib.zig").de;

pub fn IntVisitor(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Implements `getty.de.Visitor`.
        pub fn visitor(self: *Self) V {
            return .{ .context = self };
        }

        const V = de.Visitor(
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
        );

        fn visitFloat(_: *Self, comptime Error: type, input: anytype) Error!Value {
            comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Float);

            return @floatToInt(T, value);
        }

        fn visitInt(_: *Self, comptime Error: type, input: anytype) Error!Value {
            comptime std.debug.assert(@typeInfo(@TypeOf(input)) == .Int);

            return @intCast(T, value);
        }
    };
}
