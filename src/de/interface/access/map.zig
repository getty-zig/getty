const std = @import("std");

const DefaultSeed = @import("../../impl.zig").DefaultSeed;

pub fn MapAccess(
    comptime Context: type,
    comptime E: type,
    comptime nextKeySeedFn: @TypeOf(struct {
        fn f(c: Context, seed: anytype) E!?@TypeOf(seed).Value {
            _ = c;
            unreachable;
        }
    }.f),
    comptime nextValueSeedFn: @TypeOf(struct {
        fn f(c: Context, seed: anytype) E!@TypeOf(seed).Value {
            _ = c;
            unreachable;
        }
    }.f),
) type {
    const T = struct {
        context: Context,

        const Self = @This();

        pub const Error = E;

        pub fn nextKeySeed(self: Self, seed: anytype) Error!?@TypeOf(seed).Value {
            return try nextKeySeedFn(self.context, seed);
        }

        pub fn nextValueSeed(self: Self, seed: anytype) Error!@TypeOf(seed).Value {
            return try nextValueSeedFn(self.context, seed);
        }

        //pub fn nextEntrySeed(self: Self, kseed: anytype, vseed: anytype) Error!?std.meta.Tuple(.{ @TypeOf(kseed).Value, @TypeOf(vseed).Value }) {
        //_ = self;
        //}

        pub fn nextKey(self: Self, comptime K: type) !?K {
            var seed = DefaultSeed(K){};
            const ds = seed.seed();

            return try self.nextKeySeed(ds);
        }

        pub fn nextValue(self: Self, comptime V: type) !V {
            var seed = DefaultSeed(V){};
            const ds = seed.seed();

            return try self.nextValueSeed(ds);
        }

        //pub fn nextEntry(self: Self, comptime K: type, comptime V: type) !?std.meta.Tuple(.{ K, V }) {
        //_ = self;
        //}
    };

    return struct {
        pub fn mapAccess(self: Context) T {
            return .{ .context = self };
        }
    };
}
