const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Sequences.
pub fn SeqAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime Err: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        nextElementSeed: ?NextElementSeedFn(Impl, Err) = null,
        nextElement: ?NextElementFn(Impl, Err) = null,
        isElementAllocated: ?IsElementAllocatedFn(Impl) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.SeqAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = Err;

            pub fn nextElementSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Err!?@TypeOf(seed).Value {
                if (methods.nextElementSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("nextElementSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextElement(self: Self, ally: ?std.mem.Allocator, comptime Elem: type) Err!?Elem {
                if (methods.nextElement) |func| {
                    return try func(self.impl, ally, Elem);
                }

                var seed = DefaultSeed(Elem){};
                const ds = seed.seed();

                return try self.nextElementSeed(ally, ds);
            }

            pub fn isElementAllocated(self: Self, comptime Elem: type) bool {
                if (methods.isElementAllocated) |func| {
                    return func(self.impl, Elem);
                }

                return @typeInfo(Elem) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn seqAccess(impl: Impl) @"getty.de.SeqAccess" {
            return .{ .impl = impl };
        }
    };
}

fn NextElementSeedFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, seed: anytype) Err!?@TypeOf(seed).Value {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn NextElementFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, comptime Elem: type) Err!?Elem {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn IsElementAllocatedFn(comptime Impl: type) type {
    return fn (Impl, comptime Elem: type) bool;
}
