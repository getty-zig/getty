const Seed = @import("../../impl.zig").Seed;

pub fn SeqAccess(
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
            var seed = Seed(Value){};
            const ds = seed.deserializeSeed();

            return (try self.nextElementSeed(ds)).?;
        }
    };

    return struct {
        pub fn seqAccess(self: Context) T {
            return .{ .context = self };
        }
    };
}
