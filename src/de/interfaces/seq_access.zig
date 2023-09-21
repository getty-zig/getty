const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Sequences.
pub fn SeqAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        nextElementSeed: NextElementSeedFn(Impl, E) = null,
        nextElement: ?NextElementFn(Impl, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.SeqAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Err = E;

            pub fn nextElementSeed(self: Self, ally: std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
                if (methods.nextElementSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("nextElementSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn nextElement(self: Self, ally: std.mem.Allocator, comptime Elem: type) E!?Elem {
                if (methods.nextElement) |func| {
                    return try func(self.impl, ally, Elem);
                }

                var seed = DefaultSeed(Elem){};
                const ds = seed.seed();

                return try self.nextElementSeed(ally, ds);
            }
        };

        /// Returns an interface value.
        pub fn seqAccess(impl: Impl) @"getty.de.SeqAccess" {
            return .{ .impl = impl };
        }
    };
}

fn NextElementSeedFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn NextElementFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: std.mem.Allocator, comptime Elem: type) E!?Elem {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}
