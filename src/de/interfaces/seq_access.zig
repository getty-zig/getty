const std = @import("std");

const DefaultSeed = @import("../impls/seed/default.zig").DefaultSeed;

/// Deserialization and access interface for Getty Sequences.
pub fn SeqAccess(
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The error set returned by the interface's methods upon failure.
    comptime E: type,
    /// A namespace containing the methods that implementations of `SeqAccess` can implement.
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

        /// Returns true if the latest value deserialized by nextElementSeed was
        /// allocated on the heap. Otherwise, false is returned.
        isElementAllocated: ?fn (Context, comptime T: type) bool = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.SeqAccess" = struct {
            context: Context,

            const Self = @This();

            pub const Error = E;

            pub fn nextElementSeed(self: Self, ally: ?std.mem.Allocator, seed: anytype) Error!?@TypeOf(seed).Value {
                if (methods.nextElementSeed) |f| {
                    return try f(self.context, ally, seed);
                }

                @compileError("nextElementSeed is not implemented by type: " ++ @typeName(Context));
            }

            pub fn nextElement(self: Self, ally: ?std.mem.Allocator, comptime Value: type) Error!?Value {
                if (methods.nextElement) |f| {
                    return try f(self.context, ally, Value);
                } else {
                    var seed = DefaultSeed(Value){};
                    const ds = seed.seed();

                    return try self.nextElementSeed(ally, ds);
                }
            }

            pub fn isElementAllocated(self: Self, comptime T: type) bool {
                if (methods.isElementAllocated) |f| {
                    return f(self.context, T);
                }

                return @typeInfo(T) == .Pointer;
            }
        };

        /// Returns an interface value.
        pub fn seqAccess(self: Context) @"getty.de.SeqAccess" {
            return .{ .context = self };
        }
    };
}
