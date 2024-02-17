const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Unions.
pub fn UnionAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        variantSeed: VariantSeedFn(Impl, E) = null,
        variant: ?VariantFn(Impl, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.UnionAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Err = E;

            pub fn variantSeed(self: Self, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                if (methods.variantSeed) |func| {
                    return try func(self.impl, arena, seed);
                }

                @compileError("variantSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn variant(self: Self, arena: std.mem.Allocator, comptime Variant: type) E!Variant {
                if (methods.variant) |func| {
                    return try func(self.impl, arena, Variant);
                }

                var ds = DefaultSeed(Variant){};
                const seed = ds.seed();

                return try self.variantSeed(arena, seed);
            }
        };

        /// Returns an interface value.
        pub fn unionAccess(impl: Impl) @"getty.de.UnionAccess" {
            return .{ .impl = impl };
        }
    };
}

fn VariantSeedFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VariantFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, comptime T: type) E!T {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}
