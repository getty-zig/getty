const std = @import("std");

const de = @import("../../de.zig");

/// Deserialization and access interface for Getty Sequences.
pub fn SeqAccess(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace for the methods that implementations of the interface can implement.
    comptime methods: struct {
        nextElementSeed: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value {
                unreachable;
            }
        }.f) = null,

        // Provided method.
        nextElement: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, comptime Value: type) E!?Value {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.SeqAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextElementSeed(self: Self, allocator: ?std.mem.Allocator, seed: anytype) Return(@TypeOf(seed)) {
                if (methods.nextElementSeed) |f| {
                    return try f(self.context, allocator, seed);
                }

                @compileError("nextElementSeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn nextElement(self: Self, allocator: ?std.mem.Allocator, comptime Value: type) Error!?Value {
                if (methods.nextElement) |f| {
                    return try f(self.context, allocator, Value);
                } else {
                    var seed = de.de.DefaultSeed(Value){};
                    const ds = seed.seed();

                    return try self.nextElementSeed(allocator, ds);
                }
            }

            fn Return(comptime Seed: type) type {
                comptime de.concepts.@"getty.de.Seed"(Seed);

                return Error!?Seed.Value;
            }
        };

        /// Returns an interface value.
        pub fn seqAccess(self: Context) @"getty.de.SeqAccess" {
            return .{ .context = self };
        }
    };
}
