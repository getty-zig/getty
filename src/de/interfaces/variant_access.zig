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
        isPayloadAllocated: ?IsPayloadAllocatedFn(Impl) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.VariantAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = E;

            pub fn payloadSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                if (methods.payloadSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("payloadSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn payload(self: Self, ally: ?std.mem.Allocator, comptime Payload: type) E!Payload {
                if (methods.payload) |func| {
                    return try func(self.impl, ally, Payload);
                }

                var ds = DefaultSeed(Payload){};
                const seed = ds.seed();

                return try self.payloadSeed(ally, seed);
            }

            pub fn isPayloadAllocated(self: Self, comptime Payload: type) bool {
                if (methods.isPayloadAllocated) |func| {
                    return func(self.impl, Payload);
                }

                return @typeInfo(Payload) == .Pointer;
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
        fn func(impl: Impl, ally: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return ?@TypeOf(Lambda.func);
}

fn PayloadFn(comptime Impl: type, comptime E: type) type {
    const Lambda = struct {
        fn func(impl: Impl, ally: ?std.mem.Allocator, comptime Payload: type) E!Payload {
            _ = impl;
            _ = ally;

            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn IsPayloadAllocatedFn(comptime Impl: type) type {
    return fn (Impl, comptime Payload: type) bool;
}
