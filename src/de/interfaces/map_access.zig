const std = @import("std");

const de = @import("../../de.zig");

pub fn MapAccess(
    comptime Context: type,
    comptime E: type,
    comptime impls: struct {
        nextKeySeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        nextValueSeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        nextKey: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime K: type) E!?K {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        nextValue: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime V: type) E!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        pub const @"getty.de.MapAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextKeySeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) KeyReturn(@TypeOf(seed)) {
                if (impls.nextKeySeed) |f| {
                    return try f(self.context, allocator, seed);
                }

                @compileError("nextKeySeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn nextValueSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) ValueReturn(@TypeOf(seed)) {
                if (impls.nextValueSeed) |f| {
                    return try f(self.context, allocator, seed);
                }

                @compileError("nextValueSeed is not implemented by type: " ++ @typeName(Context));
            }

            //pub fn nextEntrySeed(self: Self, kseed: anytype, vseed: anytype) Error!?std.meta.Tuple(.{ @TypeOf(kseed).Value, @TypeOf(vseed).Value }) {
            //_ = self;
            //}

            pub fn nextKey(self: Self, allocator: ?std.mem.Allocator, comptime K: type) !?K {
                if (impls.nextKey) |f| {
                    return try f(self.context, allocator, K);
                } else {
                    var seed = de.de.DefaultSeed(K){};
                    const ds = seed.seed();

                    return try self.nextKeySeed(allocator, ds);
                }
            }

            pub fn nextValue(self: Self, allocator: ?std.mem.Allocator, comptime V: type) !V {
                if (impls.nextValue) |f| {
                    return try f(self.context, allocator, V);
                } else {
                    var seed = de.de.DefaultSeed(V){};
                    const ds = seed.seed();

                    return try self.nextValueSeed(allocator, ds);
                }
            }

            //pub fn nextEntry(self: Self, comptime K: type, comptime V: type) !?std.meta.Tuple(.{ K, V }) {
            //_ = self;
            //}

            fn KeyReturn(comptime Seed: type) type {
                comptime de.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }

            fn ValueReturn(comptime Seed: type) type {
                comptime de.concepts.@"getty.de.Seed"(Seed);

                return Error!Seed.Value;
            }
        };

        pub fn mapAccess(self: Context) @"getty.de.MapAccess" {
            return .{ .context = self };
        }
    };
}
