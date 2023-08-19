const std = @import("std");

/// A `Seed` facilitates stateful deserialization.
///
/// Generally speaking, deserialization tends to be a stateless operation.
/// However, you may occasionally find yourself wanting to pass in data to the
/// deserialization process. In such cases, you can use a `Seed` to do so.
///
/// To give you an example of stateful deserialization, suppose you wanted to
/// deserialize a JSON array into a `std.ArrayList(T)`. Normally, what would
/// happen is that a freshly allocated `std.ArrayList(T)` would be created and
/// returned. However, by using a `Seed`, you could instead provide Getty with
/// a pre-allocated `std.ArrayList(T)` for it to deserialize into.
pub fn Seed(
    /// An implementing type.
    comptime Impl: type,
    /// The type produced by using this seed.
    comptime V: type,
    /// A namespace containing methods that `Impl` must define or can override.
    comptime methods: struct {
        deserialize: ?@TypeOf(struct {
            fn f(_: Impl, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.Seed" = struct {
            impl: Impl,

            const Self = @This();

            pub const Value = V;

            pub fn deserialize(self: Self, ally: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                if (methods.deserialize) |f| {
                    return try f(self.impl, ally, deserializer);
                }

                @compileError("deserialize is not implemented by type: " ++ @typeName(Impl));
            }
        };

        /// Returns an interface value.
        pub fn seed(impl: Impl) @"getty.de.Seed" {
            return .{ .impl = impl };
        }
    };
}
