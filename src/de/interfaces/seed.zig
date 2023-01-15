const std = @import("std");

const de = @import("../de.zig");

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
    /// A namespace that owns the method implementations passed to the `methods` parameter.
    comptime Context: type,
    /// The type produced by using this seed.
    comptime V: type,
    /// A namespace containing the methods that implementations of `Seed` can implement.
    comptime methods: struct {
        deserialize: ?@TypeOf(struct {
            fn f(_: Context, _: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V {
                unreachable;
            }
        }.f) = null,
    },
) type {
    return struct {
        /// An interface type.
        pub const @"getty.de.Seed" = struct {
            context: Context,

            const Self = @This();

            pub const Value = V;

            pub fn deserialize(self: Self, allocator: ?std.mem.Allocator, deserializer: anytype) Return(@TypeOf(deserializer)) {
                if (methods.deserialize) |f| {
                    return try f(self.context, allocator, deserializer);
                }

                @compileError("deserialize is not implemented by type: " ++ @typeName(Context));
            }
        };

        /// Returns an interface value.
        pub fn seed(self: Context) @"getty.de.Seed" {
            return .{ .context = self };
        }

        fn Return(comptime Deserializer: type) type {
            comptime de.de.concepts.@"getty.Deserializer"(Deserializer);

            return Deserializer.Error!V;
        }
    };
}
