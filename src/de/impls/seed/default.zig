const std = @import("std");

const de = @import("../../de.zig");

/// The default implementation of `getty.de.Seed`.
///
/// `DefaultSeed` is the default seed used by Getty. All it does is call
/// `getty.deserialize`.
pub fn DefaultSeed(
    /// The type to deserialize into.
    comptime Value: type,
) type {
    return struct {
        const Self = @This();

        pub usingnamespace de.de.Seed(
            Self,
            Value,
            .{ .deserialize = deserialize },
        );

        fn deserialize(_: Self, allocator: ?std.mem.Allocator, deserializer: anytype) @TypeOf(deserializer).Error!Value {
            return try de.deserialize(allocator, Value, deserializer);
        }
    };
}
