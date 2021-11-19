const std = @import("std");

const DefaultSeed = @import("../../../lib.zig").de.DefaultSeed;

pub fn MapAccess(
    comptime Context: type,
    comptime Error: type,
    comptime nextKeySeed: @TypeOf(struct {
        fn f(c: Context, seed: anytype) Error!?@TypeOf(seed).Value {
            _ = c;

            unreachable;
        }
    }.f),
    comptime nextValueSeed: @TypeOf(struct {
        fn f(c: Context, seed: anytype) Error!@TypeOf(seed).Value {
            _ = c;

            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.MapAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn nextKeySeed(self: Self, seed: anytype) Error!?@TypeOf(seed).Value {
                return try nextKeySeed(self.context, seed);
            }

            pub fn nextValueSeed(self: Self, seed: anytype) Error!@TypeOf(seed).Value {
                return try nextValueSeed(self.context, seed);
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

        pub fn mapAccess(self: Context) @"getty.de.MapAccess" {
            return .{ .context = self };
        }
    };
}
