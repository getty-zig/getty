const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Unions.
pub fn UnionAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime Err: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        variantSeed: VariantSeedFn(Impl, Err) = null,
        variant: ?VariantFn(Impl, Err) = null,
        isVariantAllocated: ?IsVariantAllocatedFn(Impl) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.UnionAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = Err;

            pub fn variantSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
                if (methods.variantSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("variantSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn variant(self: Self, ally: ?std.mem.Allocator, comptime Variant: type) Err!Variant {
                if (methods.variant) |func| {
                    return try func(self.impl, ally, Variant);
                }

                var ds = DefaultSeed(Variant){};
                const seed = ds.seed();

                return try self.variantSeed(ally, seed);
            }

            pub fn isVariantAllocated(self: Self, comptime Variant: type) bool {
                if (methods.isVariantAllocated) |func| {
                    return func(self.impl, Variant);
                }

                return @typeInfo(Variant) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn unionAccess(impl: Impl) @"getty.de.UnionAccess" {
            return .{ .impl = impl };
        }
    };
}

fn VariantSeedFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn VariantFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, comptime T: type) Err!T {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn IsVariantAllocatedFn(comptime Impl: type) type {
    return fn (Impl, comptime Variant: type) bool;
}
