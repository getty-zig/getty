const std = @import("std");

const de = @import("../../de.zig");

/// Deserialization seed interface.
pub fn Seed(
    /// The namespace that owns the method implementations provided in `methods`.
    comptime Context: type,
    /// The type to deserialize into.
    comptime V: type,
    /// A namespace for the methods that implementations of the interface can implement.
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
            comptime de.concepts.@"getty.Deserializer"(Deserializer);

            return Deserializer.Error!V;
        }
    };
}
