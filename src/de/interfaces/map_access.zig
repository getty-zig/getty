const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Maps.
pub fn MapAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        nextKeySeed: NextKeySeedFn(Impl, E) = null,
        nextValueSeed: NextValueSeedFn(Impl, E) = null,
        nextKey: ?NextKeyFn(Impl, E) = null,
        nextValue: ?NextValueFn(Impl, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.MapAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Err = E;

            pub fn nextKeySeed(self: Self, arena: std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
                if (methods.nextKeySeed) |func| {
                    return try func(self.impl, arena, seed);
                }

                @compileError("nextKeySeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextValueSeed(self: Self, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                if (methods.nextValueSeed) |func| {
                    return try func(self.impl, arena, seed);
                }

                @compileError("nextValueSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextKey(self: Self, arena: std.mem.Allocator, comptime Key: type) E!?Key {
                if (methods.nextKey) |func| {
                    return try func(self.impl, arena, Key);
                }

                var seed = DefaultSeed(Key){};
                const ds = seed.seed();

                return try self.nextKeySeed(arena, ds);
            }

            pub fn nextValue(self: Self, arena: std.mem.Allocator, comptime Value: type) E!Value {
                if (methods.nextValue) |func| {
                    return try func(self.impl, arena, Value);
                }

                var seed = DefaultSeed(Value){};
                const ds = seed.seed();

                return try self.nextValueSeed(arena, ds);
            }
        };

        /// Returns an interface value.
        pub fn mapAccess(impl: Impl) @"getty.de.MapAccess" {
            return .{ .impl = impl };
        }
    };
}

fn NextKeySeedFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn NextValueSeedFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn NextKeyFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, comptime Key: type) E!?Key {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn NextValueFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, comptime Value: type) E!Value {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}
