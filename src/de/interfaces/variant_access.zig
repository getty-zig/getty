const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for variants of Getty Unions.
pub fn VariantAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        payloadSeed: PayloadSeedFn(Impl, E) = null,
        payload: ?PayloadFn(Impl, E) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.VariantAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Err = E;

            pub fn payloadSeed(self: Self, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                if (methods.payloadSeed) |func| {
                    return try func(self.impl, arena, seed);
                }

                @compileError("payloadSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn payload(self: Self, arena: std.mem.Allocator, comptime Payload: type) E!Payload {
                if (methods.payload) |func| {
                    return try func(self.impl, arena, Payload);
                }

                var ds = DefaultSeed(Payload){};
                const seed = ds.seed();

                return try self.payloadSeed(arena, seed);
            }
        };

        /// Returns an interface value.
        pub fn variantAccess(impl: Impl) @"getty.de.VariantAccess" {
            return .{ .impl = impl };
        }
    };
}

fn PayloadSeedFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn PayloadFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, arena: std.mem.Allocator, comptime Payload: type) E!Payload {
            _ = impl;
            _ = arena;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}
