const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Maps.
pub fn MapAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime Err: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        nextKeySeed: NextKeySeedFn(Impl, Err) = null,
        nextValueSeed: NextValueSeedFn(Impl, Err) = null,
        nextKey: ?NextKeyFn(Impl, Err) = null,
        nextValue: ?NextValueFn(Impl, Err) = null,
        isKeyAllocated: ?IsAllocatedFn(Impl) = null,
        isValueAllocated: ?IsAllocatedFn(Impl) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.MapAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = Err;

            pub fn nextKeySeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Err!?@TypeOf(seed).Value {
                if (methods.nextKeySeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("nextKeySeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextValueSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
                if (methods.nextValueSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("nextValueSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextKey(self: Self, ally: ?std.mem.Allocator, comptime Key: type) Err!?Key {
                if (methods.nextKey) |func| {
                    return try func(self.impl, ally, Key);
                }

                var seed = DefaultSeed(Key){};
                const ds = seed.seed();

                return try self.nextKeySeed(ally, ds);
            }

            pub fn nextValue(self: Self, ally: ?std.mem.Allocator, comptime Value: type) Err!Value {
                if (methods.nextValue) |func| {
                    return try func(self.impl, ally, Value);
                }

                var seed = DefaultSeed(Value){};
                const ds = seed.seed();

                return try self.nextValueSeed(ally, ds);
            }

            pub fn isKeyAllocated(self: Self, comptime Key: type) bool {
                if (methods.isKeyAllocated) |func| {
                    return func(self.impl, Key);
                }

                return @typeInfo(Key) == .Pointer;
            }

            pub fn isValueAllocated(self: Self, comptime Value: type) bool {
                if (methods.isValueAllocated) |func| {
                    return func(self.impl, Value);
                }

                return @typeInfo(Value) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn mapAccess(impl: Impl) @"getty.de.MapAccess" {
            return .{ .impl = impl };
        }
    };
}

fn NextKeySeedFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, seed: anytype) Err!?@TypeOf(seed).Value {
            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn NextValueSeedFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn NextKeyFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, comptime Key: type) Err!?Key {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn NextValueFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, comptime Value: type) Err!Value {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn IsAllocatedFn(comptime Impl: type) type {
    return fn (Impl, comptime KV: type) bool;
}
