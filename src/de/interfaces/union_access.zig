const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Unions.
pub fn UnionAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        variantSeed: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        ////////////////////////////////////////////////////////////////////////
        // Provided methods.
        ////////////////////////////////////////////////////////////////////////

        variant: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime T: type) E!T {
                unreachable;
            }
        }.f) = null,

        /// Returns true if the variant deserialized by variantSeed was
        /// allocated on the heap. Otherwise, false is returned.
        isVariantAllocated: ?fn (Impl, comptime V: type) bool = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.UnionAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = E;

            pub fn variantSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                if (methods.variantSeed) |f| {
                    return try f(self.impl, ally, seed);
                }

                @compileError("variantSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn variant(self: Self, ally: ?std.mem.Allocator, comptime T: type) Error!T {
                if (methods.variant) |f| {
                    return try f(self.impl, ally, T);
                } else {
                    var ds = DefaultSeed(T){};
                    const seed = ds.seed();

                    return try self.variantSeed(ally, seed);
                }
            }

            pub fn isVariantAllocated(self: Self, comptime V: type) bool {
                if (methods.isVariantAllocated) |f| {
                    return f(self.impl, V);
                }

                return @typeInfo(V) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn unionAccess(impl: Impl) @"getty.de.UnionAccess" {
            return .{ .impl = impl };
        }
    };
}
