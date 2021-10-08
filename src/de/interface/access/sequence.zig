const std = @import("std");

const DefaultSeed = @import("../../../lib.zig").de.DefaultSeed;

pub fn SequenceAccess(
    comptime Context: type,
    comptime E: type,
    comptime nextElementSeedFn: @TypeOf(struct {
        fn f(c: Context, seed: anytype) E!?@TypeOf(seed).Value {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn nextElementSeed(self: Self, seed: anytype) Error!?@TypeOf(seed).Value {
            return try nextElementSeedFn(self.context, seed);
        }

        pub fn nextElement(self: Self, comptime Value: type) Error!?Value {
            var seed = DefaultSeed(Value){};
            const ds = seed.seed();

            return try self.nextElementSeed(ds);
        }
    };

    return struct {
        pub fn sequenceAccess(self: Context) T {
            return .{ .context = self };
        }
    };
}
