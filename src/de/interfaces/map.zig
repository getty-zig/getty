const getty = @import("../../lib.zig");
const std = @import("std");

pub fn Map(
    comptime Context: type,
    comptime Error: type,
    comptime nextKeySeed: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
    comptime nextValueSeed: @TypeOf(struct {
        fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
            unreachable;
        }
    }.f),
) type {
    return struct {
        pub const @"getty.de.Map" = struct {
            context: Context,

            const Self = @This();

            pub const Error = Error;

            pub fn nextKeySeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) KeyReturn(@TypeOf(seed)) {
                return try nextKeySeed(self.context, allocator, seed);
            }

            pub fn nextValueSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) ValueReturn(@TypeOf(seed)) {
                return try nextValueSeed(self.context, allocator, seed);
            }

            //pub fn nextEntrySeed(self: Self, kseed: anytype, vseed: anytype) Error!?std.meta.Tuple(.{ @TypeOf(kseed).Value, @TypeOf(vseed).Value }) {
            //_ = self;
            //}

            pub fn nextKey(self: Self, allocator: ?std.mem.Allocator, comptime K: type) !?K {
                var seed = getty.de.DefaultSeed(K){};
                const ds = seed.seed();

                return try self.nextKeySeed(allocator, ds);
            }

            pub fn nextValue(self: Self, allocator: ?std.mem.Allocator, comptime V: type) !V {
                var seed = getty.de.DefaultSeed(V){};
                const ds = seed.seed();

                return try self.nextValueSeed(allocator, ds);
            }

            //pub fn nextEntry(self: Self, comptime K: type, comptime V: type) !?std.meta.Tuple(.{ K, V }) {
            //_ = self;
            //}

            fn KeyReturn(comptime Seed: type) type {
                comptime getty.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }

            fn ValueReturn(comptime Seed: type) type {
                comptime getty.concepts.@"getty.de.Seed"(Seed);

                return Error!Seed.Value;
            }
        };

        pub fn map(self: Context) @"getty.de.Map" {
            return .{ .context = self };
        }
    };
}
