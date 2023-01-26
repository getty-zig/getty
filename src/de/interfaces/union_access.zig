const std = @import("std");

const concepts = @import("../concepts.zig");
const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Unions.
pub fn UnionAccess(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing the methods that implementations of `UnionAccess` can implement.
    comptime methods: struct {
        variantSeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) Return(E, @TypeOf(seed)) {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        variant: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime T: type) E!T {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.UnionAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn variantSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(Error, @TypeOf(seed)) {
                if (methods.variantSeed) |f| {
                    return try f(self.context, allocator, seed);
                }

                @compileError("variantSeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn variant(self: Self, allocator: ?std.mem.Allocator, comptime T: type) Error!T {
                if (methods.variant) |f| {
                    return try f(self.context, allocator, T);
                } else {
                    var ds = DefaultSeed(T){};
                    const seed = ds.seed();

                    return try self.variantSeed(allocator, seed);
                }
            }
        };

        /// Returns an interface value.
        pub fn unionAccess(self: Context) @"getty.de.UnionAccess" {
            return .{ .context = self };
        }
    };
}

fn Return(comptime Error: type, comptime Seed: type) type {
    comptime concepts.@"getty.de.Seed"(Seed);

    return Error!Seed.Value;
}
