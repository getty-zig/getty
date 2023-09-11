const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for variants of Getty Unions.
pub fn VariantAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set to be returned by the interface's methods upon failure.
    comptime Err: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        payloadSeed: ?PayloadSeedFn(Impl, Err) = null,
        payload: ?PayloadFn(Impl, Err) = null,
        isPayloadAllocated: ?IsPayloadAllocatedFn(Impl) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.VariantAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = Err;

            pub fn payloadSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
                if (methods.payloadSeed) |func| {
                    return try func(self.impl, ally, seed);
                }

                @compileError("payloadSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn payload(self: Self, ally: ?std.mem.Allocator, comptime Payload: type) Err!Payload {
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

fn PayloadSeedFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, seed: anytype) Err!@TypeOf(seed).Value {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn PayloadFn(comptime Impl: type, comptime Err: type) type {
    const Lambda = struct {
        fn func(_: Impl, _: ?std.mem.Allocator, comptime Payload: type) Err!Payload {
            unreachable;
        }
    };

    return @TypeOf(Lambda.func);
}

fn IsPayloadAllocatedFn(comptime Impl: type) type {
    return fn (Impl, comptime Payload: type) bool;
}
