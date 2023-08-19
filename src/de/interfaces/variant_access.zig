const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for variants of Getty Unions.
pub fn VariantAccess(
    /// An implementing type.
    comptime Impl: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        payloadSeed: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        payload: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, comptime T: type) E!T {
                unreachable;
            }
        }.f) = null,

        /// Returns true if the latest value deserialized by payloadSeed was
        /// allocated on the heap. Otherwise, false is returned.
        isPayloadAllocated: ?fn (Impl, comptime T: type) bool = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.VariantAccess" = struct {
            impl: Impl,

            const Self = @This();

            pub const Error = E;

            pub fn payloadSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Error!@TypeOf(seed).Value {
                if (methods.payloadSeed) |f| {
                    return try f(self.impl, ally, seed);
                }

                @compileError("payloadSeed is not implemented by type: " ++ @typeName(Impl));
            }

            pub fn payload(self: Self, ally: ?std.mem.Allocator, comptime T: type) Error!T {
                if (methods.payload) |f| {
                    return try f(self.impl, ally, T);
                } else {
                    var ds = DefaultSeed(T){};
                    const seed = ds.seed();

                    return try self.payloadSeed(ally, seed);
                }
            }

            pub fn isPayloadAllocated(self: Self, comptime T: type) bool {
                if (methods.isPayloadAllocated) |f| {
                    return f(self.impl, T);
                }

                return @typeInfo(T) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn variantAccess(impl: Impl) @"getty.de.VariantAccess" {
            return .{ .impl = impl };
        }
    };
}
