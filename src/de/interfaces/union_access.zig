const std = @import("std");

const de = @import("../de.zig");

/// Deserialization and access interface for Getty Unions.
pub fn UnionAccess(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace for the methods that implementations of the interface can implement.
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
                    var ds = de.de.DefaultSeed(T){};
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
    comptime de.concepts.@"getty.de.Seed"(Seed);

    return Error!Seed.Value;
}
